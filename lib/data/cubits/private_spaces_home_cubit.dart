import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/repositories/private_spaces_repository.dart';

abstract class PrivateSpacesHomeState {}

class PrivateSpacesHomeInitial extends PrivateSpacesHomeState {}

class PrivateSpacesHomeInProgress extends PrivateSpacesHomeState {}

class PrivateSpacesHomeSuccess extends PrivateSpacesHomeState {
  final List<ItemModel> items;

  PrivateSpacesHomeSuccess(this.items);
}

class PrivateSpacesHomeFailure extends PrivateSpacesHomeState {
  final dynamic error;

  PrivateSpacesHomeFailure(this.error);
}

class PrivateSpacesHomeCubit extends Cubit<PrivateSpacesHomeState> {
  PrivateSpacesHomeCubit() : super(PrivateSpacesHomeInitial());
  PrivateSpacesRepository repository = PrivateSpacesRepository();

  Future<void> fetchPrivateSpacesHome() async {
    try {
      emit(PrivateSpacesHomeInProgress());

      final items = await repository.fetchPrivateSpacesHomeItems();
      emit(PrivateSpacesHomeSuccess(items));
    } catch (e) {
      emit(PrivateSpacesHomeFailure(e.toString()));
    }
  }
}
