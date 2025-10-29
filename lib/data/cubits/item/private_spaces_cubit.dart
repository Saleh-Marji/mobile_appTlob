import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/cubits/item/space_items_cubit.dart';
import 'package:tlobni/data/model/private_space.dart';
import 'package:tlobni/data/repositories/private_spaces_repository.dart';

abstract class PrivateSpacesState {}

class PrivateSpacesInitial extends PrivateSpacesState {}

class PrivateSpacesInProgress extends PrivateSpacesState {}

class PrivateSpacesSuccess extends PrivateSpacesState {
  final List<PrivateSpace> spaces;
  final Map<int, SpaceItemsCubit> spacesCubits;

  PrivateSpacesSuccess(this.spaces, this.spacesCubits);
}

class PrivateSpacesFailure extends PrivateSpacesState {
  final dynamic error;

  PrivateSpacesFailure(this.error);
}

class PrivateSpacesCubit extends Cubit<PrivateSpacesState> {
  PrivateSpacesCubit() : super(PrivateSpacesInitial());
  PrivateSpacesRepository repository = PrivateSpacesRepository();

  Future<void> fetchPrivateSpaces() async {
    try {
      emit(PrivateSpacesInProgress());

      final spaces = await repository.fetchPrivateSpaces();
      emit(PrivateSpacesSuccess(spaces, spaces.asMap().map((key, value) => MapEntry(value.id, SpaceItemsCubit(value)))));
    } catch (e) {
      emit(PrivateSpacesFailure(e.toString()));
    }
  }
}
