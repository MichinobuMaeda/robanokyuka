import {vi} from "vitest";
import type {CallableRequest} from "firebase-functions/https";
import type {
  DocumentSnapshot,
  DocumentReference,
} from "firebase-admin/firestore";

import type {Context} from "./common";

const testEmail = (uid: string) => `${uid}@example.com`;

export const adminId = "admin01id";
export const user01Id = "user01id";
export const user02Id = "user02id";
export const adminEmail = testEmail(adminId);
export const user01Email = testEmail(user01Id);
export const user02Email = testEmail(user02Id);
export const uiVersion = "0.1.2+1";

/**
 * Creates a mock Firestore {@link DocumentSnapshot} for use in unit tests.
 *
 * @param {Record<string, unknown>} fields - Field values returned by `snapshot.get(field)`.
 * @param {Partial<DocumentReference>} ref - Optional overrides merged into `snapshot.ref`.
 * @return {DocumentSnapshot} A stub snapshot with `get` and `ref` populated.
 */
export function makeDocSnapshot(
  fields: Record<string, unknown>,
  ref?: Partial<DocumentReference>,
): DocumentSnapshot {
  return {
    get: (field: string) => fields[field],
    ref: {
      set: vi.fn(),
      update: vi.fn(),
      ...ref,
    } as unknown as DocumentReference,
  } as unknown as DocumentSnapshot;
}

/**
 * Creates a mock {@link Context} for use in unit tests.
 *
 * Returns the context alongside individual vi mock functions so tests can
 * assert on calls to `db`, `auth`, and `logger` without re-querying them
 * from the context object.
 *
 * Default behavior:
 * - `service/conf` returns `{ admins: ["admin01id"], uiVersion: "0.1.2+1" }`
 * - `service/version` returns `{ id: "version" }`
 * - `users/<uid>` document does not exist (`exists: false`)
 * - `auth.getUserByEmail` resolves with `{ uid: "user01id" }`
 * - `auth.createUser` resolves with `{ uid: "new-uid" }`
 * - `db.batch()` returns a stub with `set`, `update`, and `commit` mocks
 *
 * @param {Partial<Context>} overrides - Optional properties to merge into the
 *   context, replacing the default mocks.
 * @return {{ context: Context, logger: { info: vi.Mock, error: vi.Mock },
 *   collection: vi.Mock, usersDoc: vi.Mock, usersGet: vi.Mock,
 *   serviceDoc: vi.Mock, set: vi.Mock, get: vi.Mock, update: vi.Mock,
 *   batch: { set: vi.Mock, update: vi.Mock, commit: vi.Mock },
 *   auth: { getUserByEmail: vi.Mock, getUser: vi.Mock, createUser: vi.Mock,
 *     deleteUser: vi.Mock, updateUser: vi.Mock }
 * }} The mock context and its constituent vi mock functions.
 */
export function makeContext(overrides?: Partial<Context>) {
  const set = vi.fn().mockResolvedValue(undefined);
  const update = vi.fn().mockResolvedValue(undefined);
  const get = vi.fn().mockResolvedValue({
    data: () => ({admins: [adminId], uiVersion}),
  });

  const batch = {
    set: vi.fn(),
    update: vi.fn(),
    commit: vi.fn().mockResolvedValue(undefined),
  };

  const usersGet = vi.fn().mockResolvedValue({exists: false});
  const usersDoc = vi.fn().mockReturnValue({set, get: usersGet});
  const serviceDoc = vi.fn((id: string) => {
    if (id === "conf") {
      return {id: "conf", get, update};
    }
    if (id === "version") {
      return {id: "version"};
    }
    return {id, set, get, update};
  });

  const collection = vi.fn((name: string) => {
    if (name === "users") {
      return {doc: usersDoc};
    }
    if (name === "service") {
      return {doc: serviceDoc};
    }
    return {doc: vi.fn()};
  });

  const auth = {
    getUserByEmail: vi.fn().mockResolvedValue({uid: user01Id}),
    getUser: vi.fn(async (uid: string) => ({uid, email: `${uid}@example.com`})),
    createUser: vi.fn().mockResolvedValue({uid: user02Id}),
    deleteUser: vi.fn().mockResolvedValue(undefined),
    updateUser: vi.fn().mockResolvedValue(undefined),
  };

  const db = {
    collection,
    batch: vi.fn().mockReturnValue(batch),
  };
  const logger = {
    info: vi.fn(),
    error: vi.fn(),
  };

  const context = {logger, db, auth, ...overrides} as unknown as Context;

  return {
    context,
    logger,
    collection,
    usersDoc,
    usersGet,
    serviceDoc,
    set,
    get,
    update,
    batch,
    auth,
  };
}

/**
 * Creates a mock {@link CallableRequest} for use in unit tests.
 *
 * @param {string | undefined} uid - The caller UID to embed in `event.auth`.
 *   Pass `undefined` to produce a request with no `auth` property, simulating
 *   an unauthenticated call.
 * @param {unknown} data - Optional request data payload.
 * @return {CallableRequest} A {@link CallableRequest} stub.
 */
export function makeEvent(
  uid: string | undefined,
  data: unknown = {},
): CallableRequest {
  return {
    data,
    auth: uid !== undefined ?
      {uid, token: {} as never, rawToken: ""} :
      undefined,
    rawRequest: {} as never,
    acceptsStreaming: false,
  } as CallableRequest;
}
