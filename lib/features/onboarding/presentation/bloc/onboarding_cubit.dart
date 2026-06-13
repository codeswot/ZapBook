import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:ndk/ndk.dart' show Nip19;
import 'package:zapbook/core/services/clipboard_service.dart';
import 'package:zapbook/core/services/key_package_service.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/services/profile_meta_generator.dart';
import 'package:zapbook/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:zapbook/features/onboarding/domain/usecases/generate_identity.dart';
import 'package:zapbook/features/onboarding/domain/usecases/import_identity.dart';
import 'package:zapbook/features/onboarding/presentation/bloc/onboarding_state.dart';

export 'package:zapbook/features/onboarding/presentation/bloc/onboarding_state.dart';

@injectable
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(
    this._clipboardService,
    this._nostrService,
    this._generateIdentity,
    this._importIdentity,
    this._completeOnboarding,
    this._keyPackage,
  ) : super(const OnboardingState(step: OnboardingStep.welcome)) {
    generateKeys();
  }

  static final Logger _log = Logger('OnboardingCubit');

  final ClipboardService _clipboardService;
  final NostrService _nostrService;
  final GenerateIdentity _generateIdentity;
  final ImportIdentity _importIdentity;
  final CompleteOnboarding _completeOnboarding;
  final KeyPackageService _keyPackage;

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
    await _clipboardService.copy(
      "npub: ${state.generatedNpub}\nnsec: ${state.generatedNsec}",
    );
  }

  Future<String?> pasteNsec() async {
    final text = await _clipboardService.paste();
    if (text != null) {
      updateImportedNsec(text);
    }
    return text;
  }

  Future<void> pasteLightningAddress() async {
    final text = await _clipboardService.paste();
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
    final pubkey = Nip19.decode(state.generatedNpub);
    if (pubkey.isEmpty) return;
    emit(state.copyWith(isFetchingMetadata: true));
    try {
      final metadata = await _nostrService
          .getMetadata(pubkey)
          .timeout(const Duration(seconds: 10));
      if (metadata != null) {
        final fetchedName = metadata.displayName ?? metadata.name;
        final hasName = fetchedName != null && fetchedName.isNotEmpty;
        emit(
          state.copyWith(
            displayName: hasName ? fetchedName : state.displayName,
            picture: metadata.picture ?? state.picture,
            lightningAddress: metadata.lud16 ?? state.lightningAddress,
            isFetchingMetadata: false,
            hasExistingProfile: hasName || metadata.picture != null,
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
    if (npub.isEmpty || nsec.isEmpty) {
      emit(state.copyWith(error: "No identity to save"));
      return false;
    }
    emit(state.copyWith(isBusy: true));
    await _completeOnboarding(npub: npub, nsec: nsec);
    if (publish && _nostrService.isLoggedIn) {
      unawaited(
        _nostrService.publishMetadata(
          displayName: state.displayName.isNotEmpty ? state.displayName : null,
          lud16: state.lightningAddress.isNotEmpty
              ? state.lightningAddress
              : null,
          picture: state.picture.isNotEmpty ? state.picture : null,
        ),
      );
    }
    final keyPackageOk = await _keyPackage.ensurePublished();
    emit(
      state.copyWith(
        isComplete: true,
        isBusy: false,
        keyPackagePublishFailed: !keyPackageOk,
      ),
    );
    return true;
  }
}
