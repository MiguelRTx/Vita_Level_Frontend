import { createServer } from 'node:http';
import { readFile, stat, realpath } from 'node:fs/promises';
import { resolve, extname, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { gzipSync } from 'node:zlib';

const mimeTypes = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.mjs': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.json': 'application/json; charset=utf-8', '.svg': 'image/svg+xml', '.png': 'image/png', '.ico': 'image/x-icon', '.wasm': 'application/wasm', '.ttf': 'font/ttf', '.otf': 'font/otf', '.woff2': 'font/woff2', '.txt': 'text/plain; charset=utf-8' };

export function contentSecurityPolicy(apiOrigin) {
  const url = new URL(apiOrigin);
  if (!['http:', 'https:'].includes(url.protocol) || url.origin !== apiOrigin || url.username || url.password) throw new Error('Expected a public API origin.');
  return ["default-src 'self'", "script-src 'self' 'wasm-unsafe-eval'", "style-src 'self' 'unsafe-inline'", `connect-src 'self' ${url.origin}`, "font-src 'self'", "img-src 'self' data: blob:", "worker-src 'self' blob:", "object-src 'none'", "frame-src 'none'", "frame-ancestors 'none'", "base-uri 'self'", "form-action 'self'"].join('; ');
}

export function createWebServer({ root = fileURLToPath(new URL('../build/web/', import.meta.url)), apiOrigin = 'http://localhost:3000' } = {}) {
  const directory = resolve(root);
  const cache = new Map();
  const policy = contentSecurityPolicy(apiOrigin);
  return createServer(async (request, response) => {
    response.setHeader('Content-Security-Policy', policy);
    response.setHeader('X-Content-Type-Options', 'nosniff');
    response.setHeader('X-Frame-Options', 'DENY');
    response.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
    response.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=(), payment=()');
    response.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    response.setHeader('Vary', 'Accept-Encoding');
    if (!['GET', 'HEAD'].includes(request.method)) { response.writeHead(405, { Allow: 'GET, HEAD' }); response.end(); return; }
    try {
      const pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
      if (pathname.includes('\0') || pathname.includes('\\') || pathname.split('/').some((part) => part.startsWith('.'))) throw new Error('Invalid asset path');
      let path = resolve(directory, `.${pathname === '/' ? '/index.html' : pathname}`);
      if (!path.startsWith(directory + sep)) throw new Error('Invalid asset path');
      path = await realpath(path);
      if (!path.toLowerCase().startsWith((directory + sep).toLowerCase())) throw new Error('Invalid asset path');
      const info = await stat(path);
      if (!info.isFile()) throw new Error('Not a file');
      const key = `${path}:${info.mtimeMs}:${info.size}`;
      let asset = cache.get(key);
      if (!asset) {
        const bytes = await readFile(path);
        const type = mimeTypes[extname(path)] ?? 'application/octet-stream';
        const compressed = bytes.length > 1024 && /javascript|json|text|svg|wasm|font/.test(type) ? gzipSync(bytes, { level: 6 }) : null;
        asset = { bytes, compressed, type, etag: `W/"${createHash('sha256').update(bytes).digest('hex')}"` };
        if (cache.size >= 64) cache.clear();
        cache.set(key, asset);
      }
      response.setHeader('Content-Type', asset.type);
      response.setHeader('Cache-Control', 'public, max-age=0, must-revalidate');
      response.setHeader('ETag', asset.etag);
      if (request.headers['if-none-match'] === asset.etag) { response.writeHead(304); response.end(); return; }
      const acceptsGzip = (request.headers['accept-encoding'] ?? '').split(',').some((part) => {
        const [name, quality] = part.trim().split(';');
        return name === 'gzip' && (quality === undefined || Number(quality.trim().replace('q=', '')) > 0);
      });
      const bytes = acceptsGzip && asset.compressed ? asset.compressed : asset.bytes;
      if (bytes === asset.compressed) response.setHeader('Content-Encoding', 'gzip');
      response.setHeader('Content-Length', bytes.length);
      response.writeHead(200); response.end(request.method === 'HEAD' ? undefined : bytes);
    } catch {
      response.setHeader('Cache-Control', 'no-store');
      response.setHeader('Content-Type', 'text/html; charset=utf-8');
      const fallback = await readFile(resolve(directory, '404.html')).catch(() => Buffer.from('<!doctype html><html lang="es"><title>404 · Ritmo</title><h1>404</h1><p>Esta página no existe.</p><a href="/">Volver a Ritmo</a></html>'));
      response.writeHead(404); response.end(request.method === 'HEAD' ? undefined : fallback);
    }
  });
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const port = Number(process.env.WEB_PORT ?? 5173);
  const host = process.env.WEB_HOST ?? 'localhost';
  const root = fileURLToPath(new URL('../build/web/', import.meta.url));
  await stat(resolve(root, 'index.html')).catch(() => { throw new Error('Build Flutter web before starting the web server.'); });
  const server = createWebServer({ root, apiOrigin: process.env.API_ORIGIN ?? 'http://localhost:3000' });
  server.on('error', () => { console.error('Web server could not start. Check WEB_PORT and whether another process is using it.'); process.exitCode = 1; });
  server.listen(port, host, () => console.info(`Ritmo disponible en http://${host}:${port}`));
  for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => { server.close(); server.closeIdleConnections(); });
}
