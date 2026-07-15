# ZapBook Clean Architecture Refactor Checklist

This file tracks the progress of our refactor to a strict Clean Architecture. The dependency flow we are aiming for is:
**Presentation (Cubit/Bloc)** → **Domain (UseCase)** → **Domain (Repository Interface)** ← **Data (Repository Impl)** → **Data (DataSource)** → **Infrastructure (Services/DB/Network)**.

**CRITICAL ARCHITECTURE RULE**: UseCases MUST ONLY depend on Repository Interfaces defined in the Domain layer. They must NEVER depend directly on DataSources, Services, or any implementation details. Do not inject `*Service` or `*DataSource` into a UseCase!

---

## 1. Core Layer (`lib/core/`)

- [x] `lib/core/config/` (AppConfig, Env)
- [x] `lib/core/constants/` (Colors, Strings)
- [ ] `lib/core/data/`
  - [ ] `database/` (AppDatabase, DAOs)
  - [ ] `network/` (NetworkClient wrapper)
  - [ ] `infrastructure/` (Low-level services: `NdkWrapper`, `ReadingStatsTracker`)
- [ ] `lib/core/domain/`
  - [ ] `entities/` (Shared entities like `AppMessage`, `UserProfile`)
  - [ ] `exceptions/` (Custom app exceptions)
- [ ] `lib/core/presentation/`
  - [ ] `widgets/` (Shared UI components)
  - [ ] `theme/` (App theme definitions)
  - [ ] `router/` (GoRouter configurations)
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

- [ ] **Domain**
  - [ ] `entities/` (`LibraryBook.dart`)
  - [ ] `repositories/` (`LibraryRepository` interface)
  - [ ] `usecases/`
    - [ ] `GetUserLibraryUseCase.dart`
- [ ] **Data**
  - [ ] `datasources/` (`LibraryLocalDataSource.dart`)
  - [ ] `repositories/` (`LibraryRepositoryImpl.dart`)
- [ ] **Presentation**
  - [ ] `bloc/` (`LibraryCubit.dart`)
  - [ ] `pages/`
  - [ ] `widgets/`

### Feature: Onboarding & Identity

- [ ] **Domain**
  - [ ] `entities/` (`Identity.dart`)
  - [ ] `repositories/` (`IdentityRepository` interface)
  - [ ] `usecases/`
    - [ ] `GenerateKeysUseCase.dart`
    - [ ] `ImportKeysUseCase.dart`
    - [ ] `CheckExistingSessionUseCase.dart`
- [ ] **Data**
  - [ ] `datasources/` (`IdentityLocalDataSource.dart`)
  - [ ] `repositories/` (`IdentityRepositoryImpl.dart`)
- [ ] **Presentation**
  - [ ] `bloc/` (`OnboardingCubit.dart`)
  - [ ] `pages/`
  - [ ] `widgets/`

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

- [ ] **App Setup**
  - [ ] `lib/app/` (Move `main.dart`, `app.dart` logic here cleanly)
- [ ] **ZBF (ZapBook Format Parser)**
  - [ ] Extract ZBF strictly as a package or keep it isolated in `lib/zbf/`
  - [ ] `entities/`, `enums/`, `support/`
- [ ] **Theme Consolidation**
  - [ ] Merge `lib/theme/` into `lib/core/presentation/theme/` to keep root folder clean.
