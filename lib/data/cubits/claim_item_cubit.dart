import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/repositories/claim_item_repository.dart';

abstract class ClaimItemState {}

class ClaimItemInitial extends ClaimItemState {}

class ClaimItemInProgress extends ClaimItemState {}

class ClaimItemSuccess extends ClaimItemState {
  bool claimedItem;

  ClaimItemSuccess(this.claimedItem);
}

class ClaimItemFailure extends ClaimItemState {
  final dynamic error;

  ClaimItemFailure(this.error);
}

class ClaimItemCubit extends Cubit<ClaimItemState> {
  ClaimItemCubit() : super(ClaimItemInitial());
  ClaimItemRepository repository = ClaimItemRepository();

  void loadClaimed(int id) async {
    try {
      emit(ClaimItemInProgress());

      final claimed = await repository.hasClaimedItem(id);
      emit(ClaimItemSuccess(claimed));
    } catch (e) {
      emit(ClaimItemFailure(e.toString()));
    }
  }

  Future<void> claimItem(int id) async {
    try {
      emit(ClaimItemInProgress());

      final claimed = await repository.claimItem(id);
      emit(ClaimItemSuccess(claimed));
    } catch (e) {
      loadClaimed(id);
    }
  }
}
