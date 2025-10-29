import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/item_filter_model.dart';
import 'package:tlobni/data/model/private_space.dart';
import 'package:tlobni/data/repositories/item/item_repository.dart';
import 'package:tlobni/utils/api.dart';

class PrivateSpacesRepository {
  final itemRepository = ItemRepository();

  Future<List<PrivateSpace>> fetchPrivateSpaces() async {
    final response = await Api.get(url: Api.getPrivateSpaces);
    return (response['data'] as List<dynamic>? ?? []).map((e) => PrivateSpace.fromJson(e)).toList();
  }

  Future<List<ItemModel>> fetchPrivateSpacesHomeItems() async {
    final response = await itemRepository.searchItem(
        '',
        ItemFilterModel(
          privateSpacesOnly: true,
        ),
        page: 0,
        limit: 5);
    return response.modelList;
  }
}
