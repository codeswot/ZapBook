import 'package:equatable/equatable.dart';

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
