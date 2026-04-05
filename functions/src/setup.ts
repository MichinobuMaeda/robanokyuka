import {DocumentSnapshot} from "firebase-admin/firestore";

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
        createdAt: new Date(),
      }
    );
    await addUserWithEmailAndName({logger, auth, db}, {email});
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
 * Performs initial setup for version 2 of the service configuration.
 * @param {Context} context - The function context containing logger, db, and auth.
 * @param {DocumentSnapshot | undefined} data - The deleted version document snapshot.
 * @return {Promise<void>}
 */
async function setupV2(
  {logger, db}: Context
): Promise<number | undefined> {
  try {
    logger.info("Performing setup for version 2");
    const batch = db.batch();

    holidays.forEach(({year, month, day, name}) => {
      // eslint-disable-next-line max-len
      const id = `${year}${String(month).padStart(2, "0")}${String(day).padStart(2, "0")}`;
      batch.set(db.collection("holidays").doc(id), {name});
    });

    await batch.commit();

    return 2;
  } catch (e) {
    logger.error(
      "Error during setupV2:", e,
      e instanceof Error ? e.stack : undefined
    );
    return;
  }
}

/**
 * Updates the UI version in the service configuration.
 * @param {Context} context - The function context containing logger and db.
 * @param {DocumentSnapshot} data - The deleted version document snapshot.
 * @return {Promise<void>}
 */
export async function updateUiVersion(
  {logger, db}: Context,
): Promise<void> {
  const confRef = db.collection("service").doc("conf");
  const curUiVersion = (await confRef.get()).data()?.uiVersion as string | "";

  const uiVersion = process.env.UI_VERSION;

  if (curUiVersion === uiVersion) {
    logger.info("UI version is already up to date:", curUiVersion);
    return;
  } else {
    logger.info("Updating UI version to:", uiVersion);
    await confRef.update({uiVersion, updatedAt: new Date()});
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

    if (curVersion < 2) {
      version = await setupV2(context);
      if (!version) {
        logger.error("Setup for version 2 failed, aborting further setup");
        return;
      }
    }

    await data.ref.set({version, createdAt: new Date()});

    await updateUiVersion(context);
  } catch (e) {
    logger.error(
      "Error during setup:", e,
      e instanceof Error ? e.stack : undefined
    );
  }
}

const holidays = [
  {year: 2024, month: 1, day: 1, name: "元日"},
  {year: 2024, month: 1, day: 8, name: "成人の日"},
  {year: 2024, month: 2, day: 11, name: "建国記念の日"},
  {year: 2024, month: 2, day: 12, name: "休日"},
  {year: 2024, month: 2, day: 23, name: "天皇誕生日"},
  {year: 2024, month: 3, day: 20, name: "春分の日"},
  {year: 2024, month: 4, day: 29, name: "昭和の日"},
  {year: 2024, month: 5, day: 3, name: "憲法記念日"},
  {year: 2024, month: 5, day: 4, name: "みどりの日"},
  {year: 2024, month: 5, day: 5, name: "こどもの日"},
  {year: 2024, month: 5, day: 6, name: "休日"},
  {year: 2024, month: 7, day: 15, name: "海の日"},
  {year: 2024, month: 8, day: 11, name: "山の日"},
  {year: 2024, month: 8, day: 12, name: "休日"},
  {year: 2024, month: 9, day: 16, name: "敬老の日"},
  {year: 2024, month: 9, day: 22, name: "秋分の日"},
  {year: 2024, month: 9, day: 23, name: "休日"},
  {year: 2024, month: 10, day: 14, name: "スポーツの日"},
  {year: 2024, month: 11, day: 3, name: "文化の日"},
  {year: 2024, month: 11, day: 4, name: "休日"},
  {year: 2024, month: 11, day: 23, name: "勤労感謝の日"},
  {year: 2025, month: 1, day: 1, name: "元日"},
  {year: 2025, month: 1, day: 13, name: "成人の日"},
  {year: 2025, month: 2, day: 11, name: "建国記念の日"},
  {year: 2025, month: 2, day: 23, name: "天皇誕生日"},
  {year: 2025, month: 2, day: 24, name: "休日"},
  {year: 2025, month: 3, day: 20, name: "春分の日"},
  {year: 2025, month: 4, day: 29, name: "昭和の日"},
  {year: 2025, month: 5, day: 3, name: "憲法記念日"},
  {year: 2025, month: 5, day: 4, name: "みどりの日"},
  {year: 2025, month: 5, day: 5, name: "こどもの日"},
  {year: 2025, month: 5, day: 6, name: "休日"},
  {year: 2025, month: 7, day: 21, name: "海の日"},
  {year: 2025, month: 8, day: 11, name: "山の日"},
  {year: 2025, month: 9, day: 15, name: "敬老の日"},
  {year: 2025, month: 9, day: 23, name: "秋分の日"},
  {year: 2025, month: 10, day: 13, name: "スポーツの日"},
  {year: 2025, month: 11, day: 3, name: "文化の日"},
  {year: 2025, month: 11, day: 23, name: "勤労感謝の日"},
  {year: 2025, month: 11, day: 24, name: "休日"},
  {year: 2026, month: 1, day: 1, name: "元日"},
  {year: 2026, month: 1, day: 12, name: "成人の日"},
  {year: 2026, month: 2, day: 11, name: "建国記念の日"},
  {year: 2026, month: 2, day: 23, name: "天皇誕生日"},
  {year: 2026, month: 3, day: 20, name: "春分の日"},
  {year: 2026, month: 4, day: 29, name: "昭和の日"},
  {year: 2026, month: 5, day: 3, name: "憲法記念日"},
  {year: 2026, month: 5, day: 4, name: "みどりの日"},
  {year: 2026, month: 5, day: 5, name: "こどもの日"},
  {year: 2026, month: 5, day: 6, name: "休日"},
  {year: 2026, month: 7, day: 20, name: "海の日"},
  {year: 2026, month: 8, day: 11, name: "山の日"},
  {year: 2026, month: 9, day: 21, name: "敬老の日"},
  {year: 2026, month: 9, day: 22, name: "休日"},
  {year: 2026, month: 9, day: 23, name: "秋分の日"},
  {year: 2026, month: 10, day: 12, name: "スポーツの日"},
  {year: 2026, month: 11, day: 3, name: "文化の日"},
  {year: 2026, month: 11, day: 23, name: "勤労感謝の日"},
  {year: 2027, month: 1, day: 1, name: "元日"},
  {year: 2027, month: 1, day: 11, name: "成人の日"},
  {year: 2027, month: 2, day: 11, name: "建国記念の日"},
  {year: 2027, month: 2, day: 23, name: "天皇誕生日"},
  {year: 2027, month: 3, day: 21, name: "春分の日"},
  {year: 2027, month: 3, day: 22, name: "休日"},
  {year: 2027, month: 4, day: 29, name: "昭和の日"},
  {year: 2027, month: 5, day: 3, name: "憲法記念日"},
  {year: 2027, month: 5, day: 4, name: "みどりの日"},
  {year: 2027, month: 5, day: 5, name: "こどもの日"},
  {year: 2027, month: 7, day: 19, name: "海の日"},
  {year: 2027, month: 8, day: 11, name: "山の日"},
  {year: 2027, month: 9, day: 20, name: "敬老の日"},
  {year: 2027, month: 9, day: 23, name: "秋分の日"},
  {year: 2027, month: 10, day: 11, name: "スポーツの日"},
  {year: 2027, month: 11, day: 3, name: "文化の日"},
  {year: 2027, month: 11, day: 23, name: "勤労感謝の日"},
];
