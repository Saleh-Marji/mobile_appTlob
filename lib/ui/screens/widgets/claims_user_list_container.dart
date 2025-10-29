import 'package:flutter/material.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/data/model/user_model.dart';
import 'package:tlobni/ui/widgets/buttons/regular_button.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';

class ClaimsUserListContainer extends StatelessWidget {
  const ClaimsUserListContainer(this.userModel, {super.key});

  final UserModel userModel;

  double get _borderRadius => 10;

  @override
  Widget build(BuildContext context) {
    return RegularButton(
      disabledColor: Colors.white,
      disabledElevation: 1,
      disabledTextColor: kColorNavyBlue,
      color: Colors.white,
      padding: EdgeInsets.all(10),
      onPressed: null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius), side: BorderSide(color: Color(0xfff3f3f3))),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Builder(builder: (context) {
              double size = 70;
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.color.secondary.withValues(alpha: 0.7), width: 4),
                ),
                height: size,
                width: size,
                child: ClipOval(child: UiUtils.getImage(userModel.profile ?? '', height: size)),
              );
            }),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    // _itemType(),
                    _title(),
                    _description(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title() => HeadingText(
        userModel.name ?? '',
        maxLines: 1,
        fontSize: 20,
      );

  Widget _description() => Row(
        children: [
          Icon(
            Icons.location_on_sharp,
            color: kColorNavyBlue,
          ),
          SizedBox(width: 5),
          DescriptionText(
            userModel.location ?? '',
            color: kColorNavyBlue,
            fontSize: 14,
            maxLines: 2,
          )
        ],
      );
}
