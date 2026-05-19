String template(String title, String body) {
  return '''<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta property="og:title" content="ロバの休日" />
  <meta property="og:site_name" content="ロバの休日" />
  <meta property="og:description" content="" />
  <meta
    property="og:image"
    content="https://robanokyuka.firebaseapp.com/docs/screen-shot-1200x630.png"
  />
  <meta name="twitter:title" content="ロバの休日" />
  <meta name="twitter:description" content="" />
  <meta name="twitter:creator" content="@robanokyuka" />
  <meta name="twitter:card" content="summary_large_image" />
  <meta
    name="twitter:image"
    content="https://robanokyuka.firebaseapp.com/docs/icon-square-144x144.png"
  />
  <title>ロバの休日</title>
  <link rel="stylesheet" href="main.css">
</head>
<body>
  <main>
    $body
  </main>
</body>
</html>
''';
}
