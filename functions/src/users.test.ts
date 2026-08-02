import { describe, it, expect, vi, beforeEach } from "vitest";
import { onUserCreating, addUserWithEmailAndName, handleAddUser, handleDeleteUser, handleUserUpdated } from "./users";
import type { AuthBlockingEvent } from "firebase-functions/identity";
import type { CallableRequest } from "firebase-functions/v2/https";

import { msg, type Context } from "./common";
import { makeContext, adminId, user01Id } from "./testutils";

describe("onUserCreating", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("logs error and returns when uid is missing", async () => {
    const { context, logger, collection } = makeContext();
    const event = { data: { uid: undefined } } as unknown as AuthBlockingEvent;

    await onUserCreating(context, event);

    expect(logger.error).toHaveBeenCalledWith(
      msg.noUidInEvent
    );
    expect(collection).not.toHaveBeenCalled();
  });

  it("creates user document when uid is present", async () => {
    const { context, logger, collection, usersDoc, set } = makeContext();
    const event = { data: { uid: user01Id } } as unknown as AuthBlockingEvent;

    await onUserCreating(context, event);

    expect(logger.info).toHaveBeenCalledWith(msg.creatingUser(user01Id));
    expect(collection).toHaveBeenCalledWith("users");
    expect(usersDoc).toHaveBeenCalledWith(user01Id);
    expect(set).toHaveBeenCalledTimes(1);
    expect(set).toHaveBeenCalledWith(
      expect.objectContaining({ createdAt: expect.any(Date) })
    );
  });

  it("uses displayName as name when provided", async () => {
    const { context, set } = makeContext();
    const event = {
      data: {
        uid: user01Id,
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
    const { context, set } = makeContext();
    const event = {
      data: {
        uid: user01Id,
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
    const { context, auth, set, usersGet } = makeContext();
    auth.getUserByEmail.mockRejectedValue(new Error("not found"));
    usersGet.mockResolvedValue({ exists: false });

    await addUserWithEmailAndName(
      context,
      { email: "new@example.com", name: "New User" },
    );

    expect(auth.createUser).toHaveBeenCalledWith(
      { email: "new@example.com", displayName: "New User" },
    );
    expect(set).toHaveBeenCalledWith(
      expect.objectContaining({ name: "New User", createdAt: expect.any(Date) })
    );
  });

  it("creates auth user without displayName when email is new and name is omitted", async () => {
    const { context, auth, set, usersGet } = makeContext();
    auth.getUserByEmail.mockRejectedValue(new Error("not found"));
    usersGet.mockResolvedValue({ exists: false });

    await addUserWithEmailAndName(context, { email: "new@example.com" });

    expect(auth.createUser).toHaveBeenCalledWith({ email: "new@example.com" });
    expect(set).toHaveBeenCalledWith(
      expect.objectContaining({ name: "new", createdAt: expect.any(Date) })
    );
  });

  it("reuses existing auth user when email already exists", async () => {
    const { context, auth, set, usersGet } = makeContext();
    auth.getUserByEmail.mockResolvedValue({ uid: "existing-uid" });
    usersGet.mockResolvedValue({ exists: false });

    await addUserWithEmailAndName(context, { email: "old@example.com" });

    expect(auth.createUser).not.toHaveBeenCalled();
    expect(set).toHaveBeenCalledWith(
      expect.objectContaining({ name: "old", createdAt: expect.any(Date) })
    );
  });

  it("skips Firestore set when user doc already exists", async () => {
    const { context, auth, set, usersGet } = makeContext();
    auth.getUserByEmail.mockResolvedValue({ uid: "existing-uid" });
    usersGet.mockResolvedValue({ exists: true });

    await addUserWithEmailAndName(context, { email: "old@example.com" });

    expect(set).not.toHaveBeenCalled();
  });
});

describe("handleAddUser", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("throws Email is required when email is missing", async () => {
    const { context, logger } = makeContext();
    const event = {
      auth: { uid: adminId },
      data: {},
    } as unknown as CallableRequest;

    await expect(handleAddUser(context, event)).rejects.toThrow("Email is required");
    expect(logger.error).toHaveBeenCalledWith(
      msg.noEmail
    );
  });

  it("throws Unauthorized when uid is missing", async () => {
    const { context, logger } = makeContext();
    const event = {
      auth: undefined,
      data: { email: "foo@example.com" },
    } as unknown as CallableRequest;

    await expect(handleAddUser(context, event)).rejects.toThrow(msg.unauthorized);
    expect(logger.error).toHaveBeenCalledWith(
      msg.missingUid
    );
  });

  it("throws Unauthorized when uid is not in admins", async () => {
    const { context, logger } = makeContext();
    const event = {
      auth: { uid: "non-admin" },
      data: { email: "foo@example.com" },
    } as unknown as CallableRequest;

    await expect(handleAddUser(context, event)).rejects.toThrow(msg.unauthorized);
    expect(logger.error).toHaveBeenCalledWith(msg.notAdmin("non-admin"));
  });

  it("calls addUserWithEmailAndName when uid is admin and email is present", async () => {
    const { context, auth } = makeContext();
    const event = {
      auth: { uid: adminId },
      data: { email: "foo@example.com", name: "Foo" },
    } as unknown as CallableRequest;

    await handleAddUser(context, event);

    expect(auth.getUserByEmail).toHaveBeenCalledWith("foo@example.com");
  });
});

describe("handleDeleteUser", () => {
  function makeDeleteContext(admins = [adminId]) {
    const batchDelete = vi.fn();
    const batchCommit = vi.fn().mockResolvedValue(undefined);
    const batch = { delete: batchDelete, commit: batchCommit };

    const recordDoc1 = { ref: { id: "rec-1" } };
    const recordDoc2 = { ref: { id: "rec-2" } };
    const recordsGet = vi.fn().mockResolvedValue({ docs: [recordDoc1, recordDoc2] });
    const recordsCollection = vi.fn().mockReturnValue({ get: recordsGet });

    const userDocRef = { collection: recordsCollection };
    const usersDoc = vi.fn().mockReturnValue(userDocRef);

    const confGet = vi.fn().mockResolvedValue({ data: () => ({ admins }) });
    const serviceDoc = vi.fn().mockReturnValue({ get: confGet });

    const collection = vi.fn((name: string) => {
      if (name === "users") return { doc: usersDoc };
      if (name === "service") return { doc: serviceDoc };
      return { doc: vi.fn() };
    });

    const db = { collection, batch: vi.fn().mockReturnValue(batch) };
    const auth = {
      deleteUser: vi.fn().mockResolvedValue(undefined),
    };
    const logger = { info: vi.fn(), error: vi.fn() };
    const context = { logger, db, auth } as unknown as Context;

    return { context, logger, auth, collection, usersDoc, recordsCollection, recordsGet, batchDelete, batchCommit };
  }

  beforeEach(() => vi.clearAllMocks());

  it("throws UID is required when target uid is missing", async () => {
    const { context, logger } = makeDeleteContext();
    const event = {
      auth: { uid: adminId },
      data: {},
    } as unknown as CallableRequest;

    await expect(handleDeleteUser(context, event)).rejects.toThrow("UID is required");
    expect(logger.error).toHaveBeenCalledWith(
      msg.noTargetUid
    );
  });

  it("throws Unauthorized when caller is not admin", async () => {
    const { context, logger } = makeDeleteContext([adminId]);
    const event = {
      auth: { uid: "non-admin" },
      data: { uid: "target-uid" },
    } as unknown as CallableRequest;

    await expect(handleDeleteUser(context, event)).rejects.toThrow(msg.unauthorized);
    expect(logger.error).toHaveBeenCalledWith(msg.notAdmin("non-admin"));
  });

  it("deletes records, user doc, and auth user", async () => {
    const { context, logger, auth, usersDoc, batchDelete, batchCommit } = makeDeleteContext();
    const event = {
      auth: { uid: adminId },
      data: { uid: user01Id },
    } as unknown as CallableRequest;

    await handleDeleteUser(context, event);

    expect(logger.info).toHaveBeenCalledWith(msg.deletingUser(user01Id));
    expect(usersDoc).toHaveBeenCalledWith(user01Id);
    expect(batchDelete).toHaveBeenCalledTimes(3); // 2 records + 1 user doc
    expect(batchCommit).toHaveBeenCalled();
    expect(auth.deleteUser).toHaveBeenCalledWith(user01Id);
  });

  it("deletes user doc and auth user when no records exist", async () => {
    const { context, auth, recordsGet, batchDelete, batchCommit } = makeDeleteContext();
    recordsGet.mockResolvedValue({ docs: [] });
    const event = {
      auth: { uid: adminId },
      data: { uid: user01Id },
    } as unknown as CallableRequest;

    await handleDeleteUser(context, event);

    expect(batchDelete).toHaveBeenCalledTimes(1); // only user doc
    expect(batchCommit).toHaveBeenCalled();
    expect(auth.deleteUser).toHaveBeenCalledWith(user01Id);
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
        before: { get: (f: string) => f === "name" ? nameBefore : undefined },
        after: {
          id: uid,
          get: (f: string) => f === "name" ? nameAfter : undefined,
        },
      },
    };
  }

  beforeEach(() => vi.clearAllMocks());

  it("skips auth update when name is unchanged", async () => {
    const auth = { updateUser: vi.fn() };
    const logger = { info: vi.fn(), error: vi.fn() };
    const context = { logger, auth } as unknown as Context;
    const event = makeEvent(user01Id, "Alice", "Alice");

    await handleUserUpdated(context, event as never);

    expect(auth.updateUser).not.toHaveBeenCalled();
  });

  it("skips auth update when uid is missing", async () => {
    const auth = { updateUser: vi.fn() };
    const logger = { info: vi.fn(), error: vi.fn() };
    const context = { logger, auth } as unknown as Context;
    const event = makeEvent(undefined, "Alice", "Bob");

    await handleUserUpdated(context, event as never);

    expect(auth.updateUser).not.toHaveBeenCalled();
  });

  it("updates displayName when name changes", async () => {
    const auth = { updateUser: vi.fn().mockResolvedValue(undefined) };
    const logger = { info: vi.fn(), error: vi.fn() };
    const context = { logger, auth } as unknown as Context;
    const event = makeEvent(user01Id, "Alice", "Bob");

    await handleUserUpdated(context, event as never);

    expect(auth.updateUser).toHaveBeenCalledWith(
      user01Id, { displayName: "Bob" }
    );
  });

  it("uses empty string when nameAfter is undefined", async () => {
    const auth = { updateUser: vi.fn().mockResolvedValue(undefined) };
    const logger = { info: vi.fn(), error: vi.fn() };
    const context = { logger, auth } as unknown as Context;
    const event = makeEvent(user01Id, "Alice", undefined);

    await handleUserUpdated(context, event as never);

    expect(auth.updateUser).toHaveBeenCalledWith(
      user01Id, { displayName: "" }
    );
  });
});
