// Browser-side API client. Every call goes to /api/*, which Next.js proxies to the
// Node API server, so no secret ever reaches the browser.

export async function api<T = any>(path: string, body?: unknown): Promise<T> {
  const res = await fetch(
    path,
    body === undefined ? { cache: 'no-store' } : { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }
  );
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || `Request failed (${res.status})`);
  return data as T;
}

export type SseHandlers = Record<string, (data: any) => void | Promise<void>>;

// POSTs and reads a text/event-stream response, calling handlers[event](data) in order.
// If the server answered with JSON instead (e.g. "start this guided flow"), returns it.
export async function streamPost<T = any>(path: string, body: unknown, handlers: SseHandlers, signal?: AbortSignal): Promise<T | null> {
  const res = await fetch(path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
    signal,
  });
  const type = res.headers.get('content-type') || '';
  if (!type.includes('text/event-stream')) {
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(data.error || `Request failed (${res.status})`);
    return data as T;
  }
  const reader = res.body!.getReader();
  const decoder = new TextDecoder();
  let buffer = '';
  for (;;) {
    const { value, done } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });
    let idx;
    while ((idx = buffer.indexOf('\n\n')) >= 0) {
      const raw = buffer.slice(0, idx);
      buffer = buffer.slice(idx + 2);
      let event = 'message';
      let data = '';
      for (const line of raw.split('\n')) {
        if (line.startsWith('event:')) event = line.slice(6).trim();
        else if (line.startsWith('data:')) data += line.slice(5).trim();
      }
      let parsed: any = null;
      try {
        parsed = data ? JSON.parse(data) : null;
      } catch {
        parsed = null;
      }
      const handler = handlers[event];
      if (handler) await handler(parsed);
    }
  }
  return null;
}
