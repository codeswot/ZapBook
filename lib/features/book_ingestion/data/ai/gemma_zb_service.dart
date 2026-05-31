import 'dart:io';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import 'package:zapbook/core/services/ai_service.dart';
import 'package:zapbook/features/book_ingestion/data/ai/zb_prompt.dart';
import 'package:zapbook/features/book_ingestion/data/ai/zb_refinement_parser.dart';
import 'package:zapbook/features/book_ingestion/domain/ai/zb_inference_service.dart';

@LazySingleton(as: ZbInferenceService)
final class GemmaZbService implements ZbInferenceService {
  GemmaZbService(this._aiService);

  final AiService _aiService;
  final ZbRefinementParser _parser = const ZbRefinementParser();

  static const String _modelFile = 'ai_models/gemma_model.litertlm';

  InferenceModel? _model;
  Future<void>? _loading;

  @override
  Future<bool> isReady() async {
    if (_aiService.currentState.status != AiModelStatus.ready) {
      return false;
    }
    return File(await _modelPath()).exists();
  }

  @override
  Future<void> warmUp() => _loading ??= _load();

  Future<void> _load() async {
    if (_model != null) {
      return;
    }
    await FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.litertlm,
    ).fromFile(await _modelPath()).install();
    _model = await FlutterGemmaPlugin.instance.createModel(
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.litertlm,
      maxTokens: 2048,
      supportImage: true,
    );
  }

  @override
  Future<ZbPageRefinement> refine(ZbPageRequest request) async {
    await warmUp();
    final model = _model;
    if (model == null) {
      return const ZbPageRefinement(blocks: []);
    }

    final session = await model.createSession(
      systemInstruction: ZbPrompt.system,
      enableVisionModality: true,
      temperature: 0.2,
      topK: 1,
    );
    try {
      await session.addQueryChunk(
        Message.withImage(
          text: ZbPrompt.pageInstruction(
            pageNumber: request.pageNumber,
            draftBlocks: request.draftBlocks,
            availableAssetRefs: request.availableAssetRefs,
          ),
          imageBytes: request.pageImage,
          isUser: true,
        ),
      );
      final raw = await session.getResponse();
      return _parser.parse(raw, allowedAssetRefs: request.availableAssetRefs);
    } finally {
      await session.close();
    }
  }

  @override
  Future<void> dispose() async {
    _loading = null;
    _model = null;
  }

  Future<String> _modelPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_modelFile';
  }
}
