import * as logger from "firebase-functions/logger";
import {Firestore} from "firebase-admin/firestore";
import {Auth} from "firebase-admin/auth";

export interface Context {
  logger: typeof logger;
  db: Firestore;
  auth: Auth;
}

/**
 *
 * @param {Context} context - The function context containing logger, db, and auth.
 * @param {string | undefined} uid - The UID of the user to check for admin privileges.
 * @return {Promise<boolean>} - Returns true if the user is an admin, otherwise false.
 */
export async function isAdminUid(
  context: Context,
  uid: string | undefined
): Promise<boolean> {
  const {logger, db} = context;

  if (!uid) {
    logger.error("No UID found in the callable request");
    return false;
  }

  const conf = await db.collection("service").doc("conf").get();
  const admins: string[] = conf.data()?.admins ?? [];

  if (!admins.includes(uid)) {
    logger.error("User is not an admin:", uid);
    return false;
  }

  return true;
}
