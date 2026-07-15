enum PerfMode {
  auto,
  on,
  off;

  static PerfMode fromName(String? name) => PerfMode.values.firstWhere(
    (mode) => mode.name == name,
    orElse: () => PerfMode.auto,
  );
}
