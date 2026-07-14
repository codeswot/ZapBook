import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/services/contact_service.dart';

@injectable
class FriendsUseCases {
  final ContactService _contacts;

  FriendsUseCases(this._contacts);

  Stream<List<Contact>> get friends => _contacts.friends;
  
  bool isValidNpub(String npub) => _contacts.isValidNpub(npub);
  
  Future<void> add(String npub) => _contacts.add(npub);
  
  Future<void> remove(String npub) => _contacts.remove(npub);
  
  Future<Contact> resolve(String npub) => _contacts.resolve(npub);
}
