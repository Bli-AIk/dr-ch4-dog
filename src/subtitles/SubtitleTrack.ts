import {Txt} from '@motion-canvas/2d';
import {ThreadGenerator, waitFor} from '@motion-canvas/core';

import type {SubtitleCue} from './types';

export interface SubtitleTrackOptions {
  fadeDuration?: number;
}

/** Play a subtitle cue list against a single text node. */
export function* playSubtitleTrack(
  text: Txt,
  cues: readonly SubtitleCue[],
  {fadeDuration = 0.12}: SubtitleTrackOptions = {},
): ThreadGenerator {
  let cursor = 0;

  for (const cue of cues) {
    if (cue.start < cursor) {
      throw new Error(`Subtitle ${cue.id} overlaps the previous cue`);
    }

    const duration = cue.end - cue.start;
    const fade = Math.min(Math.max(fadeDuration, 0), duration / 2);

    yield* waitFor(cue.start - cursor);
    text.text(cue.text);

    if (fade > 0) {
      yield* text.opacity(1, fade);
    } else {
      text.opacity(1);
    }

    yield* waitFor(duration - fade * 2);

    if (fade > 0) {
      yield* text.opacity(0, fade);
    } else {
      text.opacity(0);
    }

    cursor = cue.end;
  }
}
