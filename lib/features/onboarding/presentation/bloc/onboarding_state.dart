import 'package:equatable/equatable.dart';

enum OnboardingStep { welcome, identity, wallet, profile }

class OnboardingState extends Equatable {
  final OnboardingStep step;
  final bool isGeneratingNew;
  final String generatedNpub;
  final String generatedNsec;
  final String importedNsec;
  final String lightningAddress;
  final String displayName;
  final String picture;
  final bool isFetchingMetadata;
  final bool isBusy;
  final String? error;
  final bool isComplete;
  final bool hasExistingProfile;
  final bool keyPackagePublishFailed;

  const OnboardingState({
    required this.step,
    this.isGeneratingNew = true,
    this.generatedNpub = "",
    this.generatedNsec = "",
    this.importedNsec = "",
    this.lightningAddress = "",
    this.displayName = "",
    this.picture = "",
    this.isFetchingMetadata = false,
    this.isBusy = false,
    this.error,
    this.isComplete = false,
    this.hasExistingProfile = false,
    this.keyPackagePublishFailed = false,
  });

  @override
  List<Object?> get props => [
    step,
    isGeneratingNew,
    generatedNpub,
    generatedNsec,
    importedNsec,
    lightningAddress,
    displayName,
    picture,
    isFetchingMetadata,
    isBusy,
    error,
    isComplete,
    hasExistingProfile,
    keyPackagePublishFailed,
  ];

  OnboardingState copyWith({
    OnboardingStep? step,
    bool? isGeneratingNew,
    String? generatedNpub,
    String? generatedNsec,
    String? importedNsec,
    String? lightningAddress,
    String? displayName,
    String? picture,
    bool? isFetchingMetadata,
    bool? isBusy,
    String? error,
    bool? isComplete,
    bool? hasExistingProfile,
    bool? keyPackagePublishFailed,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      isGeneratingNew: isGeneratingNew ?? this.isGeneratingNew,
      generatedNpub: generatedNpub ?? this.generatedNpub,
      generatedNsec: generatedNsec ?? this.generatedNsec,
      importedNsec: importedNsec ?? this.importedNsec,
      lightningAddress: lightningAddress ?? this.lightningAddress,
      displayName: displayName ?? this.displayName,
      picture: picture ?? this.picture,
      isFetchingMetadata: isFetchingMetadata ?? this.isFetchingMetadata,
      isBusy: isBusy ?? this.isBusy,
      error: error,
      isComplete: isComplete ?? this.isComplete,
      hasExistingProfile: hasExistingProfile ?? this.hasExistingProfile,
      keyPackagePublishFailed:
          keyPackagePublishFailed ?? this.keyPackagePublishFailed,
    );
  }
}
