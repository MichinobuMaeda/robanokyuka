import {describe, it, expect, vi, beforeEach, afterEach} from "vitest";
import {setup, addTestData, updateUiVersion, getUiVersion} from "./setup";
import {msg, type Context} from "./common";
import type {
  DocumentReference,
  WriteBatch,
  CollectionReference,
} from "firebase-admin/firestore";

import {
  makeContext,
  makeDocSnapshot,
  adminEmail,
  user02Id,
  uiVersion,
  adminId,
} from "./testutils";

const testUser01 = "user01@example.com";
const appVersionUrl = "https://example.com/version.json";

describe("setup", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.APP_VERSION_URL = appVersionUrl;
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue({
      json: vi.fn().mockResolvedValue({version: "0.1.2", build_number: "1"}),
    }));
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    delete process.env.APP_VERSION_URL;
  });

  it("does nothing when data is undefined", async () => {
    const {context: ctx} = makeContext();
    await setup(ctx, {data: undefined});
    expect(ctx.logger.info).toHaveBeenCalledWith(
      msg.noDeletedDoc
    );
  });

  it("does nothing when version >= 1", async () => {
    const {context: ctx} = makeContext();
    const data = makeDocSnapshot({version: 1});
    await setup(ctx, {data});
    expect(ctx.auth.createUser).not.toHaveBeenCalled();
    expect(ctx.logger.info).toHaveBeenCalledWith(msg.uiVersionUpToDate(uiVersion));
  });

  it("runs setupV1 including holidays and gengos", async () => {
    const {context: ctx} = makeContext();
    const data = makeDocSnapshot({version: 0, email: adminEmail});

    await setup(ctx, {data});

    expect(ctx.logger.info).toHaveBeenCalledWith(
      msg.performingSetupV1
    );
    expect(ctx.db.batch).toHaveBeenCalled();
    const batch = ctx.db.batch();
    expect(batch.set).toHaveBeenCalledWith(
      expect.objectContaining({id: "y2024"}),
      expect.objectContaining({"0101": "元日"})
    );
    expect(batch.set).toHaveBeenCalledWith(
      expect.objectContaining({id: "y2025"}),
      expect.objectContaining({"0101": "元日"})
    );
    expect(batch.set).toHaveBeenCalledWith(
      expect.objectContaining({id: "y2026"}),
      expect.objectContaining({"0101": "元日"})
    );
    expect(batch.set).toHaveBeenCalledWith(
      expect.objectContaining({id: "y2027"}),
      expect.objectContaining({"0101": "元日"})
    );
    expect(batch.set).toHaveBeenCalledWith(
      expect.objectContaining({id: "conf"}),
      expect.objectContaining({
        gengos: expect.arrayContaining([
          expect.objectContaining({name: "令和", short: "R"}),
        ]),
      })
    );
    expect(data.ref.set).toHaveBeenCalledWith({
      version: 1,
      createdAt: expect.objectContaining({}),
    });
  });

  it("defaults missing version to 0 and runs setupV1", async () => {
    const {context: ctx} = makeContext();
    const data = makeDocSnapshot({email: adminEmail});
    await setup(ctx, {data});
    expect(ctx.logger.info).toHaveBeenCalledWith(
      msg.settingUpDataVersion,
      0
    );
    expect(ctx.auth.createUser).toHaveBeenCalledWith({
      displayName: "Primary User",
      email: adminEmail,
    });
    expect(ctx.db.batch().commit).toHaveBeenCalled();
  });

  it("calls setupV1 when version is 0", async () => {
    const {context: ctx} = makeContext();
    const data = makeDocSnapshot({version: 0, email: adminEmail});
    await setup(ctx, {data});
    expect(
      ctx.auth.createUser
    ).toHaveBeenCalledWith({
      displayName: "Primary User",
      email: adminEmail,
    });
    expect(ctx.db.batch().commit).toHaveBeenCalled();
  });

  it("logs error and returns when no email in version document", async () => {
    const {context: ctx} = makeContext();
    const data = makeDocSnapshot({version: 0, email: undefined});
    await setup(ctx, {data});
    expect(
      ctx.logger.error
    ).toHaveBeenCalledWith(msg.noAdminEmail);
    expect(ctx.auth.createUser).not.toHaveBeenCalled();
  });

  it("logs error when setup throws", async () => {
    const {context: ctx} = makeContext();
    const data = makeDocSnapshot(
      {version: 0, email: adminEmail},
      {
        set: vi.fn().mockRejectedValue(new Error("Firestore write failed")),
      }
    );
    await setup(ctx, {data});
    expect(ctx.logger.error).toHaveBeenCalledWith(
      msg.errorSetup,
      expect.any(Error),
      expect.stringContaining("Firestore write failed")
    );
  });

  it("logs error without stack when setup throws non-Error", async () => {
    const {context: ctx} = makeContext();
    const data = makeDocSnapshot(
      {version: 0, email: adminEmail},
      {
        set: vi.fn().mockRejectedValue("Firestore write failed"),
      }
    );
    await setup(ctx, {data});
    expect(ctx.logger.error).toHaveBeenCalledWith(
      msg.errorSetup,
      "Firestore write failed",
      undefined
    );
  });

  // eslint-disable-next-line max-len
  it("updates UI version when it differs from the deployed version", async () => {
    const {context: ctx} = makeContext({
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

    await setup(ctx, {data: makeDocSnapshot({version: 2})});

    expect(ctx.logger.info).toHaveBeenCalledWith(msg.updatingUiVersion("0.1.2+1"));
  });

  it("logs error with stack trace when setupV1 throws", async () => {
    const err = new Error("createUser failed");
    const {context: ctx} = makeContext({
      auth: {
        createUser: vi.fn().mockRejectedValue(err),
      } as unknown as Context["auth"],
    });
    const data = makeDocSnapshot({version: 0, email: adminEmail});
    await setup(ctx, {data});
    expect(ctx.logger.error).toHaveBeenCalledWith(msg.errorSetupVersion(err));
  });

  it("logs error without stack when setupV1 throws non-Error", async () => {
    const {context: ctx} = makeContext({
      auth: {
        createUser: vi.fn().mockRejectedValue("createUser failed"),
      } as unknown as Context["auth"],
    });
    const data = makeDocSnapshot({version: 0, email: adminEmail});
    await setup(ctx, {data});
    expect(ctx.logger.error).toHaveBeenCalledWith(
      msg.errorSetupVersion("createUser failed")
    );
  });

  it("logs error and aborts when setupV1 batch throws", async () => {
    const batchV1 = {
      set: vi.fn(),
      update: vi.fn(),
      commit: vi.fn().mockRejectedValue(new Error("holiday write failed")),
    } as unknown as WriteBatch;
    const {context: ctx} = makeContext({
      db: {
        batch: vi.fn().mockReturnValue(batchV1),
        collection: makeContext().collection,
      } as unknown as Context["db"],
    });
    const data = makeDocSnapshot({version: 0, email: adminEmail});

    await setup(ctx, {data});

    expect(ctx.logger.error).toHaveBeenCalledWith(msg.setupFailed("1"));
    expect(data.ref.set).toHaveBeenCalledTimes(1);
    expect(data.ref.set).toHaveBeenCalledWith({
      version: 0, createdAt: expect.objectContaining({}),
    });
  });

  it("logs error without stack when setupV1 batch throws non-Error", async () => {
    const batchV1 = {
      set: vi.fn(),
      update: vi.fn(),
      commit: vi.fn().mockRejectedValue("holiday write failed"),
    } as unknown as WriteBatch;
    const {context: ctx} = makeContext({
      db: {
        batch: vi.fn().mockReturnValue(batchV1),
        collection: makeContext().collection,
      } as unknown as Context["db"],
    });
    const data = makeDocSnapshot({version: 0, email: adminEmail});

    await setup(ctx, {data});

    expect(ctx.logger.error).toHaveBeenCalledWith(
      msg.errorSetupVersion("holiday write failed")
    );
    expect(ctx.logger.error).toHaveBeenCalledWith(msg.setupFailed("1"));
    expect(data.ref.set).toHaveBeenCalledTimes(1);
    expect(data.ref.set).toHaveBeenCalledWith({
      version: 0, createdAt: expect.objectContaining({}),
    });
  });

  it("calls addTestData when NODE_ENV is development", async () => {
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = "development";
    try {
      const {context: ctx} = makeContext();
      const data = makeDocSnapshot({version: 1});
      await setup(ctx, {data});
      expect(ctx.auth.createUser).toHaveBeenCalledWith(
        expect.objectContaining({email: testUser01})
      );
    } finally {
      process.env.NODE_ENV = originalEnv;
    }
  });
});

