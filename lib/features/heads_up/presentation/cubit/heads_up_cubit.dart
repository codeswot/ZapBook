import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/heads_up_message.dart';

@lazySingleton
class HeadsUpCubit extends Cubit<List<HeadsUpMessage>> {
  HeadsUpCubit() : super(const []);

  void showBanner(HeadsUpMessage message) {
    final updatedList = List<HeadsUpMessage>.from(state);
    final existingIndex = updatedList.indexWhere((m) => m.id == message.id);
    if (existingIndex != -1) {
      updatedList[existingIndex] = message;
    } else {
      updatedList.add(message);
    }
    emit(updatedList);
  }

  void dismissBanner(String id) {
    final updatedList = List<HeadsUpMessage>.from(state);
    updatedList.removeWhere((m) => m.id == id);
    emit(updatedList);
  }

  void clearAll() {
    emit(const []);
  }
}
