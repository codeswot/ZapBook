import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/domain/wizard_data.dart';
import 'package:zapbook/features/library/presentation/bloc/ingestion_queue_state.dart';

@injectable
class IngestionQueueCubit extends Cubit<IngestionQueueState> {
  IngestionQueueCubit() : super(const IngestionQueueState());

  Future<({String hash, CircleBook? existing})> findDuplicate(File file) async {
    return (hash: '', existing: null);
  }

  void enqueue(
    File file, {
    Future<WizardData>? wizardDataFuture,
    String? contentHash,
  }) {}

  void dismiss(String jobId) {}
}
