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
import 'package:zapbook/core/data/app_database.dart' as _i708;
import 'package:zapbook/core/data/cache/nostr_cache_store.dart' as _i68;
import 'package:zapbook/core/data/dao/cheers_dao.dart' as _i826;
import 'package:zapbook/core/data/dao/page_dao.dart' as _i50;
import 'package:zapbook/core/data/datasources/genre_datasource.dart' as _i850;
import 'package:zapbook/core/data/datasources/onboarding_local_datasource.dart'
    as _i342;
import 'package:zapbook/core/data/documents_directory.dart' as _i240;
import 'package:zapbook/core/data/library_file_store.dart' as _i854;
import 'package:zapbook/core/data/search/book_search_index.dart' as _i525;
import 'package:zapbook/core/data/search/book_vector_index.dart' as _i491;
import 'package:zapbook/core/data/search/embedding_service.dart' as _i18;
import 'package:zapbook/core/di/marmot_module.dart' as _i817;
import 'package:zapbook/core/di/nostr_module.dart' as _i96;
import 'package:zapbook/core/di/register_module.dart' as _i200;
import 'package:zapbook/core/domain/book_ingestion_repository.dart' as _i379;
import 'package:zapbook/core/domain/ingest_book.dart' as _i696;
import 'package:zapbook/core/domain/pdf_chunk_extractor.dart' as _i970;
import 'package:zapbook/core/domain/pdf_page_rasterizer.dart' as _i283;
import 'package:zapbook/core/domain/usecases/delete_circle_book.dart' as _i812;
import 'package:zapbook/core/domain/wizard_data.dart' as _i230;
import 'package:zapbook/core/identity/identity_local_data_source.dart' as _i603;
import 'package:zapbook/core/identity/identity_repository.dart' as _i63;
import 'package:zapbook/core/identity/local_key_signer_source.dart' as _i429;
import 'package:zapbook/core/identity/marmot_identity_repository.dart' as _i538;
import 'package:zapbook/core/identity/nostr_session.dart' as _i1073;
import 'package:zapbook/core/identity/nostr_signer_source.dart' as _i148;
import 'package:zapbook/core/presentation/bloc/circle_operations/circle_operations_cubit.dart'
    as _i41;
import 'package:zapbook/core/presentation/bloc/earnings/earnings_cubit.dart'
    as _i362;
import 'package:zapbook/core/presentation/bloc/performance/performance_cubit.dart'
    as _i400;
import 'package:zapbook/core/router/app_router.dart' as _i571;
import 'package:zapbook/core/services/app_info_service.dart' as _i19;
import 'package:zapbook/core/services/blossom_service.dart' as _i873;
import 'package:zapbook/core/services/circle_store_service.dart' as _i821;
import 'package:zapbook/core/services/clipboard_service.dart' as _i1053;
import 'package:zapbook/core/services/contact_service.dart' as _i244;
import 'package:zapbook/core/services/decoded_message_cache.dart' as _i118;
import 'package:zapbook/core/services/density_service.dart' as _i740;
import 'package:zapbook/core/services/file_hasher.dart' as _i917;
import 'package:zapbook/core/services/file_picker_service.dart' as _i1034;
import 'package:zapbook/core/services/group_envelope_service.dart' as _i394;
import 'package:zapbook/core/services/group_store_service.dart' as _i40;
import 'package:zapbook/core/services/group_transfer_service.dart' as _i860;
import 'package:zapbook/core/services/key_package_service.dart' as _i397;
import 'package:zapbook/core/services/lnurl_service.dart' as _i96;
import 'package:zapbook/core/services/marmot_sync_service.dart' as _i140;
import 'package:zapbook/core/services/message_router_service.dart' as _i223;
import 'package:zapbook/core/services/milestone_service.dart' as _i31;
import 'package:zapbook/core/services/nostr_service.dart' as _i11;
import 'package:zapbook/core/services/nwc_service.dart' as _i507;
import 'package:zapbook/core/services/performance_service.dart' as _i39;
import 'package:zapbook/core/services/quiz_service.dart' as _i995;
import 'package:zapbook/core/services/reading_stats_service.dart' as _i182;
import 'package:zapbook/core/services/secure_storage_service.dart' as _i123;
import 'package:zapbook/core/services/welcome_inbox_service.dart' as _i82;
import 'package:zapbook/core/services/zap_confirmation_service.dart' as _i140;
import 'package:zapbook/core/services/zap_earnings_service.dart' as _i240;
import 'package:zapbook/core/services/zap_nudge_service.dart' as _i718;
import 'package:zapbook/core/services/zap_service.dart' as _i362;
import 'package:zapbook/core/services/zap_support_service.dart' as _i582;
import 'package:zapbook/core/session/session_reloader.dart' as _i803;
import 'package:zapbook/core/theme/theme_cubit.dart' as _i465;
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
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_orchestrator_cubit.dart'
    as _i1043;
