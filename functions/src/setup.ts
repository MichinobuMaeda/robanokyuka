import {DocumentSnapshot, FieldValue} from "firebase-admin/firestore";

import {holidays} from "./holidays.json";
import {gengos} from "./gengos.json";
import {msg, Context} from "./common";
import {addUserWithEmailAndName} from "./users";

/**
 * Performs initial setup for version 1 of the service configuration.
 * @param {Context} context - The function context containing logger, db, and auth.
 * @param {DocumentSnapshot | undefined} data - The deleted version document snapshot.
 * @return {Promise<void>}
 */
async function setupV1(
  {logger, db, auth}: Context,
  data: DocumentSnapshot,
): Promise<number | undefined> {
  try {
    logger.info(msg.performingSetupV1);

    const email = data.get("email") as string | undefined;
    const displayName = "Primary User";

    if (!email) {
      logger.error(msg.noAdminEmail);
      return;
    }

    logger.info(msg.adminEmailProvided(email));
    const user = await auth.createUser({email, displayName});
    const batch = db.batch();
    batch.set(
      db.collection("service").doc("conf"),
      {
        admins: [user.uid],
        gengos,
        createdAt: FieldValue.serverTimestamp(),
      }
    );

    await addUserWithEmailAndName({logger, auth, db}, {email});

    const pad2 = (num: number) => String(num).padStart(2, "0");
    const mmdd = (month: number, day: number) => `${pad2(month)}${pad2(day)}`;
    const yearId = (year: number) => `y${year}`;

    Object.entries(holidays.reduce(
      (
        prev: {[yyyy: string]: { [mmdd: string]: string }},
        {year, month, day, name}
      ) => {
        prev[yearId(year)] = {
          ...prev[yearId(year)] ?? {},
          [mmdd(month, day)]: name,
        };
        return prev;
      },
      {})
    ).forEach(([id, item]) => {
      batch.set(
        db.collection("service").doc(id),
        {...item, updatedAt: FieldValue.serverTimestamp()},
      );
    });

    await batch.commit();

    return 1;
  } catch (e) {
    logger.error(msg.errorSetupVersion(e));
    return;
  }
}

/**
 * Updates the UI version in the service configuration.
 * @param {Context} context - The function context containing logger and db.
 * @return {Promise<void>}
 */
export async function updateUiVersion(
  {logger, db}: Context,
): Promise<void> {
  const confRef = db.collection("service").doc("conf");
  const curUiVersion = (await confRef.get()).data()?.uiVersion as string | "";

  const uiVersion = process.env.UI_VERSION;
  const updatedAt = FieldValue.serverTimestamp();

  if (curUiVersion === uiVersion) {
    logger.info(msg.uiVersionUpToDate(uiVersion));
    return;
  } else {
    logger.info(msg.updatingUiVersion(uiVersion));
    await confRef.update({uiVersion, updatedAt});
  }
}

/**
 * Adds test data for development and testing purposes.
 * @param {Context} context - The function context containing logger and db.
 * @return {Promise<void>}
 */
export async function addTestData(
  {logger, db, auth}: Context,
): Promise<void> {
  try {
    const password = "password";
    const confRef = db.collection("service").doc("conf");
    const conf = await confRef.get();
    const admin = conf.data()?.admins?.[0] as string | undefined;
    if (admin) {
      await auth.updateUser(admin, {password});
    }
    const email = "user01@example.com";
    const displayName = "User 01";
    await auth.createUser({email, password, displayName});
    await addUserWithEmailAndName({logger, auth, db}, {email});
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
export async function setup(
  context: Context,
  {data}: { data: DocumentSnapshot | undefined },
): Promise<void> {
  const {logger} = context;
  logger.info(msg.nodeEnv(process.env.NODE_ENV));

  try {
    let version: number | undefined = 0;

    if (!data) {
      logger.info(msg.noDeletedDoc);
      return;
    }

    const curVersion = (data.get("version") as number) ?? 0;
    logger.info(msg.settingUpDataVersion, curVersion);

    if (curVersion < 1) {
      version = await setupV1(context, data);
      if (!version) {
        logger.error(msg.setupFailed("1"));
        return;
      }
    }

    await data.ref.set({version, createdAt: FieldValue.serverTimestamp()});

    await updateUiVersion(context);

    if (process.env.NODE_ENV === "development") {
      await addTestData(context);
    }
  } catch (e) {
    logger.error(
      msg.errorSetup, e,
      e instanceof Error ? e.stack : undefined
    );
  }
}
