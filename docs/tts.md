# Local TTS

The project uses Piper's `zh_CN-chaowen-medium` voice. It runs on the CPU, so no CUDA or discrete GPU is required.

## Run

Use two terminals from the project root:

```bash
pnpm tts:server
pnpm audio:generate
```

For automatic regeneration while editing the subtitle file:

```bash
pnpm audio:watch
```

The watcher hashes each normalized dialogue together with the Piper model and synthesis parameters. An unchanged dialogue reuses `audio-cache/episode-01/*.wav`; only a changed dialogue makes a new request to `http://127.0.0.1:5000/synthesize`. The final WAV is rebuilt from the cached clips and written to `public/audio/episode-01.wav`.

The mix places each clip at the cue's SRT start time. It does not change the SRT timing or automatically speed up speech when a generated clip is longer than its cue.

## First-time setup

The local environment used by this project is `.venv-tts/`. If it is missing, install the CPU dependencies with `uv`:

```bash
uv venv .venv-tts --python 3.13
uv pip install --python .venv-tts/bin/python 'piper-tts[http]'
uv pip install --python .venv-tts/bin/python 'torch>=2,<3' --index-url https://download.pytorch.org/whl/cpu
uv pip install --python .venv-tts/bin/python 'g2pW>=0.1.1,<1' 'sentence-stream>=1.2.1,<2' 'unicode-rbnf>=2.4,<3' 'requests>=2,<3' socksio
pnpm tts:download
```

Piper may download the Chinese `g2pW` resource on the first synthesis request. It is kept in the ignored `g2pW/` directory.
