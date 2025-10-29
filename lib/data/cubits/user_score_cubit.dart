import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/model/user_score.dart';
import 'package:tlobni/data/repositories/user_score_repository.dart';
import 'package:tlobni/utils/hive_utils.dart';

abstract class UserScoreState {}

class UserScoreInitial extends UserScoreState {}

class UserScoreInProgress extends UserScoreState {}

class UserScoreSuccess extends UserScoreState {
  final UserScore userScore;

  UserScoreSuccess({required this.userScore});

  UserScoreSuccess copyWith({UserScore? userScore}) {
    return UserScoreSuccess(userScore: userScore ?? this.userScore);
  }
}

class UserScoreFailure extends UserScoreState {
  final dynamic errorMessage;

  UserScoreFailure(this.errorMessage);
}

class UserScoreCubit extends Cubit<UserScoreState> {
  UserScoreCubit() : super(UserScoreInitial()) {
    initializeTimer();
  }

  final UserScoreRepository _repository = UserScoreRepository();

  UserScore? _previousUserScore;

  Timer? _timer;

  Future<void> fetchScore() async {
    try {
      if (!HiveUtils.isUserAuthenticated()) {
        emit(UserScoreInitial());
        return;
      }
      emit(UserScoreInProgress());

      UserScore result = await _repository.fetchUserScore();

      _previousUserScore = result;

      emit(
        UserScoreSuccess(userScore: result),
      );
    } catch (e) {
      emit(UserScoreFailure(e));
    }
  }

  UserScore? get score => state is UserScoreSuccess ? (state as UserScoreSuccess).userScore : _previousUserScore;

  void initializeTimer() {
    _timer = Timer.periodic(Duration(seconds: 5), (_) {
      fetchScore();
    });
  }
}
