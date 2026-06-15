import 'package:intl/intl.dart';

extension SatsFormatting on int {
  String get formatSats =>
      this >= 1000 ? '${(this / 1000).toStringAsFixed(0)}k' : '$this';

  String get formatSatsDelimited => NumberFormat.decimalPattern().format(this);
}
