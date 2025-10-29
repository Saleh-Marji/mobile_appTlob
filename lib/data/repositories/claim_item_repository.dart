import 'package:tlobni/utils/api.dart';

class ClaimItemRepository {
  Future<bool> hasClaimedItem(int id) async {
    final response = await Api.get(url: Api.checkIfClaimed, queryParameters: {'item_id': id});
    return response['data'];
  }

  Future<bool> claimItem(int id) async {
    final response = await Api.post(url: Api.claimItem, parameter: {
      'item_id': id,
    });
    return true;
  }
}
