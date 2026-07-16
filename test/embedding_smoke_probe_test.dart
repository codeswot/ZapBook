import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fonnx/dylib_path_overrides.dart';
import 'package:fonnx/models/minilml6v2/mini_lm_l6_v2.dart';
import 'package:zapbook/core/data/search/embedding_service.dart';

void main() {
  test('real MiniLM inference via fonnx FFI on host', () async {
    const fonnxRoot =
        '/Users/codeswot/.pub-cache/git/fonnx-0d6e1201fb6189d06afd8c7fc04ca0be29ef6929';
    fonnxOrtDylibPathOverride =
        '$fonnxRoot/macos/onnx_runtime/osx/libonnxruntime.1.16.1.dylib';

    final modelPath =
        '${Directory.current.path}/assets/models/miniLmL6V2.onnx';
    expect(File(modelPath).existsSync(), isTrue, reason: 'model asset present');

    final model = MiniLmL6V2.load(modelPath);
    final tokens = EmbeddingService.tokenize(
      'lightning network payment channels route sats instantly',
    );
    final stopwatch = Stopwatch()..start();
    final vector = await model.getEmbeddingAsVector(tokens.first);
    stopwatch.stop();

    final list = vector.toList();
    expect(list.length, EmbeddingService.dimensions);
    final magnitude = list.fold<double>(0, (s, v) => s + v * v);
    expect(magnitude, closeTo(1.0, 0.01));

    final second = await model.getEmbeddingAsVector(
      EmbeddingService.tokenize('bitcoin lightning payments').first,
    );
    final unrelated = await model.getEmbeddingAsVector(
      EmbeddingService.tokenize('grandma baked sourdough bread').first,
    );
    double cos(List<double> a, List<double> b) {
      var d = 0.0;
      for (var i = 0; i < a.length; i++) {
        d += a[i] * b[i];
      }
      return d;
    }

    final related = cos(list, second.toList());
    final distant = cos(list, unrelated.toList());
    // ignore: avoid_print
    print(
      'inference=${stopwatch.elapsedMilliseconds}ms related=$related distant=$distant',
    );
    expect(related, greaterThan(distant));
  });
}
