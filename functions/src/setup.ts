import {DocumentSnapshot, FieldValue} from "firebase-admin/firestore";

import {holidays} from "./holidays.json";
import {gengos} from "./gengos.json";
import {Context} from "./common";
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
    logger.info("Performing setup for version 1");

    const email = data.get("email") as string | undefined;

    if (!email) {
      logger.error("No admin email provided in the version document");
      return;
    }

    logger.info("Admin email provided:", email);
    const user = await auth.createUser({email});
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
    logger.error(
      "Error during setupV1:", e,
      e instanceof Error ? e.stack : undefined
    );
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
    logger.info("UI version is already up to date:", curUiVersion);
    return;
  } else {
    logger.info("Updating UI version to:", uiVersion);
    await confRef.update({uiVersion, updatedAt});
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

  try {
    let version: number | undefined = 0;

    if (!data) {
      logger.info("No deleted document found, skipping setup");
      return;
    }

    const curVersion = (data.get("version") as number) ?? 0;
    logger.info("Setting up for data version", curVersion);

    if (curVersion < 1) {
      version = await setupV1(context, data);
      if (!version) {
        logger.error("Setup for version 1 failed, aborting further setup");
        return;
      }
    }

    await data.ref.set({version, createdAt: FieldValue.serverTimestamp()});

    await updateUiVersion(context);
  } catch (e) {
    logger.error(
      "Error during setup:", e,
      e instanceof Error ? e.stack : undefined
    );
  }
}
