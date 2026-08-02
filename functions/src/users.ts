import { type AuthBlockingEvent } from "firebase-functions/identity";
import { type CallableRequest } from "firebase-functions/v2/https";
import {
  type FirestoreEvent, type Change,
} from "firebase-functions/v2/firestore";
import { type QueryDocumentSnapshot } from "firebase-admin/firestore";

import { msg, Context, isAdminUid } from "./common";

/**
 * Handles the beforeUserCreated event by creating a Firestore user document.
 * @param {Context} context - The function context containing logger, db, and auth.
 * @param {AuthBlockingEvent} event - The auth blocking event containing user data.
 * @return {Promise<void>}
 */
export async function onUserCreating(
  { logger, db }: Context,
  event: AuthBlockingEvent,
): Promise<void> {
  const uid = event.data?.uid;
  const email = event.data?.email;
  const name = event.data?.displayName;

  if (!uid) {
    logger.error(msg.noUidInEvent);
    return;
  }

  logger.info(msg.creatingUser(uid));

  await db.collection("users").doc(uid).set({
    name: name || email?.replace(/@.*/, "") || "",
    createdAt: new Date(),
  });
}

/**
 *
 * @param {Context} context - The function context containing logger, db, and auth.
 * @param {Object} data - The data containing email and name for the new user.
 * @param {string} data.email - The email of the new user.
 * @param {string?} data.name - The name of the new user.
 * @return {Promise<void>}
 */
export async function addUserWithEmailAndName(
  { logger, auth, db }: Context,
  { email, name }: {email: string, name?: string},
): Promise<void> {
  logger.info(msg.addingUser, { email, name });

  let uid: string;
  try {
    const existing = await auth.getUserByEmail(email);
    logger.info(msg.authUserExists(email));
    uid = existing.uid;
  } catch {
    const created = await auth.createUser(
      name ? { email, displayName: name } : { email },
    );
    uid = created.uid;
    logger.info(msg.authUserCreated(email));
  }

  const docRef = db.collection("users").doc(uid);
  const docSnap = await docRef.get();
  if (docSnap.exists) {
    logger.info(msg.userDocExists(uid));
    return;
  }

  await docRef.set({
    name: name || email.replace(/@.*/, ""),
    createdAt: new Date(),
  });
  logger.info(msg.userDocCreated(email));
}

/**
 * Handles the addUser callable function by creating a Firestore user document.
 * @param {Context} context - The function context containing logger, db, and auth.
 * @param {CallableRequest} event - The callable request containing user data.
 * @return {Promise<void>}
 */
export async function handleAddUser(
  { logger, auth, db }: Context,
  event: CallableRequest,
): Promise<void> {
  const email = event.data?.email;
  const name = event.data?.name;

  if (!email) {
    logger.error(msg.noEmail);
    throw new Error("Email is required");
  }

  if (!(await isAdminUid({ logger, auth, db }, event))) {
    throw new Error(msg.unauthorized);
  }

  await addUserWithEmailAndName({ logger, auth, db }, { email, name });
}


/**
 * Handles Firestore onDocumentUpdated for users/{uid}.
 * If the name field changed, updates the auth user's displayName.
 * @param {Context} context - The function context containing logger and auth.
 * @param {FirestoreEvent} event - The Firestore document updated event.
 * @return {Promise<void>}
 */
export async function handleUserUpdated(
  { logger, auth }: Context,
  event: FirestoreEvent<
    Change<QueryDocumentSnapshot> | undefined, {uid: string}
  >,
): Promise<void> {
  const uid = event.data?.after.id;
  if (!uid) return;

  const nameBefore = event.data?.before.get("name") as string | undefined;
  const nameAfter = event.data?.after.get("name") as string | undefined;
  if (nameBefore === nameAfter) return;

  logger.info(msg.updatingDisplayName(uid, nameAfter));
  await auth.updateUser(uid, { displayName: nameAfter ?? "" });
}

/**
 * Handles the deleteUser callable function by deleting the auth user and
 * their Firestore documents.
 * @param {Context} context - The function context containing logger, db, and auth.
 * @param {CallableRequest} event - The callable request containing user data.
 * @return {Promise<void>}
 */
export async function handleDeleteUser(
  { logger, auth, db }: Context,
  event: CallableRequest,
): Promise<void> {
  const uid = event.data?.uid;

  if (!uid) {
    logger.error(msg.noTargetUid);
    throw new Error("UID is required");
  }

  if (!(await isAdminUid({ logger, auth, db }, event))) {
    throw new Error(msg.unauthorized);
  }

  logger.info(msg.deletingUser(uid));

  await auth.deleteUser(uid);
  const userDocRef = db.collection("users").doc(uid);
  const recordsSnap = await userDocRef.collection("records").get();
  const batch = db.batch();
  for (const doc of recordsSnap.docs) {
    batch.delete(doc.ref);
  }
  batch.delete(userDocRef);
  await batch.commit();
}

