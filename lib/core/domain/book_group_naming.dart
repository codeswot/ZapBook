final class BookGroupNaming {
  const BookGroupNaming._();

  static const prefix = 'zapbook-book-';

  static String nameFor(String bookId) => '$prefix$bookId';

  static bool matches(String groupName) => groupName.startsWith(prefix);

  static String bookIdOf(String groupName) =>
      groupName.replaceFirst(prefix, '');
}
