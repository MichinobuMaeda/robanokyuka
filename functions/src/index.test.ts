import {describe, it, expect, vi, afterAll, beforeEach} from "vitest";
import functionsTest from "firebase-functions-test";
import type {CloudFunction, CloudEvent} from "firebase-functions/v2";
import * as setupModule from "./setup";
import * as usersModule from "./users";
import * as testdataModule from "./testdata";
import {adminId, makeEvent} from "./testutils";

import * as myFunctions from "./index";

vi.mock("firebase-admin/app", () => ({initializeApp: vi.fn()}));
vi.mock("firebase-admin/firestore", () => ({getFirestore: vi.fn().mockReturnValue({})}));
vi.mock("firebase-admin/auth", () => ({getAuth: vi.fn().mockReturnValue({})}));
vi.mock("./setup", () => ({setup: vi.fn().mockResolvedValue(undefined)}));
vi.mock("./users", () => ({
  onUserCreating: vi.fn().mockResolvedValue(undefined),
  handleAddUser: vi.fn().mockResolvedValue(undefined),
  handleUserUpdated: vi.fn().mockResolvedValue(undefined),
  handleDeleteUser: vi.fn().mockResolvedValue(undefined),
}));
vi.mock("./testdata", () => ({
  setupTestData: vi.fn().mockResolvedValue(undefined),
}));

const tester = functionsTest();

afterAll(() => tester.cleanup());

beforeEach(() => vi.clearAllMocks());

describe("onServiceVersionDeleted", () => {
  it("is exported", () => {
    expect(myFunctions.onServiceVersionDeleted).toBeDefined();
  });

  it("delegates to setup with context and event", async () => {
    const wrapped = tester.wrap(myFunctions.onServiceVersionDeleted);
    await wrapped({data: undefined});
    expect(setupModule.setup).toHaveBeenCalledWith(
      expect.objectContaining({logger: expect.any(Object)}),
      expect.any(Object),
    );
  });
});

describe("handleBeforeUserCreated", () => {
  it("is exported", () => {
    expect(myFunctions.handleBeforeUserCreated).toBeDefined();
  });

  it("delegates to onUserCreating with context and event", async () => {
    const wrapped = tester.wrap(
      myFunctions.handleBeforeUserCreated as unknown as CloudFunction<CloudEvent<unknown>>,
    );
    await wrapped({data: {uid: "user-123", email: "user@example.com"}});
    expect(usersModule.onUserCreating).toHaveBeenCalledWith(
      expect.objectContaining({logger: expect.any(Object)}),
      expect.any(Object),
    );
  });
});

describe("onUserUpdated", () => {
  it("is exported", () => {
    expect(myFunctions.onUserUpdated).toBeDefined();
  });

  it("delegates to handleUserUpdated with context and event", async () => {
    const wrapped = tester.wrap(myFunctions.onUserUpdated);
    await wrapped({data: tester.makeChange(
      tester.firestore.makeDocumentSnapshot({name: "Old"}, "users/uid-1"),
      tester.firestore.makeDocumentSnapshot({name: "New"}, "users/uid-1"),
    )});
    expect(usersModule.handleUserUpdated).toHaveBeenCalledWith(
      expect.objectContaining({logger: expect.any(Object)}),
      expect.any(Object),
    );
  });
});

describe("addUser", () => {
  it("is exported", () => {
    expect(myFunctions.addUser).toBeDefined();
  });

  it("delegates to handleAddUser with context and event", async () => {
    const wrapped = tester.wrap(myFunctions.addUser);
    const event = makeEvent(adminId, {email: "new@example.com"});
    await wrapped(event);
    expect(usersModule.handleAddUser).toHaveBeenCalledWith(
      expect.objectContaining({logger: expect.any(Object)}),
      event,
    );
  });
});

describe("deleteUser", () => {
  it("is exported", () => {
    expect(myFunctions.deleteUser).toBeDefined();
  });

  it("delegates to handleDeleteUser with context and event", async () => {
    const wrapped = tester.wrap(myFunctions.deleteUser);
    const event = makeEvent(adminId, {uid: "user-to-delete"});
    await wrapped(event);
    expect(usersModule.handleDeleteUser).toHaveBeenCalledWith(
      expect.objectContaining({logger: expect.any(Object)}),
      event,
    );
  });
});

describe("testData", () => {
  it("is exported", () => {
    expect(myFunctions.testData).toBeDefined();
  });

  it("calls setupTestData when NODE_ENV is development", async () => {
    vi.stubEnv("NODE_ENV", "development");
    const wrapped = tester.wrap(myFunctions.testData);
    await wrapped(makeEvent(undefined));
    expect(testdataModule.setupTestData).toHaveBeenCalledWith(
      expect.objectContaining({logger: expect.any(Object)}),
    );
    vi.unstubAllEnvs();
  });

  it("returns null when NODE_ENV is not development", async () => {
    vi.stubEnv("NODE_ENV", "production");
    const wrapped = tester.wrap(myFunctions.testData);
    const result = await wrapped(makeEvent(undefined));
    expect(result).toBeNull();
    expect(testdataModule.setupTestData).not.toHaveBeenCalled();
    vi.unstubAllEnvs();
  });
});
