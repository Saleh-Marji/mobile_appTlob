import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/repositories/user/user_repository.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/hive_utils.dart';

abstract class CurrentUserProfileState {}

class CurrentUserProfileInitial extends CurrentUserProfileState {}

class CurrentUserProfileFetchProgress extends CurrentUserProfileState {}

class CurrentUserProfileProgress extends CurrentUserProfileState {}

class CurrentUserProfileSuccess extends CurrentUserProfileState {
  User user;

  CurrentUserProfileSuccess({required this.user});
}

class CurrentUserProfileFailure extends CurrentUserProfileState {
  final String errorMessage;

  CurrentUserProfileFailure(this.errorMessage);
}

class CurrentUserProfileCubit extends Cubit<CurrentUserProfileState> {
  CurrentUserProfileCubit() : super(CurrentUserProfileInitial());

  final UserRepository _userRepository = UserRepository();

  Future<void> fetchCurrentUser() async {
    if (state is CurrentUserProfileFetchProgress) return;
    try {
      String? userId = HiveUtils.getUserId();
      if (userId == null) throw 'User not logged in';
      emit(CurrentUserProfileFetchProgress());
      User result = await _userRepository.fetchProvider(int.parse(userId));

      emit(CurrentUserProfileSuccess(user: result));
    } catch (e, s) {
      print(e.toString());
      print(s);
      emit(CurrentUserProfileFailure(e.toString()));
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? email,
    File? fileUserimg,
    String? fcmToken,
    String? notification,
    String? mobile,
    String? countryCode,
    String? country,
    String? city,
    String? state,
    String? categories,
    String? bio,
    String? facebook,
    String? twitter,
    String? instagram,
    String? tiktok,
    String? gender,
    int? personalDetail,
  }) async {
    emit(CurrentUserProfileFetchProgress());
    Map<String, dynamic> parameters = {
      Api.name: name ?? '',
      Api.email: email ?? '',
      Api.fcmId: fcmToken ?? '',
      Api.notification: notification,
      Api.mobile: mobile,
      Api.city: city,
      Api.country: country,
      Api.state: state,
      Api.countryCode: countryCode,
      Api.personalDetail: personalDetail,
      Api.country: country ?? '',
      'gender': gender ?? '',
      'categories': categories ?? '',
      'bio': bio ?? '',
      'facebook': facebook ?? '',
      'twitter': twitter ?? '',
      'instagram': instagram ?? '',
      'tiktok': tiktok ?? '',
    };
    if (fileUserimg != null) {
      parameters['profile'] = await MultipartFile.fromFile(fileUserimg.path);
    }

    try {
      var response = await Api.post(url: Api.updateProfileApi, parameter: parameters);
      if (!response[Api.error]) {
        HiveUtils.setUserData(response['data']);
        //checkIsAuthenticated();
      }

      emit(CurrentUserProfileSuccess(user: User.fromJson(response['data'])));
    } catch (e, s) {
      print(e.toString());
      print(s);
      emit(CurrentUserProfileFailure(e.toString()));
    }
  }
}
