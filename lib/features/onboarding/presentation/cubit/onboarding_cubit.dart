import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zapbook/core/identity/identity_repository.dart';
import 'package:zapbook/core/services/clipboard_service.dart';

enum OnboardingStep { welcome, identity, wallet, model }

class OnboardingState extends Equatable {
  final OnboardingStep step;
  final bool isGeneratingNew;
  final String generatedNpub;
  final String generatedNsec;
  final String importedNsec;
  final String lightningAddress;
  final bool isBusy;
  final String? error;
  final bool isComplete;

  const OnboardingState({
    required this.step,
    this.isGeneratingNew = true,
    this.generatedNpub = "",
    this.generatedNsec = "",
    this.importedNsec = "",
    this.lightningAddress = "",
    this.isBusy = false,
    this.error,
    this.isComplete = false,
  });

  @override
  List<Object?> get props => [
    step,
    isGeneratingNew,
    generatedNpub,
    generatedNsec,
    importedNsec,
    lightningAddress,
    isBusy,
    error,
    isComplete,
  ];

  OnboardingState copyWith({
    OnboardingStep? step,
    bool? isGeneratingNew,
    String? generatedNpub,
    String? generatedNsec,
    String? importedNsec,
    String? lightningAddress,
    bool? isBusy,
    String? error,
    bool? isComplete,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      isGeneratingNew: isGeneratingNew ?? this.isGeneratingNew,
      generatedNpub: generatedNpub ?? this.generatedNpub,
      generatedNsec: generatedNsec ?? this.generatedNsec,
      importedNsec: importedNsec ?? this.importedNsec,
      lightningAddress: lightningAddress ?? this.lightningAddress,
      isBusy: isBusy ?? this.isBusy,
      error: error,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

@injectable
class OnboardingCubit extends Cubit<OnboardingState> {
  final SharedPreferences _prefs;
  final ClipboardService _clipboardService;
  final IdentityRepository _identity;

  OnboardingCubit(this._prefs, this._clipboardService, this._identity)
    : super(const OnboardingState(step: OnboardingStep.welcome)) {
    regenerateKeys();
  }

  void nextStep() {
    switch (state.step) {
      case OnboardingStep.welcome:
        emit(state.copyWith(step: OnboardingStep.identity));
        break;
      case OnboardingStep.identity:
        emit(state.copyWith(step: OnboardingStep.wallet));
        break;
      case OnboardingStep.wallet:
        emit(state.copyWith(step: OnboardingStep.model));
        break;
      case OnboardingStep.model:
        completeOnboarding();
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
      case OnboardingStep.model:
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
      regenerateKeys();
    }
  }

  Future<void> regenerateKeys() async {
    emit(state.copyWith(isBusy: true, error: null));
    try {
      final keypair = await _identity.generate();
      emit(
        state.copyWith(
          isBusy: false,
          generatedNpub: keypair.npub,
          generatedNsec: keypair.nsec ?? "",
        ),
      );
    } on Object {
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
      final isValid = await _identity.validateNsec(trimmed);
      if (!isValid) {
        emit(state.copyWith(isBusy: false, error: "Invalid secret key"));
        return false;
      }
      final keypair = await _identity.importFromNsec(trimmed);
      emit(
        state.copyWith(
          isBusy: false,
          importedNsec: trimmed,
          generatedNpub: keypair.npub,
          generatedNsec: keypair.nsec ?? trimmed,
        ),
      );
      return true;
    } on Object {
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

  Future<bool> completeOnboarding() async {
    final npub = state.generatedNpub;
    final nsec = state.generatedNsec;
    if (npub.isEmpty || nsec.isEmpty) {
      emit(state.copyWith(error: "No identity to save"));
      return false;
    }
    await _identity.persist(npub: npub, nsec: nsec);
    await _prefs.setBool('onboarding_complete', true);
    emit(state.copyWith(isComplete: true));
    return true;
  }
}