describe("getUiVersion", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.APP_VERSION_URL = appVersionUrl;
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue({
      json: vi.fn().mockResolvedValue({version: "0.1.2", build_number: "1"}),
    }));
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    delete process.env.APP_VERSION_URL;
  });

  function makeGetUiVersionContext() {
    const logger = {info: vi.fn(), error: vi.fn()};
    return {logger} as unknown as Context;
  }

  it("returns null and logs error when APP_VERSION_URL is not set", async () => {
    delete process.env.APP_VERSION_URL;
    const ctx = makeGetUiVersionContext();
    const result = await getUiVersion(ctx);
    expect(result).toBeNull();
    expect(ctx.logger.error).toHaveBeenCalledWith(msg.noAppVersionUrl);
  });

  it("fetches version JSON and constructs version string from https URL", async () => {
    const ctx = makeGetUiVersionContext();
    const result = await getUiVersion(ctx);
    expect(fetch).toHaveBeenCalledWith(appVersionUrl);
    expect(result).toBe(uiVersion);
  });

  it("returns APP_VERSION_URL directly when it does not start with https://", async () => {
    const directVersion = "0.9.9+1";
    process.env.APP_VERSION_URL = directVersion;
    const ctx = makeGetUiVersionContext();
    const result = await getUiVersion(ctx);
    expect(fetch).not.toHaveBeenCalled();
    expect(result).toBe(directVersion);
  });
});

