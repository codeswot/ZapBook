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
import 'package:zapbook/core/cubit/ai_model_cubit.dart' as _i421;
import 'package:zapbook/core/data/cache/nostr_cache_store.dart' as _i68;
import 'package:zapbook/core/data/datasources/genre_datasource.dart' as _i850;
import 'package:zapbook/core/data/datasources/onboarding_local_datasource.dart'
    as _i342;
import 'package:zapbook/core/data/documents_directory.dart' as _i240;
import 'package:zapbook/core/data/library_file_store.dart' as _i854;
import 'package:zapbook/core/di/marmot_module.dart' as _i817;
import 'package:zapbook/core/di/nostr_module.dart' as _i96;
import 'package:zapbook/core/di/register_module.dart' as _i200;
import 'package:zapbook/core/domain/book_ingestion_repository.dart' as _i379;
import 'package:zapbook/core/domain/ingest_book.dart' as _i696;
import 'package:zapbook/core/domain/pdf_chunk_extractor.dart' as _i970;
import 'package:zapbook/core/domain/pdf_page_rasterizer.dart' as _i283;
import 'package:zapbook/core/domain/wizard_data.dart' as _i230;
import 'package:zapbook/core/identity/identity_local_data_source.dart' as _i603;
import 'package:zapbook/core/identity/identity_repository.dart' as _i63;
import 'package:zapbook/core/identity/local_key_signer_source.dart' as _i429;
import 'package:zapbook/core/identity/marmot_identity_repository.dart' as _i538;
import 'package:zapbook/core/identity/nostr_session.dart' as _i1073;
import 'package:zapbook/core/identity/nostr_signer_source.dart' as _i148;
import 'package:zapbook/core/router/app_router.dart' as _i571;
import 'package:zapbook/core/services/ai_service.dart' as _i1012;
import 'package:zapbook/core/services/blossom_service.dart' as _i873;
import 'package:zapbook/core/services/clipboard_service.dart' as _i1053;
import 'package:zapbook/core/services/contact_service.dart' as _i244;
import 'package:zapbook/core/services/density_service.dart' as _i740;
import 'package:zapbook/core/services/device_capability_service.dart' as _i447;
import 'package:zapbook/core/services/file_hasher.dart' as _i917;
import 'package:zapbook/core/services/file_picker_service.dart' as _i1034;
import 'package:zapbook/core/services/key_package_service.dart' as _i397;
import 'package:zapbook/core/services/lnurl_service.dart' as _i96;
import 'package:zapbook/core/services/marmot_sync_service.dart' as _i140;
import 'package:zapbook/core/services/milestone_service.dart' as _i31;
import 'package:zapbook/core/services/nostr_service.dart' as _i11;
import 'package:zapbook/core/services/nwc_service.dart' as _i507;
import 'package:zapbook/core/services/quiz_service.dart' as _i995;
import 'package:zapbook/core/services/reading_stats_service.dart' as _i182;
import 'package:zapbook/core/services/secure_storage_service.dart' as _i123;
import 'package:zapbook/core/services/welcome_inbox_service.dart' as _i82;
import 'package:zapbook/core/services/zap_service.dart' as _i362;
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
import 'package:zapbook/features/book_reader/data/reading_progress_repository.dart'
    as _i898;
import 'package:zapbook/features/book_reader/presentation/bloc/reader_settings/reader_settings_cubit.dart'
    as _i58;
import 'package:zapbook/features/cheers/data/datasources/cheers_data_source.dart'
    as _i64;
import 'package:zapbook/features/cheers/data/repositories/cheers_repository_impl.dart'
    as _i489;
import 'package:zapbook/features/cheers/domain/repositories/cheers_repository.dart'
    as _i314;
import 'package:zapbook/features/cheers/domain/usecases/send_cheers_zap.dart'
    as _i636;
import 'package:zapbook/features/cheers/domain/usecases/watch_cheers_activities.dart'
    as _i654;
import 'package:zapbook/features/cheers/presentation/bloc/cheers_cubit.dart'
    as _i584;
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
import 'package:zapbook/features/library/data/marmot/book_group_datasource.dart'
    as _i398;