import 'package:zapbook/features/book_reader/data/quiz_repository.dart'
    as _i246;
import 'package:zapbook/features/book_reader/data/reading_progress_repository.dart'
    as _i898;
import 'package:zapbook/features/book_reader/data/recognition_quiz_builder.dart'
    as _i974;
import 'package:zapbook/features/book_reader/presentation/bloc/reader_settings/reader_settings_cubit.dart'
    as _i58;
import 'package:zapbook/features/cheers/data/datasources/cheers_data_source.dart'
    as _i64;
import 'package:zapbook/features/cheers/data/repositories/cheers_repository_impl.dart'
    as _i489;
import 'package:zapbook/features/cheers/domain/repositories/cheers_repository.dart'
    as _i314;
import 'package:zapbook/features/cheers/domain/usecases/load_more_cheers_activities.dart'
    as _i73;
import 'package:zapbook/features/cheers/domain/usecases/send_cheers_zap.dart'
    as _i636;
import 'package:zapbook/features/cheers/domain/usecases/watch_cheers_activities.dart'
    as _i654;
import 'package:zapbook/features/cheers/presentation/bloc/cheers_cubit.dart'
    as _i584;
import 'package:zapbook/features/circles/presentation/bloc/circle_detail_cubit.dart'
    as _i947;
import 'package:zapbook/features/circles/presentation/bloc/circle_members_cubit.dart'
    as _i688;
import 'package:zapbook/features/circles/presentation/bloc/circles_cubit.dart'
    as _i761;
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
import 'package:zapbook/features/library/data/repositories/marmot_library_repository.dart'
    as _i894;
import 'package:zapbook/features/library/domain/repositories/library_repository.dart'
    as _i516;
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
import 'package:zapbook/features/profile/data/datasources/profile_remote_datasource.dart'
    as _i735;
import 'package:zapbook/features/profile/data/repositories/profile_repository_impl.dart'
    as _i160;
import 'package:zapbook/features/profile/domain/repositories/profile_repository.dart'
    as _i582;
import 'package:zapbook/features/profile/domain/usecases/load_profile.dart'
    as _i385;
import 'package:zapbook/features/profile/domain/usecases/sign_out.dart'
    as _i915;
import 'package:zapbook/features/profile/domain/usecases/update_profile.dart'
    as _i223;
import 'package:zapbook/features/profile/presentation/bloc/donate_cubit.dart'
    as _i469;
import 'package:zapbook/features/profile/presentation/bloc/friends_cubit.dart'
    as _i397;
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart'
    as _i145;
