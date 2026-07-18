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
import 'package:zapbook/core/data/cache/nostr_cache_store.dart' as _i68;
import 'package:zapbook/core/data/database/app_database.dart' as _i525;
import 'package:zapbook/core/data/database/dao/cheers_dao.dart' as _i562;
import 'package:zapbook/core/data/database/dao/circle_progress_dao.dart'
    as _i348;
import 'package:zapbook/core/data/database/dao/page_dao.dart' as _i492;
import 'package:zapbook/core/data/database/dao/reading_stats_dao.dart' as _i312;
import 'package:zapbook/core/data/database/dao/zap_sats_earnings_dao.dart'
    as _i760;
import 'package:zapbook/core/data/datasources/circle_progress_data_source.dart'
    as _i220;
import 'package:zapbook/core/data/datasources/genre_datasource.dart' as _i850;
import 'package:zapbook/core/data/datasources/onboarding_local_datasource.dart'
    as _i342;
import 'package:zapbook/core/data/documents_directory.dart' as _i240;
import 'package:zapbook/core/data/infrastructure/app_info_service.dart'
    as _i739;
import 'package:zapbook/core/data/infrastructure/blossom_service.dart' as _i901;
import 'package:zapbook/core/data/infrastructure/circle_share_service.dart'
    as _i540;
import 'package:zapbook/core/data/infrastructure/circle_store_service.dart'
    as _i516;
import 'package:zapbook/core/data/infrastructure/clipboard_service.dart'
    as _i78;
import 'package:zapbook/core/data/infrastructure/contact_service.dart' as _i409;
import 'package:zapbook/core/data/infrastructure/density_service.dart' as _i54;
import 'package:zapbook/core/data/infrastructure/file_logger_service.dart'
    as _i879;
import 'package:zapbook/core/data/infrastructure/file_picker_service.dart'
    as _i1049;
import 'package:zapbook/core/data/infrastructure/group_envelope_service.dart'
    as _i733;
import 'package:zapbook/core/data/infrastructure/group_store_service.dart'
    as _i676;
import 'package:zapbook/core/data/infrastructure/key_package_service.dart'
    as _i383;
import 'package:zapbook/core/data/infrastructure/lnurl_service.dart' as _i192;
import 'package:zapbook/core/data/infrastructure/local_notification_service.dart'
    as _i551;
import 'package:zapbook/core/data/infrastructure/marmot_sync_service.dart'
    as _i904;
import 'package:zapbook/core/data/infrastructure/message_router_service.dart'
    as _i194;
import 'package:zapbook/core/data/infrastructure/milestone_service.dart'
    as _i80;
import 'package:zapbook/core/data/infrastructure/nostr_service.dart' as _i295;
import 'package:zapbook/core/data/infrastructure/notification_gate.dart'
    as _i903;
import 'package:zapbook/core/data/infrastructure/nwc_service.dart' as _i409;
import 'package:zapbook/core/data/infrastructure/performance_service.dart'
    as _i797;
import 'package:zapbook/core/data/infrastructure/quiz_service.dart' as _i876;
import 'package:zapbook/core/data/infrastructure/reading_stats_service.dart'
    as _i837;
import 'package:zapbook/core/data/infrastructure/secure_storage_service.dart'
    as _i206;
import 'package:zapbook/core/data/infrastructure/share_service.dart' as _i210;
import 'package:zapbook/core/data/infrastructure/sync_service_channel.dart'
    as _i1064;
import 'package:zapbook/core/data/infrastructure/welcome_inbox_service.dart'
    as _i1029;
import 'package:zapbook/core/data/infrastructure/zap_earnings_service.dart'
    as _i377;
import 'package:zapbook/core/data/infrastructure/zap_nudge_service.dart'
    as _i954;
import 'package:zapbook/core/data/infrastructure/zap_service.dart' as _i327;
import 'package:zapbook/core/data/infrastructure/zap_support_service.dart'
    as _i1058;
import 'package:zapbook/core/data/library_file_store.dart' as _i854;
import 'package:zapbook/core/data/repositories/book_download_repository_impl.dart'
    as _i558;
import 'package:zapbook/core/data/repositories/book_search_repository_impl.dart'
    as _i33;
import 'package:zapbook/core/data/repositories/circle_progress_repository.dart'
    as _i59;
import 'package:zapbook/core/data/repositories/earnings_repository_impl.dart'
    as _i1042;
import 'package:zapbook/core/data/search/book_search_index.dart' as _i525;
import 'package:zapbook/core/data/search/book_vector_index.dart' as _i491;
import 'package:zapbook/core/data/search/embedding_service.dart' as _i18;
import 'package:zapbook/core/data/search/search_index_backfill.dart' as _i64;
import 'package:zapbook/core/di/marmot_module.dart' as _i817;
import 'package:zapbook/core/di/nostr_module.dart' as _i96;
import 'package:zapbook/core/di/register_module.dart' as _i200;
import 'package:zapbook/core/domain/book_ingestion_repository.dart' as _i379;
import 'package:zapbook/core/domain/ingest_book.dart' as _i696;
import 'package:zapbook/core/domain/pdf_chunk_extractor.dart' as _i970;
import 'package:zapbook/core/domain/pdf_page_rasterizer.dart' as _i283;
import 'package:zapbook/core/domain/repositories/book_download_repository.dart'
    as _i753;
import 'package:zapbook/core/domain/repositories/book_search_repository.dart'
    as _i83;
import 'package:zapbook/core/domain/repositories/earnings_repository.dart'
    as _i949;
import 'package:zapbook/core/domain/repositories/performance_repository.dart'
    as _i801;
import 'package:zapbook/core/domain/usecases/book_search_usecases.dart'
    as _i741;
import 'package:zapbook/core/domain/usecases/clipboard_usecases.dart' as _i854;
import 'package:zapbook/core/domain/usecases/delete_circle_book.dart' as _i812;
import 'package:zapbook/core/domain/usecases/download_circle_book.dart'
    as _i665;
import 'package:zapbook/core/domain/usecases/earnings_usecases.dart' as _i177;
import 'package:zapbook/core/domain/usecases/pdf_usecases.dart' as _i616;
import 'package:zapbook/core/domain/usecases/performance_usecases.dart'
    as _i1045;
import 'package:zapbook/core/domain/usecases/watch_global_book_download_progress.dart'
    as _i153;
import 'package:zapbook/core/domain/usecases/watch_my_reading_progress.dart'
    as _i35;
import 'package:zapbook/core/domain/wizard_data.dart' as _i230;
import 'package:zapbook/core/identity/bunker_signer_source.dart' as _i991;
import 'package:zapbook/core/identity/identity_local_data_source.dart' as _i603;
import 'package:zapbook/core/identity/identity_repository.dart' as _i63;
import 'package:zapbook/core/identity/local_key_signer_source.dart' as _i429;
import 'package:zapbook/core/identity/marmot_identity_repository.dart' as _i538;
import 'package:zapbook/core/identity/nip55_signer.dart' as _i513;
import 'package:zapbook/core/identity/nip55_signer_source.dart' as _i552;
import 'package:zapbook/core/identity/nostr_session.dart' as _i1073;
import 'package:zapbook/core/identity/nostr_signer_source.dart' as _i148;
import 'package:zapbook/core/identity/signer_source_resolver.dart' as _i105;
import 'package:zapbook/core/presentation/bloc/book_download/book_download_cubit.dart'
    as _i81;
