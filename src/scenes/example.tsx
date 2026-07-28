import {Circle, Rect, Txt, makeScene2D} from '@motion-canvas/2d';
import {all, createRef} from '@motion-canvas/core';

import episodeSubtitles from '../subtitles/episode-01.srt?raw';
import {parseSrt} from '../subtitles/parseSrt';
import {playSubtitleTrack} from '../subtitles/SubtitleTrack';

const SUBTITLE_FONT_FAMILY = 'Fusion Pixel 10px';
const SUBTITLE_FONT_CSS = `"${SUBTITLE_FONT_FAMILY}"`;
const SUBTITLE_FONT_SIZE = 58;

export default makeScene2D(function* (view) {
  yield Promise.all([
    document.fonts.load(
      `400 ${SUBTITLE_FONT_SIZE}px "${SUBTITLE_FONT_FAMILY}"`,
      '这是一个由字幕驱动的动画。',
    ),
    document.fonts.load(
      `400 ${SUBTITLE_FONT_SIZE}px "${SUBTITLE_FONT_FAMILY}"`,
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
    ),
  ]);

  const circle = createRef<Circle>();
  const subtitle = createRef<Txt>();

  view.add(<Rect width={1920} height={1080} fill={'#17202a'} />);

  view.add(
    <Circle
      ref={circle}
      size={320}
      fill={'#49c5b6'}
      shadowColor={'rgba(0, 0, 0, 0.28)'}
      shadowBlur={30}
      shadowOffsetY={18}
    />,
  );

  view.add(
    <Txt
      ref={subtitle}
      text={''}
      y={390}
      width={1600}
      fontFamily={SUBTITLE_FONT_CSS}
      fontSize={SUBTITLE_FONT_SIZE}
      fontWeight={400}
      lineHeight={'125%'}
      textAlign={'center'}
      textWrap={true}
      fill={'#ffffff'}
      stroke={'#000000'}
      strokeFirst={true}
      lineWidth={12}
      shadowColor={'rgba(0, 0, 0, 0.35)'}
      shadowBlur={12}
      shadowOffsetY={4}
      opacity={0}
    />,
  );

  yield* all(
    circle().scale(2, 2).to(1, 2),
    playSubtitleTrack(subtitle(), parseSrt(episodeSubtitles)),
  );
});
