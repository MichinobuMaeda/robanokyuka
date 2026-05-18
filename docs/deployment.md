# ![ロバの休暇](logo.svg)

[« 概要](./index.md) [« 開発](./development.md)

## Deployment

<https://console.firebase.google.com/>

- Create a project: robanokyuka
- [v] Enable Gemini in Firebase
- [v] Enable Google Analytics for this project
- Choose or create a Google Analytics account: robanokyuka
- Analytics location: Japan
- [v] Use the default settings for sharing Google Analytics data

<https://console.firebase.google.com/project/robanokyuka>

- Settings
  - Project settings
    - Environment
      - Environment type: Production
    - Your apps
      - Web
        - App nickname: ロバの休暇
        - [v] Also set up Firebase Hosting for this app
  - Usage and billing
    - Details & settings
      - Firebase billing plan: Blaze
- Database & Storage
  - Firestore
    - Create database: Standard edition
      - Location: asia-northeast2(Osaka)
      - Configure: Start in production mode
  - Storage
    - Set up default bucket
      - All locations
        - Location: asia-northeast2
        - Access frequency: Standard
      - Configure: Start in production mode
- Security
  - Authentication
    - Sign-in method
      - Email/Password: Enable
        - Email link (passwordless sign-in): Enable
      - Google: Enable
        - Public-facing name for project: ロバの休暇
        - Support email for project: my address
    - Template
      - Template language: Japanese
    - Settings
      - User account linking: Link accounts that use the same email
      - User actions
        - [v] Enable create (sign-up)
        - [v] Enable delete
        - [v] Email enumeration protection (recommended)
      - Blocking functions: Upgrade to Firebase Auth with Identity Platform to access this feature.
        - Password policy
          - Enforcement mode: Require enforcement
          - Password requirement options
            - [v] Require uppercase character
            - [v] Require lowercase character
            - [v] Require special character
            - [v] Require numeric character
            - [ ] Force upgrade on sign-in
          - Password length requirements: 10
          - Maximum password length: 4096

```JavaScript
const firebaseConfig = {
  apiKey: "******************************",
  authDomain: "robanokyuka.firebaseapp.com",
  projectId: "robanokyuka",
  storageBucket: "robanokyuka.firebasestorage.app",
  messagingSenderId: "506698003908",
  appId: "1:506698003908:web:17437702a35ccbfbdf2091",
  measurementId: "G-0YGD503CHF"
};
```

<https://console.cloud.google.com/welcome?project=robanokyuka>

- APIs & Services
  - Enable Cloud Billing API

