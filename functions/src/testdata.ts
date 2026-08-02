import { msg, Context } from "./common";
import { addUserWithEmailAndName } from "./users";
import { setup } from "./setup";

/**
 * Adds test data for development and testing purposes.
 * @param {Context} context - The function context containing logger and db.
 * @return {Promise<void>}
 */
export async function addTestData(
  context: Context,
): Promise<void> {
  const { logger, db, auth } = context;
  try {
    const password = "password";
    const confRef = db.collection("service").doc("conf");
    const conf = await confRef.get();
    const admin = conf.data()?.admins?.[0] as string | undefined;
    if (admin) {
      await auth.updateUser(admin, { password });
    }
    const email = "user01@example.com";
    const displayName = "User 01";
    await auth.createUser({ email, password, displayName });
    await addUserWithEmailAndName({ logger, auth, db }, { email });
  } catch (e) {
    logger.error(
      msg.errorAddTestData, e,
      e instanceof Error ? e.stack : undefined
    );
  }
}

/**
 * Handles setup tasks triggered when the service/version document is deleted.
 * @param {Context} context - The function context containing logger, db, and auth.
 * @param {FirestoreEvent} event - The Firestore delete event.
 * @return {Promise<void>}
 */
export async function setupTestData(
  context: Context,
): Promise<void> {
  const { logger, db } = context;

  logger.info(msg.nodeEnv(process.env.NODE_ENV));

  try {
    const versionRef = db.collection("service").doc("version");
    await versionRef.set({ email: "primary@example.com" });
    const versionDoc = await versionRef.get();
    await setup(context, { data: versionDoc });
    await addTestData(context);
  } catch (e) {
    logger.error(
      msg.errorSetup, e,
      e instanceof Error ? e.stack : undefined
    );
  }
}
