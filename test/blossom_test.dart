import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  test('Blossom encode test', () {
    final enc1 = base64UrlEncode(utf8.encode('{"hello":"world"}'));
    final enc2 = base64Encode(utf8.encode('{"hello":"world"}'));
    if (kDebugMode) {
      print(enc1);
    }
    if (kDebugMode) {
      print(enc2);
    }
  });
}
