import * as logger from "firebase-functions/logger";
import {Firestore} from "firebase-admin/firestore";
import {Auth} from "firebase-admin/auth";
import {type CallableRequest} from "firebase-functions/https";

export const msg = {
  nodeEnv: (env: string | undefined) => `Node environment: ${env}`,
  unauthorized: "Unauthorized",
  missingUid: "The UID of the request caller is missing",
  notAdmin: (uid: string) => `The request caller is not an admin: ${uid}`,
  noUidInEvent: "No UID found in the event data",
  creatingUser: (uid: string) => `Creating user: ${uid}`,
  addingUser: "Adding user with email and name: ",
  authUserExists: (email: string) =>
    `The auth user with email already exists: ${email}`,
  authUserCreated: (email: string) =>
    `The auth user with email was created: ${email}`,
  userDocExists: (uid: string) => `The user doc already exists: ${uid}`,
  userDocCreated: (email: string) =>
    `The user doc with email was created: ${email}`,
  noEmail: "No email provided in the request",
  updatingDisplayName: (uid: string, name: string | undefined) =>
    `Updating displayName for user: ${uid} to: ${name}`,
  noTargetUid: "No target UID provided in the callable request",
  deletingUser: (uid: string) => `Deleting user: ${uid}`,
  noAdminEmail: "No admin email provided in the version document",
  adminEmailProvided: (email: string) => `Admin email provided: ${email}`,
  uiVersionUpToDate: (version: string) =>
    `UI version is already up to date: ${version}`,
  updatingUiVersion: (version: string | undefined) =>
    `Updating UI version to: ${version}`,
  noDeletedDoc: "No deleted document found, skipping setup",
  settingUpDataVersion: "Setting up for data version",
  performingSetupV1: "Performing setup for version 1",
  errorSetupVersion: (e: Error | unknown) =>
    e instanceof Error ?
      `Error during setup for version: ${e.message} ${e.stack}` :
      `Error during setup for version: ${e}`,
  setupFailed: (version: string) =>
    `Setup for version ${version} failed, aborting further setup`,
  errorSetup: "Error during setup:",
  errorAddTestData: "Error during addTestData:",
};

export interface Context {
  logger: typeof logger;
  db: Firestore;
  auth: Auth;
}

/**
 * Checks if the request caller is an admin.
 * @param {Context} context - The function context containing logger, db, and auth.
 * @param {CallableRequest} event - The callable request.
 * @return {Promise<boolean>} - Returns true if the user is an admin, otherwise false.
 */
export async function isAdminUid(
  context: Context,
  event: CallableRequest,
): Promise<boolean> {
  const {logger, db} = context;
  const uid = event.auth?.uid;

  if (!uid) {
    logger.error(msg.missingUid);
    return false;
  }

  const conf = await db.collection("service").doc("conf").get();
  const admins: string[] = conf.data()?.admins ?? [];

  if (!admins.includes(uid)) {
    logger.error(msg.notAdmin(uid));
    return false;
  }

  return true;
}