import 'package:zapbook/core/presentation/bloc/circle_operations/circle_operations_cubit.dart'
    as _i41;
import 'package:zapbook/core/presentation/bloc/earnings/earnings_cubit.dart'
    as _i362;
import 'package:zapbook/core/presentation/bloc/performance/performance_cubit.dart'
    as _i400;
import 'package:zapbook/core/presentation/router/app_router.dart' as _i520;
import 'package:zapbook/core/presentation/theme/theme_cubit.dart' as _i584;
import 'package:zapbook/core/session/session_reloader.dart' as _i803;
import 'package:zapbook/core/utils/file_hasher.dart' as _i918;
import 'package:zapbook/features/book_ingestion/data/ai/printing_pdf_rasterizer.dart'
    as _i217;
import 'package:zapbook/features/book_ingestion/data/book_ingestion_repository_impl.dart'
    as _i785;
import 'package:zapbook/features/book_ingestion/data/cover/cover_generator.dart'
    as _i201;
import 'package:zapbook/features/book_ingestion/data/di/ingestion_module.dart'
    as _i627;
import 'package:zapbook/features/book_ingestion/data/extractors/book_extractor.dart'
    as _i751;
import 'package:zapbook/features/book_ingestion/data/repositories/ingestion_orchestrator_repository_impl.dart'
    as _i289;
import 'package:zapbook/features/book_ingestion/domain/repositories/ingestion_orchestrator_repository.dart'
    as _i810;
import 'package:zapbook/features/book_ingestion/domain/usecases/ingestion_orchestrator_usecases.dart'
    as _i704;
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_orchestrator_cubit.dart'
    as _i1043;
import 'package:zapbook/features/book_reader/data/reading_progress_local_store.dart'
    as _i603;
import 'package:zapbook/features/book_reader/data/recognition_quiz_builder.dart'
    as _i974;
import 'package:zapbook/features/book_reader/data/repositories/book_reader_repository_impl.dart'
    as _i995;
import 'package:zapbook/features/book_reader/data/repositories/quiz_repository_impl.dart'
    as _i389;
import 'package:zapbook/features/book_reader/domain/repositories/book_reader_repository.dart'
    as _i188;
import 'package:zapbook/features/book_reader/domain/repositories/quiz_repository.dart'
    as _i902;
import 'package:zapbook/features/book_reader/domain/usecases/book_reader_usecases.dart'
    as _i571;
import 'package:zapbook/features/book_reader/domain/usecases/quiz_usecases.dart'
    as _i297;
import 'package:zapbook/features/book_reader/presentation/bloc/quiz_cubit.dart'
    as _i552;
import 'package:zapbook/features/book_reader/presentation/bloc/reader_init_cubit.dart'
    as _i227;
import 'package:zapbook/features/book_reader/presentation/bloc/reader_search_cubit.dart'
    as _i444;
import 'package:zapbook/features/book_reader/presentation/bloc/reader_settings/reader_settings_cubit.dart'
    as _i58;
import 'package:zapbook/features/book_reader/presentation/bloc/reading_progress_cubit.dart'
    as _i362;
import 'package:zapbook/features/cheers/data/datasources/cheers_data_source.dart'
    as _i64;
import 'package:zapbook/features/cheers/data/repositories/cheers_repository_impl.dart'
    as _i489;
import 'package:zapbook/features/cheers/domain/cheers_note_composer.dart'
    as _i912;
import 'package:zapbook/features/cheers/domain/repositories/cheers_repository.dart'
    as _i314;
import 'package:zapbook/features/cheers/domain/usecases/cheers_usecases.dart'
    as _i921;
import 'package:zapbook/features/cheers/presentation/bloc/cheers_cubit.dart'
    as _i584;
import 'package:zapbook/features/circles/data/datasources/circles_data_source.dart'
    as _i0;
import 'package:zapbook/features/circles/data/datasources/circles_data_source_impl.dart'
    as _i160;
import 'package:zapbook/features/circles/data/repositories/circles_repository_impl.dart'
    as _i557;
import 'package:zapbook/features/circles/domain/repositories/circles_repository.dart'
    as _i203;
import 'package:zapbook/features/circles/domain/usecases/circles_usecases.dart'
    as _i1006;
import 'package:zapbook/features/circles/presentation/bloc/circle_detail_cubit.dart'
    as _i947;
import 'package:zapbook/features/circles/presentation/bloc/circle_members_cubit.dart'
    as _i688;
import 'package:zapbook/features/circles/presentation/bloc/circles_cubit.dart'
    as _i761;
import 'package:zapbook/features/circles/presentation/bloc/reader_zap_cubit.dart'
    as _i492;
import 'package:zapbook/features/circles/presentation/bloc/share_circle_cubit.dart'
    as _i620;
import 'package:zapbook/features/heads_up/presentation/cubit/heads_up_cubit.dart'
    as _i539;
import 'package:zapbook/features/home/data/datasources/home_dashboard_data_source.dart'
    as _i265;
import 'package:zapbook/features/home/data/repositories/home_dashboard_repository_impl.dart'
    as _i139;
import 'package:zapbook/features/home/domain/repositories/home_dashboard_repository.dart'
    as _i326;
import 'package:zapbook/features/home/domain/usecases/touch_dashboard_book_opened.dart'
    as _i899;
import 'package:zapbook/features/home/domain/usecases/watch_home_dashboard.dart'
    as _i1021;
import 'package:zapbook/features/home/presentation/bloc/home_cubit.dart'
    as _i602;
import 'package:zapbook/features/library/data/repositories/book_ingestion_repository_impl.dart'
    as _i484;
import 'package:zapbook/features/library/data/repositories/marmot_library_repository.dart'
    as _i894;
import 'package:zapbook/features/library/domain/repositories/book_ingestion_repository.dart'
    as _i737;
import 'package:zapbook/features/library/domain/repositories/library_repository.dart'
    as _i516;
import 'package:zapbook/features/library/domain/usecases/book_ingestion_usecases.dart'
    as _i20;
import 'package:zapbook/features/library/domain/usecases/watch_last_opened_library_book.dart'
    as _i16;
import 'package:zapbook/features/library/domain/usecases/watch_library_books.dart'
    as _i1024;
import 'package:zapbook/features/library/presentation/bloc/book_text_search_cubit.dart'
    as _i385;
import 'package:zapbook/features/library/presentation/bloc/library_cubit.dart'
    as _i107;
import 'package:zapbook/features/library/presentation/bloc/page/ingestion_page_cubit.dart'
    as _i696;
import 'package:zapbook/features/library/presentation/bloc/wizard/book_wizard_cubit.dart'
    as _i405;
