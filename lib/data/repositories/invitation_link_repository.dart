import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/utils/api.dart';

class InvitationLinkRepository {
  Future<String> invite(String email, ItemAudience type) async {
    final response = await Api.post(url: Api.linkUser, parameter: {
      'email': email,
      'type': type.name,
    });
    return response['data'];
  }
}
