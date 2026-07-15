# ZapBook Clean Architecture Refactor Checklist

This file tracks the progress of our refactor to a strict Clean Architecture. The dependency flow we are aiming for is:
**Presentation (Cubit/Bloc)** → **Domain (UseCase)** → **Domain (Repository Interface)** ← **Data (Repository Impl)** → **Data (DataSource)** → **Infrastructure (Services/DB/Network)**.

**CRITICAL ARCHITECTURE RULE**: UseCases MUST ONLY depend on Repository Interfaces defined in the Domain layer. They must NEVER depend directly on DataSources, Services, or any implementation details. Do not inject `*Service` or `*DataSource` into a UseCase!

---

## 1. Core Layer (`lib/core/`)

- [x] `lib/core/config/` (AppConfig, Env)
- [x] `lib/core/constants/` (Colors, Strings)
- [x] `lib/core/data/`
  - [x] `database/` (AppDatabase, DAOs)
  - [x] `network/` (NetworkClient wrapper)
  - [x] `infrastructure/` (Low-level services: `NdkWrapper`, `ReadingStatsTracker`)
- [x] `lib/core/domain/`
  - [x] `entities/` (Shared entities like `AppMessage`, `UserProfile`)
  - [x] `exceptions/` (Custom app exceptions)
- [x] `lib/core/presentation/`
  - [x] `widgets/` (Shared UI components)
  - [x] `theme/` (App theme definitions)
  - [x] `router/` (GoRouter configurations)
- [x] `lib/core/di/` (GetIt Service Locator setup)
- [x] `lib/core/utils/` (Helper extensions and formatters)

## 2. Features Layer (`lib/features/`)

### Feature: Profile

- [x] **Domain**
  - [x] `entities/` (Profile specific entities)
  - [x] `repositories/` (`ProfileRepository` interface)
  - [x] `usecases/`
    - [x] `LoadUserProfileUseCase.dart`
    - [x] `UpdateUserProfileUseCase.dart`
    - [x] `SignOutUseCase.dart`
- [x] **Data**
  - [x] `datasources/`
    - [x] `ProfileLocalDataSource.dart` (reads from local DB)
    - [x] `ProfileRemoteDataSource.dart` (reads from Nostr)
  - [x] `repositories/` (`ProfileRepositoryImpl.dart`)
- [x] **Presentation**
  - [x] `bloc/` (`ProfileCubit.dart` - *Depends only on UseCases*)
  - [x] `pages/`
  - [x] `widgets/`

### Feature: Home (Dashboard)

- [x] **Domain**
  - [x] `entities/` (`DashboardData.dart`)
  - [x] `repositories/` (`HomeRepository` interface)
  - [x] `usecases/`
    - [x] `GetHomeDashboardDataUseCase.dart`
- [x] **Data**
  - [x] `datasources/` (`HomeLocalDataSource.dart`, `HomeRemoteDataSource.dart`)
  - [x] `repositories/` (`HomeRepositoryImpl.dart`)
- [x] **Presentation**
  - [x] `bloc/` (`HomeCubit.dart` - *Depends only on UseCases*)
  - [x] `pages/`
  - [x] `widgets/`

### Feature: Circles

- [x] **Domain**
  - [x] `entities/` (`Circle.dart`)
  - [x] `repositories/` (`CirclesRepository` interface)
  - [x] `usecases/`
    - [x] `GetCircleDetailsUseCase.dart`
    - [x] `JoinCircleUseCase.dart`
    - [x] `LeaveCircleUseCase.dart`
- [x] **Data**
  - [x] `datasources/` (`CirclesRemoteDataSource.dart`)
  - [x] `repositories/` (`CirclesRepositoryImpl.dart`)
- [x] **Presentation**
  - [x] `bloc/` (`CirclesCubit.dart`, `CircleOperationsBloc.dart`)
  - [x] `pages/`
  - [x] `widgets/`

### Feature: Cheers (Social Celebrations)

- [x] **Domain**
  - [x] `entities/` (`CheersActivity.dart`)
  - [x] `repositories/` (`CheersRepository` interface)
  - [x] `usecases/`
    - [x] `WatchCheersActivitiesUseCase.dart`
    - [x] `SendCheersZapUseCase.dart`
    - [x] `SendCheersNudgeUseCase.dart`