import 'package:zapbook/features/onboarding/data/repositories/identity_repository_impl.dart'
    as _i503;
import 'package:zapbook/features/onboarding/data/repositories/onboarding_repository_impl.dart'
    as _i444;
import 'package:zapbook/features/onboarding/domain/repositories/identity_repository.dart'
    as _i1033;
import 'package:zapbook/features/onboarding/domain/repositories/onboarding_repository.dart'
    as _i377;
import 'package:zapbook/features/onboarding/domain/usecases/complete_onboarding.dart'
    as _i341;
import 'package:zapbook/features/onboarding/domain/usecases/connect_external_signer.dart'
    as _i234;
import 'package:zapbook/features/onboarding/domain/usecases/fetch_existing_profile.dart'
    as _i1070;
import 'package:zapbook/features/onboarding/domain/usecases/generate_identity.dart'
    as _i709;
import 'package:zapbook/features/onboarding/domain/usecases/import_identity.dart'
    as _i136;
import 'package:zapbook/features/onboarding/presentation/bloc/onboarding_cubit.dart'
    as _i634;
import 'package:zapbook/features/profile/data/datasources/profile_remote_datasource.dart'
    as _i735;
import 'package:zapbook/features/profile/data/repositories/donate_repository_impl.dart'
    as _i51;
import 'package:zapbook/features/profile/data/repositories/friends_repository_impl.dart'
    as _i876;
import 'package:zapbook/features/profile/data/repositories/profile_repository_impl.dart'
    as _i160;
import 'package:zapbook/features/profile/data/repositories/profile_settings_repository_impl.dart'
    as _i366;
import 'package:zapbook/features/profile/data/repositories/switch_account_repository_impl.dart'
    as _i629;
import 'package:zapbook/features/profile/data/repositories/user_profile_repository_impl.dart'
    as _i615;
import 'package:zapbook/features/profile/domain/repositories/donate_repository.dart'
    as _i993;
import 'package:zapbook/features/profile/domain/repositories/friends_repository.dart'
    as _i856;
import 'package:zapbook/features/profile/domain/repositories/profile_repository.dart'
    as _i582;
import 'package:zapbook/features/profile/domain/repositories/profile_settings_repository.dart'
    as _i493;
import 'package:zapbook/features/profile/domain/repositories/switch_account_repository.dart'
    as _i991;
import 'package:zapbook/features/profile/domain/repositories/user_profile_repository.dart'
    as _i771;
import 'package:zapbook/features/profile/domain/usecases/donate_usecases.dart'
    as _i631;
import 'package:zapbook/features/profile/domain/usecases/friends_usecases.dart'
    as _i86;
import 'package:zapbook/features/profile/domain/usecases/load_profile.dart'
    as _i385;
import 'package:zapbook/features/profile/domain/usecases/profile_usecases.dart'
    as _i1055;
import 'package:zapbook/features/profile/domain/usecases/sign_out.dart'
    as _i915;
import 'package:zapbook/features/profile/domain/usecases/switch_account_usecases.dart'
    as _i1009;
import 'package:zapbook/features/profile/domain/usecases/update_profile.dart'
    as _i223;
import 'package:zapbook/features/profile/domain/usecases/user_profile_usecases.dart'
    as _i644;
import 'package:zapbook/features/profile/presentation/bloc/donate_cubit.dart'
    as _i469;
import 'package:zapbook/features/profile/presentation/bloc/friends_cubit.dart'
    as _i397;
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart'
    as _i145;
import 'package:zapbook/features/profile/presentation/bloc/switch_account_cubit.dart'
    as _i982;
import 'package:zapbook/features/profile/presentation/bloc/user_profile_cubit.dart'
    as _i623;
import 'package:zapbook/features/profile/presentation/bloc/user_profile_zap_cubit.dart'
    as _i3;
