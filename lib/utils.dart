import 'dart:math';

import 'package:ble_chat/common/constants.dart';

Random _random = Random.secure();

String generateCode() => List.generate(
  codeLength,
  (_) => codeChars[_random.nextInt(codeChars.length)],
).join();
