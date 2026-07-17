import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fonnx/ort_minilm_isolate.dart';
import 'package:zapbook/core/data/search/embedding_service.dart';

String? _fonnxRoot() {
  final config = File(
    '${Directory.current.path}/.dart_tool/package_config.json',
  );
  if (!config.existsSync()) return null;
  final packages =
      (jsonDecode(config.readAsStringSync())
              as Map<String, dynamic>)['packages']
          as List<dynamic>;
  for (final entry in packages.cast<Map<String, dynamic>>()) {
    if (entry['name'] == 'fonnx') {
      final rootUri = entry['rootUri'] as String;
      final uri = Uri.parse(rootUri);
      if (uri.isScheme('file')) return uri.toFilePath();
      return File('${config.parent.path}/$rootUri').absolute.path;
    }
  }
  return null;
}

String? _ortDylib() {
  final root = _fonnxRoot();
  if (root == null) return null;
  final osxDir = Directory('$root/macos/onnx_runtime/osx');
  if (!osxDir.existsSync()) return null;
  for (final file in osxDir.listSync().whereType<File>()) {
    if (file.path.contains('libonnxruntime')) return file.path;
  }
  return null;
}

void main() {
  test('real MiniLM inference via fonnx FFI on host', () async {
    final dylib = _ortDylib();
    if (!Platform.isMacOS || dylib == null) {
      markTestSkipped('ORT dylib unavailable on this host');
      return;
    }

    final modelPath = '${Directory.current.path}/assets/models/miniLmL6V2.onnx';
    expect(File(modelPath).existsSync(), isTrue, reason: 'model asset present');

    final manager = OnnxIsolateManager();
    await manager.start(OnnxIsolateType.miniLm);

    Future<Float32List> embed(String text) => manager.sendInference(
      modelPath,
      EmbeddingService.tokenize(text).first,
      ortDylibPathOverride: dylib,
    );

    final stopwatch = Stopwatch()..start();
    final first = await embed(
      'lightning network payment channels route sats instantly',
    );
    stopwatch.stop();

    expect(first.length, EmbeddingService.dimensions);

    final second = await embed('bitcoin lightning payments');
    final unrelated = await embed('grandma baked sourdough bread');

    double cos(Float32List a, Float32List b) {
      var d = 0.0, ma = 0.0, mb = 0.0;
      for (var i = 0; i < a.length; i++) {
        d += a[i] * b[i];
        ma += a[i] * a[i];
        mb += b[i] * b[i];
      }
      return d / (math.sqrt(ma) * math.sqrt(mb));
    }

    final related = cos(first, second);
    final distant = cos(first, unrelated);
    expect(related, greaterThan(distant));
    expect(related, greaterThan(0.3));
    manager.stop();
  });
}
