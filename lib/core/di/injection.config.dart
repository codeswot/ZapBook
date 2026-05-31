// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:zapbook/core/services/file_picker_service.dart' as _i1034;
import 'package:zapbook/features/book_ingestion/data/book_ingestion_repository_impl.dart'
    as _i785;
import 'package:zapbook/features/book_ingestion/data/cover/cover_generator.dart'
    as _i201;
import 'package:zapbook/features/book_ingestion/data/di/ingestion_module.dart'
    as _i627;
import 'package:zapbook/features/book_ingestion/data/documents_directory.dart'
    as _i746;
import 'package:zapbook/features/book_ingestion/data/extractors/book_extractor.dart'
    as _i751;
import 'package:zapbook/features/book_ingestion/domain/entities/wizard_data.dart'
    as _i1003;
import 'package:zapbook/features/book_ingestion/domain/repositories/book_ingestion_repository.dart'
    as _i865;
import 'package:zapbook/features/book_ingestion/domain/usecases/get_ingested_books.dart'
    as _i850;
import 'package:zapbook/features/book_ingestion/domain/usecases/ingest_book.dart'
    as _i605;
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_bloc.dart'
    as _i318;
import 'package:zapbook/features/book_ingestion/presentation/bloc/page/ingestion_page_cubit.dart'
    as _i439;
import 'package:zapbook/features/book_ingestion/presentation/bloc/wizard/book_wizard_cubit.dart'
    as _i842;
import 'package:zapbook/zbf/zbf.dart' as _i1;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final ingestionModule = _$IngestionModule();
    gh.lazySingleton<_i1034.FilePickerService>(
      () => _i1034.FilePickerService(),
    );
    gh.lazySingleton<_i201.CoverGenerator>(
      () => ingestionModule.coverGenerator(),
    );
    gh.lazySingleton<_i1.ZbfWriter>(() => ingestionModule.zbfWriter());
    gh.lazySingleton<_i1.ZbfReader>(() => ingestionModule.zbfReader());
    gh.lazySingleton<_i746.DocumentsDirectory>(
      () => const _i746.PathProviderDocumentsDirectory(),
    );
    gh.factory<_i439.IngestionPageCubit>(
      () => _i439.IngestionPageCubit(gh<_i1034.FilePickerService>()),
    );
    gh.factoryParam<
      _i842.BookWizardCubit,
      _i687.Completer<_i1003.WizardData>,
      String?
    >(
      (_completer, initialTitle) => _i842.BookWizardCubit(
        gh<_i1034.FilePickerService>(),
        _completer,
        initialTitle,
      ),
    );
    gh.lazySingleton<List<_i751.BookExtractor>>(
      () => ingestionModule.bookExtractors(gh<_i201.CoverGenerator>()),
    );
    gh.lazySingleton<_i865.BookIngestionRepository>(
      () => _i785.BookIngestionRepositoryImpl(
        extractors: gh<List<_i751.BookExtractor>>(),
        documentsDirectory: gh<_i746.DocumentsDirectory>(),
        writer: gh<_i1.ZbfWriter>(),
        reader: gh<_i1.ZbfReader>(),
      ),
    );
    gh.factory<_i850.GetIngestedBooks>(
      () => _i850.GetIngestedBooks(gh<_i865.BookIngestionRepository>()),
    );
    gh.factory<_i605.IngestBook>(
      () => _i605.IngestBook(gh<_i865.BookIngestionRepository>()),
    );
    gh.factory<_i318.IngestionBloc>(
      () => _i318.IngestionBloc(ingestBook: gh<_i605.IngestBook>()),
    );
    return this;
  }
}

class _$IngestionModule extends _i627.IngestionModule {}