import 'package:zapbook/features/library/data/marmot/progressive_book_opener.dart'
    as _i1063;
import 'package:zapbook/features/library/data/repositories/marmot_library_repository.dart'
    as _i894;
import 'package:zapbook/features/library/domain/entities/library_book.dart'
    as _i297;
import 'package:zapbook/features/library/domain/repositories/library_repository.dart'
    as _i516;
import 'package:zapbook/features/library/domain/usecases/add_book_to_library.dart'
    as _i1071;
import 'package:zapbook/features/library/domain/usecases/backfill_library.dart'
    as _i887;
import 'package:zapbook/features/library/domain/usecases/delete_library_book.dart'
    as _i1038;
import 'package:zapbook/features/library/domain/usecases/dissolve_circle.dart'
    as _i210;
import 'package:zapbook/features/library/domain/usecases/find_book_by_content_hash.dart'
    as _i190;
import 'package:zapbook/features/library/domain/usecases/get_book_members.dart'
    as _i1000;
import 'package:zapbook/features/library/domain/usecases/get_circle_admins.dart'
    as _i428;
import 'package:zapbook/features/library/domain/usecases/get_library_book.dart'
    as _i807;
import 'package:zapbook/features/library/domain/usecases/leave_circle.dart'
    as _i1056;
import 'package:zapbook/features/library/domain/usecases/remove_book_member.dart'
    as _i310;
import 'package:zapbook/features/library/domain/usecases/share_book.dart'
    as _i555;
import 'package:zapbook/features/library/domain/usecases/share_book_with.dart'
    as _i286;
import 'package:zapbook/features/library/domain/usecases/sync_welcomes.dart'
    as _i626;
import 'package:zapbook/features/library/domain/usecases/touch_book_opened.dart'
    as _i296;
import 'package:zapbook/features/library/domain/usecases/update_book_metadata.dart'
    as _i96;
import 'package:zapbook/features/library/domain/usecases/watch_circles.dart'
    as _i96;
import 'package:zapbook/features/library/domain/usecases/watch_library_books.dart'
    as _i1024;
import 'package:zapbook/features/library/presentation/bloc/book_edit_cubit.dart'
    as _i404;
import 'package:zapbook/features/library/presentation/bloc/circle_detail_cubit.dart'
    as _i458;
import 'package:zapbook/features/library/presentation/bloc/circle_members_cubit.dart'
    as _i906;
import 'package:zapbook/features/library/presentation/bloc/circles_cubit.dart'
    as _i668;
import 'package:zapbook/features/library/presentation/bloc/ingestion_queue_cubit.dart'
    as _i327;
import 'package:zapbook/features/library/presentation/bloc/library_cubit.dart'
    as _i107;
import 'package:zapbook/features/library/presentation/bloc/page/ingestion_page_cubit.dart'
    as _i696;
