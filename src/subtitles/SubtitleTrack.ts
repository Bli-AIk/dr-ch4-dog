import {Txt} from '@motion-canvas/2d';
import {ThreadGenerator, waitFor} from '@motion-canvas/core';

import type {SubtitleCue} from './types';

/** Play a subtitle cue list against a single text node. */
export function* playSubtitleTrack(
  text: Txt,
  cues: readonly SubtitleCue[],
): ThreadGenerator {
  let cursor = 0;

  for (const cue of cues) {
    if (cue.start < cursor) {
      throw new Error(`Subtitle ${cue.id} overlaps the previous cue`);
    }

    yield* waitFor(cue.start - cursor);
    text.text(cue.text);

    text.opacity(1);
    yield* waitFor(cue.end - cue.start);
    text.opacity(0);

    cursor = cue.end;
  }
}