import 'package:zapbook/features/profile/presentation/bloc/switch_account_cubit.dart'
    as _i982;
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
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.factory<_i620.ShareCircleCubit>(() => _i620.ShareCircleCubit());
    gh.factory<_i385.BookTextSearchCubit>(() => _i385.BookTextSearchCubit());
    gh.singleton<_i708.AppDatabase>(() => _i708.AppDatabase());
    await gh.singletonAsync<_i19.AppInfoService>(
      () => registerModule.appInfoService(),
      preResolve: true,
    );
    gh.lazySingleton<_i850.GenreDataSource>(() => _i850.GenreDataSource());
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
    gh.lazySingleton<_i571.AppRouter>(() => _i571.AppRouter());
    gh.lazySingleton<_i1053.ClipboardService>(() => _i1053.ClipboardService());
    gh.lazySingleton<_i118.DecodedMessageCache>(
      () => _i118.DecodedMessageCache(),
    );
    gh.lazySingleton<_i740.DensityService>(() => _i740.DensityService());
    gh.lazySingleton<_i917.FileHasher>(() => const _i917.FileHasher());
    gh.lazySingleton<_i1034.FilePickerService>(
      () => _i1034.FilePickerService(),
    );
    gh.lazySingleton<_i96.LnurlService>(
      () => _i96.LnurlService(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i995.QuizService>(() => _i995.QuizService());
    gh.lazySingleton<_i123.SecureStorageService>(
      () => _i123.SecureStorageService(),
    );
    gh.lazySingleton<_i201.CoverGenerator>(
      () => ingestionModule.coverGenerator(),
    );
    gh.lazySingleton<_i1.ZbfWriter>(() => ingestionModule.zbfWriter());
    gh.lazySingleton<_i1.ZbfReader>(() => ingestionModule.zbfReader());
    gh.lazySingleton<_i539.HeadsUpCubit>(() => _i539.HeadsUpCubit());
    gh.lazySingleton<_i803.SessionReloader>(
      () => const _i803.SessionManagerReloader(),
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
    gh.lazySingleton<_i603.IdentityLocalDataSource>(
      () => _i603.IdentityLocalDataSource(gh<_i123.SecureStorageService>()),
    );
    gh.singleton<_i39.PerformanceService>(
      () => _i39.PerformanceService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i342.OnboardingLocalDataSource>(
      () => _i342.OnboardingLocalDataSource(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i582.ZapSupportService>(
      () => _i582.ZapSupportService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i465.ThemeCubit>(
      () => _i465.ThemeCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i58.ReaderSettingsCubit>(
      () => _i58.ReaderSettingsCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i400.PerformanceCubit>(
      () => _i400.PerformanceCubit(gh<_i39.PerformanceService>()),
    );
    gh.lazySingleton<_i397.KeyPackageService>(
      () => _i397.KeyPackageService(
        gh<_i970.Marmot>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i857.Ndk>(),
      ),
    );
    gh.lazySingleton<_i246.QuizRepository>(
      () => _i246.QuizRepository(gh<_i857.Ndk>(), gh<_i68.NostrCacheStore>()),
    );
    gh.lazySingleton<_i898.ReadingProgressRepository>(
      () => _i898.ReadingProgressRepository(
        gh<_i857.Ndk>(),
        gh<_i68.NostrCacheStore>(),
      ),
    );
    gh.lazySingleton<_i31.MilestoneService>(
      () => _i31.MilestoneService(
        gh<_i970.Marmot>(),
        gh<_i857.Ndk>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i118.DecodedMessageCache>(),
      ),
    );
    gh.lazySingleton<_i718.ZapNudgeService>(
      () => _i718.ZapNudgeService(
        gh<_i970.Marmot>(),
        gh<_i857.Ndk>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i118.DecodedMessageCache>(),
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
        gh<_i1034.FilePickerService>(),
      ),
    );
    gh.lazySingleton<_i148.NostrSignerSource>(
      () => _i429.LocalKeySignerSource(gh<_i603.IdentityLocalDataSource>()),
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
    gh.lazySingleton<_i826.CheersDao>(
      () => _i826.CheersDao(gh<_i708.AppDatabase>()),
    );
    gh.lazySingleton<_i50.PageDao>(() => _i50.PageDao(gh<_i708.AppDatabase>()));
    gh.lazySingleton<_i507.NwcService>(
      () => _i507.NwcService(
        gh<_i460.SharedPreferences>(),
        gh<_i857.Ndk>(),
        gh<_i123.SecureStorageService>(),
      ),
    );
    gh.lazySingleton<_i873.BlossomService>(
      () => _i873.BlossomService(gh<_i857.Ndk>()),
    );
    gh.lazySingleton<_i394.GroupEnvelopeService>(
      () => _i394.GroupEnvelopeService(gh<_i857.Ndk>()),
    );
    gh.lazySingleton<_i240.ZapEarningsService>(
      () => _i240.ZapEarningsService(gh<_i857.Ndk>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i63.IdentityRepository>(
      () => _i538.MarmotIdentityRepository(gh<_i603.IdentityLocalDataSource>()),
    );
    gh.factory<_i709.GenerateIdentity>(
      () => _i709.GenerateIdentity(gh<_i63.IdentityRepository>()),
    );
    gh.factory<_i136.ImportIdentity>(
      () => _i136.ImportIdentity(gh<_i63.IdentityRepository>()),
    );
    gh.lazySingleton<_i82.WelcomeInboxService>(
      () => _i82.WelcomeInboxService(
        gh<_i970.Marmot>(),
        gh<_i857.Ndk>(),
        gh<_i603.IdentityLocalDataSource>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i974.RecognitionQuizBuilder>(
      () => _i974.RecognitionQuizBuilder(gh<_i491.BookVectorIndex>()),
    );
    gh.lazySingleton<_i860.GroupTransferService>(
      () => _i860.GroupTransferService(
        gh<_i970.Marmot>(),
        gh<_i873.BlossomService>(),
        gh<_i854.LibraryFileStore>(),
        gh<_i394.GroupEnvelopeService>(),
      ),
    );
    gh.lazySingleton<_i182.ReadingStatsService>(
      () => _i182.ReadingStatsService(
        gh<_i857.Ndk>(),
        gh<_i68.NostrCacheStore>(),
        gh<_i31.MilestoneService>(),
        gh<_i240.ZapEarningsService>(),
      ),
    );
    gh.lazySingleton<_i11.NostrService>(
      () => _i11.NostrService(gh<_i857.Ndk>(), gh<_i68.NostrCacheStore>()),
    );
    gh.lazySingleton<_i362.ZapService>(
      () => _i362.ZapService(
        gh<_i96.LnurlService>(),
        gh<_i857.Ndk>(),
        gh<_i507.NwcService>(),
        gh<_i582.ZapSupportService>(),
      ),
    );
    gh.factory<_i362.EarningsCubit>(
      () => _i362.EarningsCubit(gh<_i240.ZapEarningsService>()),
    );
    gh.lazySingleton<_i377.OnboardingRepository>(
      () =>
          _i444.OnboardingRepositoryImpl(gh<_i342.OnboardingLocalDataSource>()),
    );
    gh.lazySingleton<_i140.MarmotSyncService>(
      () => _i140.MarmotSyncService(
        gh<_i970.Marmot>(),
        gh<_i857.Ndk>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i397.KeyPackageService>(),
      ),
    );
    gh.lazySingleton<_i244.ContactService>(
      () => _i244.ContactService(
        gh<_i460.SharedPreferences>(),
        gh<_i11.NostrService>(),
        gh<_i603.IdentityLocalDataSource>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.factory<_i397.FriendsCubit>(
      () => _i397.FriendsCubit(gh<_i244.ContactService>()),
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
    gh.factory<_i688.CircleMembersCubit>(
      () => _i688.CircleMembersCubit(
        gh<_i970.Marmot>(),
        gh<_i244.ContactService>(),
        gh<_i603.IdentityLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i735.ProfileRemoteDataSource>(
      () => _i735.ProfileRemoteDataSource(gh<_i11.NostrService>()),
    );
    gh.lazySingleton<_i1073.NostrSession>(
      () => _i1073.NostrSession(
        gh<_i857.Ndk>(),
        gh<_i148.NostrSignerSource>(),
        gh<_i11.NostrService>(),
        gh<_i140.MarmotSyncService>(),
      ),
    );
    gh.factory<_i469.DonateCubit>(
      () => _i469.DonateCubit(gh<_i362.ZapService>()),
    );
    gh.lazySingleton<_i582.ProfileRepository>(
      () => _i160.ProfileRepositoryImpl(
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i735.ProfileRemoteDataSource>(),
        gh<_i342.OnboardingLocalDataSource>(),
        gh<_i1073.NostrSession>(),
        gh<_i182.ReadingStatsService>(),
        gh<_i803.SessionReloader>(),
        gh<_i118.DecodedMessageCache>(),
      ),
    );
    gh.lazySingleton<_i64.CheersDataSource>(
      () => _i64.CheersDataSourceImpl(
        gh<_i970.Marmot>(),
        gh<_i857.Ndk>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i31.MilestoneService>(),
        gh<_i244.ContactService>(),
        gh<_i118.DecodedMessageCache>(),
        gh<_i140.MarmotSyncService>(),
        gh<_i826.CheersDao>(),
      ),
    );
    gh.factory<_i696.IngestBook>(
      () => _i696.IngestBook(gh<_i379.BookIngestionRepository>()),
    );
    gh.lazySingleton<_i314.CheersRepository>(
      () => _i489.CheersRepositoryImpl(gh<_i64.CheersDataSource>()),
    );
    gh.lazySingleton<_i223.MessageRouterService>(
      () => _i223.MessageRouterService(gh<_i140.MarmotSyncService>()),
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
    gh.lazySingleton<_i40.GroupStoreService>(
      () => _i40.GroupStoreService(
        gh<_i140.MarmotSyncService>(),
        gh<_i970.Marmot>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i873.BlossomService>(),
        gh<_i394.GroupEnvelopeService>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.factory<_i982.SwitchAccountCubit>(
      () => _i982.SwitchAccountCubit(
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i63.IdentityRepository>(),
        gh<_i735.ProfileRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i821.CircleStoreService>(
      () => _i821.CircleStoreService(
        gh<_i40.GroupStoreService>(),
        gh<_i854.LibraryFileStore>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i1043.IngestionOrchestratorCubit>(
      () => _i1043.IngestionOrchestratorCubit(
        gh<_i379.BookIngestionRepository>(),
        gh<_i821.CircleStoreService>(),
        gh<_i860.GroupTransferService>(),
        gh<_i854.LibraryFileStore>(),
      ),
    );
    gh.lazySingleton<_i265.HomeDashboardDataSource>(
      () => _i265.HomeDashboardDataSourceImpl(
        gh<_i970.Marmot>(),
        gh<_i857.Ndk>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i182.ReadingStatsService>(),
        gh<_i821.CircleStoreService>(),
      ),
    );
    gh.lazySingleton<_i326.HomeDashboardRepository>(
      () => _i139.HomeDashboardRepositoryImpl(
        gh<_i265.HomeDashboardDataSource>(),
      ),
    );
    gh.lazySingleton<_i140.ZapConfirmationService>(
      () => _i140.ZapConfirmationService(
        gh<_i460.SharedPreferences>(),
        gh<_i857.Ndk>(),
        gh<_i64.CheersDataSource>(),
      ),
    );
    gh.factory<_i696.IngestionPageCubit>(
      () => _i696.IngestionPageCubit(
        gh<_i1034.FilePickerService>(),
        gh<_i917.FileHasher>(),
        gh<_i821.CircleStoreService>(),
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
    gh.factory<_i73.LoadMoreCheersActivities>(
      () => _i73.LoadMoreCheersActivities(gh<_i314.CheersRepository>()),
    );
    gh.factory<_i636.SendCheersZap>(
      () => _i636.SendCheersZap(gh<_i314.CheersRepository>()),
    );
    gh.factory<_i654.WatchCheersActivities>(
      () => _i654.WatchCheersActivities(gh<_i314.CheersRepository>()),
    );
    gh.factory<_i761.CirclesCubit>(
      () => _i761.CirclesCubit(gh<_i821.CircleStoreService>()),
    );
    gh.lazySingleton<_i516.LibraryRepository>(
      () => _i894.LibraryRepositoryImpl(gh<_i821.CircleStoreService>()),
    );
    gh.factory<_i145.ProfileCubit>(
      () => _i145.ProfileCubit(
        gh<_i385.LoadProfile>(),
        gh<_i223.UpdateProfile>(),
        gh<_i915.SignOut>(),
        gh<_i1053.ClipboardService>(),
        gh<_i507.NwcService>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i1034.FilePickerService>(),
        gh<_i397.KeyPackageService>(),
        gh<_i19.AppInfoService>(),
        gh<_i582.ZapSupportService>(),
      ),
    );
    gh.factory<_i584.CheersCubit>(
      () => _i584.CheersCubit(
        gh<_i654.WatchCheersActivities>(),
        gh<_i636.SendCheersZap>(),
        gh<_i73.LoadMoreCheersActivities>(),
        gh<_i362.ZapService>(),
        gh<_i718.ZapNudgeService>(),
        gh<_i11.NostrService>(),
        gh<_i507.NwcService>(),
        gh<_i140.ZapConfirmationService>(),
      ),
    );
    gh.factory<_i899.TouchDashboardBookOpened>(
      () => _i899.TouchDashboardBookOpened(gh<_i326.HomeDashboardRepository>()),
    );
    gh.factory<_i1021.WatchHomeDashboard>(
      () => _i1021.WatchHomeDashboard(gh<_i326.HomeDashboardRepository>()),
    );
    gh.factory<_i947.CircleDetailCubit>(
      () => _i947.CircleDetailCubit(gh<_i516.LibraryRepository>()),
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
    gh.factory<_i41.CircleOperationsCubit>(
      () => _i41.CircleOperationsCubit(
        gh<_i812.DeleteCircleBook>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i821.CircleStoreService>(),
      ),
    );
    gh.factory<_i602.HomeCubit>(
      () => _i602.HomeCubit(
        gh<_i1021.WatchHomeDashboard>(),
        gh<_i899.TouchDashboardBookOpened>(),
      ),
    );
    gh.factory<_i107.LibraryCubit>(
      () => _i107.LibraryCubit(
        gh<_i1024.WatchCircleBooks>(),
        gh<_i16.WatchLastOpenedLibraryBook>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i200.RegisterModule {}

class _$MarmotModule extends _i817.MarmotModule {}

class _$NostrModule extends _i96.NostrModule {}

class _$IngestionModule extends _i627.IngestionModule {}
