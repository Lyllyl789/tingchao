import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';

const root = new URL('../', import.meta.url);
const files = new Map([
  ['/', ['studio/index.html', 'text/html; charset=utf-8']],
  ['/studio.css', ['studio/studio.css', 'text/css; charset=utf-8']],
  ['/studio.js', ['studio/studio.js', 'text/javascript; charset=utf-8']],
  ['/calculator.worker.js', ['studio/calculator.worker.js', 'text/javascript; charset=utf-8']],
  ['/compiled/engine.js', ['studio/compiled/engine.js', 'text/javascript; charset=utf-8']],
  ['/mark.svg', ['identity/mark.svg', 'image/svg+xml']],
  ...['retail', 'energy', 'visitors', 'accuracy-tradeoff'].map(name =>
    [`/cases/${name}.json`, [`cases/${name}.json`, 'application/json; charset=utf-8']]),
]);

const server = createServer(async (req, res) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('Referrer-Policy', 'no-referrer');
  res.setHeader('Content-Security-Policy', "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'");
  const item = files.get(req.url);
  if (req.method !== 'GET' || !item) {
    res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    return res.end('Not found');
  }
  try {
    const content = await readFile(new URL(item[0], root));
    res.writeHead(200, { 'Content-Type': item[1] });
    res.end(content);
  } catch {
    res.writeHead(503, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Required application asset is unavailable. Run the documented build first.');
  }
});

server.on('error', () => {
  console.error('Could not start the studio. Check whether port 8787 is available.');
  process.exitCode = 1;
});
server.listen(8787, '127.0.0.1', () => console.log('Tingchao Studio: http://127.0.0.1:8787'));
