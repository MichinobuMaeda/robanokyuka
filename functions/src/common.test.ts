/* eslint-disable require-jsdoc */
import {describe, it, expect, vi, beforeEach} from "vitest";
import {isAdminUid} from "./common";
import type {Context} from "./common";
import type {DocumentReference, CollectionReference} from "firebase-admin/firestore";

function makeContext(admins: string[] = ["admin-1"]): Context {
  const confGet = vi.fn().mockResolvedValue({
    data: () => ({admins}),
  });
  const confDoc = {get: confGet} as unknown as DocumentReference;
  const serviceCollection = {
    doc: vi.fn().mockReturnValue(confDoc),
  } as unknown as CollectionReference;

  const db = {
    collection: vi.fn().mockReturnValue(serviceCollection),
  };

  const logger = {
    info: vi.fn(),
    error: vi.fn(),
  };

  return {logger, db, auth: {} as Context["auth"]} as unknown as Context;
}

describe("isAdminUid", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns true when uid is in admins", async () => {
    const ctx = makeContext(["admin-1"]);
    const result = await isAdminUid(ctx, "admin-1");
    expect(result).toBe(true);
  });

  it("returns false when uid is empty string", async () => {
    const ctx = makeContext();
    const result = await isAdminUid(ctx, "");
    expect(result).toBe(false);
    expect(ctx.logger.error).toHaveBeenCalledWith(
      "No UID found in the callable request"
    );
  });

  it("returns false when uid is not in admins", async () => {
    const ctx = makeContext(["admin-1"]);
    const result = await isAdminUid(ctx, "other-user");
    expect(result).toBe(false);
    expect(ctx.logger.error).toHaveBeenCalledWith(
      "User is not an admin:", "other-user"
    );
  });

  it("returns false when conf has no admins field", async () => {
    const confGet = vi.fn().mockResolvedValue({data: () => ({})});
    const db = {
      collection: vi.fn().mockReturnValue({
        doc: vi.fn().mockReturnValue({get: confGet}),
      }),
    };
    const logger = {info: vi.fn(), error: vi.fn()};
    const ctx = {logger, db, auth: {}} as unknown as Context;

    const result = await isAdminUid(ctx, "someone");
    expect(result).toBe(false);
  });
});
