import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    debugPrint = (String? message, {int? wrapWidth}) {};
  });
  await testMain();
}
