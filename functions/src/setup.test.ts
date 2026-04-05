/* eslint-disable require-jsdoc */
import {describe, it, expect, vi, beforeEach} from "vitest";
import {setup} from "./setup";
import type {Context} from "./common";
import type {
  DocumentSnapshot,
  DocumentReference,
  WriteBatch,
  CollectionReference,
} from "firebase-admin/firestore";

function makeDocSnapshot(
  fields: Record<string, unknown>,
  ref?: Partial<DocumentReference>
): DocumentSnapshot {
  return {
    get: (field: string) => fields[field],
    // eslint-disable-next-line max-len
    ref: {set: vi.fn(), update: vi.fn(), ...ref} as unknown as DocumentReference,
  } as unknown as DocumentSnapshot;
}

function makeContext(overrides?: Partial<Context>): Context {
  const batch = {
    set: vi.fn(),
    update: vi.fn(),
    commit: vi.fn().mockResolvedValue(undefined),
  } as unknown as WriteBatch;

  const confDocRef = {
    id: "conf",
    get: vi.fn().mockResolvedValue({
      data: () => ({uiVersion: "0.1.2+1"}),
    }),
    update: vi.fn().mockResolvedValue(undefined),
  } as unknown as DocumentReference;
  const versionDocRef = {id: "version"} as unknown as DocumentReference;
  const userDocRef = {
    id: "test-uid",
    get: vi.fn().mockResolvedValue({exists: false}),
    set: vi.fn().mockResolvedValue(undefined),
  } as unknown as DocumentReference;
  const serviceCollection = {
    doc: vi.fn((id: string) => {
      if (id === "conf") {
        return confDocRef;
      }
      if (id === "version") {
        return versionDocRef;
      }
      return {id} as unknown as DocumentReference;
    }),
  } as unknown as CollectionReference;
  const usersCollection = {
    doc: vi.fn().mockReturnValue(userDocRef),
  } as unknown as CollectionReference;

  const db = {
    batch: vi.fn().mockReturnValue(batch),
    collection: vi.fn((path: string) => {
      if (path === "service") {
        return serviceCollection;
      }
      if (path === "users") {
        return usersCollection;
      }
      return {doc: vi.fn()} as unknown as CollectionReference;
    }),
  };

  const auth = {
    createUser: vi.fn().mockResolvedValue({uid: "test-uid"}),
    getUserByEmail: vi.fn().mockResolvedValue({uid: "test-uid"}),
  };

  const logger = {
    info: vi.fn(),
    error: vi.fn(),
  };

  return {logger, db, auth, ...overrides} as unknown as Context;
}

