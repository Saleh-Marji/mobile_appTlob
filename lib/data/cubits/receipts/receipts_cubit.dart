import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/model/receipt_model.dart';
import 'package:tlobni/data/repositories/receipts_repository.dart';

abstract class ReceiptsState {}

class ReceiptsInitial extends ReceiptsState {}

class ReceiptsFetchInProgress extends ReceiptsState {}

class ReceiptsFetchSuccess extends ReceiptsState {
  final List<ReceiptModel> receipts;
  final bool isLoadingMore;
  final int totalReceiptsCount;
  final bool hasMoreFetchError;
  final bool hasMore;
  final int page;

  ReceiptsFetchSuccess({
    required this.receipts,
    required this.isLoadingMore,
    required this.totalReceiptsCount,
    required this.hasMoreFetchError,
    required this.page,
    required this.hasMore,
  });

  ReceiptsFetchSuccess copyWith({
    List<ReceiptModel>? receipts,
    bool? isLoadingMore,
    int? totalReceiptsCount,
    bool? hasMoreFetchError,
    bool? hasMore,
    int? page,
  }) {
    return ReceiptsFetchSuccess(
      receipts: receipts ?? this.receipts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      hasMoreFetchError: hasMoreFetchError ?? this.hasMoreFetchError,
      totalReceiptsCount: totalReceiptsCount ?? this.totalReceiptsCount,
    );
  }
}

class ReceiptsFetchFailure extends ReceiptsState {
  final dynamic errorMessage;

  ReceiptsFetchFailure(this.errorMessage);
}

class ReceiptsCubit extends Cubit<ReceiptsState> {
  final ReceiptsRepository receiptsRepository;

  ReceiptsCubit(this.receiptsRepository) : super(ReceiptsInitial());

  void getReceipts() async {
    try {
      emit(ReceiptsFetchInProgress());
      final result = await receiptsRepository.fetchReceipts(page: 1);

      emit(ReceiptsFetchSuccess(
        receipts: result.modelList,
        totalReceiptsCount: result.total,
        hasMoreFetchError: false,
        page: 1,
        isLoadingMore: false,
        hasMore: (result.modelList.length < result.total),
      ));
    } catch (e) {
      if (e.toString() == "No Data Found") {
        // In case of 0 receipts - make it success for fresh users
        emit(ReceiptsFetchSuccess(
          receipts: [],
          isLoadingMore: false,
          totalReceiptsCount: 0,
          page: 1,
          hasMoreFetchError: false,
          hasMore: false,
        ));
      } else {
        // When there's an API error or auth error, return empty receipts list
        emit(ReceiptsFetchSuccess(
          receipts: [],
          isLoadingMore: false,
          totalReceiptsCount: 0,
          page: 1,
          hasMoreFetchError: false,
          hasMore: false,
        ));
      }
    }
  }

  bool hasMoreReceipts() {
    return (state is ReceiptsFetchSuccess)
        ? (state as ReceiptsFetchSuccess).hasMore
        : false;
  }

  void getMoreReceipts() async {
    if (state is ReceiptsFetchSuccess) {
      try {
        if ((state as ReceiptsFetchSuccess).isLoadingMore) {
          return;
        }
        emit((state as ReceiptsFetchSuccess).copyWith(isLoadingMore: true));
        final result = await receiptsRepository.fetchReceipts(
            page: (state as ReceiptsFetchSuccess).page + 1);
        List<ReceiptModel> updatedResults =
            (state as ReceiptsFetchSuccess).receipts;
        updatedResults.addAll(result.modelList);
        emit(ReceiptsFetchSuccess(
          isLoadingMore: false,
          receipts: updatedResults,
          totalReceiptsCount: result.total,
          hasMoreFetchError: false,
          page: (state as ReceiptsFetchSuccess).page + 1,
          hasMore: updatedResults.length < result.total,
        ));
      } catch (e) {
        emit(ReceiptsFetchSuccess(
          isLoadingMore: false,
          receipts: (state as ReceiptsFetchSuccess).receipts,
          hasMoreFetchError: (e.toString() == "No Data Found") ? false : true,
          page: (state as ReceiptsFetchSuccess).page + 1,
          totalReceiptsCount: (state as ReceiptsFetchSuccess).totalReceiptsCount,
          hasMore: (state as ReceiptsFetchSuccess).hasMore,
        ));
      }
    }
  }

  void resetState() {
    emit(ReceiptsFetchInProgress());
  }
}
