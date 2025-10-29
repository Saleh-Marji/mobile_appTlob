import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/private_space.dart';
import 'package:tlobni/data/repositories/space_items_repository.dart';

abstract class SpaceItemsState {}

class SpaceItemsInitial extends SpaceItemsState {}

class SpaceItemsInProgress extends SpaceItemsState {}

class SpaceItemsSuccess extends SpaceItemsState {
  List<ItemModel> items;

  SpaceItemsSuccess(this.items);
}

class SpaceItemsFailure extends SpaceItemsState {
  final dynamic error;

  SpaceItemsFailure(this.error);
}

class SpaceItemsCubit extends Cubit<SpaceItemsState> {
  SpaceItemsCubit(this.space) : super(SpaceItemsInitial()) {
    fetchItems();
  }

  final PrivateSpace space;

  SpaceItemsRepository repository = SpaceItemsRepository();

  void fetchItems() async {
    try {
      emit(SpaceItemsInProgress());
      final items = await repository.fetchSpaceTopNItems(spaceId: space.id, limit: 5);
      emit(SpaceItemsSuccess(items));
    } catch (e) {
      emit(SpaceItemsFailure(e));
    }
  }
}
