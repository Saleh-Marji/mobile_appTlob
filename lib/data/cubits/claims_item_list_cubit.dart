import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/repositories/claims_item_list_repository.dart';
import 'package:tlobni/utils/hive_utils.dart';

abstract class ClaimsItemListState {}

class ClaimsItemListInitial extends ClaimsItemListState {}

class ClaimsItemListInProgress extends ClaimsItemListState {}

class ClaimsItemListSuccess extends ClaimsItemListState {
  final int total;
  final int page;
  final String searchQuery;
  final bool isLoadingMore;
  final bool hasMore;
  final List<ItemModel> items;
  final bool hasError;

  ClaimsItemListSuccess({
    required this.total,
    required this.page,
    required this.searchQuery,
    required this.isLoadingMore,
    required this.hasMore,
    required this.items,
    required this.hasError,
  });

  ClaimsItemListSuccess copyWith({
    int? total,
    int? page,
    String? searchQuery,
    bool? isLoadingMore,
    bool? hasMore,
    List<ItemModel>? searchedItems,
    bool? hasError,
  }) {
    return ClaimsItemListSuccess(
      total: total ?? this.total,
      page: page ?? this.page,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      items: searchedItems ?? this.items,
      hasError: hasError ?? this.hasError,
    );
  }
}

class ClaimsItemListFailure extends ClaimsItemListState {
  final dynamic error;

  ClaimsItemListFailure(this.error);
}

class ClaimsItemListCubit extends Cubit<ClaimsItemListState> {
  ClaimsItemListCubit() : super(ClaimsItemListInitial());
  ClaimsItemListRepository repository = ClaimsItemListRepository();

  bool get isProvider => HiveUtils.isProvider();

  Future<DataOutput<ItemModel>> getItemsPage(String searchQuery, int page) {
    if (isProvider) {
      return repository.fetchMyItemsClaimedByOthers(searchQuery, page);
    } else {
      return repository.fetchItemsClaimedByMe(searchQuery, page);
    }
  }

  Future<void> fetchItems(String searchQuery) async {
    try {
      emit(ClaimsItemListInProgress());
      DataOutput<ItemModel> result = await getItemsPage(searchQuery, 1);
      emit(ClaimsItemListSuccess(
        isLoadingMore: false,
        page: 1,
        items: result.modelList,
        total: result.total,
        hasMore: (result.modelList.length < result.total),
        searchQuery: searchQuery,
        hasError: false,
      ));
    } catch (e) {
      emit(ClaimsItemListFailure(e.toString()));
    }
  }

  Future<void> fetchMoreItems() async {
    try {
      if (state is ClaimsItemListSuccess) {
        if ((state as ClaimsItemListSuccess).isLoadingMore) {
          return;
        }
        emit((state as ClaimsItemListSuccess).copyWith(isLoadingMore: true));

        DataOutput<ItemModel> result = await getItemsPage(
          (state as ClaimsItemListSuccess).searchQuery,
          (state as ClaimsItemListSuccess).page + 1,
        );

        ClaimsItemListSuccess myItemsState = (state as ClaimsItemListSuccess);
        myItemsState.items.addAll(result.modelList);
        emit(ClaimsItemListSuccess(
          isLoadingMore: false,
          page: result.page ?? ((state as ClaimsItemListSuccess).page + 1),
          items: result.modelList,
          total: result.total,
          hasMore: (result.modelList.length < result.total),
          searchQuery: (state as ClaimsItemListSuccess).searchQuery,
          hasError: false,
        ));
      }
    } catch (e) {
      emit(
        (state as ClaimsItemListSuccess).copyWith(
          isLoadingMore: false,
          hasError: true,
        ),
      );
    }
  }

  bool hasMoreData() {
    if (state is ClaimsItemListSuccess) {
      return (state as ClaimsItemListSuccess).items.length < (state as ClaimsItemListSuccess).total;
    }
    return false;
  }
}
