import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:zapbook/core/domain/usecases/clipboard_usecases.dart';
import 'package:zapbook/core/identity/signer_meta.dart';
import 'package:zapbook/core/identity/bunker_signer_source.dart';
import 'package:zapbook/core/utils/profile_meta_generator.dart';
import 'package:zapbook/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:zapbook/features/onboarding/domain/usecases/connect_external_signer.dart';
import 'package:zapbook/features/onboarding/domain/usecases/generate_identity.dart';
import 'package:zapbook/features/onboarding/domain/usecases/import_identity.dart';
import 'package:zapbook/features/onboarding/domain/usecases/fetch_existing_profile.dart';
import 'package:zapbook/features/onboarding/presentation/bloc/onboarding_state.dart';

export 'package:zapbook/features/onboarding/presentation/bloc/onboarding_state.dart';

@injectable
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(
    this._copyText,
    this._pasteText,
    this._fetchExistingProfileUseCase,
    this._generateIdentity,
    this._importIdentity,
    this._completeOnboarding,
    this._connectExternalSigner,
  ) : super(const OnboardingState(step: OnboardingStep.welcome)) {
    generateKeys();
  }

  static final Logger _log = Logger('OnboardingCubit');

  final CopyTextUseCase _copyText;
  final PasteTextUseCase _pasteText;
  final FetchExistingProfileUseCase _fetchExistingProfileUseCase;
  final GenerateIdentity _generateIdentity;
  final ImportIdentity _importIdentity;
  final CompleteOnboarding _completeOnboarding;
  final ConnectExternalSigner _connectExternalSigner;

  void nextStep() {
    switch (state.step) {
      case OnboardingStep.welcome:
        emit(state.copyWith(step: OnboardingStep.identity));
        break;
      case OnboardingStep.identity:
        emit(state.copyWith(step: OnboardingStep.wallet));
        break;
      case OnboardingStep.wallet:
        if (state.hasExistingProfile || state.importedNsec.isNotEmpty) {
          completeOnboarding(publish: false);
        } else {
          emit(state.copyWith(step: OnboardingStep.profile));
          _onEnterProfile();
        }
        break;
      case OnboardingStep.profile:
        completeOnboarding(publish: true);
        break;
    }
  }

  void previousStep() {
    switch (state.step) {
      case OnboardingStep.welcome:
        break;
      case OnboardingStep.identity:
        emit(state.copyWith(step: OnboardingStep.welcome));
        break;
      case OnboardingStep.wallet:
        emit(state.copyWith(step: OnboardingStep.identity));
        break;
      case OnboardingStep.profile:
        emit(state.copyWith(step: OnboardingStep.wallet));
        break;
    }
  }

  void selectStep(OnboardingStep step) {
    emit(state.copyWith(step: step));
  }

  void toggleIdentityMode(bool isGeneratingNew) {
    emit(state.copyWith(isGeneratingNew: isGeneratingNew, error: null));
    if (isGeneratingNew && state.generatedNpub.isEmpty) {
      generateKeys();
    }
  }

  Future<void> generateKeys() async {
    emit(state.copyWith(isBusy: true, error: null));
    try {
      final keypair = await _generateIdentity();
      emit(
        state.copyWith(
          isBusy: false,
          generatedNpub: keypair.npub,
          generatedNsec: keypair.nsec ?? "",
        ),
      );
    } on Exception catch (error, stack) {
      _log.severe('generateKeys failed', error, stack);
      emit(state.copyWith(isBusy: false, error: "Failed to generate keypair"));
    }
  }

  Future<bool> connectExternalSigner() async {
    if (!await _connectExternalSigner.isAvailable()) {
      emit(
        state.copyWith(
          error:
              "No Nostr signer app found. Install Amber (or another NIP-55 signer) to continue.",
        ),
      );
      return false;
    }
    emit(state.copyWith(isBusy: true, error: null));
    try {
      final connection = await _connectExternalSigner();
      emit(
        state.copyWith(
          isExternalSigner: true,
          signerPackage: connection.package,
          generatedNpub: connection.npub,
          generatedNsec: "",
          importedNsec: "",
        ),
      );
      await _fetchExistingProfile();
      emit(state.copyWith(isBusy: false));
      return true;
    } on Nip55Exception catch (error, stack) {
      _log.warning('connectExternalSigner failed', error, stack);
      emit(state.copyWith(isBusy: false, error: _signerErrorMessage(error)));
      return false;
    }
  }

  Future<bool> connectBunker(String bunkerUrl) async {
    emit(state.copyWith(isBusy: true, error: null));
    try {
      final connection = await _connectExternalSigner.connectBunker(bunkerUrl);
      emit(
        state.copyWith(
          isExternalSigner: true,
          signerConnectionJson: connection.connectionJson,
          signerPackage: "",
          generatedNpub: connection.npub,
          generatedNsec: "",
          importedNsec: "",
        ),
      );
      await _fetchExistingProfile();
      emit(state.copyWith(isBusy: false));
      return true;
    } on Nip55Exception catch (error, stack) {
      _log.warning('connectBunker failed', error, stack);
      emit(state.copyWith(isBusy: false, error: _bunkerErrorMessage(error)));
      return false;
    } on Object catch (error, stack) {
      _log.warning('connectBunker failed', error, stack);
      emit(
        state.copyWith(
          isBusy: false,
          error: "Couldn't connect to the remote signer. Check the link.",
        ),
      );
      return false;
    }
  }

  NostrConnectSession startNostrConnect() {
    return _connectExternalSigner.initiateNostrConnect(appName: 'ZapBook');
  }

  Future<bool> connectNostrConnect(NostrConnectSession session) async {
    emit(state.copyWith(isBusy: true, error: null));
    try {
      final connection = await session.awaitConnection();
      emit(
        state.copyWith(
          isExternalSigner: true,
          signerConnectionJson: connection.connectionJson,
          signerPackage: "",
          generatedNpub: connection.npub,
          generatedNsec: "",
          importedNsec: "",
        ),
      );
      await _fetchExistingProfile();
      emit(state.copyWith(isBusy: false));
      return true;
    } on Object catch (error, stack) {
      _log.warning('connectNostrConnect failed', error, stack);
      emit(
        state.copyWith(
          isBusy: false,
          error: "Signer did not connect or an error occurred.",
        ),
      );
      return false;
    }
  }

  String _signerErrorMessage(Nip55Exception error) => switch (error) {
    SignerNotInstalled() =>
      "No Nostr signer app found. Install Amber (or another NIP-55 signer) to continue.",
    SignerRejected() => "Signing request was declined.",
    SignerTimeout() => "Signer didn't respond. Try again.",
    SignerUnavailable() ||
    SignerMalformed() => "Couldn't reach the signer app. Try again.",
  };

  String _bunkerErrorMessage(Nip55Exception error) => switch (error) {
    SignerMalformed() => "Enter a valid bunker:// connection link.",
    _ => "Couldn't connect to the remote signer. Check the link.",
  };

  Future<bool> importNsec(String nsec) async {
    final trimmed = nsec.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(error: "Please enter your secret key"));
      return false;
    }
    emit(state.copyWith(isBusy: true, error: null));
    try {
      final keypair = await _importIdentity(trimmed);
      emit(
        state.copyWith(
          importedNsec: trimmed,
          generatedNpub: keypair.npub,
          generatedNsec: keypair.nsec ?? trimmed,
        ),
      );

      await _fetchExistingProfile();
      emit(state.copyWith(isBusy: false));
      return true;
    } on Exception catch (error, stack) {
      _log.severe('importNsec failed', error, stack);
      emit(state.copyWith(isBusy: false, error: "Invalid secret key"));
      return false;
    }
  }

  void updateImportedNsec(String nsec) {
    emit(state.copyWith(importedNsec: nsec, error: null));
  }

  void updateLightningAddress(String address) {
    emit(state.copyWith(lightningAddress: address));
  }

  Future<void> copyKeys() async {
    await _copyText(
      "npub: ${state.generatedNpub}\nnsec: ${state.generatedNsec}",
    );
  }

  Future<String?> pasteNsec() async {
    final text = await _pasteText();
    if (text != null) {
      updateImportedNsec(text);
    }
    return text;
  }

  Future<void> pasteLightningAddress() async {
    final text = await _pasteText();
    if (text != null) {
      updateLightningAddress(text);
    }
  }

  void updateDisplayName(String name) {
    emit(state.copyWith(displayName: name));
  }

  void cycleMeta() {
    final meta = ProfileMetaGenerator.generate();
    emit(state.copyWith(displayName: meta.displayName, picture: meta.avatar));
  }

  void _onEnterProfile() {
    if (state.displayName.isEmpty) {
      final meta = ProfileMetaGenerator.generate(seed: state.generatedNpub);
      emit(state.copyWith(displayName: meta.displayName, picture: meta.avatar));
    }
  }

  Future<void> _fetchExistingProfile() async {
    if (state.generatedNpub.isEmpty) return;
    emit(state.copyWith(isFetchingMetadata: true));
    try {
      final profile = await _fetchExistingProfileUseCase(state.generatedNpub);
      if (profile != null) {
        final fetchedName = profile.displayName;
        final hasName = fetchedName != null && fetchedName.isNotEmpty;
        emit(
          state.copyWith(
            displayName: hasName ? fetchedName : state.displayName,
            picture: profile.picture ?? state.picture,
            lightningAddress:
                profile.lightningAddress ?? state.lightningAddress,
            existingLud16: profile.lightningAddress ?? '',
            isFetchingMetadata: false,
            hasExistingProfile: hasName || profile.picture != null,
          ),
        );
      } else {
        emit(state.copyWith(isFetchingMetadata: false));
      }
    } on Exception catch (e) {
      _log.warning('_fetchExistingProfile failed: $e');
      emit(state.copyWith(isFetchingMetadata: false));
    }
  }

  Future<bool> completeOnboarding({bool publish = true}) async {
    final npub = state.generatedNpub;
    final nsec = state.generatedNsec;
    if (npub.isEmpty || (!state.isExternalSigner && nsec.isEmpty)) {
      emit(state.copyWith(error: "No identity to save"));
      return false;
    }
    emit(state.copyWith(isBusy: true));
    final lud16 = state.lightningAddress;
    final lud16Changed = lud16.isNotEmpty && lud16 != state.existingLud16;
    await _completeOnboarding(
      npub: npub,
      nsec: nsec,
      signerPackage: state.isExternalSigner ? state.signerPackage : null,
      bunkerConnectionJson: state.isExternalSigner
          ? state.signerConnectionJson
          : null,
      displayName: publish && state.displayName.isNotEmpty
          ? state.displayName
          : null,
      lud16: (publish && lud16.isNotEmpty) || lud16Changed ? lud16 : null,
      picture: publish && state.picture.isNotEmpty ? state.picture : null,
    );
    return true;
  }
}
