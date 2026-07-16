enum SignerType { local, nip55, nip46 }

class SignerMeta {
  const SignerMeta({required this.type, this.package, this.connectionJson});

  final SignerType type;
  final String? package;
  final String? connectionJson;

  bool get isExternal =>
      type == SignerType.nip55 || type == SignerType.nip46;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (package != null) 'package': package,
        if (connectionJson != null) 'connection': connectionJson,
      };

  static SignerMeta? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final type = raw['type'];
    if (type == SignerType.nip55.name) {
      final package = raw['package'];
      return SignerMeta(
        type: SignerType.nip55,
        package: package is String ? package : null,
      );
    }
    if (type == SignerType.nip46.name) {
      final connection = raw['connection'];
      return SignerMeta(
        type: SignerType.nip46,
        connectionJson: connection is String ? connection : null,
      );
    }
    return const SignerMeta(type: SignerType.local);
  }
}

sealed class Nip55Exception implements Exception {
  const Nip55Exception(this.message);

  final String message;

  factory Nip55Exception.fromCode(String? code, String? detail) {
    final message = detail ?? code ?? 'Signer error';
    return switch (code) {
      'not-installed' => const SignerNotInstalled(),
      'rejected' => const SignerRejected(),
      'timeout' => const SignerTimeout(),
      'malformed' => SignerMalformed(message),
      _ => SignerUnavailable(message),
    };
  }

  @override
  String toString() => 'Nip55Exception($message)';
}

class SignerNotInstalled extends Nip55Exception {
  const SignerNotInstalled() : super('No signer app installed');
}

class SignerRejected extends Nip55Exception {
  const SignerRejected() : super('Signer request was declined');
}

class SignerTimeout extends Nip55Exception {
  const SignerTimeout() : super('Signer did not respond');
}

class SignerUnavailable extends Nip55Exception {
  const SignerUnavailable(super.message);
}

class SignerMalformed extends Nip55Exception {
  const SignerMalformed(super.message);
}
