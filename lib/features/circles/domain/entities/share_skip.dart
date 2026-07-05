enum ShareSkipReason { noKeyPackage, unknownError }

class ShareSkip {
  const ShareSkip({required this.npub, required this.reason});

  final String npub;
  final ShareSkipReason reason;

  String description() {
    switch (reason) {
      case ShareSkipReason.noKeyPackage:
        return 'needs to update their key package or install ZapBook';
      case ShareSkipReason.unknownError:
        return 'an unknown error occurred';
    }
  }
}
