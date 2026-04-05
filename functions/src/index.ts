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

const region = "asia-northeast2";
setGlobalOptions({maxInstances: 10});

initializeApp();
const db = getFirestore();
const auth = getAuth();
const context = {logger, db, auth};

exports.onServiceVersionDeleted = onDocumentDeleted(
  {region, document: "service/version"},
  (event) => setup(context, event),
);

exports.handleBeforeUserCreated = beforeUserCreated(
  {region},
  (event) => users.onUserCreating(context, event),
);

exports.onUserUpdated = onDocumentUpdated(
  {region, document: "users/{uid}"},
  (event) => users.handleUserUpdated(context, event),
);

exports.addUser = onCall(
  {region},
  (event) => users.handleAddUser(context, event),
);

exports.deleteUser = onCall(
  {region},
  (event) => users.handleDeleteUser(context, event),
);
