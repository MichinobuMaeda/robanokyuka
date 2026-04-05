/* eslint-disable require-jsdoc */
import {describe, it, expect, vi, beforeEach} from "vitest";
import {onUserCreating, addUserWithEmailAndName, handleAddUser, handleDeleteUser, handleUserUpdated} from "./users";
import type {Context} from "./common";
import type {AuthBlockingEvent} from "firebase-functions/identity";
import type {CallableRequest} from "firebase-functions/v2/https";

function makeContext(overrides?: Partial<Context>) {
  const set = vi.fn().mockResolvedValue(undefined);
  const update = vi.fn().mockResolvedValue(undefined);
  const get = vi.fn().mockResolvedValue({
    data: () => ({admins: ["admin-1"]}),
  });

  const usersGet = vi.fn().mockResolvedValue({exists: false});
  const usersDoc = vi.fn().mockReturnValue({set, get: usersGet});
  const serviceDoc = vi.fn((id: string) => {
    if (id === "conf") {
      return {get, update};
    }
    return {set, get, update};
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
    getUserByEmail: vi.fn().mockResolvedValue({uid: "user-123"}),
    getUser: vi.fn(async (uid: string) => ({uid, email: `${uid}@example.com`})),
    createUser: vi.fn().mockResolvedValue({uid: "new-uid"}),
  };

  const db = {collection};
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
    auth,
  };
}

describe("onUserCreating", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("logs error and returns when uid is missing", async () => {
    const {context, logger, collection} = makeContext();
    const event = {data: {uid: undefined}} as unknown as AuthBlockingEvent;

    await onUserCreating(context, event);

    expect(logger.error).toHaveBeenCalledWith(
      "No UID found in the event data"
    );
    expect(collection).not.toHaveBeenCalled();
  });

  it("creates user document when uid is present", async () => {
    const {context, logger, collection, usersDoc, set} = makeContext();
    const event = {data: {uid: "user-123"}} as unknown as AuthBlockingEvent;

    await onUserCreating(context, event);

    expect(logger.info).toHaveBeenCalledWith("Creating user:", "user-123");
    expect(collection).toHaveBeenCalledWith("users");
    expect(usersDoc).toHaveBeenCalledWith("user-123");
    expect(set).toHaveBeenCalledTimes(1);
    expect(set).toHaveBeenCalledWith(
      expect.objectContaining({createdAt: expect.any(Date)})
    );
  });

  it("uses displayName as name when provided", async () => {
    const {context, set} = makeContext();
    const event = {
      data: {
        uid: "user-123",
        email: "foo@example.com",
        displayName: "Foo Bar",
      },
    } as unknown as AuthBlockingEvent;

    await onUserCreating(context, event);

    expect(set).toHaveBeenCalledWith(
      expect.objectContaining({
        name: "Foo Bar",
        createdAt: expect.any(Date),
      })
    );
  });

  it("uses email local part as name when displayName is missing", async () => {
    const {context, set} = makeContext();
    const event = {
      data: {
        uid: "user-123",
        email: "foo@example.com",
      },
    } as unknown as AuthBlockingEvent;

    await onUserCreating(context, event);

    expect(set).toHaveBeenCalledWith(
      expect.objectContaining({
        name: "foo",
        createdAt: expect.any(Date),
      })
    );
  });
});