describe("addTestData", () => {
  afterEach(() => {
    vi.clearAllMocks();
  });

  function makeAddTestDataContext(adminUid?: string) {
    const confData = adminUid ? {admins: [adminUid]} : {};
    const confRef = {
      get: vi.fn().mockResolvedValue({data: () => confData}),
    } as unknown as import("firebase-admin/firestore").DocumentReference;
    const usersCollection = {
      doc: vi.fn().mockReturnValue({
        get: vi.fn().mockResolvedValue({exists: false}),
        set: vi.fn().mockResolvedValue(undefined),
      }),
    } as unknown as import("firebase-admin/firestore").CollectionReference;
    const db = {
      batch: vi.fn().mockReturnValue({
        set: vi.fn(),
        update: vi.fn(),
        commit: vi.fn().mockResolvedValue(undefined),
      }),
      collection: vi.fn((path: string) => {
        if (path === "service") {
          return {doc: vi.fn().mockReturnValue(confRef)};
        }
        return usersCollection;
      }),
    };
    const auth = {
      createUser: vi.fn().mockResolvedValue({uid: user02Id}),
      getUserByEmail: vi.fn().mockResolvedValue({uid: user02Id}),
      updateUser: vi.fn().mockResolvedValue(undefined),
    };
    const logger = {info: vi.fn(), error: vi.fn()};
    return {logger, db, auth} as unknown as import("./common").Context;
  }

  it("sets admin password and creates user01 when admin exists", async () => {
    const ctx = makeAddTestDataContext(adminId);
    await addTestData(ctx);
    expect(ctx.auth.updateUser).toHaveBeenCalledWith(adminId, {password: "password"});
    expect(ctx.auth.createUser).toHaveBeenCalledWith({
      email: testUser01,
      password: "password",
      displayName: "User 01",
    });
  });

  it("skips updateUser when no admin in conf", async () => {
    const ctx = makeAddTestDataContext();
    await addTestData(ctx);
    expect(ctx.auth.updateUser).not.toHaveBeenCalled();
    expect(ctx.auth.createUser).toHaveBeenCalledWith(
      expect.objectContaining({email: testUser01})
    );
  });

  it("logs Error with stack when addTestData throws", async () => {
    const err = new Error("createUser failed");
    const ctx = makeAddTestDataContext(adminId);
    (ctx.auth.createUser as ReturnType<typeof vi.fn>).mockRejectedValue(err);
    await addTestData(ctx);
    expect(ctx.logger.error).toHaveBeenCalledWith(
      msg.errorAddTestData, err, err.stack
    );
  });

  it("logs non-Error without stack when addTestData throws", async () => {
    const ctx = makeAddTestDataContext(adminId);
    (ctx.auth.createUser as ReturnType<typeof vi.fn>).mockRejectedValue("boom");
    await addTestData(ctx);
    expect(ctx.logger.error).toHaveBeenCalledWith(
      msg.errorAddTestData, "boom", undefined
    );
  });
});

