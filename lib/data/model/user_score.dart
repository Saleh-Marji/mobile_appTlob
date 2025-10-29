enum UserScoreType {
  growth,
  impact;

  @override
  String toString() => name;

  String toJson() => name;

  String toLettersString() => switch (this) {
        growth => 'GS',
        impact => 'IS',
      };

  static UserScoreType? fromString(String? json) {
    for (var value in values) {
      if (value.name == json) {
        return value;
      }
    }
    return null;
  }
}

class UserScore {
  int score;
  UserScoreType? type;

  UserScore({
    required this.score,
    required this.type,
  });
}
