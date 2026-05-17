import {setGlobalOptions} from "firebase-functions";
import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {getAuth} from "firebase-admin/auth";
import {
  onDocumentDeleted,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {onCall} from "firebase-functions/v2/https";
import {beforeUserCreated} from "firebase-functions/v2/identity";

import {setup} from "./setup";
import * as users from "./users";
import {setupTestData} from "./testdata";

const region = "asia-northeast2";
setGlobalOptions({maxInstances: 10});

initializeApp();
const db = getFirestore();
const auth = getAuth();
const context = {logger, db, auth};

export const onServiceVersionDeleted = onDocumentDeleted(
  {region, document: "service/version"},
  (event) => setup(context, event),
);

export const handleBeforeUserCreated = beforeUserCreated(
  {region},
  (event) => users.onUserCreating(context, event),
);

export const onUserUpdated = onDocumentUpdated(
  {region, document: "users/{uid}"},
  (event) => users.handleUserUpdated(context, event),
);

export const addUser = onCall(
  {region},
  (event) => users.handleAddUser(context, event),
);

export const deleteUser = onCall(
  {region},
  (event) => users.handleDeleteUser(context, event),
);

export const testData = onCall(
  {region},
  () => (process.env.NODE_ENV === "development") ?
    setupTestData(context) : null,
);
