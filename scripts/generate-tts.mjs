import {createHash} from 'node:crypto';
import {existsSync, mkdirSync, readFileSync, renameSync, watch} from 'node:fs';
import {writeFile} from 'node:fs/promises';
import {basename, dirname, isAbsolute, join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');

const config = {
  subtitlePath: resolveFromRoot(process.env.SUBTITLE_FILE ?? 'src/subtitles/episode-01.srt'),
  cacheDir: resolveFromRoot(process.env.TTS_CACHE_DIR ?? 'audio-cache/episode-01'),
  outputPath: resolveFromRoot(process.env.TTS_OUTPUT ?? 'public/audio/episode-01.wav'),
  endpoint: process.env.PIPER_URL ?? 'http://127.0.0.1:5000/synthesize',
  model: process.env.PIPER_MODEL ?? 'zh_CN-chaowen-medium',
  speakerId: 0,
  lengthScale: 1,
  noiseScale: 0.667,
  noiseWScale: 0.8,
};

function resolveFromRoot(value) {
  return isAbsolute(value) ? value : resolve(projectRoot, value);
}

function parseTimestamp(value, cueId) {
  const match = value.match(/^(\d{1,2}):(\d{2}):(\d{2})[,.](\d{3})$/);
  if (!match) {
    throw new Error(`Invalid ${cueId} timestamp: ${value}`);
  }

  const hours = Number(match[1]);
  const minutes = Number(match[2]);
  const seconds = Number(match[3]);
  const milliseconds = Number(match[4]);

  if (minutes >= 60 || seconds >= 60) {
    throw new Error(`Invalid ${cueId} timestamp: ${value}`);
  }

  return hours * 3600 + minutes * 60 + seconds + milliseconds / 1000;
}

function parseSrt(source) {
  const normalized = source.replace(/^\uFEFF/, '').replace(/\r\n?/g, '\n').trim();
  if (!normalized) {
    return [];
  }

  return normalized.split(/\n{2,}/).map((block, blockIndex) => {
    const lines = block.split('\n');
    const timeLineIndex = lines.findIndex(line => line.includes('-->'));
    if (timeLineIndex === -1) {
      throw new Error(`Subtitle block ${blockIndex + 1} has no timing line`);
    }

    const timing = lines[timeLineIndex].match(/^\s*(\S+)\s+-->\s+(\S+)/);
    if (!timing) {
      throw new Error(`Subtitle block ${blockIndex + 1} has invalid timing`);
    }

    const id = lines.slice(0, timeLineIndex).join(' ').trim() || String(blockIndex + 1);
    const start = parseTimestamp(timing[1], `${id} start`);
    const end = parseTimestamp(timing[2], `${id} end`);
    const text = lines.slice(timeLineIndex + 1).join('\n').trim();

    if (start >= end) {
      throw new Error(`Subtitle ${id} must end after it starts`);
    }
    if (!text) {
      throw new Error(`Subtitle ${id} has no text`);
    }

    return {id, start, end, text};
  });
}

function normalizeSpeechText(text) {
  return text.replace(/\s+/g, ' ').trim();
}

function getCueHash(text) {
  const cacheKey = JSON.stringify({
    text,
    model: config.model,
    speakerId: config.speakerId,
    lengthScale: config.lengthScale,
    noiseScale: config.noiseScale,
    noiseWScale: config.noiseWScale,
  });

  return createHash('sha256').update(cacheKey).digest('hex');
}

function ensureParent(filePath) {
  mkdirSync(dirname(filePath), {recursive: true});
}

function isWav(buffer) {
  return buffer.length >= 44 && buffer.toString('ascii', 0, 4) === 'RIFF' && buffer.toString('ascii', 8, 12) === 'WAVE';
}

async function synthesizeCue(text, outputPath) {
  const response = await fetch(config.endpoint, {
    method: 'POST',
    headers: {'content-type': 'application/json'},
    body: JSON.stringify({
      text,
      voice: config.model,
      speaker_id: config.speakerId,
      length_scale: config.lengthScale,
      noise_scale: config.noiseScale,
      noise_w_scale: config.noiseWScale,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Piper returned HTTP ${response.status}: ${errorText.slice(0, 300)}`);
  }

  const audio = Buffer.from(await response.arrayBuffer());
  if (!isWav(audio)) {
    throw new Error('Piper returned data that is not a WAV file');
  }

  const temporaryPath = `${outputPath}.tmp`;
  ensureParent(outputPath);
  await writeFile(temporaryPath, audio);
  renameSync(temporaryPath, outputPath);
}

function runFfmpeg(args) {
  const result = spawnSync('ffmpeg', args, {
    cwd: projectRoot,
    stdio: 'inherit',
  });

  if (result.error) {
    throw new Error(`Unable to start ffmpeg: ${result.error.message}`);
  }
  if (result.status !== 0) {
    throw new Error(`ffmpeg exited with status ${result.status}`);
  }
}

function mixCues(cues, audioPaths) {
  ensureParent(config.outputPath);

  const filterParts = [];
  for (let index = 0; index < cues.length; index += 1) {
    const delayMilliseconds = Math.round(cues[index].start * 1000);
    filterParts.push(`[${index}:a]adelay=${delayMilliseconds}|${delayMilliseconds}[cue${index}]`);
  }

  const inputLabels = cues.map((_, index) => `[cue${index}]`).join('');
  filterParts.push(`${inputLabels}amix=inputs=${cues.length}:duration=longest:dropout_transition=0:normalize=0[mixed]`);
  filterParts.push('[mixed]alimiter=limit=0.95:level=0[out]');

  const temporaryPath = `${config.outputPath}.tmp.wav`;
  const args = ['-hide_banner', '-loglevel', 'warning', '-y'];
  for (const audioPath of audioPaths) {
    args.push('-i', audioPath);
  }
  args.push(
    '-filter_complex',
    filterParts.join(';'),
    '-map',
    '[out]',
    '-ac',
    '1',
    '-ar',
    '22050',
    '-c:a',
    'pcm_s16le',
    temporaryPath,
  );

  runFfmpeg(args);
  renameSync(temporaryPath, config.outputPath);
}

async function generateAudio() {
  const source = readFileSync(config.subtitlePath, 'utf8');
  const cues = parseSrt(source);
  if (cues.length === 0) {
    throw new Error(`No subtitle cues found in ${config.subtitlePath}`);
  }

  mkdirSync(config.cacheDir, {recursive: true});
  const audioPaths = [];
  let generatedCount = 0;

  for (const cue of cues) {
    const speechText = normalizeSpeechText(cue.text);
    const hash = getCueHash(speechText);
    const audioPath = join(config.cacheDir, `${hash}.wav`);

    if (existsSync(audioPath)) {
      console.log(`[cache] cue ${cue.id}: ${hash.slice(0, 12)}`);
    } else {
      console.log(`[tts] cue ${cue.id}: ${speechText}`);
      await synthesizeCue(speechText, audioPath);
      generatedCount += 1;
    }

    audioPaths.push(audioPath);
  }

  if (generatedCount === 0) {
    console.log('[tts] no cue text changed; reusing cached WAV files');
  }
  console.log(`[mix] ${audioPaths.length} cue(s) -> ${config.outputPath}`);
  mixCues(cues, audioPaths);
  console.log(`[done] generated ${generatedCount} new cue(s)`);
}

function printConfig() {
  console.log(`字幕: ${config.subtitlePath}`);
  console.log(`Piper: ${config.endpoint} (${config.model})`);
  console.log(`缓存: ${config.cacheDir}`);
  console.log(`输出: ${config.outputPath}`);
}

async function main() {
  const watchMode = process.argv.includes('--watch');
  printConfig();
  await generateAudio();

  if (!watchMode) {
    return;
  }

  console.log('[watch] waiting for subtitle changes...');
  let running = false;
  let pending = false;
  let timer;

  const rerun = async () => {
    if (running) {
      pending = true;
      return;
    }

    running = true;
    try {
      await generateAudio();
    } catch (error) {
      console.error(`[watch] ${error instanceof Error ? error.message : error}`);
    } finally {
      running = false;
      if (pending) {
        pending = false;
        await rerun();
      }
    }
  };

  watch(dirname(config.subtitlePath), (eventType, filename) => {
    if (filename && filename.toString() !== basename(config.subtitlePath)) {
      return;
    }
    clearTimeout(timer);
    timer = setTimeout(() => void rerun(), 250);
  });
}

main().catch(error => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
