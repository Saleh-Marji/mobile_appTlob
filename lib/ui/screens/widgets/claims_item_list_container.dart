import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/ui/widgets/buttons/regular_button.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';

class ClaimsItemListContainer extends StatelessWidget {
  const ClaimsItemListContainer(this.itemModel, {super.key, required this.refreshData, required this.showSlots, required this.onPressed});

  final ItemModel itemModel;
  final VoidCallback refreshData;
  final Future<void> Function()? onPressed;
  final bool showSlots;

  double get _borderRadius => 10;

  @override
  Widget build(BuildContext context) {
    return RegularButton(
      disabledColor: Colors.white,
      disabledElevation: 2,
      disabledTextColor: kColorNavyBlue,
      color: Colors.white,
      onPressed: onPressed == null
          ? null
          : () {
              onPressed?.call().then((_) => refreshData());
            },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius), side: BorderSide(color: Color(0xfff3f3f3))),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(_borderRadius)),
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: CachedNetworkImageProvider(itemModel.image ?? ''),
                  ),
                ),
              ),
            ),
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
                    _price(),
                    if (showSlots) _slotsAvailable(),
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
        itemModel.name ?? '',
        maxLines: 1,
        fontSize: 20,
      );

  Widget _description() => DescriptionText(
        itemModel.description ?? '',
        color: Colors.grey,
        fontSize: 14,
        maxLines: 2,
      );

  Widget _slotsAvailable() => Builder(builder: (context) {
        return SmallText('${itemModel.slotsTaken} slot${itemModel.slotsTaken == 1 ? '' : 's'} taken');
        int slotsTaken = itemModel.slotsTaken ?? 0, totalSlots = itemModel.slotsAvailable;
        int slotsAvailable = totalSlots - slotsTaken;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: SmallText('Slots Left:')),
                SmallText(
                  '$slotsAvailable of $totalSlots',
                  color: kColorSecondaryBeige,
                  weight: FontWeight.w600,
                ),
              ],
            ),
            SizedBox(height: 5),
            LinearProgressIndicator(
              backgroundColor: kColorSecondaryBeige,
              valueColor: AlwaysStoppedAnimation(kColorNavyBlue),
              value: slotsAvailable / totalSlots,
              minHeight: 5,
              borderRadius: BorderRadius.circular(60),
            )
          ],
        );
      });

  Widget _price() => Builder(builder: (context) {
        return Row(
          children: [
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: context.color.secondary,
                ),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: DescriptionText('\$${itemModel.price?.toStringAsFixed(1)}', fontSize: 14),
              ),
            )
          ],
        );
      });
}
