# ZapBook Clean Architecture Refactor Checklist

This file tracks the progress of our refactor to a strict Clean Architecture. The dependency flow we are aiming for is:
**Presentation (Cubit/Bloc)** → **Domain (UseCase)** → **Domain (Repository Interface)** ← **Data (Repository Impl)** → **Data (DataSource)** → **Infrastructure (Services/DB/Network)**.

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

- [ ] **Domain**
  - [ ] `entities/` (`DashboardData.dart`)
  - [ ] `repositories/` (`HomeRepository` interface)
  - [ ] `usecases/`
    - [ ] `GetHomeDashboardDataUseCase.dart`
- [ ] **Data**
  - [ ] `datasources/` (`HomeLocalDataSource.dart`, `HomeRemoteDataSource.dart`)
  - [ ] `repositories/` (`HomeRepositoryImpl.dart`)
- [ ] **Presentation**
  - [ ] `bloc/` (`HomeCubit.dart` - *Depends only on UseCases*)
  - [ ] `pages/`
  - [ ] `widgets/`

### Feature: Circles

- [ ] **Domain**
  - [ ] `entities/` (`Circle.dart`)
  - [ ] `repositories/` (`CirclesRepository` interface)
  - [ ] `usecases/`
    - [ ] `GetCircleDetailsUseCase.dart`
    - [ ] `JoinCircleUseCase.dart`
    - [ ] `LeaveCircleUseCase.dart`
- [ ] **Data**
  - [ ] `datasources/` (`CirclesRemoteDataSource.dart`)
  - [ ] `repositories/` (`CirclesRepositoryImpl.dart`)
- [ ] **Presentation**
  - [ ] `bloc/` (`CirclesCubit.dart`, `CircleOperationsBloc.dart`)
  - [ ] `pages/`
  - [ ] `widgets/`

### Feature: Cheers (Social Celebrations)

- [ ] **Domain**
  - [ ] `entities/` (`CheersActivity.dart`)
  - [ ] `repositories/` (`CheersRepository` interface)
  - [ ] `usecases/`
    - [ ] `GetCheersActivityUseCase.dart`
    - [ ] `SendZapUseCase.dart`
    - [ ] `SendNudgeUseCase.dart`
- [ ] **Data**
  - [ ] `datasources/` (`CheersLocalDataSource.dart`, `CheersRemoteDataSource.dart`)
  - [ ] `repositories/` (`CheersRepositoryImpl.dart`)
- [ ] **Presentation**
  - [ ] `bloc/` (`CheersCubit.dart` - *Depends only on UseCases*)
  - [ ] `pages/`
  - [ ] `widgets/`

### Feature: Book Reader & Progress (Tracking)

- [ ] **Domain**
  - [ ] `entities/` (`BookProgress.dart`)
  - [ ] `repositories/` (`BookReaderRepository` interface)
  - [ ] `usecases/`
    - [ ] `ReportReadingProgressUseCase.dart` (Handles tracking stats and generating milestones)
    - [ ] `GetBookContentUseCase.dart`
- [ ] **Data**
  - [ ] `datasources/` (`BookReaderLocalDataSource.dart`, `ProgressRemoteDataSource.dart`)
  - [ ] `repositories/` (`BookReaderRepositoryImpl.dart`)
- [ ] **Presentation**
  - [ ] `bloc/` (`BookReaderCubit.dart`)
  - [ ] `pages/`
  - [ ] `widgets/`

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

- [ ] **Domain**
  - [ ] `entities/` (`HeadsUpMessage.dart`)
  - [ ] `repositories/` (`HeadsUpRepository` interface)
  - [ ] `usecases/`
    - [ ] `ShowNotificationUseCase.dart`
    - [ ] `DismissNotificationUseCase.dart`
- [ ] **Data**
  - [ ] `datasources/` (`HeadsUpLocalDataSource.dart`)
  - [ ] `repositories/` (`HeadsUpRepositoryImpl.dart`)
- [ ] **Presentation**
  - [ ] `cubit/` (`HeadsUpCubit.dart`)
  - [ ] `models/`
  - [ ] `widgets/`

### Feature: Book Ingestion (AI Parsing & Cover Generation)

- [ ] **Domain**
  - [ ] `entities/` (`IngestionJob.dart`, etc.)
  - [ ] `repositories/` (`BookIngestionRepository` interface)
  - [ ] `usecases/`
    - [ ] `ParseBookUseCase.dart`
    - [ ] `GenerateCoverUseCase.dart`
- [ ] **Data**
  - [ ] `datasources/` (`AiRemoteDataSource.dart`, etc.)
  - [ ] `repositories/` (`BookIngestionRepositoryImpl.dart`)
- [ ] **Presentation**
  - [ ] `bloc/` (`BookIngestionBloc.dart`)
  - [ ] `pages/`
  - [ ] `widgets/`

## 3. App & Foundation (`lib/app/` & `lib/zbf/`)

- [ ] **App Setup**
  - [ ] `lib/app/` (Move `main.dart`, `app.dart` logic here cleanly)
- [ ] **ZBF (ZapBook Format Parser)**
  - [ ] Extract ZBF strictly as a package or keep it isolated in `lib/zbf/`
  - [ ] `entities/`, `enums/`, `support/`
- [ ] **Theme Consolidation**
  - [ ] Merge `lib/theme/` into `lib/core/presentation/theme/` to keep root folder clean.