describe("addUserWithEmailAndName", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("creates auth user and Firestore doc when email is new", async () => {
    const {context, auth, set, usersGet} = makeContext();
    auth.getUserByEmail.mockRejectedValue(new Error("not found"));
    usersGet.mockResolvedValue({exists: false});

    await addUserWithEmailAndName(
      context,
      {email: "new@example.com", name: "New User"},
    );

    expect(auth.createUser).toHaveBeenCalledWith(
      {email: "new@example.com", displayName: "New User"},
    );
    expect(set).toHaveBeenCalledWith(
      expect.objectContaining({name: "New User", createdAt: expect.any(Date)})
    );
  });

  it("creates auth user without displayName when email is new and name is omitted", async () => {
    const {context, auth, set, usersGet} = makeContext();
    auth.getUserByEmail.mockRejectedValue(new Error("not found"));
    usersGet.mockResolvedValue({exists: false});

    await addUserWithEmailAndName(context, {email: "new@example.com"});

    expect(auth.createUser).toHaveBeenCalledWith({email: "new@example.com"});
    expect(set).toHaveBeenCalledWith(
      expect.objectContaining({name: "new", createdAt: expect.any(Date)})
    );
  });

  it("reuses existing auth user when email already exists", async () => {
    const {context, auth, set, usersGet} = makeContext();
    auth.getUserByEmail.mockResolvedValue({uid: "existing-uid"});
    usersGet.mockResolvedValue({exists: false});

    await addUserWithEmailAndName(context, {email: "old@example.com"});

    expect(auth.createUser).not.toHaveBeenCalled();
    expect(set).toHaveBeenCalledWith(
      expect.objectContaining({name: "old", createdAt: expect.any(Date)})
    );
  });

  it("skips Firestore set when user doc already exists", async () => {
    const {context, auth, set, usersGet} = makeContext();
    auth.getUserByEmail.mockResolvedValue({uid: "existing-uid"});
    usersGet.mockResolvedValue({exists: true});

    await addUserWithEmailAndName(context, {email: "old@example.com"});

    expect(set).not.toHaveBeenCalled();
  });
});

describe("handleAddUser", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("throws Email is required when email is missing", async () => {
    const {context, logger} = makeContext();
    const event = {
      auth: {uid: "admin-1"},
      data: {},
    } as unknown as CallableRequest;

    await expect(handleAddUser(context, event)).rejects.toThrow("Email is required");
    expect(logger.error).toHaveBeenCalledWith(
      "No email provided in the callable request"
    );
  });

  it("throws Unauthorized when uid is missing", async () => {
    const {context, logger} = makeContext();
    const event = {
      auth: undefined,
      data: {email: "foo@example.com"},
    } as unknown as CallableRequest;

    await expect(handleAddUser(context, event)).rejects.toThrow("Unauthorized");
    expect(logger.error).toHaveBeenCalledWith(
      "No UID found in the callable request"
    );
  });

  it("throws Unauthorized when uid is not in admins", async () => {
    const {context, logger} = makeContext();
    const event = {
      auth: {uid: "non-admin"},
      data: {email: "foo@example.com"},
    } as unknown as CallableRequest;

    await expect(handleAddUser(context, event)).rejects.toThrow("Unauthorized");
    expect(logger.error).toHaveBeenCalledWith("User is not an admin:", "non-admin");
  });

  it("calls addUserWithEmailAndName when uid is admin and email is present", async () => {
    const {context, auth} = makeContext();
    const event = {
      auth: {uid: "admin-1"},
      data: {email: "foo@example.com", name: "Foo"},
    } as unknown as CallableRequest;

    await handleAddUser(context, event);

    expect(auth.getUserByEmail).toHaveBeenCalledWith("foo@example.com");
  });
});