describe("updateUiVersion", () => {
  const appVersionUrl = "https://example.com/version.json";

  beforeEach(() => {
    vi.clearAllMocks();
    process.env.APP_VERSION_URL = appVersionUrl;
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue({
      json: vi.fn().mockResolvedValue({version: "0.1.2", build_number: "1"}),
    }));
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    delete process.env.APP_VERSION_URL;
  });

  function makeUpdateUiVersionContext(storedVersion: string | undefined) {
    const update = vi.fn().mockResolvedValue(undefined);
    const confRef = {
      get: vi.fn().mockResolvedValue({data: () => ({uiVersion: storedVersion})}),
      update,
    } as unknown as DocumentReference;
    const db = {
      collection: vi.fn(() => ({doc: vi.fn().mockReturnValue(confRef)})),
    } as unknown as import("./common").Context["db"];
    const logger = {info: vi.fn(), error: vi.fn()};
    return {context: {logger, db} as unknown as import("./common").Context, update};
  }

  it("returns early when getUiVersion returns null", async () => {
    delete process.env.APP_VERSION_URL;
    const {context: ctx, update} = makeUpdateUiVersionContext(uiVersion);
    await updateUiVersion(ctx);
    expect(update).not.toHaveBeenCalled();
  });

  it("logs up-to-date and does not update when version matches", async () => {
    const {context: ctx, update} = makeUpdateUiVersionContext(uiVersion);
    await updateUiVersion(ctx);
    expect(ctx.logger.info).toHaveBeenCalledWith(msg.uiVersionUpToDate(uiVersion));
    expect(update).not.toHaveBeenCalled();
  });

  it("updates conf and logs when stored version differs", async () => {
    const {context: ctx, update} = makeUpdateUiVersionContext("0.1.1+1");
    await updateUiVersion(ctx);
    expect(ctx.logger.info).toHaveBeenCalledWith(msg.updatingUiVersion(uiVersion));
    expect(update).toHaveBeenCalledWith(
      expect.objectContaining({uiVersion})
    );
  });

  it("updates conf when stored version is undefined", async () => {
    const {context: ctx, update} = makeUpdateUiVersionContext(undefined);
    await updateUiVersion(ctx);
    expect(update).toHaveBeenCalledWith(
      expect.objectContaining({uiVersion})
    );
  });
});