import 'package:zapbook/zbf/zbf.dart' as _i1;
import 'package:zapbook/zbf/zbf_reader.dart' as _i138;

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
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.factory<_i912.CheersNoteComposer>(
      () => const _i912.CheersNoteComposer(),
    );
    gh.singleton<_i525.AppDatabase>(() => _i525.AppDatabase());
    await gh.singletonAsync<_i739.AppInfoService>(
      () => registerModule.appInfoService(),
      preResolve: true,
    );
    gh.lazySingleton<_i850.GenreDataSource>(() => _i850.GenreDataSource());
    gh.lazySingleton<_i78.ClipboardService>(() => _i78.ClipboardService());
    gh.lazySingleton<_i54.DensityService>(() => _i54.DensityService());
    gh.lazySingleton<_i879.FileLoggerService>(() => _i879.FileLoggerService());
    gh.lazySingleton<_i1049.FilePickerService>(
      () => _i1049.FilePickerService(),
    );
    gh.lazySingleton<_i192.LnurlService>(
      () => _i192.LnurlService.create(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i551.LocalNotificationService>(
      () => _i551.LocalNotificationService(),
    );
    gh.lazySingleton<_i876.QuizService>(() => _i876.QuizService());
    gh.lazySingleton<_i206.SecureStorageService>(
      () => _i206.SecureStorageService(),
    );
    gh.lazySingleton<_i210.ShareService>(() => _i210.ShareService());
    gh.lazySingleton<_i1064.SyncServiceChannel>(
      () => _i1064.SyncServiceChannel(),
    );
    gh.lazySingleton<_i854.LibraryFileStore>(() => _i854.LibraryFileStore());
    gh.lazySingleton<_i525.BookSearchIndex>(() => _i525.BookSearchIndex());
    gh.lazySingleton<_i18.EmbeddingService>(() => _i18.EmbeddingService());
    await gh.lazySingletonAsync<_i970.Marmot>(
      () => marmotModule.marmot(),
      preResolve: true,
    );
    await gh.lazySingletonAsync<_i68.NostrCacheStore>(
      () => nostrModule.cacheStore(),
      preResolve: true,
    );
    gh.lazySingleton<_i513.Nip55Signer>(() => const _i513.Nip55Signer());
    gh.lazySingleton<_i520.AppRouter>(() => _i520.AppRouter());
    gh.lazySingleton<_i918.FileHasher>(() => const _i918.FileHasher());
    gh.lazySingleton<_i201.CoverGenerator>(
      () => ingestionModule.coverGenerator(),
    );
    gh.lazySingleton<_i1.ZbfWriter>(() => ingestionModule.zbfWriter());
    gh.lazySingleton<_i1.ZbfReader>(() => ingestionModule.zbfReader());
    gh.lazySingleton<_i539.HeadsUpCubit>(() => _i539.HeadsUpCubit());
    gh.lazySingleton<_i803.SessionReloader>(
      () => const _i803.SessionManagerReloader(),
    );
    gh.factory<_i854.CopyTextUseCase>(
      () => _i854.CopyTextUseCase(gh<_i78.ClipboardService>()),
    );
    gh.factory<_i854.PasteTextUseCase>(
      () => _i854.PasteTextUseCase(gh<_i78.ClipboardService>()),
    );
    gh.lazySingleton<_i348.CircleProgressDao>(
      () => _i348.CircleProgressDao(gh<_i525.AppDatabase>()),
    );
    gh.lazySingleton<_i312.ReadingStatsDao>(
      () => _i312.ReadingStatsDao(gh<_i525.AppDatabase>()),
    );
    gh.lazySingleton<_i760.ZapSatsEarningsDao>(
      () => _i760.ZapSatsEarningsDao(gh<_i525.AppDatabase>()),
    );
    gh.lazySingleton<_i949.EarningsRepository>(
      () => _i1042.EarningsRepositoryImpl(gh<_i760.ZapSatsEarningsDao>()),
    );
    gh.factory<_i227.ReaderInitCubit>(
      () => _i227.ReaderInitCubit(gh<_i138.ZbfReader>()),
    );
    gh.lazySingleton<_i603.IdentityLocalDataSource>(
      () => _i603.IdentityLocalDataSource(gh<_i206.SecureStorageService>()),
    );
    await gh.lazySingletonAsync<_i857.Ndk>(
      () => nostrModule.ndk(gh<_i68.NostrCacheStore>()),
      preResolve: true,
    );
    gh.lazySingleton<_i240.DocumentsDirectory>(
      () => const _i240.PathProviderDocumentsDirectory(),
    );
    gh.lazySingleton<_i283.PdfPageRasterizer>(
      () => const _i217.PrintingPdfRasterizer(),
    );
    gh.factory<_i616.RasterizePdfPageUseCase>(
      () => _i616.RasterizePdfPageUseCase(gh<_i283.PdfPageRasterizer>()),
    );
    gh.lazySingleton<_i429.LocalKeySignerSource>(
      () => _i429.LocalKeySignerSource(gh<_i603.IdentityLocalDataSource>()),
    );
    gh.lazySingleton<_i342.OnboardingLocalDataSource>(
      () => _i342.OnboardingLocalDataSource(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i1058.ZapSupportService>(
      () => _i1058.ZapSupportService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i584.ThemeCubit>(
      () => _i584.ThemeCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i58.ReaderSettingsCubit>(
      () => _i58.ReaderSettingsCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i383.KeyPackageService>(
      () => _i383.KeyPackageService(
        gh<_i970.Marmot>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i857.Ndk>(),
      ),
    );
    gh.lazySingleton<_i220.CircleProgressDataSource>(
      () => _i220.CircleProgressDataSourceImpl(gh<_i348.CircleProgressDao>()),
    );
    gh.lazySingleton<_i409.NwcService>(
      () => _i409.NwcService(
        gh<_i460.SharedPreferences>(),
        gh<_i857.Ndk>(),
        gh<_i206.SecureStorageService>(),
      ),
    );
    gh.lazySingleton<_i59.CircleProgressRepository>(
      () => _i59.CircleProgressRepository(gh<_i220.CircleProgressDataSource>()),
    );
    gh.lazySingleton<_i552.Nip55SignerSource>(
      () => _i552.Nip55SignerSource(gh<_i513.Nip55Signer>()),
    );
    gh.singleton<_i801.PerformanceRepository>(
      () => _i797.PerformanceService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i491.BookVectorIndex>(
      () => _i491.BookVectorIndex(gh<_i18.EmbeddingService>()),
    );
    gh.lazySingleton<_i970.PdfChunkExtractor>(
      () => ingestionModule.pdfChunkExtractor(gh<_i201.CoverGenerator>()),
    );
    gh.lazySingleton<List<_i751.BookExtractor>>(
      () => ingestionModule.bookExtractors(gh<_i201.CoverGenerator>()),
    );
    gh.lazySingleton<_i377.ZapEarningsService>(
      () => _i377.ZapEarningsService(
        gh<_i857.Ndk>(),
        gh<_i760.ZapSatsEarningsDao>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i562.CheersDao>(
      () => _i562.CheersDao(gh<_i525.AppDatabase>()),
    );
    gh.lazySingleton<_i492.PageDao>(
      () => _i492.PageDao(gh<_i525.AppDatabase>()),
    );
    gh.lazySingleton<_i901.BlossomService>(
      () => _i901.BlossomService(gh<_i857.Ndk>()),
    );
    gh.lazySingleton<_i733.GroupEnvelopeService>(
      () => _i733.GroupEnvelopeService(gh<_i857.Ndk>()),
    );
    gh.lazySingleton<_i991.BunkerSignerSource>(
      () => _i991.BunkerSignerSource(gh<_i857.Ndk>()),
    );
    gh.lazySingleton<_i540.CircleShareService>(
      () => _i540.CircleShareService(
        gh<_i970.Marmot>(),
        gh<_i901.BlossomService>(),
        gh<_i854.LibraryFileStore>(),
        gh<_i733.GroupEnvelopeService>(),
      ),
    );
    gh.lazySingleton<_i83.BookSearchRepository>(
      () => _i33.BookSearchRepositoryImpl(
        gh<_i525.BookSearchIndex>(),
        gh<_i491.BookVectorIndex>(),
        gh<_i854.LibraryFileStore>(),
      ),
    );
    gh.factory<_i741.SearchBooks>(
      () => _i741.SearchBooks(gh<_i83.BookSearchRepository>()),
    );
    gh.factory<_i741.EnsureBookSearchable>(
      () => _i741.EnsureBookSearchable(gh<_i83.BookSearchRepository>()),
    );
    gh.factory<_i444.ReaderSearchCubit>(
      () => _i444.ReaderSearchCubit(gh<_i741.SearchBooks>()),
    );
    gh.factory<_i385.BookTextSearchCubit>(
      () => _i385.BookTextSearchCubit(gh<_i741.SearchBooks>()),
    );
    gh.lazySingleton<_i1029.WelcomeInboxService>(
      () => _i1029.WelcomeInboxService(
        gh<_i970.Marmot>(),
        gh<_i857.Ndk>(),
        gh<_i603.IdentityLocalDataSource>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.factory<_i902.QuizRepository>(
      () => _i389.QuizRepositoryImpl(
        gh<_i857.Ndk>(),
        gh<_i68.NostrCacheStore>(),
        gh<_i876.QuizService>(),
      ),
    );
    gh.lazySingleton<_i974.RecognitionQuizBuilder>(
      () => _i974.RecognitionQuizBuilder(gh<_i491.BookVectorIndex>()),
    );
    gh.lazySingleton<_i603.ReadingProgressLocalStore>(
      () => _i603.ReadingProgressLocalStore(
        gh<_i460.SharedPreferences>(),
        gh<_i603.IdentityLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i148.NostrSignerSource>(
      () => _i105.SignerSourceResolver(
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i429.LocalKeySignerSource>(),
        gh<_i552.Nip55SignerSource>(),
        gh<_i991.BunkerSignerSource>(),
      ),
    );
    gh.lazySingleton<_i295.NostrService>(
      () => _i295.NostrService(gh<_i857.Ndk>(), gh<_i68.NostrCacheStore>()),
    );
    gh.factory<_i35.WatchMyReadingProgressUseCase>(
      () => _i35.WatchMyReadingProgressUseCase(
        gh<_i59.CircleProgressRepository>(),
        gh<_i603.IdentityLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i327.ZapService>(
      () => _i327.ZapService(
        gh<_i192.LnurlService>(),
        gh<_i857.Ndk>(),
        gh<_i409.NwcService>(),
        gh<_i1058.ZapSupportService>(),
      ),
    );
    gh.lazySingleton<_i377.OnboardingRepository>(
      () =>
          _i444.OnboardingRepositoryImpl(gh<_i342.OnboardingLocalDataSource>()),
    );
    gh.lazySingleton<_i63.IdentityRepository>(
      () => _i538.MarmotIdentityRepository(
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i513.Nip55Signer>(),
        gh<_i991.BunkerSignerSource>(),
      ),
    );
    gh.lazySingleton<_i904.MarmotSyncService>(
      () => _i904.MarmotSyncService(
        gh<_i970.Marmot>(),
        gh<_i857.Ndk>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i383.KeyPackageService>(),
      ),
    );
    gh.lazySingleton<_i493.ProfileSettingsRepository>(
      () => _i366.ProfileSettingsRepositoryImpl(
        gh<_i78.ClipboardService>(),
        gh<_i409.NwcService>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i1049.FilePickerService>(),
        gh<_i383.KeyPackageService>(),
        gh<_i739.AppInfoService>(),
        gh<_i1058.ZapSupportService>(),
      ),
    );
    gh.lazySingleton<_i735.ProfileRemoteDataSource>(
      () => _i735.ProfileRemoteDataSource(gh<_i295.NostrService>()),
    );
    gh.lazySingleton<_i837.ReadingStatsService>(
      () => _i837.ReadingStatsService(
        gh<_i348.CircleProgressDao>(),
        gh<_i312.ReadingStatsDao>(),
        gh<_i760.ZapSatsEarningsDao>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i377.ZapEarningsService>(),
        gh<_i857.Ndk>(),
      ),
    );
    gh.factory<_i993.DonateRepository>(
      () => _i51.DonateRepositoryImpl(
        gh<_i327.ZapService>(),
        gh<_i78.ClipboardService>(),
      ),
    );
    gh.lazySingleton<_i379.BookIngestionRepository>(
      () => _i785.BookIngestionRepositoryImpl(
        extractors: gh<List<_i751.BookExtractor>>(),
        fileStore: gh<_i854.LibraryFileStore>(),
        searchIndex: gh<_i525.BookSearchIndex>(),
        vectorIndex: gh<_i491.BookVectorIndex>(),
        writer: gh<_i1.ZbfWriter>(),
      ),
    );
    gh.factory<_i341.CompleteOnboarding>(
      () => _i341.CompleteOnboarding(
        gh<_i63.IdentityRepository>(),
        gh<_i377.OnboardingRepository>(),
        gh<_i803.SessionReloader>(),
      ),
    );
    gh.lazySingleton<_i676.GroupStoreService>(
      () => _i676.GroupStoreService(
        gh<_i904.MarmotSyncService>(),
        gh<_i970.Marmot>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i901.BlossomService>(),
        gh<_i733.GroupEnvelopeService>(),
        gh<_i460.SharedPreferences>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i64.SearchIndexBackfill>(
      () => _i64.SearchIndexBackfill(gh<_i83.BookSearchRepository>()),
    );
    gh.factory<_i753.BookDownloadRepository>(
      () => _i558.BookDownloadRepositoryImpl(gh<_i540.CircleShareService>()),
    );
    gh.factory<_i1045.WatchPerformanceModeUseCase>(
      () =>
          _i1045.WatchPerformanceModeUseCase(gh<_i801.PerformanceRepository>()),
    );
    gh.factory<_i1045.SetPerformanceModeUseCase>(
      () => _i1045.SetPerformanceModeUseCase(gh<_i801.PerformanceRepository>()),
    );
    gh.factory<_i1045.GetPerformanceModeUseCase>(
      () => _i1045.GetPerformanceModeUseCase(gh<_i801.PerformanceRepository>()),
    );
    gh.factory<_i631.DonateUseCases>(
      () => _i631.DonateUseCases(gh<_i993.DonateRepository>()),
    );
    gh.factory<_i991.SwitchAccountRepository>(
      () => _i629.SwitchAccountRepositoryImpl(
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i63.IdentityRepository>(),
        gh<_i735.ProfileRemoteDataSource>(),
        gh<_i803.SessionReloader>(),
      ),
    );
    gh.lazySingleton<_i1073.NostrSession>(
      () => _i1073.NostrSession(
        gh<_i857.Ndk>(),
        gh<_i148.NostrSignerSource>(),
        gh<_i295.NostrService>(),
        gh<_i904.MarmotSyncService>(),
      ),
    );
    gh.factory<_i469.DonateCubit>(
      () => _i469.DonateCubit(gh<_i631.DonateUseCases>()),
    );
    gh.factory<_i616.ExtractPdfChunkUseCase>(
      () => _i616.ExtractPdfChunkUseCase(gh<_i970.PdfChunkExtractor>()),
    );
    gh.factory<_i1033.IdentityRepository>(
      () => _i503.IdentityRepositoryImpl(gh<_i295.NostrService>()),
    );
    gh.lazySingleton<_i80.MilestoneService>(
      () => _i80.MilestoneService(
        gh<_i970.Marmot>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i733.GroupEnvelopeService>(),
        gh<_i348.CircleProgressDao>(),
        gh<_i562.CheersDao>(),
        gh<_i837.ReadingStatsService>(),
      ),
    );
    gh.lazySingleton<_i954.ZapNudgeService>(
      () => _i954.ZapNudgeService(
        gh<_i970.Marmot>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i733.GroupEnvelopeService>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_i297.WatchQuizSurfaceUseCase>(
      () => _i297.WatchQuizSurfaceUseCase(gh<_i902.QuizRepository>()),
    );
    gh.factory<_i297.SubmitQuizUseCase>(
      () => _i297.SubmitQuizUseCase(gh<_i902.QuizRepository>()),
    );
    gh.factory<_i297.SkipQuizUseCase>(
      () => _i297.SkipQuizUseCase(gh<_i902.QuizRepository>()),
    );
    gh.lazySingleton<_i409.ContactService>(
      () => _i409.ContactService(
        gh<_i295.NostrService>(),
        gh<_i603.IdentityLocalDataSource>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.factory<_i234.ConnectExternalSigner>(
      () => _i234.ConnectExternalSigner(gh<_i63.IdentityRepository>()),
    );
    gh.factory<_i709.GenerateIdentity>(
      () => _i709.GenerateIdentity(gh<_i63.IdentityRepository>()),
    );
    gh.factory<_i136.ImportIdentity>(
      () => _i136.ImportIdentity(gh<_i63.IdentityRepository>()),
    );
    gh.factory<_i177.WatchEarningsUseCase>(
      () => _i177.WatchEarningsUseCase(
        gh<_i949.EarningsRepository>(),
        gh<_i63.IdentityRepository>(),
      ),
    );
    gh.factory<_i177.GetEarningsUseCase>(
      () => _i177.GetEarningsUseCase(
        gh<_i949.EarningsRepository>(),
        gh<_i63.IdentityRepository>(),
      ),
    );
    gh.factory<_i856.FriendsRepository>(
      () => _i876.FriendsRepositoryImpl(gh<_i409.ContactService>()),
    );
    gh.factory<_i188.BookReaderRepository>(
      () => _i995.BookReaderRepositoryImpl(
        gh<_i603.ReadingProgressLocalStore>(),
        gh<_i80.MilestoneService>(),
        gh<_i492.PageDao>(),
        gh<_i540.CircleShareService>(),
      ),
    );
    gh.factory<_i696.IngestBook>(
      () => _i696.IngestBook(gh<_i379.BookIngestionRepository>()),
    );
    gh.factory<_i153.WatchGlobalBookDownloadProgress>(
      () => _i153.WatchGlobalBookDownloadProgress(
        gh<_i753.BookDownloadRepository>(),
      ),
    );
    gh.factory<_i1055.ProfileSettingsUseCases>(
      () =>
          _i1055.ProfileSettingsUseCases(gh<_i493.ProfileSettingsRepository>()),
    );
    gh.factory<_i665.DownloadCircleBook>(
      () => _i665.DownloadCircleBook(
        gh<_i753.BookDownloadRepository>(),
        gh<_i83.BookSearchRepository>(),
      ),
    );
    gh.factory<_i552.QuizCubit>(
      () => _i552.QuizCubit(
        gh<_i297.WatchQuizSurfaceUseCase>(),
        gh<_i297.SubmitQuizUseCase>(),
        gh<_i297.SkipQuizUseCase>(),
      ),
    );
    gh.lazySingleton<_i194.MessageRouterService>(
      () => _i194.MessageRouterService(
        gh<_i904.MarmotSyncService>(),
        gh<_i562.CheersDao>(),
        gh<_i348.CircleProgressDao>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i970.Marmot>(),
      ),
    );
    gh.lazySingleton<_i582.ProfileRepository>(
      () => _i160.ProfileRepositoryImpl(
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i735.ProfileRemoteDataSource>(),
        gh<_i342.OnboardingLocalDataSource>(),
        gh<_i1073.NostrSession>(),
        gh<_i837.ReadingStatsService>(),
        gh<_i803.SessionReloader>(),
        gh<_i760.ZapSatsEarningsDao>(),
      ),
    );
    gh.factory<_i1070.FetchExistingProfileUseCase>(
      () => _i1070.FetchExistingProfileUseCase(gh<_i1033.IdentityRepository>()),
    );
    gh.lazySingleton<_i771.UserProfileRepository>(
      () => _i615.UserProfileRepositoryImpl(
        gh<_i735.ProfileRemoteDataSource>(),
        gh<_i837.ReadingStatsService>(),
        gh<_i348.CircleProgressDao>(),
        gh<_i327.ZapService>(),
        gh<_i409.ContactService>(),
        gh<_i603.IdentityLocalDataSource>(),
      ),
    );
    gh.factory<_i1009.SwitchAccountUseCases>(
      () => _i1009.SwitchAccountUseCases(gh<_i991.SwitchAccountRepository>()),
    );
    gh.factory<_i362.EarningsCubit>(
      () => _i362.EarningsCubit(
        gh<_i177.GetEarningsUseCase>(),
        gh<_i177.WatchEarningsUseCase>(),
      ),
    );
    gh.factory<_i644.LoadUserProfileUseCase>(
      () => _i644.LoadUserProfileUseCase(gh<_i771.UserProfileRepository>()),
    );
    gh.factory<_i644.ToggleFollowUseCase>(
      () => _i644.ToggleFollowUseCase(gh<_i771.UserProfileRepository>()),
    );
    gh.factory<_i644.SendProfileZapUseCase>(
      () => _i644.SendProfileZapUseCase(gh<_i771.UserProfileRepository>()),
    );
    gh.lazySingleton<_i400.PerformanceCubit>(
      () => _i400.PerformanceCubit(
        gh<_i1045.WatchPerformanceModeUseCase>(),
        gh<_i1045.GetPerformanceModeUseCase>(),
        gh<_i1045.SetPerformanceModeUseCase>(),
      ),
    );
    gh.factory<_i571.SaveReadingSnapshotUseCase>(
      () => _i571.SaveReadingSnapshotUseCase(gh<_i188.BookReaderRepository>()),
    );
    gh.factory<_i571.LoadReadingSnapshotUseCase>(
      () => _i571.LoadReadingSnapshotUseCase(gh<_i188.BookReaderRepository>()),
    );
    gh.factory<_i571.ReportReadingProgressUseCase>(
      () =>
          _i571.ReportReadingProgressUseCase(gh<_i188.BookReaderRepository>()),
    );
    gh.factory<_i571.GetBookContentUseCase>(
      () => _i571.GetBookContentUseCase(gh<_i188.BookReaderRepository>()),
    );
    gh.factory<_i571.SaveBookContentUseCase>(
      () => _i571.SaveBookContentUseCase(gh<_i188.BookReaderRepository>()),
    );
    gh.factory<_i571.WatchBookDownloadProgressUseCase>(
      () => _i571.WatchBookDownloadProgressUseCase(
        gh<_i188.BookReaderRepository>(),
      ),
    );
    gh.factory<_i634.OnboardingCubit>(
      () => _i634.OnboardingCubit(
        gh<_i854.CopyTextUseCase>(),
        gh<_i854.PasteTextUseCase>(),
        gh<_i1070.FetchExistingProfileUseCase>(),
        gh<_i709.GenerateIdentity>(),
        gh<_i136.ImportIdentity>(),
        gh<_i341.CompleteOnboarding>(),
        gh<_i234.ConnectExternalSigner>(),
      ),
    );
    gh.factory<_i81.BookDownloadCubit>(
      () => _i81.BookDownloadCubit(
        gh<_i665.DownloadCircleBook>(),
        gh<_i153.WatchGlobalBookDownloadProgress>(),
      ),
    );
    gh.factory<_i385.LoadProfile>(
      () => _i385.LoadProfile(gh<_i582.ProfileRepository>()),
    );
    gh.factory<_i915.SignOut>(
      () => _i915.SignOut(gh<_i582.ProfileRepository>()),
    );
    gh.factory<_i223.UpdateProfile>(
      () => _i223.UpdateProfile(gh<_i582.ProfileRepository>()),
    );
    gh.lazySingleton<_i516.CircleStoreService>(
      () => _i516.CircleStoreService(
        gh<_i676.GroupStoreService>(),
        gh<_i854.LibraryFileStore>(),
        gh<_i409.ContactService>(),
        gh<_i383.KeyPackageService>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.factory<_i86.FriendsUseCases>(
      () => _i86.FriendsUseCases(gh<_i856.FriendsRepository>()),
    );
    gh.lazySingleton<_i0.CirclesDataSource>(
      () => _i160.CirclesDataSourceImpl(
        gh<_i516.CircleStoreService>(),
        gh<_i409.ContactService>(),
        gh<_i348.CircleProgressDao>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i327.ZapService>(),
        gh<_i954.ZapNudgeService>(),
        gh<_i383.KeyPackageService>(),
        gh<_i733.GroupEnvelopeService>(),
        gh<_i540.CircleShareService>(),
        gh<_i676.GroupStoreService>(),
        gh<_i970.Marmot>(),
      ),
    );
    gh.factory<_i810.IngestionOrchestratorRepository>(
      () => _i289.IngestionOrchestratorRepositoryImpl(
        gh<_i516.CircleStoreService>(),
        gh<_i540.CircleShareService>(),
        gh<_i854.LibraryFileStore>(),
      ),
    );
    gh.factory<_i982.SwitchAccountCubit>(
      () => _i982.SwitchAccountCubit(gh<_i1009.SwitchAccountUseCases>()),
    );
    gh.factory<_i3.UserProfileZapCubit>(
      () => _i3.UserProfileZapCubit(gh<_i644.SendProfileZapUseCase>()),
    );
    gh.factory<_i623.UserProfileCubit>(
      () => _i623.UserProfileCubit(
        gh<_i644.LoadUserProfileUseCase>(),
        gh<_i644.ToggleFollowUseCase>(),
        gh<_i854.CopyTextUseCase>(),
      ),
    );
    gh.lazySingleton<_i903.NotificationGate>(
      () => _i903.NotificationGate(
        gh<_i194.MessageRouterService>(),
        gh<_i904.MarmotSyncService>(),
        gh<_i377.ZapEarningsService>(),
        gh<_i551.LocalNotificationService>(),
        gh<_i1064.SyncServiceChannel>(),
        gh<_i409.ContactService>(),
        gh<_i603.IdentityLocalDataSource>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.factory<_i704.CreateCircleBookUseCase>(
      () => _i704.CreateCircleBookUseCase(
        gh<_i810.IngestionOrchestratorRepository>(),
      ),
    );
    gh.factory<_i704.DeleteBookFilesUseCase>(
      () => _i704.DeleteBookFilesUseCase(
        gh<_i810.IngestionOrchestratorRepository>(),
      ),
    );
    gh.factory<_i704.FinalizeAndUploadBookUseCase>(
      () => _i704.FinalizeAndUploadBookUseCase(
        gh<_i810.IngestionOrchestratorRepository>(),
      ),
    );
    gh.factory<_i145.ProfileCubit>(
      () => _i145.ProfileCubit(
        gh<_i385.LoadProfile>(),
        gh<_i223.UpdateProfile>(),
        gh<_i915.SignOut>(),
        gh<_i1055.ProfileSettingsUseCases>(),
      ),
    );
    gh.lazySingleton<_i265.HomeDashboardDataSource>(
      () => _i265.HomeDashboardDataSourceImpl(
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i837.ReadingStatsService>(),
        gh<_i516.CircleStoreService>(),
        gh<_i348.CircleProgressDao>(),
        gh<_i760.ZapSatsEarningsDao>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.lazySingleton<_i397.FriendsCubit>(
      () => _i397.FriendsCubit(
        gh<_i86.FriendsUseCases>(),
        gh<_i854.CopyTextUseCase>(),
      ),
    );
    gh.lazySingleton<_i203.CirclesRepository>(
      () => _i557.CirclesRepositoryImpl(
        gh<_i0.CirclesDataSource>(),
        gh<_i516.CircleStoreService>(),
      ),
    );
    gh.factory<_i737.BookIngestionRepository>(
      () => _i484.BookIngestionRepositoryImpl(
        gh<_i1049.FilePickerService>(),
        gh<_i516.CircleStoreService>(),
      ),
    );
    gh.lazySingleton<_i64.CheersDataSource>(
      () => _i64.CheersDataSourceImpl(
        gh<_i516.CircleStoreService>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i562.CheersDao>(),
        gh<_i409.ContactService>(),
        gh<_i327.ZapService>(),
        gh<_i954.ZapNudgeService>(),
        gh<_i295.NostrService>(),
        gh<_i78.ClipboardService>(),
        gh<_i210.ShareService>(),
      ),
    );
    gh.factory<_i1006.WatchCirclesUseCase>(
      () => _i1006.WatchCirclesUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.GetCircleMembersUseCase>(
      () => _i1006.GetCircleMembersUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.GetCircleBookUseCase>(
      () => _i1006.GetCircleBookUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.RemoveCircleMemberUseCase>(
      () => _i1006.RemoveCircleMemberUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.ToggleContactUseCase>(
      () => _i1006.ToggleContactUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.LeaveCircleBookUseCase>(
      () => _i1006.LeaveCircleBookUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.DeleteCircleBookUseCase>(
      () => _i1006.DeleteCircleBookUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.WatchProgressByBookUseCase>(
      () => _i1006.WatchProgressByBookUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.GetMyNpubUseCase>(
      () => _i1006.GetMyNpubUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.SendCircleZapUseCase>(
      () => _i1006.SendCircleZapUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.ShareCircleBookUseCase>(
      () => _i1006.ShareCircleBookUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.GetFriendsUseCase>(
      () => _i1006.GetFriendsUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.GetExistingMemberNpubsUseCase>(
      () => _i1006.GetExistingMemberNpubsUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.PrepareCircleCoverUseCase>(
      () => _i1006.PrepareCircleCoverUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.UpdateCircleBookMetadataUseCase>(
      () =>
          _i1006.UpdateCircleBookMetadataUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.SetUploadingCoverUseCase>(
      () => _i1006.SetUploadingCoverUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.ClearUploadingCoverUseCase>(
      () => _i1006.ClearUploadingCoverUseCase(gh<_i203.CirclesRepository>()),
    );
    gh.factory<_i1006.UpdateCircleBookCoverOptimisticUseCase>(
      () => _i1006.UpdateCircleBookCoverOptimisticUseCase(
        gh<_i203.CirclesRepository>(),
      ),
    );
    gh.lazySingleton<_i516.LibraryRepository>(
      () => _i894.LibraryRepositoryImpl(gh<_i516.CircleStoreService>()),
    );
    gh.lazySingleton<_i326.HomeDashboardRepository>(
      () => _i139.HomeDashboardRepositoryImpl(
        gh<_i265.HomeDashboardDataSource>(),
      ),
    );
    gh.factory<_i492.ReaderZapCubit>(
      () => _i492.ReaderZapCubit(gh<_i1006.SendCircleZapUseCase>()),
    );
    gh.factory<_i812.DeleteCircleBook>(
      () => _i812.DeleteCircleBook(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i16.WatchLastOpenedLibraryBook>(
      () => _i16.WatchLastOpenedLibraryBook(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i1024.WatchCircleBooks>(
      () => _i1024.WatchCircleBooks(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i688.CircleMembersCubit>(
      () => _i688.CircleMembersCubit(
        gh<_i1006.GetMyNpubUseCase>(),
        gh<_i1006.GetCircleMembersUseCase>(),
        gh<_i1006.ToggleContactUseCase>(),
      ),
    );
    gh.factory<_i20.PickBookFileUseCase>(
      () => _i20.PickBookFileUseCase(gh<_i737.BookIngestionRepository>()),
    );
    gh.factory<_i20.PickCoverImageUseCase>(
      () => _i20.PickCoverImageUseCase(gh<_i737.BookIngestionRepository>()),
    );
    gh.factory<_i20.FindExistingBookUseCase>(
      () => _i20.FindExistingBookUseCase(gh<_i737.BookIngestionRepository>()),
    );
    gh.lazySingleton<_i1043.IngestionOrchestratorCubit>(
      () => _i1043.IngestionOrchestratorCubit(
        gh<_i379.BookIngestionRepository>(),
        gh<_i704.CreateCircleBookUseCase>(),
        gh<_i704.DeleteBookFilesUseCase>(),
        gh<_i704.FinalizeAndUploadBookUseCase>(),
      ),
    );
    gh.lazySingleton<_i314.CheersRepository>(
      () => _i489.CheersRepositoryImpl(gh<_i64.CheersDataSource>()),
    );
    gh.factory<_i41.CircleOperationsCubit>(
      () => _i41.CircleOperationsCubit(
        gh<_i1006.GetMyNpubUseCase>(),
        gh<_i1006.DeleteCircleBookUseCase>(),
        gh<_i1006.LeaveCircleBookUseCase>(),
        gh<_i1006.PrepareCircleCoverUseCase>(),
        gh<_i1006.UpdateCircleBookMetadataUseCase>(),
        gh<_i1006.SetUploadingCoverUseCase>(),
        gh<_i1006.ClearUploadingCoverUseCase>(),
        gh<_i1006.UpdateCircleBookCoverOptimisticUseCase>(),
      ),
    );
    gh.factory<_i620.ShareCircleCubit>(
      () => _i620.ShareCircleCubit(
        gh<_i1006.GetFriendsUseCase>(),
        gh<_i1006.GetCircleBookUseCase>(),
        gh<_i1006.GetExistingMemberNpubsUseCase>(),
        gh<_i1006.ShareCircleBookUseCase>(),
        gh<_i1006.GetMyNpubUseCase>(),
      ),
    );
    gh.factory<_i947.CircleDetailCubit>(
      () => _i947.CircleDetailCubit(
        gh<_i1006.GetCircleBookUseCase>(),
        gh<_i1006.GetMyNpubUseCase>(),
        gh<_i1006.GetCircleMembersUseCase>(),
        gh<_i1006.WatchProgressByBookUseCase>(),
        gh<_i1006.RemoveCircleMemberUseCase>(),
        gh<_i1006.ToggleContactUseCase>(),
        gh<_i1006.LeaveCircleBookUseCase>(),
        gh<_i1006.DeleteCircleBookUseCase>(),
      ),
    );
    gh.factoryParam<
      _i405.BookWizardCubit,
      _i687.Completer<_i230.WizardData>,
      _i230.WizardInitialData?
    >(
      (_completer, initialData) => _i405.BookWizardCubit(
        _completer,
        initialData,
        gh<_i20.PickCoverImageUseCase>(),
      ),
    );
    gh.factory<_i761.CirclesCubit>(
      () => _i761.CirclesCubit(gh<_i1006.WatchCirclesUseCase>()),
    );
    gh.factory<_i107.LibraryCubit>(
      () => _i107.LibraryCubit(
        gh<_i1024.WatchCircleBooks>(),
        gh<_i16.WatchLastOpenedLibraryBook>(),
        gh<_i741.EnsureBookSearchable>(),
      ),
    );
    gh.factory<_i899.TouchDashboardBookOpened>(
      () => _i899.TouchDashboardBookOpened(gh<_i326.HomeDashboardRepository>()),
    );
    gh.factory<_i1021.WatchHomeDashboard>(
      () => _i1021.WatchHomeDashboard(gh<_i326.HomeDashboardRepository>()),
    );
    gh.factory<_i362.ReadingProgressCubit>(
      () => _i362.ReadingProgressCubit(
        gh<_i571.SaveReadingSnapshotUseCase>(),
        gh<_i571.LoadReadingSnapshotUseCase>(),
        gh<_i571.ReportReadingProgressUseCase>(),
        gh<_i35.WatchMyReadingProgressUseCase>(),
        gh<_i899.TouchDashboardBookOpened>(),
      ),
    );
    gh.factory<_i921.WatchCheersActivitiesUseCase>(
      () => _i921.WatchCheersActivitiesUseCase(gh<_i314.CheersRepository>()),
    );
    gh.factory<_i921.SendCheersZapUseCase>(
      () => _i921.SendCheersZapUseCase(gh<_i314.CheersRepository>()),
    );
    gh.factory<_i921.SendCheersNudgeUseCase>(
      () => _i921.SendCheersNudgeUseCase(gh<_i314.CheersRepository>()),
    );
    gh.factory<_i921.LookupLud16UseCase>(
      () => _i921.LookupLud16UseCase(gh<_i314.CheersRepository>()),
    );
    gh.factory<_i921.CopyCheersActivityTextUseCase>(
      () => _i921.CopyCheersActivityTextUseCase(gh<_i314.CheersRepository>()),
    );
    gh.factory<_i921.ShareCheersActivityTextUseCase>(
      () => _i921.ShareCheersActivityTextUseCase(gh<_i314.CheersRepository>()),
    );
    gh.factory<_i921.PostCheersNoteUseCase>(
      () => _i921.PostCheersNoteUseCase(gh<_i314.CheersRepository>()),
    );
    gh.factory<_i696.IngestionPageCubit>(
      () => _i696.IngestionPageCubit(
        gh<_i20.PickBookFileUseCase>(),
        gh<_i918.FileHasher>(),
        gh<_i20.FindExistingBookUseCase>(),
      ),
    );
    gh.factory<_i602.HomeCubit>(
      () => _i602.HomeCubit(
        gh<_i1021.WatchHomeDashboard>(),
        gh<_i899.TouchDashboardBookOpened>(),
      ),
    );
    gh.factory<_i584.CheersCubit>(
      () => _i584.CheersCubit(
        gh<_i921.WatchCheersActivitiesUseCase>(),
        gh<_i921.SendCheersZapUseCase>(),
        gh<_i921.SendCheersNudgeUseCase>(),
        gh<_i921.LookupLud16UseCase>(),
        gh<_i921.CopyCheersActivityTextUseCase>(),
        gh<_i921.ShareCheersActivityTextUseCase>(),
        gh<_i921.PostCheersNoteUseCase>(),
        gh<_i912.CheersNoteComposer>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i200.RegisterModule {}

class _$MarmotModule extends _i817.MarmotModule {}

class _$NostrModule extends _i96.NostrModule {}

class _$IngestionModule extends _i627.IngestionModule {}
