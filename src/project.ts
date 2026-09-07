import {makeProject} from '@motion-canvas/core';

import example from './scenes/example?scene';
import './global.css';

export default makeProject({
  scenes: [example],
  audio: '/audio/episode-01.wav',
});
