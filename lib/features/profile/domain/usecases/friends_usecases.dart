import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/features/profile/domain/repositories/friends_repository.dart';

@injectable
class FriendsUseCases {
  final FriendsRepository _repository;

  FriendsUseCases(this._repository);

  Stream<List<Contact>> get friends => _repository.friends;

  bool isValidNpub(String npub) => _repository.isValidNpub(npub);

  Future<void> add(String npub) => _repository.add(npub);

  Future<void> remove(String npub) => _repository.remove(npub);

  Future<Contact> resolve(String npub) => _repository.resolve(npub);
}
