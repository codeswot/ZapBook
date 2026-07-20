import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_detail_state.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_members_state.dart';

MemberEntry _entry(String npub, String label, {bool isSelf = false}) {
  return MemberEntry(
    npub: npub,
    contact: Contact(npub: npub, displayName: label),
    isSelf: isSelf,
    isFollow: false,
  );
}

void main() {
  group('MemberProgressRanking.compareEntries', () {
    test('ranks higher fraction first', () {
      final a = _entry('a', 'Alice');
      final b = _entry('b', 'Bob');
      final progress = {
        'a': const MemberProgress(currentPage: 5, fraction: 0.5),
        'b': const MemberProgress(currentPage: 5, fraction: 0.9),
      };

      final sorted = [a, b]..sort(progress.compareEntries);

      expect(sorted, [b, a]);
    });

    test('breaks fraction ties by current page', () {
      final a = _entry('a', 'Alice');
      final b = _entry('b', 'Bob');
      final progress = {
        'a': const MemberProgress(currentPage: 3, fraction: 0.5),
        'b': const MemberProgress(currentPage: 10, fraction: 0.5),
      };

      final sorted = [a, b]..sort(progress.compareEntries);

      expect(sorted, [b, a]);
    });

    test('breaks page ties alphabetically by label', () {
      final a = _entry('a', 'Zoe');
      final b = _entry('b', 'Amy');
      final progress = {
        'a': const MemberProgress(currentPage: 3, fraction: 0.5),
        'b': const MemberProgress(currentPage: 3, fraction: 0.5),
      };

      final sorted = [a, b]..sort(progress.compareEntries);

      expect(sorted, [b, a]);
    });

    test('treats missing progress as zero', () {
      final a = _entry('a', 'Alice');
      final b = _entry('b', 'Bob');
      final progress = {'b': const MemberProgress(currentPage: 1, fraction: 0.1)};

      final sorted = [a, b]..sort(progress.compareEntries);

      expect(sorted, [b, a]);
    });
  });
}
