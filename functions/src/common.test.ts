import {describe, it, expect, vi, beforeEach} from "vitest";
import {msg, isAdminUid} from "./common";
import type {Context} from "./common";

import {makeContext, makeEvent, adminId, user01Id} from "./testutils";

describe("isAdminUid", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns true when uid is in admins", async () => {
    const {context: ctx} = makeContext();
    const result = await isAdminUid(ctx, makeEvent(adminId));
    expect(result).toBe(true);
  });

  it("returns false and logs error when auth is missing", async () => {
    const {context: ctx} = makeContext();
    const result = await isAdminUid(ctx, makeEvent(undefined));
    expect(result).toBe(false);
    expect(ctx.logger.error).toHaveBeenCalledWith(
      msg.missingUid
    );
  });

  it("returns false and logs error when uid is not in admins", async () => {
    const {context: ctx} = makeContext();
    const result = await isAdminUid(ctx, makeEvent(user01Id));
    expect(result).toBe(false);
    expect(ctx.logger.error).toHaveBeenCalledWith(msg.notAdmin(user01Id));
  });

  it("returns false when conf has no admins field", async () => {
    const db = {
      collection: vi.fn().mockReturnValue({
        doc: vi.fn().mockReturnValue({
          get: vi.fn().mockResolvedValue({data: () => ({})}),
        }),
      }),
    };
    const logger = {info: vi.fn(), error: vi.fn()};
    const ctx = {logger, db, auth: {}} as unknown as Context;

    const result = await isAdminUid(ctx, makeEvent("someone"));
    expect(result).toBe(false);
  });
});