import 'package:zapbook/features/library/presentation/bloc/share_circle_cubit.dart'
    as _i659;
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
    gh.lazySingleton<_i850.GenreDataSource>(() => _i850.GenreDataSource());
    gh.lazySingleton<_i854.LibraryFileStore>(() => _i854.LibraryFileStore());
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
    gh.lazySingleton<_i740.DensityService>(() => _i740.DensityService());
    gh.lazySingleton<_i917.FileHasher>(() => const _i917.FileHasher());
    gh.lazySingleton<_i1034.FilePickerService>(
      () => _i1034.FilePickerService(),
    );
    gh.lazySingleton<_i96.LnurlService>(() => const _i96.LnurlService());
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
    gh.lazySingleton<_i447.DeviceCapabilityService>(
      () => _i447.DeviceCapabilityServiceImpl(),
    );
    gh.factoryParam<
      _i405.BookWizardCubit,
      _i687.Completer<_i230.WizardData>,
      String?
    >(
      (_completer, initialTitle) => _i405.BookWizardCubit(
        gh<_i1034.FilePickerService>(),
        gh<_i850.GenreDataSource>(),
        _completer,
        initialTitle,
      ),
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
    gh.lazySingleton<_i1012.AiService>(
      () => _i1012.AiServiceImpl(
        gh<_i460.SharedPreferences>(),
        gh<_i447.DeviceCapabilityService>(),
      ),
    );
    gh.lazySingleton<_i342.OnboardingLocalDataSource>(
      () => _i342.OnboardingLocalDataSource(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i465.ThemeCubit>(
      () => _i465.ThemeCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i58.ReaderSettingsCubit>(
      () => _i58.ReaderSettingsCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i362.ZapService>(
      () => _i362.ZapService(gh<_i96.LnurlService>(), gh<_i857.Ndk>()),
    );
    gh.lazySingleton<_i397.KeyPackageService>(
      () => _i397.KeyPackageService(
        gh<_i970.Marmot>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i857.Ndk>(),
      ),
    );
    gh.lazySingleton<_i898.ReadingProgressRepository>(
      () => _i898.ReadingProgressRepository(
        gh<_i857.Ndk>(),
        gh<_i68.NostrCacheStore>(),
      ),
    );
    gh.lazySingleton<_i507.NwcService>(
      () => _i507.NwcService(gh<_i460.SharedPreferences>(), gh<_i857.Ndk>()),
    );
    gh.factory<_i696.IngestionPageCubit>(
      () => _i696.IngestionPageCubit(gh<_i1034.FilePickerService>()),
    );
    gh.lazySingleton<_i64.CheersDataSource>(
      () => _i64.CheersDataSourceImpl(
        gh<_i970.Marmot>(),
        gh<_i857.Ndk>(),
        gh<_i603.IdentityLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i148.NostrSignerSource>(
      () => _i429.LocalKeySignerSource(gh<_i603.IdentityLocalDataSource>()),
    );
    gh.lazySingleton<_i970.PdfChunkExtractor>(
      () => ingestionModule.pdfChunkExtractor(gh<_i201.CoverGenerator>()),
    );
    gh.lazySingleton<List<_i751.BookExtractor>>(
      () => ingestionModule.bookExtractors(gh<_i201.CoverGenerator>()),
    );
    gh.lazySingleton<_i379.BookIngestionRepository>(
      () => _i785.BookIngestionRepositoryImpl(
        extractors: gh<List<_i751.BookExtractor>>(),
        fileStore: gh<_i854.LibraryFileStore>(),
        writer: gh<_i1.ZbfWriter>(),
      ),
    );
    gh.lazySingleton<_i873.BlossomService>(
      () => _i873.BlossomService(gh<_i857.Ndk>()),
    );
    gh.lazySingleton<_i11.NostrService>(
      () => _i11.NostrService(gh<_i857.Ndk>()),
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
    gh.lazySingleton<_i31.MilestoneService>(
      () => _i31.MilestoneService(
        gh<_i970.Marmot>(),
        gh<_i857.Ndk>(),
        gh<_i603.IdentityLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i82.WelcomeInboxService>(
      () => _i82.WelcomeInboxService(
        gh<_i970.Marmot>(),
        gh<_i857.Ndk>(),
        gh<_i603.IdentityLocalDataSource>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.factory<_i469.DonateCubit>(
      () => _i469.DonateCubit(gh<_i362.ZapService>()),
    );
    gh.factory<_i696.IngestBook>(
      () => _i696.IngestBook(gh<_i379.BookIngestionRepository>()),
    );
    gh.lazySingleton<_i314.CheersRepository>(
      () => _i489.CheersRepositoryImpl(gh<_i64.CheersDataSource>()),
    );
    gh.factory<_i626.SyncWelcomes>(
      () => _i626.SyncWelcomes(gh<_i82.WelcomeInboxService>()),
    );
    gh.lazySingleton<_i398.BookGroupDatasource>(
      () => _i398.BookGroupDatasource(
        gh<_i970.Marmot>(),
        gh<_i873.BlossomService>(),
        gh<_i854.LibraryFileStore>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i857.Ndk>(),
        gh<_i397.KeyPackageService>(),
        gh<_i1.ZbfReader>(),
      ),
    );
    gh.lazySingleton<_i377.OnboardingRepository>(
      () =>
          _i444.OnboardingRepositoryImpl(gh<_i342.OnboardingLocalDataSource>()),
    );
    gh.lazySingleton<_i244.ContactService>(
      () => _i244.ContactService(
        gh<_i460.SharedPreferences>(),
        gh<_i11.NostrService>(),
        gh<_i603.IdentityLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i1063.ProgressiveBookOpener>(
      () => _i1063.ProgressiveBookOpener(gh<_i398.BookGroupDatasource>()),
    );
    gh.lazySingleton<_i421.AiModelCubit>(
      () => _i421.AiModelCubit(gh<_i1012.AiService>()),
    );
    gh.factory<_i397.FriendsCubit>(
      () => _i397.FriendsCubit(gh<_i244.ContactService>()),
    );
    gh.lazySingleton<_i182.ReadingStatsService>(
      () => _i182.ReadingStatsService(
        gh<_i857.Ndk>(),
        gh<_i68.NostrCacheStore>(),
        gh<_i31.MilestoneService>(),
      ),
    );
    gh.lazySingleton<_i735.ProfileRemoteDataSource>(
      () => _i735.ProfileRemoteDataSource(gh<_i11.NostrService>()),
    );
    gh.factory<_i636.SendCheersZap>(
      () => _i636.SendCheersZap(gh<_i314.CheersRepository>()),
    );
    gh.factory<_i654.WatchCheersActivities>(
      () => _i654.WatchCheersActivities(gh<_i314.CheersRepository>()),
    );
    gh.factory<_i584.CheersCubit>(
      () => _i584.CheersCubit(
        gh<_i654.WatchCheersActivities>(),
        gh<_i636.SendCheersZap>(),
      ),
    );
    gh.lazySingleton<_i516.LibraryRepository>(
      () => _i894.MarmotLibraryRepository(
        gh<_i398.BookGroupDatasource>(),
        gh<_i854.LibraryFileStore>(),
        gh<_i1.ZbfReader>(),
        gh<_i740.DensityService>(),
      ),
    );
    gh.lazySingleton<_i265.HomeDashboardDataSource>(
      () => _i265.HomeDashboardDataSourceImpl(
        gh<_i970.Marmot>(),
        gh<_i857.Ndk>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i854.LibraryFileStore>(),
        gh<_i182.ReadingStatsService>(),
        gh<_i31.MilestoneService>(),
      ),
    );
    gh.lazySingleton<_i326.HomeDashboardRepository>(
      () => _i139.HomeDashboardRepositoryImpl(
        gh<_i265.HomeDashboardDataSource>(),
      ),
    );
    gh.lazySingleton<_i140.MarmotSyncService>(
      () => _i140.MarmotSyncService(
        gh<_i970.Marmot>(),
        gh<_i857.Ndk>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i516.LibraryRepository>(),
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
    gh.factory<_i210.DissolveCircle>(
      () => _i210.DissolveCircle(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i190.FindBookByContentHash>(
      () => _i190.FindBookByContentHash(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i1000.GetBookMembers>(
      () => _i1000.GetBookMembers(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i428.GetCircleAdmins>(
      () => _i428.GetCircleAdmins(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i807.GetLibraryBook>(
      () => _i807.GetLibraryBook(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i1056.LeaveCircle>(
      () => _i1056.LeaveCircle(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i310.RemoveBookMember>(
      () => _i310.RemoveBookMember(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i555.ShareBook>(
      () => _i555.ShareBook(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i286.ShareBookWith>(
      () => _i286.ShareBookWith(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i296.TouchBookOpened>(
      () => _i296.TouchBookOpened(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i96.UpdateBookMetadata>(
      () => _i96.UpdateBookMetadata(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i96.WatchCircles>(
      () => _i96.WatchCircles(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i1024.WatchLibraryBooks>(
      () => _i1024.WatchLibraryBooks(gh<_i516.LibraryRepository>()),
    );
    gh.factory<_i107.LibraryCubit>(
      () => _i107.LibraryCubit(
        gh<_i1024.WatchLibraryBooks>(),
        gh<_i887.BackfillLibrary>(),
        gh<_i296.TouchBookOpened>(),
        gh<_i555.ShareBook>(),
        gh<_i1038.DeleteLibraryBook>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i398.BookGroupDatasource>(),
        gh<_i516.LibraryRepository>(),
        gh<_i244.ContactService>(),
        gh<_i82.WelcomeInboxService>(),
        gh<_i342.OnboardingLocalDataSource>(),
      ),
    );
    gh.factory<_i906.CircleMembersCubit>(
      () => _i906.CircleMembersCubit(
        gh<_i1000.GetBookMembers>(),
        gh<_i310.RemoveBookMember>(),
        gh<_i244.ContactService>(),
        gh<_i603.IdentityLocalDataSource>(),
      ),
    );
    gh.factory<_i668.CirclesCubit>(
      () => _i668.CirclesCubit(gh<_i96.WatchCircles>()),
    );
    gh.factory<_i659.ShareCircleCubit>(
      () => _i659.ShareCircleCubit(
        gh<_i244.ContactService>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i1000.GetBookMembers>(),
        gh<_i286.ShareBookWith>(),
      ),
    );
    gh.factory<_i458.CircleDetailCubit>(
      () => _i458.CircleDetailCubit(
        gh<_i807.GetLibraryBook>(),
        gh<_i1000.GetBookMembers>(),
        gh<_i428.GetCircleAdmins>(),
        gh<_i310.RemoveBookMember>(),
        gh<_i1056.LeaveCircle>(),
        gh<_i210.DissolveCircle>(),
        gh<_i296.TouchBookOpened>(),
        gh<_i244.ContactService>(),
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i31.MilestoneService>(),
      ),
    );
    gh.factory<_i327.IngestionQueueCubit>(
      () => _i327.IngestionQueueCubit(
        gh<_i696.IngestBook>(),
        gh<_i1071.AddBookToLibrary>(),
        gh<_i917.FileHasher>(),
        gh<_i190.FindBookByContentHash>(),
      ),
    );
    gh.factory<_i899.TouchDashboardBookOpened>(
      () => _i899.TouchDashboardBookOpened(gh<_i326.HomeDashboardRepository>()),
    );
    gh.factory<_i1021.WatchHomeDashboard>(
      () => _i1021.WatchHomeDashboard(gh<_i326.HomeDashboardRepository>()),
    );
    gh.lazySingleton<_i1073.NostrSession>(
      () => _i1073.NostrSession(
        gh<_i857.Ndk>(),
        gh<_i148.NostrSignerSource>(),
        gh<_i11.NostrService>(),
        gh<_i140.MarmotSyncService>(),
      ),
    );
    gh.factory<_i341.CompleteOnboarding>(
      () => _i341.CompleteOnboarding(
        gh<_i63.IdentityRepository>(),
        gh<_i377.OnboardingRepository>(),
        gh<_i1073.NostrSession>(),
      ),
    );
    gh.factoryParam<_i404.BookEditCubit, _i297.LibraryBook, dynamic>(
      (book, _) => _i404.BookEditCubit(
        gh<_i850.GenreDataSource>(),
        gh<_i1034.FilePickerService>(),
        gh<_i96.UpdateBookMetadata>(),
        book,
      ),
    );
    gh.lazySingleton<_i582.ProfileRepository>(
      () => _i160.ProfileRepositoryImpl(
        gh<_i603.IdentityLocalDataSource>(),
        gh<_i735.ProfileRemoteDataSource>(),
        gh<_i342.OnboardingLocalDataSource>(),
        gh<_i1073.NostrSession>(),
        gh<_i507.NwcService>(),
      ),
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
    gh.factory<_i602.HomeCubit>(
      () => _i602.HomeCubit(
        gh<_i1021.WatchHomeDashboard>(),
        gh<_i899.TouchDashboardBookOpened>(),
      ),
    );
    gh.factory<_i223.UpdateProfile>(
      () => _i223.UpdateProfile(
        gh<_i735.ProfileRemoteDataSource>(),
        gh<_i1073.NostrSession>(),
      ),
    );
    gh.factory<_i385.LoadProfile>(
      () => _i385.LoadProfile(gh<_i582.ProfileRepository>()),
    );
    gh.factory<_i915.SignOut>(
      () => _i915.SignOut(gh<_i582.ProfileRepository>()),
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
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i200.RegisterModule {}

class _$MarmotModule extends _i817.MarmotModule {}

class _$NostrModule extends _i96.NostrModule {}

class _$IngestionModule extends _i627.IngestionModule {}
