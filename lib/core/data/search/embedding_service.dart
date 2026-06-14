import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:fonnx/models/minilml6v2/mini_lm_l6_v2.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

@lazySingleton
class EmbeddingService {
  EmbeddingService();

  static const dimensions = 384;
  static const _assetPath = 'assets/models/miniLmL6V2.onnx';
  static const _modelFileName = 'miniLmL6V2.onnx';

  Future<MiniLmL6V2>? _loading;

  Future<MiniLmL6V2> _load() => _loading ??= _materialize();

  Future<MiniLmL6V2> _materialize() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/models/$_modelFileName');
    if (!file.existsSync()) {
      final data = await rootBundle.load(_assetPath);
      file.parent.createSync(recursive: true);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    return MiniLmL6V2.load(file.path);
  }

  static List<List<int>> tokenize(String text) =>
      MiniLmL6V2.tokenizer.tokenize(text).map((piece) => piece.tokens).toList();

  Future<Float32List> embed(String text) => embedTokens(tokenize(text));

  Future<Float32List> embedTokens(List<List<int>> pieces) async {
    if (pieces.isEmpty) {
      return Float32List(dimensions);
    }
    final dir = await getApplicationSupportDirectory();
    final modelPath = '${dir.path}/models/$_modelFileName';
    await _load();
    final token = RootIsolateToken.instance!;
    return Isolate.run(() async {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      final model = MiniLmL6V2.load(modelPath);
      if (pieces.length == 1) {
        final vector = await model.getEmbeddingAsVector(pieces.first);
        return Float32List.fromList(vector.toList());
      }
      final sum = Float32List(dimensions);
      for (final tokens in pieces) {
        final vector = await model.getEmbeddingAsVector(tokens);
        final values = vector.toList();
        for (var i = 0; i < dimensions; i++) {
          sum[i] += values[i];
        }
      }
      return normalized(sum);
    });
  }

  static Float32List normalized(Float32List input) {
    var magnitudeSquared = 0.0;
    for (final value in input) {
      magnitudeSquared += value * value;
    }
    if (magnitudeSquared == 0) return input;
    final inverse = 1.0 / math.sqrt(magnitudeSquared);
    final result = Float32List(input.length);
    for (var i = 0; i < input.length; i++) {
      result[i] = input[i] * inverse;
    }
    return result;
  }

  static double cosine(Float32List a, Float32List b) {
    var dot = 0.0;
    for (var i = 0; i < a.length && i < b.length; i++) {
      dot += a[i] * b[i];
    }
    return dot;
  }
}
