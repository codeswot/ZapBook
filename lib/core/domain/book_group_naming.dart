final class BookGroupNaming {
  const BookGroupNaming._();

  static const prefix = 'zapbook-circle-';
  static const legacyPrefix = 'zapbook-book-';

  static String nameFor(String circleDirId, String title) =>
      '$prefix$circleDirId:$title';

  static bool matches(String groupName) =>
      groupName.startsWith(prefix) || groupName.startsWith(legacyPrefix);

  static String legacyNameFor(String circleBookId) =>
      '$legacyPrefix$circleBookId';

  static String circleBookIdOf(String groupName) => circleDirIdOf(groupName);

  static String circleDirIdOf(String groupName) {
    if (groupName.startsWith(prefix)) {
      final withoutPrefix = groupName.substring(prefix.length);
      final colonIndex = withoutPrefix.indexOf(':');
      if (colonIndex != -1) {
        return withoutPrefix.substring(0, colonIndex);
      }
      return withoutPrefix;
    } else {
      return groupName.substring(legacyPrefix.length);
    }
  }

  static String titleOf(String groupName) {
    if (groupName.startsWith(prefix)) {
      final withoutPrefix = groupName.substring(prefix.length);
      final colonIndex = withoutPrefix.indexOf(':');
      if (colonIndex != -1) {
        return withoutPrefix.substring(colonIndex + 1);
      }
    }
    return 'Untitled';
  }
}
