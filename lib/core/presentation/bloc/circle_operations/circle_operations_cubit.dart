import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/domain/usecases/delete_circle_book.dart';
import 'package:zapbook/core/presentation/bloc/circle_operations/circle_operations_state.dart';

@injectable
class CircleOperationsCubit extends Cubit<CircleOperationsState> {
  CircleOperationsCubit(this._deleteCircleBook)
      : super(const CircleOperationsInitial());

  final DeleteCircleBook _deleteCircleBook;

  Future<void> deleteBook(CircleBook book) async {
    try {
      emit(const CircleOperationsLoading());
      await _deleteCircleBook(book);
      emit(const CircleOperationsSuccess());
    } catch (e) {
      emit(CircleOperationsFailure(e.toString()));
    }
  }

  Future<void> leaveCircle(CircleBook book) async {
    // Stub
  }

  Future<void> shareBook(CircleBook book, String memberNpub) async {
    // Stub
  }

  Future<bool> isAdminOf(String circleBookId) async => false;

  Future<String> ownerLabelFor(String circleBookId) async => '';
}
