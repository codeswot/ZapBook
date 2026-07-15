import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/cheers_activity_type.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';

@injectable
class CheersNoteComposer {
  const CheersNoteComposer();

  static const _site = 'https://www.zapbook.space';
  static const _hashtags = '#zapbook #reading #nostr';

  String compose(CheersActivity activity) {
    final firstPerson = activity.isMine;

    if (activity.type == CheersActivityType.milestone) {
      return _isFinished(activity)
          ? _finished(activity, firstPerson: firstPerson)
          : _milestone(activity, firstPerson: firstPerson);
    }

    return _generic(activity, firstPerson: firstPerson);
  }

  String _milestone(CheersActivity activity, {required bool firstPerson}) {
    final book = _bookLabel(activity, firstPerson: firstPerson);
    final milestone = _milestoneLabel(activity);
    final progress = _progressPhrase(activity);
    final progressSuffix = progress.isEmpty ? '' : ' — now on $progress';

    if (firstPerson) {
      return 'Just hit $milestone while reading $book$progressSuffix. '
          '📖 Track progress and read with friends on ZapBook at $_site.\n'
          '$_hashtags';
    }

    return '${activity.actorName} is making great progress on $book$progressSuffix, '
        'just passing $milestone! see whats it like on ZapBook at $_site.\n'
        '$_hashtags';
  }

  String _finished(CheersActivity activity, {required bool firstPerson}) {
    final book = _bookLabel(activity, firstPerson: firstPerson);

    if (firstPerson) {
      return 'I just finished $book. Proof-of-Reading = Sats. ⚡️\n'
          'try ZapBook out $_site\n'
          '$_hashtags';
    }

    return '${activity.actorName} just finished reading $book. '
        'Proof-of-Reading = Sats. ⚡️ experience it ZapBook out $_site.\n'
        '$_hashtags';
  }

  String _generic(CheersActivity activity, {required bool firstPerson}) {
    final description = activity.targetDescription.trim();

    if (firstPerson) {
      return '$description on ZapBook. Track progress and read with friends '
          'on $_site.\n'
          '$_hashtags';
    }

    return '${activity.actorName}: $description on ZapBook. See what it is '
        'like at $_site.\n'
        '$_hashtags';
  }

  bool _isFinished(CheersActivity activity) =>
      activity.targetDescription.toLowerCase().contains('finished');

  String _bookLabel(CheersActivity activity, {required bool firstPerson}) {
    final title = activity.bookCircleTitle?.trim();
    if (title != null && title.isNotEmpty) return title;
    return firstPerson ? 'my book' : 'their book';
  }

  String _milestoneLabel(CheersActivity activity) {
    final description = activity.targetDescription.trim();
    final colon = description.indexOf(':');
    final label = colon > 0
        ? description.substring(0, colon).trim()
        : description;
    return label.isEmpty ? 'a new milestone' : label;
  }

  String _progressPhrase(CheersActivity activity) {
    final description = activity.targetDescription;
    final page = _firstInt(RegExp(r'page\s+(\d+)').firstMatch(description));
    if (page == null) return '';

    final total = activity.pageCount;
    final percent = _percent(description);

    final buffer = StringBuffer('page $page');
    if (total != null && total > 0) buffer.write(' of $total');
    if (percent != null) buffer.write(', $percent% progress');
    return buffer.toString();
  }

  int? _firstInt(RegExpMatch? match) {
    final group = match?.group(1);
    return group == null ? null : int.tryParse(group);
  }

  int? _percent(String description) {
    final match = RegExp(r'\(([\d.]+)%\)').firstMatch(description);
    final value = match?.group(1);
    if (value == null) return null;
    return double.tryParse(value)?.round();
  }
}
