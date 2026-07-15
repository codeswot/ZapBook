import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_type.dart';
import 'package:zapbook/features/cheers/domain/cheers_note_composer.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';

const _npub = 'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6';

CheersActivity buildActivity({
  bool isMine = false,
  String actorName = 'Alice',
  String actorNpub = _npub,
  String targetDescription = 'Milestone 3: page 120 (45.0%)',
  String? bookCircleTitle = 'The Hobbit',
  int? pageCount = 200,
  CheersActivityType type = CheersActivityType.milestone,
}) => CheersActivity(
  id: '1',
  groupId: 'g1',
  actorNpub: actorNpub,
  otherPartyNpub: '',
  otherPartyName: '',
  otherPartyPicture: '',
  actorName: actorName,
  actorPicture: '',
  targetId: '',
  targetDescription: targetDescription,
  timestamp: DateTime(2026),
  type: type,
  isUnread: false,
  isMine: isMine,
  bookCircleTitle: bookCircleTitle,
  pageCount: pageCount,
);

void main() {
  const composer = CheersNoteComposer();

  group('milestone', () {
    test('first-person includes book, page/total, percent, and links', () {
      final note = composer.compose(buildActivity(isMine: true));

      expect(note, contains('Just hit Milestone 3'));
      expect(note, contains('while reading The Hobbit'));
      expect(note, contains('page 120 of 200, 45% progress'));
      expect(note, contains('https://www.zapbook.space'));
      expect(note, contains('#zapbook #reading #nostr'));
    });

    test('third-person mentions the actor via nostr: token', () {
      final note = composer.compose(buildActivity(isMine: false));

      expect(note, contains('nostr:$_npub is making great progress'));
      expect(note, contains('just passing Milestone 3'));
      expect(note, contains('page 120 of 200, 45% progress'));
    });

    test('drops "of total" when page count is unknown', () {
      final note = composer.compose(
        buildActivity(isMine: true, pageCount: null),
      );

      expect(note, contains('page 120, 45% progress'));
      expect(note, isNot(contains('of ')));
    });

    test('drops progress clause when description has no page', () {
      final note = composer.compose(
        buildActivity(isMine: true, targetDescription: 'Milestone 3'),
      );

      expect(note, contains('Just hit Milestone 3 while reading The Hobbit.'));
      expect(note, isNot(contains('now on page')));
    });

    test('falls back to a generic book label when title is missing', () {
      final mine = composer.compose(
        buildActivity(isMine: true, bookCircleTitle: null),
      );
      final theirs = composer.compose(
        buildActivity(isMine: false, bookCircleTitle: null),
      );

      expect(mine, contains('while reading my book'));
      expect(theirs, contains('great progress on their book'));
    });

    test('mention falls back to name when actor npub is not an npub', () {
      final note = composer.compose(
        buildActivity(isMine: false, actorNpub: '', actorName: 'Bob'),
      );

      expect(note, contains('Bob is making great progress'));
      expect(note, isNot(contains('nostr:')));
    });
  });

  group('finished', () {
    test('first-person finished message', () {
      final note = composer.compose(
        buildActivity(isMine: true, targetDescription: 'Finished the book'),
      );

      expect(note, contains('I just finished The Hobbit.'));
      expect(note, contains('Proof-of-Reading = Sats.'));
    });

    test('third-person finished mentions the actor', () {
      final note = composer.compose(
        buildActivity(isMine: false, targetDescription: 'Finished the book'),
      );

      expect(note, contains('nostr:$_npub just finished reading The Hobbit.'));
    });
  });

  group('non-milestone activities', () {
    test('uses a generic template with links', () {
      final note = composer.compose(
        buildActivity(
          isMine: true,
          type: CheersActivityType.zap,
          targetDescription: 'Sent a zap',
        ),
      );

      expect(note, contains('Sent a zap on ZapBook.'));
      expect(note, contains('https://www.zapbook.space'));
      expect(note, contains('#zapbook #reading #nostr'));
    });
  });
}
