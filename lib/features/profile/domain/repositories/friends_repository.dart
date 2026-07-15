import 'package:zapbook/core/domain/contact.dart';

abstract class FriendsRepository {
  Stream<List<Contact>> get friends;
  bool isValidNpub(String npub);
  Future<void> add(String npub);
  Future<void> remove(String npub);
  Future<Contact> resolve(String npub);
}
