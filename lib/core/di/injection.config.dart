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
import 'package:marmot_dart/marmot_dart.dart' as _i970;
import 'package:ndk/ndk.dart' as _i857;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:zapbook/core/data/datasources/genre_datasource.dart' as _i850;
import 'package:zapbook/core/di/marmot_module.dart' as _i817;
import 'package:zapbook/core/di/nostr_module.dart' as _i96;
import 'package:zapbook/core/di/register_module.dart' as _i200;
import 'package:zapbook/core/identity/identity_repository.dart' as _i63;
import 'package:zapbook/core/identity/marmot_identity_repository.dart' as _i538;
import 'package:zapbook/core/router/app_router.dart' as _i571;
import 'package:zapbook/core/services/ai_service.dart' as _i1012;
import 'package:zapbook/core/services/clipboard_service.dart' as _i1053;
import 'package:zapbook/core/services/device_capability_service.dart' as _i447;
import 'package:zapbook/core/services/file_hasher.dart' as _i917;
import 'package:zapbook/core/services/file_picker_service.dart' as _i1034;
import 'package:zapbook/core/services/nostr_service.dart' as _i11;
import 'package:zapbook/core/services/secure_storage_service.dart' as _i123;
import 'package:zapbook/core/theme/theme_cubit.dart' as _i465;
import 'package:zapbook/features/ai_model/presentation/cubit/ai_model_cubit.dart'
    as _i970;
import 'package:zapbook/features/book_ingestion/data/ai/printing_pdf_rasterizer.dart'
    as _i217;
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
import 'package:zapbook/features/book_ingestion/domain/ai/pdf_page_rasterizer.dart'
    as _i370;
import 'package:zapbook/features/book_ingestion/domain/entities/wizard_data.dart'
    as _i1003;
import 'package:zapbook/features/book_ingestion/domain/repositories/book_ingestion_repository.dart'
    as _i865;
import 'package:zapbook/features/book_ingestion/domain/usecases/ingest_book.dart'
    as _i605;
import 'package:zapbook/features/book_ingestion/presentation/bloc/page/ingestion_page_cubit.dart'
    as _i439;
import 'package:zapbook/features/book_ingestion/presentation/bloc/reader_settings/reader_settings_cubit.dart'
    as _i28;
import 'package:zapbook/features/book_ingestion/presentation/bloc/wizard/book_wizard_cubit.dart'
    as _i842;
import 'package:zapbook/features/heads_up/presentation/cubit/heads_up_cubit.dart'
    as _i539;
import 'package:zapbook/features/library/data/cover/cover_store.dart' as _i828;
import 'package:zapbook/features/library/data/db/library_database.dart'
    as _i279;
import 'package:zapbook/features/library/data/di/library_module.dart' as _i808;
import 'package:zapbook/features/library/data/repositories/library_repository_impl.dart'
    as _i584;
import 'package:zapbook/features/library/domain/repositories/library_repository.dart'
    as _i516;
import 'package:zapbook/features/library/domain/usecases/add_book_to_library.dart'
    as _i1071;
import 'package:zapbook/features/library/domain/usecases/backfill_library.dart'
    as _i887;
import 'package:zapbook/features/library/domain/usecases/delete_library_book.dart'
    as _i1038;
import 'package:zapbook/features/library/domain/usecases/find_book_by_content_hash.dart'
    as _i190;
import 'package:zapbook/features/library/domain/usecases/get_library_book.dart'
    as _i807;
import 'package:zapbook/features/library/domain/usecases/touch_book_opened.dart'
    as _i296;
import 'package:zapbook/features/library/domain/usecases/update_book_metadata.dart'
    as _i96;
import 'package:zapbook/features/library/domain/usecases/watch_library_books.dart'
    as _i1024;
import 'package:zapbook/features/library/presentation/bloc/ingestion_queue_cubit.dart'
    as _i327;
import 'package:zapbook/features/library/presentation/bloc/library_cubit.dart'
    as _i107;
