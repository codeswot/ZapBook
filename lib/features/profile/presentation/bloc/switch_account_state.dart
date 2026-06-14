sealed class SwitchAccountState {
  const SwitchAccountState();
}

class SwitchAccountLoading extends SwitchAccountState {
  const SwitchAccountLoading();
}

class SwitchAccountLoaded extends SwitchAccountState {
  final List<SwitchAccountItem> accounts;
  final String activeNpub;
  const SwitchAccountLoaded({
    required this.accounts,
    required this.activeNpub,
  });
}

class SwitchAccountBusy extends SwitchAccountState {
  final List<SwitchAccountItem> accounts;
  final String activeNpub;
  final String? busyNpub;
  final bool isAdding;
  const SwitchAccountBusy({
    required this.accounts,
    required this.activeNpub,
    this.busyNpub,
    this.isAdding = false,
  });
}

class SwitchAccountError extends SwitchAccountState {
  final List<SwitchAccountItem> accounts;
  final String activeNpub;
  final String message;
  const SwitchAccountError({
    required this.accounts,
    required this.activeNpub,
    required this.message,
  });

  static SwitchAccountState from(SwitchAccountState state, String message) {
    if (state is SwitchAccountLoaded) {
      return SwitchAccountError(
        accounts: state.accounts,
        activeNpub: state.activeNpub,
        message: message,
      );
    }
    if (state is SwitchAccountBusy) {
      return SwitchAccountError(
        accounts: state.accounts,
        activeNpub: state.activeNpub,
        message: message,
      );
    }
    if (state is SwitchAccountError) {
      return SwitchAccountError(
        accounts: state.accounts,
        activeNpub: state.activeNpub,
        message: message,
      );
    }
    return SwitchAccountError(
      accounts: const [],
      activeNpub: '',
      message: message,
    );
  }
}

class SwitchAccountItem {
  final String npub;
  final String name;
  final String picture;

  const SwitchAccountItem({
    required this.npub,
    required this.name,
    required this.picture,
  });

  SwitchAccountItem copyWith({
    String? name,
    String? picture,
  }) {
    return SwitchAccountItem(
      npub: npub,
      name: name ?? this.name,
      picture: picture ?? this.picture,
    );
  }
}
