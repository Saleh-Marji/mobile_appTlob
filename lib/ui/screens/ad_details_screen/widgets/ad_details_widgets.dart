import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/buttons/unelevated_regular_button.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';

class AdDetailsWidgets {
  static Widget buildDot(int currentPage, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3.0),
      width: currentPage == index ? 12.0 : 8.0,
      height: 8.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: currentPage == index ? Colors.white : Colors.grey,
      ),
    );
  }

  static Widget buildTopRowItem({
    required AlignmentDirectional alignment,
    required double marginVal,
    required double cornerRadius,
    required Color? backgroundColor,
    required Widget child,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: EdgeInsets.all(marginVal),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cornerRadius),
          color: backgroundColor,
        ),
        child: child,
      ),
    );
  }

  static Widget buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required BuildContext context,
  }) {
    return UnelevatedRegularButton(
      onPressed: onPressed,
      shape: CircleBorder(),
      padding: EdgeInsets.all(10),
      color: context.color.primary,
      child: Icon(icon, color: context.color.onPrimary, size: 30),
    );
  }

  static Widget buildIconAndText({
    required IconData icon,
    required String text,
    double? iconSize,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        SizedBox(width: 5),
        Flexible(child: SmallText(text)),
      ],
    );
  }

  static Widget buildDivider() => const Divider(height: 1.5, thickness: 0.8);

  static Widget buildElevatedContainer({
    required Widget child,
    double borderRadius = 10,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.white,
        boxShadow: kElevationToShadow[2],
      ),
      child: child,
    );
  }

  static Widget buildLocationDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: SmallText(
            label,
            color: Colors.grey[600],
            weight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: SmallText(
            value,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  static Widget buildLimitedExperienceItem({
    required IconData icon,
    required String title,
    required String content,
    required BuildContext context,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xffeff0f2),
          ),
          child: Icon(icon, size: 30, color: context.color.primary),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SmallText(title, color: Colors.grey, fontSize: 14),
              SizedBox(height: 5),
              DescriptionText(content, fontSize: 16),
            ],
          ),
        )
      ],
    );
  }

  static Widget buildIconButton({
    required String assetName,
    required VoidCallback onTap,
    required BuildContext context,
    Color? color,
    double? height,
    double? width,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.color.borderColor.darken(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: InkWell(
          onTap: onTap,
          child: SvgPicture.asset(
            assetName,
            colorFilter:
                color == null ? ColorFilter.mode(context.color.territoryColor, BlendMode.srcIn) : ColorFilter.mode(color, BlendMode.srcIn),
            height: height,
            width: width,
          ),
        ),
      ),
    );
  }

  static Widget buildStatusContainer({
    required String status,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _getStatusColor(status, context),
      ),
      child: CustomText(
        _getStatusCustomText(status, context)!,
        fontSize: context.font.normal,
        color: _getStatusTextColor(status, context),
      ),
    );
  }

  static String? _getStatusCustomText(String? status, BuildContext context) {
    switch (status) {
      case "review":
        return "underReview".translate(context);
      case "active":
        return "active".translate(context);
      case "approved":
        return "approved".translate(context);
      case "inactive":
        return "deactivate".translate(context);
      case "sold out":
        return "soldOut".translate(context);
      case "rejected":
        return "rejected".translate(context);
      case "expired":
        return "expired".translate(context);
      default:
        return status;
    }
  }

  static Color _getStatusColor(String? status, BuildContext context) {
    switch (status) {
      case "review":
        return pendingButtonColor.withOpacity(0.1);
      case "active" || "approved":
        return activateButtonColor.withOpacity(0.1);
      case "inactive":
        return deactivateButtonColor.withOpacity(0.1);
      case "sold out":
        return soldOutButtonColor.withOpacity(0.1);
      case "rejected":
        return deactivateButtonColor.withOpacity(0.1);
      case "expired":
        return deactivateButtonColor.withOpacity(0.1);
      default:
        return context.color.territoryColor.withOpacity(0.1);
    }
  }

  static Color _getStatusTextColor(String? status, BuildContext context) {
    switch (status) {
      case "review":
        return pendingButtonColor;
      case "active" || "approved":
        return activateButtonColor;
      case "inactive":
        return deactivateButtonColor;
      case "sold out":
        return soldOutButtonColor;
      case "rejected":
        return deactivateButtonColor;
      case "expired":
        return deactivateButtonColor;
      default:
        return context.color.territoryColor;
    }
  }

  static Widget buildForACauseSection({
    required String forACauseText,
    required BuildContext context,
  }) {
    final greenColor = Color(0xff2d8959);
    return Container(
      decoration: BoxDecoration(
        color: Color(0xffe5efea),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 6,
            children: [
              Icon(
                Icons.favorite,
                color: greenColor,
                size: 20,
              ),
              Expanded(
                child: HeadingText(
                  'For a Cause',
                  color: greenColor,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          SmallText(
            forACauseText,
            color: greenColor,
          ),
        ],
      ),
    );
  }

  static Widget buildItemDetailsSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeadingText(title, fontSize: 18, weight: FontWeight.bold),
        SizedBox(height: 10),
        child,
      ],
    );
  }

  static Widget buildCoordinatesDisplay({
    required String? city,
    required String? country,
    VoidCallback? onViewOnMaps,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: kColorNavyBlue.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: kColorNavyBlue.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Icon(Icons.gps_fixed, color: kColorNavyBlue, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DescriptionText('$city, $country'),
              ],
            ),
          ),
          if (onViewOnMaps != null) ...[
            SizedBox(width: 8),
            UnelevatedRegularButton(
              onPressed: onViewOnMaps,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              color: kColorNavyBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, color: kColorSecondaryBeige, size: 14),
                  SizedBox(width: 4),
                  SmallText('View on Maps', color: kColorSecondaryBeige, fontSize: 11),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildWarningContainer({
    required String message,
    required IconData icon,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (backgroundColor ?? Colors.orange).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? Colors.orange, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: CustomText(
              message,
              color: Colors.orange.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
