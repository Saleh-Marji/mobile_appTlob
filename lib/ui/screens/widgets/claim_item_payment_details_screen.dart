import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/data/cubits/claim_item_cubit.dart';
import 'package:tlobni/data/helper/designs.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/claims_item_list_container.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/miscellanious/logo.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';

class ClaimItemPaymentDetailsScreen extends StatelessWidget {
  const ClaimItemPaymentDetailsScreen({super.key, required this.model});

  final ItemModel model;

  static Route route(RouteSettings settings) {
    final arguments = settings.arguments as Map<String, dynamic>;
    final itemModel = arguments['itemModel'] as ItemModel;
    return BlurredRouter(builder: (context) {
      return ClaimItemPaymentDetailsScreen(
        model: itemModel,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
        title: 'Claim Opportunity Confirmation',
      ),
      body: body(),
    );
  }

  Widget body() {
    return BlocBuilder<ClaimItemCubit, ClaimItemState>(builder: (context, state) {
      if (state is ClaimItemInProgress) {
        return Center(child: UiUtils.progress());
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.start, //temp
        children: [
          // SizedBox(height: 50),
          Logo(),
          SizedBox(height: 18),
          _itemDetails(),
          const Spacer(),
          if (model.price != null)
            HeadingText(
              model.price! > 0 ? '\$${model.price} / ${UiUtils.formatPriceType(model.priceType)}' : "free".translate(context),
              fontSize: context.font.xxLarge,
              weight: FontWeight.bold,
              color: context.color.textDefaultColor,
            ),
          UiUtils.buildButton(
            context,
            onPressed: () async {
              await context.read<ClaimItemCubit>().claimItem(model.id!);
              Navigator.pop(context);
            },
            radius: 10,
            height: 46,
            fontSize: context.font.large,
            buttonColor: kColorNavyBlue,
            textColor: kColorSecondaryBeige,
            buttonTitle: 'Confirm Claim',
            outerPadding: const EdgeInsets.all(20),
          )
        ],
      );
    });
  }

  Widget _itemDetails() {
    return Builder(builder: (context) {
      return Expanded(
        flex: 10,
        child: ListView(
          physics: BouncingScrollPhysics(),
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: ClaimsItemListContainer(
                model,
                refreshData: () {},
                showSlots: false,
                onPressed: null,
              ),
            ),
            // HeadingText(
            //   model.name!,
            //   weight: FontWeight.w600,
            //   fontSize: context.font.larger,
            //   textAlign: TextAlign.center,
            // ),
            // SizedBox(height: 15),
            // if (model.description != null && model.description != "") ...[
            //   SizedBox(height: 20),
            //   Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 20),
            //     child: Align(
            //       alignment: Alignment.centerLeft,
            //       child: DescriptionText(
            //         model.description!,
            //         textAlign: TextAlign.start,
            //         color: kColorNavyBlue,
            //       ),
            //     ),
            //   ),
            // ]
          ],
        ),
      );
    });
  }
}
