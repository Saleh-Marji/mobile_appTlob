import 'package:tlobni/data/helper/custom_exception.dart';
import 'package:tlobni/settings.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ProfileSettingState {}

//String? profileSettingData = '';

class ProfileSettingInitial extends ProfileSettingState {}

class ProfileSettingFetchProgress extends ProfileSettingState {}

class ProfileSettingFetchSuccess extends ProfileSettingState {
  String data;
  ProfileSettingFetchSuccess({required this.data});

  Map<String, dynamic> toMap() {
    return {
      'data': data,
    };
  }

  factory ProfileSettingFetchSuccess.fromMap(Map<String, dynamic> map) {
    return ProfileSettingFetchSuccess(
      data: map['data'] as String,
    );
  }
}

class ProfileSettingFetchFailure extends ProfileSettingState {
  final String errmsg;
  ProfileSettingFetchFailure(this.errmsg);
}

class ProfileSettingCubit extends Cubit<ProfileSettingState> {
  ProfileSettingCubit() : super(ProfileSettingInitial());

  void fetchProfileSetting(BuildContext context, String title,
      {bool? forceRefresh}) async {
    if (forceRefresh != true) {
      if (state is ProfileSettingFetchSuccess) {
        await Future.delayed(
            const Duration(seconds: AppSettings.hiddenAPIProcessDelay));
      } else {
        emit(ProfileSettingFetchProgress());
      }
    } else {
      emit(ProfileSettingFetchProgress());
    }

    if (forceRefresh == true) {
      fetchProfileSettingFromDb(context, title).then((value) {
        emit(ProfileSettingFetchSuccess(data: value ?? ""));
      }).catchError((e, stack) {
        emit(ProfileSettingFetchFailure(stack.toString()));
      });
    } else {
      if (state is! ProfileSettingFetchSuccess) {
        fetchProfileSettingFromDb(context, title).then((value) {
          emit(ProfileSettingFetchSuccess(data: value ?? ""));
        }).catchError((e, stack) {
          emit(ProfileSettingFetchFailure(stack.toString()));
        });
      } else {
        emit(
          ProfileSettingFetchSuccess(
            data: (state as ProfileSettingFetchSuccess).data,
          ),
        );
      }
    }
  }

  Future<String?> fetchProfileSettingFromDb(
      BuildContext context, String title) async {
    try {
      String? profileSettingData;
      Map<String, String> body = {
        Api.type: title,
      };

      var response = await Api.get(
        url: Api.getSystemSettingsApi,
        queryParameters: body,
      );

      if (!response[Api.error]) {
        /*if (title == Api.currencySymbol) {
          // Constant.currencySymbol = getdata['data'].toString();
        } else*/
        if (title == Api.maintenanceMode) {
          Constant.maintenanceMode = response['data'].toString();
        } else {
          Map data = (response['data']);

          if (title == Api.termsAndConditions) {
            profileSettingData = data['terms_conditions'];
            // .where((element) => element['type'] == "terms_conditions")
            // .first['data'];
          }

          if (title == Api.privacyPolicy) {
            profileSettingData = data['privacy_policy'];
            // .where((element) => element['type'] == "privacy_policy")
            // .first['data'];
          }

          if (title == Api.aboutUs) {
            profileSettingData = data['about_us'];
            // .where((element) => element['type'] == "about_us")
            // .first['data'];
          }
        }
      } else {
        throw CustomException(response[Api.message]);
      }

      return profileSettingData;
    } catch (e) {
      rethrow;
    }
  }

/*  @override
  ProfileSettingState? fromJson(Map<String, dynamic> json) {
    try {
      if (json['cubit_state'] == "ProfileSettingFetchSuccess") {
        ProfileSettingFetchSuccess profileSettingFetchSuccess =
            ProfileSettingFetchSuccess.fromMap(json);

        return profileSettingFetchSuccess;
      }
    } catch (e) {

    }
    return null;
  }

  @override
  Map<String, dynamic>? toJson(ProfileSettingState state) {
    try {
      if (state is ProfileSettingFetchSuccess) {
        Map<String, dynamic> mapped = state.toMap();
        mapped['cubit_state'] = "ProfileSettingFetchSuccess";
        return mapped;
      }
    } catch (e) {

    }

    return null;
  }*/
}