describe("handleDeleteUser", () => {
  function makeDeleteContext(admins = ["admin-1"]) {
    const batchDelete = vi.fn();
    const batchCommit = vi.fn().mockResolvedValue(undefined);
    const batch = {delete: batchDelete, commit: batchCommit};

    const recordDoc1 = {ref: {id: "rec-1"}};
    const recordDoc2 = {ref: {id: "rec-2"}};
    const recordsGet = vi.fn().mockResolvedValue({docs: [recordDoc1, recordDoc2]});
    const recordsCollection = vi.fn().mockReturnValue({get: recordsGet});

    const userDocRef = {collection: recordsCollection};
    const usersDoc = vi.fn().mockReturnValue(userDocRef);

    const confGet = vi.fn().mockResolvedValue({data: () => ({admins})});
    const serviceDoc = vi.fn().mockReturnValue({get: confGet});

    const collection = vi.fn((name: string) => {
      if (name === "users") return {doc: usersDoc};
      if (name === "service") return {doc: serviceDoc};
      return {doc: vi.fn()};
    });

    const db = {collection, batch: vi.fn().mockReturnValue(batch)};
    const auth = {
      deleteUser: vi.fn().mockResolvedValue(undefined),
    };
    const logger = {info: vi.fn(), error: vi.fn()};
    const context = {logger, db, auth} as unknown as Context;

    return {context, logger, auth, collection, usersDoc, recordsCollection, recordsGet, batchDelete, batchCommit};
  }

  beforeEach(() => vi.clearAllMocks());

  it("throws UID is required when target uid is missing", async () => {
    const {context, logger} = makeDeleteContext();
    const event = {
      auth: {uid: "admin-1"},
      data: {},
    } as unknown as CallableRequest;

    await expect(handleDeleteUser(context, event)).rejects.toThrow("UID is required");
    expect(logger.error).toHaveBeenCalledWith(
      "No target UID provided in the callable request"
    );
  });

  it("throws Unauthorized when caller is not admin", async () => {
    const {context, logger} = makeDeleteContext(["admin-1"]);
    const event = {
      auth: {uid: "non-admin"},
      data: {uid: "target-uid"},
    } as unknown as CallableRequest;

    await expect(handleDeleteUser(context, event)).rejects.toThrow("Unauthorized");
    expect(logger.error).toHaveBeenCalledWith("User is not an admin:", "non-admin");
  });

  it("deletes records, user doc, and auth user", async () => {
    const {context, logger, auth, usersDoc, batchDelete, batchCommit} = makeDeleteContext();
    const event = {
      auth: {uid: "admin-1"},
      data: {uid: "target-uid"},
    } as unknown as CallableRequest;

    await handleDeleteUser(context, event);

    expect(logger.info).toHaveBeenCalledWith("Deleting user:", "target-uid");
    expect(usersDoc).toHaveBeenCalledWith("target-uid");
    expect(batchDelete).toHaveBeenCalledTimes(3); // 2 records + 1 user doc
    expect(batchCommit).toHaveBeenCalled();
    expect(auth.deleteUser).toHaveBeenCalledWith("target-uid");
  });

  it("deletes user doc and auth user when no records exist", async () => {
    const {context, auth, recordsGet, batchDelete, batchCommit} = makeDeleteContext();
    recordsGet.mockResolvedValue({docs: []});
    const event = {
      auth: {uid: "admin-1"},
      data: {uid: "target-uid"},
    } as unknown as CallableRequest;

    await handleDeleteUser(context, event);

    expect(batchDelete).toHaveBeenCalledTimes(1); // only user doc
    expect(batchCommit).toHaveBeenCalled();
    expect(auth.deleteUser).toHaveBeenCalledWith("target-uid");
  });
});

describe("handleUserUpdated", () => {
  function makeEvent(
    uid: string | undefined,
    nameBefore: string | undefined,
    nameAfter: string | undefined,
  ) {
    return {
      params: {},
      data: {
        before: {get: (f: string) => f === "name" ? nameBefore : undefined},
        after: {
          id: uid,
          get: (f: string) => f === "name" ? nameAfter : undefined,
        },
      },
    };
  }

  beforeEach(() => vi.clearAllMocks());

  it("skips auth update when name is unchanged", async () => {
    const auth = {updateUser: vi.fn()};
    const logger = {info: vi.fn(), error: vi.fn()};
    const context = {logger, auth} as unknown as Context;
    const event = makeEvent("user-1", "Alice", "Alice");

    await handleUserUpdated(context, event as never);

    expect(auth.updateUser).not.toHaveBeenCalled();
  });

  it("skips auth update when uid is missing", async () => {
    const auth = {updateUser: vi.fn()};
    const logger = {info: vi.fn(), error: vi.fn()};
    const context = {logger, auth} as unknown as Context;
    const event = makeEvent(undefined, "Alice", "Bob");

    await handleUserUpdated(context, event as never);

    expect(auth.updateUser).not.toHaveBeenCalled();
  });

  it("updates displayName when name changes", async () => {
    const auth = {updateUser: vi.fn().mockResolvedValue(undefined)};
    const logger = {info: vi.fn(), error: vi.fn()};
    const context = {logger, auth} as unknown as Context;
    const event = makeEvent("user-1", "Alice", "Bob");

    await handleUserUpdated(context, event as never);

    expect(auth.updateUser).toHaveBeenCalledWith(
      "user-1", {displayName: "Bob"}
    );
  });

  it("uses empty string when nameAfter is undefined", async () => {
    const auth = {updateUser: vi.fn().mockResolvedValue(undefined)};
    const logger = {info: vi.fn(), error: vi.fn()};
    const context = {logger, auth} as unknown as Context;
    const event = makeEvent("user-1", "Alice", undefined);

    await handleUserUpdated(context, event as never);

    expect(auth.updateUser).toHaveBeenCalledWith(
      "user-1", {displayName: ""}
    );
  });
});
