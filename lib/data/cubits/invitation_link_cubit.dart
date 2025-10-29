import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/repositories/invitation_link_repository.dart';
import 'package:tlobni/utils/helper_utils.dart';

abstract class InvitationLinkState {}

class InvitationLinkInitial extends InvitationLinkState {}

class InvitationLinkInProgress extends InvitationLinkState {}

class InvitationLinkSuccess extends InvitationLinkState {
  String email;
  String link;

  InvitationLinkSuccess(this.link, this.email);
}

class InvitationLinkFailure extends InvitationLinkState {
  final dynamic error;

  InvitationLinkFailure(this.error);
}

class InvitationLinkCubit extends Cubit<InvitationLinkState> {
  InvitationLinkCubit() : super(InvitationLinkInitial());
  InvitationLinkRepository repository = InvitationLinkRepository();

  void onRefresh() {
    emit(InvitationLinkInitial());
  }

  Future<void> invite(String email, ItemAudience type) async {
    try {
      if (type == ItemAudience.public) return;
      emit(InvitationLinkInProgress());

      final url = await repository.invite(email, type);
      emit(InvitationLinkSuccess(url, email));
    } catch (e) {
      emit(InvitationLinkFailure(e));
    }
  }

  void copyLink(BuildContext context) {
    final link = _getLink();
    if (link == null) return;
    Clipboard.setData(ClipboardData(text: link));
    HelperUtils.showSnackBarMessage(context, 'Copied link successfully!');
  }

  void shareLink() async {
    var link = _getLink();
    if (link == null) link = 'demo url';
    await Share.share(link, subject: 'Invitation Link To Tlobni: Be More');
  }

  String? _getLink() {
    if (state is InvitationLinkSuccess) return (state as InvitationLinkSuccess).link;
    return null;
  }
}
