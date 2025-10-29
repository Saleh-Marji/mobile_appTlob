import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/model/user_model.dart';
import 'package:tlobni/data/repositories/claims_item_list_repository.dart';

abstract class UsersThatClaimedItemState {}

class UsersThatClaimedItemInitial extends UsersThatClaimedItemState {}

class UsersThatClaimedItemInProgress extends UsersThatClaimedItemState {}

class UsersThatClaimedItemSuccess extends UsersThatClaimedItemState {
  final List<UserModel> users;

  UsersThatClaimedItemSuccess(this.users);
}

class UsersThatClaimedItemFailure extends UsersThatClaimedItemState {
  final dynamic error;

  UsersThatClaimedItemFailure(this.error);
}

class UsersThatClaimedItemCubit extends Cubit<UsersThatClaimedItemState> {
  UsersThatClaimedItemCubit() : super(UsersThatClaimedItemInitial());
  ClaimsItemListRepository repository = ClaimsItemListRepository();

  void fetchUsers({required int itemId}) async {
    try {
      emit(UsersThatClaimedItemInProgress());
      List<UserModel> users = await repository.fetchUsersThatClaimedItem(itemId);
      emit(UsersThatClaimedItemSuccess(users));
    } catch (e, s) {
      emit(UsersThatClaimedItemFailure(e.toString()));
    }
  }
}
