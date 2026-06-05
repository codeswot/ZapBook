import 'package:equatable/equatable.dart';

final class OnboardingStatus extends Equatable {
  const OnboardingStatus({required this.isComplete});

  final bool isComplete;

  @override
  List<Object?> get props => [isComplete];
}
