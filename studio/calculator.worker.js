import { coordinate } from './compiled/engine.js';

self.onmessage = event => {
  try {
    self.postMessage({ id: event.data.id, output: coordinate(event.data.source) });
  } catch {
    self.postMessage({ id: event.data.id, failure: true });
  }
};