import 'package:zapbook/features/onboarding/data/datasources/onboarding_local_datasource.dart'
    as _i638;
import 'package:zapbook/features/onboarding/data/repositories/onboarding_repository_impl.dart'
    as _i444;
import 'package:zapbook/features/onboarding/domain/repositories/onboarding_repository.dart'
    as _i377;
import 'package:zapbook/features/onboarding/domain/usecases/complete_onboarding.dart'
    as _i341;
import 'package:zapbook/features/onboarding/domain/usecases/generate_identity.dart'
    as _i709;
import 'package:zapbook/features/onboarding/domain/usecases/import_identity.dart'
    as _i136;
import 'package:zapbook/features/onboarding/presentation/bloc/onboarding_cubit.dart'
    as _i634;
import 'package:zapbook/zbf/zbf.dart' as _i1;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    final marmotModule = _$MarmotModule();
    final nostrModule = _$NostrModule();
    final ingestionModule = _$IngestionModule();
    final libraryModule = _$LibraryModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i850.GenreDataSource>(() => _i850.GenreDataSource());
    gh.lazySingletonAsync<_i970.Marmot>(() => marmotModule.marmot());
    await gh.lazySingletonAsync<_i857.Ndk>(
      () => nostrModule.ndk(),
      preResolve: true,
    );
    gh.lazySingleton<_i571.AppRouter>(() => _i571.AppRouter());
    gh.lazySingleton<_i1053.ClipboardService>(() => _i1053.ClipboardService());
    gh.lazySingleton<_i917.FileHasher>(() => const _i917.FileHasher());
    gh.lazySingleton<_i1034.FilePickerService>(
      () => _i1034.FilePickerService(),
    );
    gh.lazySingleton<_i123.SecureStorageService>(
      () => _i123.SecureStorageService(),
    );
    gh.lazySingleton<_i201.CoverGenerator>(
      () => ingestionModule.coverGenerator(),
    );
    gh.lazySingleton<_i1.ZbfWriter>(() => ingestionModule.zbfWriter());
    gh.lazySingleton<_i1.ZbfReader>(() => ingestionModule.zbfReader());
    gh.lazySingleton<_i539.HeadsUpCubit>(() => _i539.HeadsUpCubit());
    gh.lazySingleton<_i447.DeviceCapabilityService>(
      () => _i447.DeviceCapabilityServiceImpl(),
    );
    gh.lazySingleton<_i370.PdfPageRasterizer>(
      () => const _i217.PrintingPdfRasterizer(),
    );
    gh.lazySingleton<_i11.NostrService>(
      () => _i11.NostrService(gh<_i857.Ndk>()),
    );
    gh.lazySingleton<_i746.DocumentsDirectory>(
      () => const _i746.PathProviderDocumentsDirectory(),
    );
    gh.lazySingleton<_i1012.AiService>(
      () => _i1012.AiServiceImpl(
        gh<_i460.SharedPreferences>(),
        gh<_i447.DeviceCapabilityService>(),
      ),
    );
    gh.lazySingleton<_i63.IdentityRepository>(
      () => _i538.MarmotIdentityRepository(gh<_i123.SecureStorageService>()),
    );
    gh.lazySingleton<_i465.ThemeCubit>(
      () => _i465.ThemeCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i28.ReaderSettingsCubit>(
      () => _i28.ReaderSettingsCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i638.OnboardingLocalDataSource>(
      () => _i638.OnboardingLocalDataSource(gh<_i460.SharedPreferences>()),
    );
    gh.factory<_i439.IngestionPageCubit>(
      () => _i439.IngestionPageCubit(gh<_i1034.FilePickerService>()),
    );
    gh.lazySingleton<_i279.LibraryDatabase>(
      () => libraryModule.libraryDatabase(gh<_i746.DocumentsDirectory>()),
    );
    gh.lazySingleton<List<_i751.BookExtractor>>(
      () => ingestionModule.bookExtractors(gh<_i201.CoverGenerator>()),
    );
    gh.factoryParam<
      _i842.BookWizardCubit,
      _i687.Completer<_i1003.WizardData>,
      String?
    >(
      (_completer, initialTitle) => _i842.BookWizardCubit(
        gh<_i1034.FilePickerService>(),
        gh<_i850.GenreDataSource>(),
        _completer,
        initialTitle,
      ),
    );
    gh.lazySingleton<_i828.CoverStore>(
      () => _i828.CoverStore(gh<_i746.DocumentsDirectory>()),
    );
    gh.factory<_i709.GenerateIdentity>(
      () => _i709.GenerateIdentity(gh<_i63.IdentityRepository>()),
    );
    gh.factory<_i136.ImportIdentity>(
      () => _i136.ImportIdentity(gh<_i63.IdentityRepository>()),
    );
    gh.lazySingleton<_i516.LibraryRepository>(
      () => _i584.LibraryRepositoryImpl(
        gh<_i279.LibraryDatabase>(),
        gh<_i828.CoverStore>(),
        gh<_i746.DocumentsDirectory>(),
        gh<_i1.ZbfReader>(),
      ),
    );
    gh.lazySingleton<_i377.OnboardingRepository>(
      () =>
          _i444.OnboardingRepositoryImpl(gh<_i638.OnboardingLocalDataSource>()),
    );
    gh.factory<_i970.AiModelCubit>(
      () => _i970.AiModelCubit(gh<_i1012.AiService>()),
    );
    gh.lazySingleton<_i865.BookIngestionRepository>(
      () => _i785.BookIngestionRepositoryImpl(
        extractors: gh<List<_i751.BookExtractor>>(),
        documentsDirectory: gh<_i746.DocumentsDirectory>(),
        writer: gh<_i1.ZbfWriter>(),
      ),
    );
    gh.factory<_i341.CompleteOnboarding>(
      () => _i341.CompleteOnboarding(
        gh<_i63.IdentityRepository>(),
        gh<_i377.OnboardingRepository>(),
        gh<_i638.OnboardingLocalDataSource>(),
      ),
    );
    gh.factory<_i1071.AddBookToLibrary>(
      () => _i1071.AddBookToLibrary(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i887.BackfillLibrary>(
      () => _i887.BackfillLibrary(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i1038.DeleteLibraryBook>(
      () => _i1038.DeleteLibraryBook(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i190.FindBookByContentHash>(
      () => _i190.FindBookByContentHash(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i807.GetLibraryBook>(
      () => _i807.GetLibraryBook(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i296.TouchBookOpened>(
      () => _i296.TouchBookOpened(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i96.UpdateBookMetadata>(
      () => _i96.UpdateBookMetadata(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i1024.WatchLibraryBooks>(
      () => _i1024.WatchLibraryBooks(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i634.OnboardingCubit>(
      () => _i634.OnboardingCubit(
        gh<_i1053.ClipboardService>(),
        gh<_i11.NostrService>(),
        gh<_i709.GenerateIdentity>(),
        gh<_i136.ImportIdentity>(),
        gh<_i341.CompleteOnboarding>(),
      ),
    );
    gh.factory<_i107.LibraryCubit>(
      () => _i107.LibraryCubit(
        gh<_i1024.WatchLibraryBooks>(),
        gh<_i887.BackfillLibrary>(),
        gh<_i296.TouchBookOpened>(),
      ),
    );
    gh.factory<_i605.IngestBook>(
      () => _i605.IngestBook(gh<_i865.BookIngestionRepository>()),
    );
    gh.factory<_i327.IngestionQueueCubit>(
      () => _i327.IngestionQueueCubit(
        gh<_i605.IngestBook>(),
        gh<_i1071.AddBookToLibrary>(),
        gh<_i917.FileHasher>(),
        gh<_i190.FindBookByContentHash>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i200.RegisterModule {}

class _$MarmotModule extends _i817.MarmotModule {}

class _$NostrModule extends _i96.NostrModule {}

class _$IngestionModule extends _i627.IngestionModule {}

class _$LibraryModule extends _i808.LibraryModule {}