describe("setup", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.UI_VERSION = "0.1.2+1";
  });

  it("does nothing when data is undefined", async () => {
    const ctx = makeContext();
    await setup(ctx, {data: undefined});
    expect(ctx.logger.info).toHaveBeenCalledWith(
      "No deleted document found, skipping setup"
    );
  });

  it("does nothing when version >= 2", async () => {
    const ctx = makeContext();
    const data = makeDocSnapshot({version: 2});
    await setup(ctx, {data});
    expect(ctx.auth.createUser).not.toHaveBeenCalled();
    expect(ctx.logger.info).toHaveBeenCalledWith(
      "UI version is already up to date:",
      "0.1.2+1"
    );
  });

  it("runs setupV2 when version is 1", async () => {
    const ctx = makeContext();
    const data = makeDocSnapshot({version: 1});

    await setup(ctx, {data});

    expect(ctx.auth.createUser).not.toHaveBeenCalled();
    expect(ctx.logger.info).toHaveBeenCalledWith(
      "Performing setup for version 2"
    );
    expect(ctx.db.batch).toHaveBeenCalled();
    expect(data.ref.set).toHaveBeenCalledWith({
      version: 2,
      createdAt: expect.any(Date),
    });
  });

  it("defaults missing version to 0 and runs setupV1", async () => {
    const ctx = makeContext();
    const data = makeDocSnapshot({email: "admin@example.com"});
    await setup(ctx, {data});
    expect(ctx.logger.info).toHaveBeenCalledWith(
      "Setting up for data version",
      0
    );
    expect(ctx.auth.createUser).toHaveBeenCalledWith({
      email: "admin@example.com",
    });
    expect(ctx.db.batch().commit).toHaveBeenCalled();
  });

  it("calls setupV1 when version is 0", async () => {
    const ctx = makeContext();
    const data = makeDocSnapshot({version: 0, email: "admin@example.com"});
    await setup(ctx, {data});
    expect(
      ctx.auth.createUser
    ).toHaveBeenCalledWith({email: "admin@example.com"});
    expect(ctx.db.batch().commit).toHaveBeenCalled();
  });

  it("logs error and returns when no email in version document", async () => {
    const ctx = makeContext();
    const data = makeDocSnapshot({version: 0, email: undefined});
    await setup(ctx, {data});
    expect(
      ctx.logger.error
    ).toHaveBeenCalledWith("No admin email provided in the version document");
    expect(ctx.auth.createUser).not.toHaveBeenCalled();
  });

  it("logs error when setup throws", async () => {
    const ctx = makeContext();
    const data = makeDocSnapshot(
      {version: 0, email: "admin@example.com"},
      {
        set: vi.fn().mockRejectedValue(new Error("Firestore write failed")),
      }
    );
    await setup(ctx, {data});
    expect(ctx.logger.error).toHaveBeenCalledWith(
      "Error during setup:",
      expect.any(Error),
      expect.stringContaining("Firestore write failed")
    );
  });

  it("logs error without stack when setup throws non-Error", async () => {
    const ctx = makeContext();
    const data = makeDocSnapshot(
      {version: 0, email: "admin@example.com"},
      {
        set: vi.fn().mockRejectedValue("Firestore write failed"),
      }
    );
    await setup(ctx, {data});
    expect(ctx.logger.error).toHaveBeenCalledWith(
      "Error during setup:",
      "Firestore write failed",
      undefined
    );
  });

  // eslint-disable-next-line max-len
  it("updates UI version when it differs from the deployed version", async () => {
    const ctx = makeContext({
      db: {
        batch: vi.fn().mockReturnValue({
          set: vi.fn(),
          update: vi.fn(),
          commit: vi.fn().mockResolvedValue(undefined),
        } as unknown as WriteBatch),
        collection: vi.fn((path: string) => {
          if (path === "service") {
            return {
              doc: vi.fn((id: string) => {
                if (id === "conf") {
                  return {
                    get: vi.fn().mockResolvedValue({
                      data: () => ({uiVersion: "0.1.1+1"}),
                    }),
                    update: vi.fn().mockResolvedValue(undefined),
                  } as unknown as DocumentReference;
                }
                return {id} as unknown as DocumentReference;
              }),
            } as unknown as CollectionReference;
          }
          return {
            doc: vi.fn().mockReturnValue({id: "test-uid"}),
          } as unknown as CollectionReference;
        }),
      } as unknown as Context["db"],
    });

    await setup(ctx, {data: makeDocSnapshot({version: 1})});

    expect(ctx.logger.info).toHaveBeenCalledWith(
      "Updating UI version to:",
      "0.1.2+1"
    );
  });

  it("logs error with stack trace when setupV1 throws", async () => {
    const err = new Error("createUser failed");
    const ctx = makeContext({
      auth: {
        createUser: vi.fn().mockRejectedValue(err),
      } as unknown as Context["auth"],
    });
    const data = makeDocSnapshot({version: 0, email: "admin@example.com"});
    await setup(ctx, {data});
    expect(ctx.logger.error).toHaveBeenCalledWith(
      "Error during setupV1:", err, err.stack
    );
  });

  it("logs error without stack when setupV1 throws non-Error", async () => {
    const ctx = makeContext({
      auth: {
        createUser: vi.fn().mockRejectedValue("createUser failed"),
      } as unknown as Context["auth"],
    });
    const data = makeDocSnapshot({version: 0, email: "admin@example.com"});
    await setup(ctx, {data});
    expect(ctx.logger.error).toHaveBeenCalledWith(
      "Error during setupV1:",
      "createUser failed",
      undefined
    );
  });

  it("logs error and aborts when setupV2 throws", async () => {
    const batchV2 = {
      set: vi.fn(),
      update: vi.fn(),
      commit: vi.fn().mockRejectedValue(new Error("holiday write failed")),
    } as unknown as WriteBatch;
    const ctx = makeContext({
      db: {
        batch: vi.fn().mockReturnValue(batchV2),
        collection: makeContext().db.collection,
      } as unknown as Context["db"],
    });
    const data = makeDocSnapshot({version: 1});

    await setup(ctx, {data});

    expect(ctx.logger.error).toHaveBeenCalledWith(
      "Error during setupV2:",
      expect.any(Error),
      expect.stringContaining("holiday write failed")
    );
    expect(ctx.logger.error).toHaveBeenCalledWith(
      "Setup for version 2 failed, aborting further setup"
    );
    expect(data.ref.set).not.toHaveBeenCalled();
  });

  it("logs error without stack when setupV2 throws non-Error", async () => {
    const batchV2 = {
      set: vi.fn(),
      update: vi.fn(),
      commit: vi.fn().mockRejectedValue("holiday write failed"),
    } as unknown as WriteBatch;
    const ctx = makeContext({
      db: {
        batch: vi.fn().mockReturnValue(batchV2),
        collection: makeContext().db.collection,
      } as unknown as Context["db"],
    });
    const data = makeDocSnapshot({version: 1});

    await setup(ctx, {data});

    expect(ctx.logger.error).toHaveBeenCalledWith(
      "Error during setupV2:",
      "holiday write failed",
      undefined
    );
    expect(ctx.logger.error).toHaveBeenCalledWith(
      "Setup for version 2 failed, aborting further setup"
    );
    expect(data.ref.set).not.toHaveBeenCalled();
  });
});
