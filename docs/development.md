# ![ロバの休暇](logo.svg)

[« 概要](./index.md)

## Development

### Prerequisites

- Git
- Flutter >= 3.41.9
- Node.js >= 24
- Java >= JDK 17

[material_symbols_icons](https://pub.dev/packages/material_symbols_icons)

```bash
dart pub global activate material_symbols_icons_cli
install_material_symbols_icons_fonts
```

### Get started

```bash
git clone git@github.com:MichinobuMaeda/robanokyuka.git
cd robanokyuka
flutter pug get
npm i
npm i --prefix functions
npm test
```

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Set SHA1 and SHA256 fingerprint to Firebase Console.

Download `android/app/google-services.json` from Firebase Console.

Download `ios/GoogleService-Info.plist` from Firebase Console.

Run Firebase Emulators

```bash
npm run emulators
```

Firebase Emulator Suite UI: <http://localhost:4000/>

Run app on Firebase Emulators

```bash
npm run dev:web
npm run dev:chrome
npm run dev:edge
npm run dev:android
npm run dev:ios
flutter devices
npm run dev -- -d [device-id]
```

Web Server in debug mode: <http://localhost:8000/>

Update test data of Firebase Emulators saved at `test/emulators`

```bash
npm run emulators:data
```

### Cloud Storage

- service
    - conf
        - admins [array]
            - [User ID]
        - gengos [array]
            - [object]
                - year [number]
                - month [number] 1-12
                - day [number]
                - name [string]
                - short [string]
        - uiVersion [string]
        - createdAt [timestamp]
        - updatedAt [timestamp]
    - version
        - version [number]
        - createdAt [timestamp]
    - y[Year]
        - [MMDD] [string] Name of a national holiday
        - updatedAt [timestamp]
- users
    - [User ID]
        - records [collection]
            - [Record ID]
                - from [string] YYYYMMDD
                - to [string] YYYYMMDD
                - holidays [array]
                    - [boolean] Sunday (Default: true)
                    - [boolean] Monday (Default: false)
                    - [boolean] Tuesday (Default: false)
                    - [boolean] Wednesday (Default: false)
                    - [boolean] Thursday (Default: false)
                    - [boolean] Friday (Default: false)
                    - [boolean] Saturday (Default: true)
                    - [boolean] National holidays (Default: true)
                - givenLeaves [number] (Default: 10)
                - minLeaves [number] (Default: 5)
                - useLeaveHourly [boolean] HH:MM (Default: "08:00")
                - createdAt [timestamp]
                - updatedAt [timestamp]
        - name [string]
        - createdAt [timestamp]
        - updatedAt [timestamp]

[» Deployment](./deployment.md)
