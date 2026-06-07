class Validators {
  Validators._();

  static final _lud16Regex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name cannot be empty';
    }
    if (value.trim().length < 2) {
      return 'Display name must be at least 2 characters';
    }
    return null;
  }

  static String? lud16(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (!_lud16Regex.hasMatch(value.trim())) {
      return 'Invalid lightning address (user@domain.com)';
    }
    return null;
  }

  static String? nsec(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Secret key cannot be empty';
    }
    if (!value.trim().startsWith('nsec1')) {
      return 'Invalid secret key (must start with nsec1)';
    }
    if (value.trim().length < 56) {
      return 'Secret key too short';
    }
    return null;
  }

  static String? required(String? value, [String label = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$label cannot be empty';
    }
    return null;
  }
}
