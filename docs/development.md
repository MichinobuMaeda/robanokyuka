# ![ロバの休暇](logo.svg)

[« 概要](./index.md)

## 開発

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
npm run dev -- -d [device-id]
```

Web Server in debug mode: <http://localhost:8000/>

Update test data of Firebase Emulators saved at `test/emulators`

```bash
npm run emulators:data
```

[» Deployment](./deployment.md)
