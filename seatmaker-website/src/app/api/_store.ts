// Simple in-memory store for serverless demo. In production, swap with KV/SQLite.
export type StoredDoc = {
  doc: any;
  createdAt: number;
  revoked: boolean;
};

const store = new Map<string, StoredDoc>();

export function put(slug: string, doc: any) {
  store.set(slug, { doc, createdAt: Date.now(), revoked: false });
}

export function get(slug: string): StoredDoc | undefined {
  return store.get(slug);
}

export function revoke(slug: string) {
  const cur = store.get(slug);
  if (cur) store.set(slug, { ...cur, revoked: true });
}


