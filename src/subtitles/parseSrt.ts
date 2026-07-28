import type {SubtitleCue} from './types';

const TIMESTAMP_PATTERN = /^\s*(\S+)\s+-->\s+(\S+)/;

function parseTimestamp(value: string, cueId: string): number {
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

/** Parse the SRT format while keeping subtitle timing in seconds. */
export function parseSrt(source: string): SubtitleCue[] {
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

    const timing = lines[timeLineIndex].match(TIMESTAMP_PATTERN);

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
