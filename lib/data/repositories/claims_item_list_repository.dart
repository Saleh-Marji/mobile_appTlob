import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/item_filter_model.dart';
import 'package:tlobni/data/model/user_model.dart';
import 'package:tlobni/data/repositories/item/item_repository.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/models/post_type.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/hive_utils.dart';

class ClaimsItemListRepository {
  final _itemRepository = ItemRepository();

  Future<DataOutput<ItemModel>> fetchItemsClaimedByMe(String searchQuery, int page) async {
    return _itemRepository.searchItem(
        searchQuery,
        ItemFilterModel(
          claimedByMe: true,
          serviceType: PostType.experience.name,
        ),
        page: page);
  }

  Future<DataOutput<ItemModel>> fetchMyItemsClaimedByOthers(String searchQuery, int page) async {
    return _itemRepository.searchItem(
        searchQuery,
        ItemFilterModel(
          havingAtLeastOneClaim: true,
          userId: HiveUtils.getUserIdInt(),
          serviceType: PostType.experience.name,
        ),
        page: page);
  }

  Future<List<UserModel>> fetchUsersThatClaimedItem(int itemId) async {
    final response = await Api.get(url: Api.usersThatClaimedItem, queryParameters: {'item_id': itemId});
    return (response['data'] as List<dynamic>? ?? []).map((e) => UserModel.fromJson(e)).toList();
  }
}
