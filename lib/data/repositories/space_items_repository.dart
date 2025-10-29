import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/hive_utils.dart';

class SpaceItemsRepository {
  Future<List<ItemModel>> fetchSpaceTopNItems({required int spaceId, required int limit}) async {
    Map<String, dynamic> parameters = {
      "limit": limit,
      'offset': 0,
      'organization_id': spaceId,
      'my_email': HiveUtils.getUserDetails().email,
      'my_id': HiveUtils.getUserIdInt(),
      if (HiveUtils.getCityName() != null) 'city': HiveUtils.getCityName(),
      if (HiveUtils.getAreaId() != null) 'area_id': HiveUtils.getAreaId(),
      if (HiveUtils.getCountryName() != null) 'country': HiveUtils.getCountryName(),
      if (HiveUtils.getStateName() != null) 'state': HiveUtils.getStateName(),
    };

    return await Api.get(url: Api.getItemApi, queryParameters: parameters).then((response) {
      if (!response[Api.error] && response['data'] != null) {
        List<ItemModel> items = [];
        if (response['data'] is List) {
          items = (response['data'] as List).map((e) => ItemModel.fromJson(e)).toList();
        } else if (response['data']['data'] is List) {
          items = (response['data']['data'] as List).map((e) => ItemModel.fromJson(e)).toList();
        } else if (response['data']['items'] is List) {
          items = (response['data']['items'] as List).map((e) => ItemModel.fromJson(e)).toList();
        }
        return items;
      }
      throw ApiException(response.toString());
    });
  }
}
