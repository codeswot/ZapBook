import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zapbook/core/services/clipboard_service.dart';

enum OnboardingStep { welcome, identity, wallet, model }

class OnboardingState extends Equatable {
  final OnboardingStep step;
  final bool isGeneratingNew;
  final String generatedNpub;
  final String generatedNsec;
  final String importedNsec;
  final String lightningAddress;
  final bool isComplete;

  const OnboardingState({
    required this.step,
    this.isGeneratingNew = true,
    this.generatedNpub = "npub1q8s7fx4k2m9v0pe3rt6yu7c5l8wd2na6hg4j0zq",
    this.generatedNsec = "nsec1u8y9px4k2m9v0pe3rt6yu7c5l8wd2na6hg4j0zqnsec",
    this.importedNsec = "",
    this.lightningAddress = "wren@walletofsatoshi.com",
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
    isComplete,
  ];

  OnboardingState copyWith({
    OnboardingStep? step,
    bool? isGeneratingNew,
    String? generatedNpub,
    String? generatedNsec,
    String? importedNsec,
    String? lightningAddress,
    bool? isComplete,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      isGeneratingNew: isGeneratingNew ?? this.isGeneratingNew,
      generatedNpub: generatedNpub ?? this.generatedNpub,
      generatedNsec: generatedNsec ?? this.generatedNsec,
      importedNsec: importedNsec ?? this.importedNsec,
      lightningAddress: lightningAddress ?? this.lightningAddress,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

@injectable
class OnboardingCubit extends Cubit<OnboardingState> {
  final SharedPreferences _prefs;
  final ClipboardService _clipboardService;

  OnboardingCubit(this._prefs, this._clipboardService)
    : super(const OnboardingState(step: OnboardingStep.welcome));

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
    emit(state.copyWith(isGeneratingNew: isGeneratingNew));
  }

  void regenerateKeys() {
    final rand = Random();
    final chars = "abcdefghijklmnopqrstuvwxyz0123456789";
    final randomPart = List.generate(
      30,
      (index) => chars[rand.nextInt(chars.length)],
    ).join("");
    final npub = "npub1q8s7f$randomPart";
    final nsec = "nsec1${randomPart}nsec";
    emit(state.copyWith(generatedNpub: npub, generatedNsec: nsec));
  }

  void updateImportedNsec(String nsec) {
    emit(state.copyWith(importedNsec: nsec));
  }

  void updateLightningAddress(String address) {
    emit(state.copyWith(lightningAddress: address));
  }

  Future<void> copyKeys() async {
    final nsec = "nsec1${state.generatedNpub.substring(5)}nsec";
    await _clipboardService.copy("npub: ${state.generatedNpub}\nnsec: $nsec");
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

  Future<void> completeOnboarding() async {
    await _prefs.setBool('onboarding_complete', true);
    emit(state.copyWith(isComplete: true));
  }
}
