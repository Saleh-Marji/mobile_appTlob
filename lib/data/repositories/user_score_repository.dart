import 'package:tlobni/data/model/user_score.dart';
import 'package:tlobni/utils/api.dart';

class UserScoreRepository {
  Future<UserScore> fetchUserScore() async {
    Map response = await Api.get(url: Api.getUserScoreApi);
    final data = response['data'];
    return UserScore(score: data['score'], type: UserScoreType.fromString(data['type']));
  }
}
