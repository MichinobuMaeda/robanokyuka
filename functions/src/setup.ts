import { DocumentSnapshot, FieldValue } from "firebase-admin/firestore";

import { holidays } from "./holidays.json";
import { gengos } from "./gengos.json";
import { msg, Context } from "./common";
import { addUserWithEmailAndName } from "./users";

/**
 * Fetches the UI version from the specified URL or environment variable.
 * @param {Context} context - The function context containing logger.
 * @return {String | null} The UI version string or null if the APP_VERSION_URL environment variable is not set.
 */
export async function getUiVersion(
  { logger }: Context,
): Promise<string | null> {
  const appVersionUrl = process.env.APP_VERSION_URL;
  if (!appVersionUrl) {
    logger.error(msg.noAppVersionUrl);
    return null;
  }
  let uiVersion: string;
  if (appVersionUrl.startsWith("https://")) {
    const res = await fetch(appVersionUrl);
    const json = await res.json() as { version: string, build_number: string };
    uiVersion = `${json.version}+${json.build_number}`;
  } else {
    uiVersion = appVersionUrl;
  }
  return uiVersion;
}

/**
 * Performs initial setup for version 1 of the service configuration.
 * @param {Context} context - The function context containing logger, db, and auth.
 * @param {DocumentSnapshot | undefined} data - The deleted version document snapshot.
 * @return {Promise<void>}
 */
async function setupV1(
  context: Context,
  data: DocumentSnapshot,
): Promise<number | undefined> {
  const { logger, db, auth } = context;
  try {
    logger.info(msg.performingSetupV1);

    const email = data.get("email") as string | undefined;
    const displayName = "Primary User";

    if (!email) {
      logger.error(msg.noAdminEmail);
      return;
    }

    logger.info(msg.adminEmailProvided(email));
    const user = await auth.createUser({ email, displayName });
    const uiVersion = await getUiVersion(context);
    const batch = db.batch();
    batch.set(
      db.collection("service").doc("conf"),
      {
        admins: [user.uid],
        gengos,
        uiVersion,
        createdAt: FieldValue.serverTimestamp(),
      }
    );

    await addUserWithEmailAndName(context, { email });

    const pad2 = (num: number) => String(num).padStart(2, "0");
    const mmdd = (month: number, day: number) => `${pad2(month)}${pad2(day)}`;
    const yearId = (year: number) => `y${year}`;

    Object.entries(holidays.reduce(
      (
        prev: { [yyyy: string]: { [mmdd: string]: string } },
        { year, month, day, name }
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
        { ...item, updatedAt: FieldValue.serverTimestamp() },
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
  context: Context,
): Promise<void> {
  const { logger, db } = context;
  const confRef = db.collection("service").doc("conf");
  const curUiVersion = (await confRef.get()).data()?.uiVersion as string | "";
  const uiVersion = await getUiVersion(context);
  if (!uiVersion) {
    return;
  }

  const updatedAt = FieldValue.serverTimestamp();

  if (curUiVersion === uiVersion) {
    logger.info(msg.uiVersionUpToDate(uiVersion));
    return;
  } else {
    logger.info(msg.updatingUiVersion(uiVersion));
    await confRef.update({ uiVersion, updatedAt });
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
  { data }: { data: DocumentSnapshot | undefined },
): Promise<void> {
  const { logger } = context;
  logger.info(msg.nodeEnv(process.env.NODE_ENV));

  try {
    if (!data) {
      logger.info(msg.noDeletedDoc);
      return;
    }

    let version: number | undefined = (data.get("version") as number) ?? 0;
    await data.ref.set({ version, createdAt: FieldValue.serverTimestamp() });
    logger.info(msg.settingUpDataVersion, version);

    if (version < 1) {
      version = await setupV1(context, data);
      if (!version) {
        logger.error(msg.setupFailed("1"));
        return;
      }
      await data.ref.set({ version, createdAt: FieldValue.serverTimestamp() });
    }

    await updateUiVersion(context);
  } catch (e) {
    logger.error(
      msg.errorSetup, e,
      e instanceof Error ? e.stack : undefined
    );
  }
}
