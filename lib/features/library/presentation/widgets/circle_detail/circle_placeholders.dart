double circleProgressFraction(String npub) =>
    (((npub.hashCode & 0x7fffffff) % 86) + 8) / 100;

int circleReaderPage(String npub, int pageCount) => pageCount <= 0
    ? 0
    : (circleProgressFraction(npub) * pageCount).round().clamp(1, pageCount);

int circleZapTotal(String seed) => ((seed.hashCode & 0x7fffffff) % 4800) + 120;

String formatSats(int sats) {
  final digits = sats.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
