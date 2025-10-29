import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/receipt_model.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/hive_utils.dart';

class ReceiptsRepository {
  Future<DataOutput<ReceiptModel>> fetchReceipts({required int page}) async {
    // Check if user is authenticated before making the API call
    if (!HiveUtils.isUserAuthenticated()) {
      // Return empty result for unauthenticated users
      return DataOutput<ReceiptModel>(
        total: 0,
        modelList: [],
      );
    }

    Map<String, dynamic> parameters = {
      Api.page: page,
    };

    Map<String, dynamic> response = await Api.get(
      url: Api.getUserReceiptsApi,
      queryParameters: parameters,
      useBaseUrl: true,
    );

    List<ReceiptModel> modelList = (response['data']['data'] as List)
        .map((e) => ReceiptModel.fromJson(e))
        .toList();

    return DataOutput<ReceiptModel>(
      total: response['data']['total'] ?? 0,
      modelList: modelList,
    );
  }
}
