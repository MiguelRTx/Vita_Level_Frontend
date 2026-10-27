import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { request } from 'node:http';
import { mkdir, writeFile, rm } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { join, resolve } from 'node:path';
import { gunzipSync } from 'node:zlib';
import { createWebServer, contentSecurityPolicy } from './serve_web.mjs';

const workspace = fileURLToPath(new URL('../.local/', import.meta.url));
const root = join(workspace, `web-test-${randomUUID()}`);
const source = 'window.example = 1;\n'.repeat(2000);
let server; let port;
function get(path, headers = {}, method = 'GET') {
  return new Promise((resolveResponse, reject) => {
    const req = request({ hostname: '127.0.0.1', port, path, method, headers }, (response) => {
      const chunks = [];
      response.on('data', (chunk) => chunks.push(chunk));
      response.on('end', () => resolveResponse({ status: response.statusCode, headers: response.headers, body: Buffer.concat(chunks) }));
    });
    req.on('error', reject); req.end();
  });
}
before(async () => {
  await mkdir(root, { recursive: true });
  await writeFile(join(root, 'index.html'), '<!doctype html><title>Ritmo</title>');
  await writeFile(join(root, '404.html'), '<!doctype html><title>404 · Ritmo</title>');
  await writeFile(join(root, 'main.dart.js'), source);
  await writeFile(join(root, '.env'), 'PRIVATE_FIXTURE');
  server = createWebServer({ root });
  await new Promise((done) => server.listen(0, '127.0.0.1', done)); port = server.address().port;
});
after(async () => {
  await new Promise((done) => server.close(done));
  if (!resolve(root).startsWith(resolve(workspace))) throw new Error('Invalid fixture directory');
  await rm(root, { recursive: true, force: true });
});
test('web CSP allows local Flutter/WASM but not inline scripts, eval, frames or remote scripts', async () => {
  const response = await get('/'); const policy = response.headers['content-security-policy'];
  assert.equal(response.status, 200);
  assert.match(policy, /script-src 'self' 'wasm-unsafe-eval';/);
  assert.doesNotMatch(policy, /script-src[^;]*'unsafe-inline'|script-src[^;]*'unsafe-eval'/);
  assert.match(policy, /frame-ancestors 'none'/);
  assert.match(policy, /connect-src 'self' http:\/\/localhost:3000/);
  assert.equal(response.headers['x-content-type-options'], 'nosniff');
  assert.throws(() => contentSecurityPolicy('https://name:password@api.example.test'));
});
test('gzip and ETag reduce repeat transfers without caching outdated unversioned bundles', async () => {
  const compressed = await get('/main.dart.js', { 'accept-encoding': 'gzip' });
  assert.equal(compressed.headers['content-encoding'], 'gzip');
  assert.equal(gunzipSync(compressed.body).toString(), source);
  assert.ok(compressed.body.length < source.length / 10);
  const unchanged = await get('/main.dart.js', { 'if-none-match': compressed.headers.etag });
  assert.equal(unchanged.status, 304); assert.equal(unchanged.body.length, 0);
  assert.match(compressed.headers['cache-control'], /must-revalidate/);
  assert.equal((await get('/main.dart.js', { 'accept-encoding': 'gzip;q=0' })).headers['content-encoding'], undefined);
});
test('missing routes and confidential paths return a real custom 404', async () => {
  for (const path of ['/missing', '/.env', '/%2e%2e/.env', '/%00']) {
    const response = await get(path); assert.equal(response.status, 404); assert.match(response.body.toString(), /404 · Ritmo/); assert.doesNotMatch(response.body.toString(), /PRIVATE_FIXTURE/);
  }
  assert.equal((await get('/', {}, 'POST')).status, 405);
  assert.equal((await get('/', {}, 'HEAD')).body.length, 0);
});
