import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/data/infrastructure/contact_service.dart';
import 'package:zapbook/features/profile/domain/repositories/friends_repository.dart';

@Injectable(as: FriendsRepository)
class FriendsRepositoryImpl implements FriendsRepository {
  final ContactService _contacts;

  FriendsRepositoryImpl(this._contacts);

  @override
  Stream<List<Contact>> get friends => _contacts.friends;

  @override
  bool isValidNpub(String npub) => _contacts.isValidNpub(npub);

  @override
  Future<void> add(String npub) => _contacts.add(npub);

  @override
  Future<void> remove(String npub) => _contacts.remove(npub);

  @override
  Future<Contact> resolve(String npub) => _contacts.resolve(npub);
}