```bash
$ brew install gh
$ gh auth login
$ gh repo create MichinobuMaeda/robanokyuka --public
$ flutter create --platforms web robanokyuka
$ cd robanokyuka
$ echo 24 > .nvmrc
$ nvm use
Now using node v24.15.0 (npm v11.12.1)
$ npm init
$ npm i firebase-tools -D
$ npx firebase login
$ npx firebase init

You're about to initialize a Firebase project in this directory:

  /Users/username/robanokyuka

✔ Which Firebase features do you want to set up for this directory?
Firestore: Configure security rules and indexes files for Firestore,
Functions: Configure a Cloud Functions directory and its files,
Hosting: Set up deployments for static web apps,
Storage: Configure a security rules file for Cloud Storage,
Emulators: Set up local emulators for Firebase products,
Authentication: Set up Firebase Authentication

=== Project Setup

First, let's associate this project directory with a Firebase project.
You can create multiple project aliases by running firebase use --add,

i  Using project robanokyuka (robanokyuka) .

=== Firestore Setup
i  firestore: ensuring required API firestore.googleapis.com is enabled...

Firestore Security Rules allow you to define how and when to allow
requests. You can keep these rules in your project directory
and publish them with firebase deploy.

✔ What file should be used for Firestore Rules? firestore.rules
i  Downloaded the existing Firestore Security Rules from the Firebase console
i  firestore.rules is unchanged

Firestore indexes allow you to perform complex queries while
maintaining performance that scales with the size of the result
set. You can keep index definitions in your project directory
and publish them with firebase deploy.

✔ What file should be used for Firestore indexes? firestore.indexes.json
i  Downloaded the existing Firestore indexes from the Firebase console
i  firestore.indexes.json is unchanged

=== Functions Setup
Let's create a new codebase for your functions.
A directory corresponding to the codebase will be created in your project
with sample code pre-configured.

See https://firebase.google.com/docs/functions/organize-functions for
more information on organizing your functions using codebases.

Functions can be deployed with firebase deploy.

✔ What language would you like to use to write Cloud Functions? TypeScript
✔ Do you want to use ESLint to catch probable bugs and enforce style? Yes
i  functions/.eslintrc.js is unchanged
i  functions/tsconfig.dev.json is unchanged
i  functions/package.json is unchanged
i  functions/tsconfig.json is unchanged
i  functions/src/index.ts is unchanged
i  functions/.gitignore is unchanged
✔ Do you want to install dependencies with npm now? No

=== Hosting Setup

Your public directory is the folder (relative to your project directory) that
will contain Hosting assets to be uploaded with firebase deploy. If you
have a build process for your assets, use your build's output directory.

✔ What do you want to use as your public directory? build/web
✔ Configure as a single-page app (rewrite all urls to /index.html)? No
✔ Set up automatic builds and deploys with GitHub? Yes

Visit this URL on this device to log in:
https://github.com/login/oauth/authorize?client_id=89cf50f02ac6aaed3484&state=801503967&redirect_uri=http%3A%2F%2Flocalhost%3A9005&scope=read%3Auser%20repo%20public_repo

Waiting for authentication...

✔  Success! Logged into GitHub as MichinobuMaeda

✔ For which GitHub repository would you like to set up a GitHub workflow? (format: user/repository) MichinobuMaeda/robanokyuka

✔  Created service account github-action-1233058792 with Firebase Hosting admin permissions.
✔  Uploaded service account JSON to GitHub as secret FIREBASE_SERVICE_ACCOUNT_ROBANOKYUKA.
i  You can manage your secrets at https://github.com/MichinobuMaeda/robanokyuka/settings/secrets.

✔ Set up the workflow to run a build script before every deploy? Yes
✔ What script should be run before every deploy? npm ci && npm run build

✔  Created workflow file /Users/username/robanokyuka/.github/workflows/firebase-hosting-pull-request.yml
✔ Set up automatic deployment to your site s live channel when a PR is merged? Yes
✔ What is the name of the GitHub branch associated with your site s live channel? main

✔  Created workflow file /Users/username/robanokyuka/.github/workflows/firebase-hosting-merge.yml

i  Action required: Visit this URL to revoke authorization for the Firebase CLI GitHub OAuth App:
https://github.com/settings/connections/applications/89cf50f02ac6aaed3484
i  Action required: Push any new workflow file(s) to your repo
✔  Wrote build/web/404.html
✔  Wrote build/web/index.html

=== Storage Setup

Firebase Storage Security Rules allow you to define how and when to allow
uploads and downloads. You can keep these rules in your project directory
and publish them with firebase deploy.

i  storage: ensuring required API firebasestorage.googleapis.com is enabled...
✔  storage: required API firebasestorage.googleapis.com is enabled
Downloaded the existing Storage Security Rules from the Firebase console
✔ What file should be used for Storage Rules? storage.rules
✔  Wrote storage.rules

=== Emulators Setup
✔ Which Firebase emulators do you want to set up? Press Space to select emulators, then Enter to confirm your choices. Authentication Emulator,
Functions Emulator, Firestore Emulator, Pub/Sub Emulator, Storage Emulator, Cloud Tasks Emulator
✔ Which port do you want to use for the auth emulator? 9099
✔ Which port do you want to use for the functions emulator? 5001
✔ Which port do you want to use for the firestore emulator? 8080
✔ Which port do you want to use for the pubsub emulator? 8085
✔ Which port do you want to use for the storage emulator? 9199
✔ Which port do you want to use for the tasks emulator? 9499
✔ Would you like to enable the Emulator UI? Yes
✔ Which port do you want to use for the Emulator UI (leave empty to use any available port)? 4000
✔ Would you like to download the emulators now? Yes
i  firestore: downloading cloud-firestore-emulator-v1.21.0.jar...

=== Authentication Setup
✔ Which providers would you like to enable?
Google Sign-In,
Email/Password

Configuring Google Sign-In...
✔ What display name would you like to use for your OAuth brand? ロバの休暇
✔ What support email would you like to register for your OAuth brand? support@undefined.firebaseapp.com
✔  Wrote configuration info to firebase.json

Generated firebase.json with auth configuration.
Run firebase deploy to enable these providers.

=== Agent Skills Setup
If you are using an AI coding agent, Firebase Agent Skills make it an expert at Firebase.
✔ Would you like to install agent skills for Firebase? No

✔  Wrote configuration info to firebase.json
✔  Wrote project information to .firebaserc

✔  Firebase initialization complete!

$ gh secret list
NAME                                  UPDATED
FIREBASE_SERVICE_ACCOUNT_ROBANOKYUKA  about 36 minutes ago

$ gh secret set FIREBASE_API_KEY_ROBANOKYUKA
? Paste your secret: ***************************************

✓ Set Actions secret FIREBASE_API_KEY_ROBANOKYUKA for MichinobuMaeda/robanokyuka

$ gh secret list
NAME                                  UPDATED
FIREBASE_API_KEY_ROBANOKYUKA          less than a minute ago
FIREBASE_SERVICE_ACCOUNT_ROBANOKYUKA  about 39 minutes ago
```

The first deployment of Functions should run from local.

```bash
$ npx firebase deploy --only functions
 ... ...
⚠  functions: Since this is your first time using 2nd gen functions, we need a little bit longer to finish setting everything up. Retry the deployment in a few minutes.

$ npx firebase deploy --only functions
 ... ...
✔  Deploy complete!
```

<https://console.cloud.google.com/welcome?project=robanokyuka>

- IAM & Admin
  - IAM
        - github-action-\*: add Role "Editor"

<https://console.firebase.google.com/project/robanokyuka>

- Security
  - Authentication
    - Settings
      - Blocking functions
        - Before account creation: 'handleBeforeUserCreated'
- Database & Storage
  - Firestore
        - Start collection
            - `service/version { email: foo@bar.baz" }`

## Create "Sleepy donkey" icon

On ChatGPT

1. 眠そうなロバの顔の絵を描いてください。
2. この絵を Cartoon 風にしてください。
3. この絵はアプリのアイコンとして低解像度で使いたいです。細部を省いて簡略化してください。
4. この絵をどうにかしてfavicon用の 16 x 16 のドット絵にしてください。
5. 先ほど生成したこの絵に酷似する他の人の作品を探してください。