- [x] **Data**
  - [x] `datasources/` (`CheersDataSource.dart`)
  - [x] `repositories/` (`CheersRepositoryImpl.dart`)
- [x] **Presentation**
  - [x] `bloc/` (`CheersCubit.dart` - *Depends only on UseCases*)
  - [x] `pages/`
  - [x] `widgets/`

### Feature: Book Reader & Progress (Tracking)

- [x] **Domain**
  - [x] `entities/` (`BookProgress.dart`)
  - [x] `repositories/` (`BookReaderRepository` interface)
  - [x] `usecases/`
    - [x] `ReportReadingProgressUseCase.dart` (Handles tracking stats and generating milestones)
    - [x] `GetBookContentUseCase.dart`
- [x] **Data**
  - [x] `datasources/` (`BookReaderLocalDataSource.dart`, `ProgressRemoteDataSource.dart`)
  - [x] `repositories/` (`BookReaderRepositoryImpl.dart`)
- [x] **Presentation**
  - [x] `bloc/` (`BookReaderCubit.dart`)
  - [x] `pages/`
  - [x] `widgets/`

### Feature: Library (My Books)

- [x] **Domain**
  - [x] `entities/` (`LibraryBook.dart`)
  - [x] `repositories/` (`LibraryRepository` interface)
  - [x] `usecases/`
    - [x] `GetUserLibraryUseCase.dart`
- [x] **Data**
  - [x] `datasources/` (`LibraryLocalDataSource.dart`)
  - [x] `repositories/` (`LibraryRepositoryImpl.dart`)
- [x] **Presentation**
  - [x] `bloc/` (`LibraryCubit.dart`)
  - [x] `pages/`
  - [x] `widgets/`

### Feature: Onboarding & Identity

- [x] **Domain**
  - [x] `entities/` (`Identity.dart`)
  - [x] `repositories/` (`IdentityRepository` interface)
  - [x] `usecases/`
    - [x] `GenerateKeysUseCase.dart`
    - [x] `ImportKeysUseCase.dart`
    - [x] `CheckExistingSessionUseCase.dart`
- [x] **Data**
  - [x] `datasources/` (`IdentityLocalDataSource.dart`)
  - [x] `repositories/` (`IdentityRepositoryImpl.dart`)
- [x] **Presentation**
  - [x] `bloc/` (`OnboardingCubit.dart`)
  - [x] `pages/`
  - [x] `widgets/`

### Feature: Heads Up (Notifications/Banner)

- [x] **Domain**
  - [x] `entities/` (`HeadsUpMessage.dart`)
  - [x] `repositories/` (`HeadsUpRepository` interface)
  - [x] `usecases/`
    - [x] `ShowNotificationUseCase.dart`
    - [x] `DismissNotificationUseCase.dart`
- [x] **Data**
  - [x] `datasources/` (`HeadsUpLocalDataSource.dart`)
  - [x] `repositories/` (`HeadsUpRepositoryImpl.dart`)
- [x] **Presentation**
  - [x] `cubit/` (`HeadsUpCubit.dart`)
  - [x] `models/`
  - [x] `widgets/`

### Feature: Book Ingestion (AI Parsing & Cover Generation)

- [x] **Domain**
  - [x] `entities/` (`IngestionJob.dart`, etc.)
  - [x] `repositories/` (`BookIngestionRepository` interface)
  - [x] `usecases/`
    - [x] `ParseBookUseCase.dart`
    - [x] `GenerateCoverUseCase.dart`
- [x] **Data**
  - [x] `datasources/` (`AiRemoteDataSource.dart`, etc.)
  - [x] `repositories/` (`BookIngestionRepositoryImpl.dart`)
- [x] **Presentation**
  - [x] `bloc/` (`BookIngestionBloc.dart`)
  - [x] `pages/`
  - [x] `widgets/`

## 3. App & Foundation (`lib/app/` & `lib/zbf/`)

- [x] **App Setup**
  - [x] `lib/app/` (Move `main.dart`, `app.dart` logic here cleanly)
- [x] **ZBF (ZapBook Format Parser)**
  - [x] Extract ZBF strictly as a package or keep it isolated in `lib/zbf/`
  - [x] `entities/`, `enums/`, `support/`
- [x] **Theme Consolidation**
  - [x] Merge `lib/theme/` into `lib/core/presentation/theme/` to keep root folder clean.
