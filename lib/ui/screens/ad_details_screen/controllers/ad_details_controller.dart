import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/chat/make_an_offer_item_cubit.dart';
import 'package:tlobni/data/cubits/favorite/favorite_cubit.dart';
import 'package:tlobni/data/cubits/favorite/manage_fav_cubit.dart';
import 'package:tlobni/data/cubits/item/delete_item_cubit.dart';
import 'package:tlobni/data/cubits/item/fetch_item_from_slug_cubit.dart';
import 'package:tlobni/data/cubits/item/fetch_item_reviews_cubit.dart';
import 'package:tlobni/data/cubits/item/fetch_my_item_cubit.dart';
import 'package:tlobni/data/cubits/item/item_total_click_cubit.dart';
import 'package:tlobni/data/cubits/item/related_item_cubit.dart';
import 'package:tlobni/data/cubits/report/fetch_item_report_reason_list.dart';
import 'package:tlobni/data/cubits/safety_tips_cubit.dart';
import 'package:tlobni/data/cubits/seller/fetch_seller_ratings_cubit.dart';
import 'package:tlobni/data/cubits/subscription/fetch_ads_listing_subscription_packages_cubit.dart';
import 'package:tlobni/data/helper/widgets.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';

class AdDetailsController {
  static void initVariables(BuildContext context, ItemModel itemModel) {
    if (!_isItemAddedByMe(itemModel)) {
      context.read<FetchItemReportReasonsListCubit>().fetch();
      context.read<FetchSafetyTipsListCubit>().fetchSafetyTips();
      context.read<FetchSellerRatingsCubit>().fetch(
            sellerId: (itemModel.user?.id != null ? itemModel.user!.id! : itemModel.userId!),
          );

      if (itemModel.id != null) {
        context.read<FetchItemReviewsCubit>().fetchItemReviews(itemId: itemModel.id!);
      }
    } else {
      context.read<FetchAdsListingSubscriptionPackagesCubit>().fetchPackages();
    }

    _setItemClick(context, itemModel);
    _fetchRelatedItems(context, itemModel);
  }

  static bool _isItemAddedByMe(ItemModel model) =>
      (model.user?.id != null ? model.user!.id.toString() : model.userId) == HiveUtils.getUserId();

  static void _setItemClick(BuildContext context, ItemModel model) {
    if (!_isItemAddedByMe(model)) {
      context.read<ItemTotalClickCubit>().itemTotalClick(model.id!);
    }
  }

  static void _fetchRelatedItems(BuildContext context, ItemModel model) {
    int? categoryId = model.category != null ? model.category?.id : model.categoryId;
    if (categoryId != null) {
      context.read<FetchRelatedItemsCubit>().fetchRelatedItems(
            categoryId: categoryId,
            city: HiveUtils.getCityName(),
            areaId: HiveUtils.getAreaId(),
            country: HiveUtils.getCountryName(),
            state: HiveUtils.getStateName(),
          );
    }
  }

  static void rootListener(BuildContext context, FetchItemFromSlugState? state) {
    if (state is FetchItemFromSlugInitial) {
      _refreshData(context);
    }
    if (state is FetchItemFromSlugSuccess) {
      log('success');
      // Handle success
    } else if (state is FetchItemFromSlugFailure) {
      if (state.errorMessage.contains("no-internet")) {
        HelperUtils.showSnackBarMessage(context, "noInternet".translate(context));
      } else if (!state.errorMessage.contains("unexpected-error") && !state.errorMessage.contains("session-expired")) {
        log("Error ignored during refresh: ${state.errorMessage}");
      }
    }
  }

  static Future<void> _refreshData(BuildContext context) async {
    try {
      // Implementation for refresh data
    } catch (e) {
      log('Error refreshing: $e');
    }
  }

  static void favoriteCubitListener(BuildContext context, UpdateFavoriteState? state) {
    if (state is UpdateFavoriteSuccess) {
      if (state.wasProcess) {
        context.read<FavoriteCubit>().addFavoriteitem(state.item);
      } else {
        context.read<FavoriteCubit>().removeFavoriteItem(state.item);
      }
    }
  }

  static void makeOfferListener(BuildContext context, MakeAnOfferItemState state, ItemModel model) {
    if (state is MakeAnOfferItemInProgress) {
      Widgets.showLoader(context);
    }
    if (state is MakeAnOfferItemSuccess || state is MakeAnOfferItemFailure) {
      Widgets.hideLoder(context);
    }
    if (state is MakeAnOfferItemSuccess) {
      _handleMakeOfferSuccess(context, state, model);
    }
    if (state is MakeAnOfferItemFailure) {
      HelperUtils.showSnackBarMessage(context, state.errorMessage.toString());
    }
  }

  static void _handleMakeOfferSuccess(BuildContext context, MakeAnOfferItemSuccess state, ItemModel model) {
    // Implementation for handling make offer success
  }

  static void deleteItemListener(BuildContext context, DeleteItemState state, ItemModel model) {
    if (state is DeleteItemInProgress) {
      Widgets.showLoader(context);
    } else {
      Widgets.hideLoder(context);
    }
    if (state is DeleteItemSuccess) {
      HelperUtils.showSnackBarMessage(context, "deleteItemSuccessMsg".translate(context));
      context.read<FetchMyItemsCubit>().deleteItem(model);
      Navigator.pop(context, "refresh");
    } else if (state is DeleteItemFailure) {
      HelperUtils.showSnackBarMessage(context, state.errorMessage);
    }
  }

  static void updateFavorite(BuildContext context, ItemModel model, bool isLike) {
    UiUtils.checkUser(
      onNotGuest: () {
        context.read<UpdateFavoriteCubit>().setFavoriteItem(
              item: model,
              type: isLike ? 0 : 1,
            );
      },
      context: context,
    );
  }

  static void shareItem(BuildContext context, ItemModel model) {
    if (model.slug != null) {
      HelperUtils.share(context, model.slug!);
    }
  }

  static void onWhatsappPressed(ItemModel model) {
    HelperUtils.launchWhatsapp(model.user?.mobile);
  }

  static void onChatPressed(BuildContext context, ItemModel model) {
    UiUtils.checkUser(
      onNotGuest: () {
        context.read<MakeAnOfferItemCubit>().makeAnOfferItem(id: model.id!, from: "chat");
      },
      context: context,
    );
  }

  static void onEditPressed(BuildContext context, ItemModel model) {
    Navigator.pushReplacementNamed(context, 'addItemDetails', arguments: {
      'isEdit': true,
      'item': model,
      'postType': model.type == 'experience' ? 'experience' : 'service',
    });
  }

  static void onDeletePressed(BuildContext context, ItemModel model) async {
    if (model.id == null) return;

    var delete = await UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        title: "deleteBtnLbl".translate(context),
        content: CustomText("deleteitemwarning".translate(context)),
      ),
    );

    if (delete == true) {
      Future.delayed(
        Duration.zero,
        () {
          context.read<DeleteItemCubit>().deleteItem(model.id!);
        },
      );
    }
  }

  static CameraPosition getInitialCameraPosition(ItemModel model) {
    return CameraPosition(
      target: LatLng(
        model.latitude ?? 0,
        model.longitude ?? 0,
      ),
      zoom: 14.4746,
    );
  }

  static String buildFullAddress(ItemModel model) {
    List<String> addressParts = [];

    if (model.city != null && model.city!.isNotEmpty) {
      addressParts.add(model.city!);
    }

    if (model.country != null && model.country!.isNotEmpty) {
      addressParts.add(model.country!);
    }

    String fullAddress = addressParts.join(', ');
    return fullAddress.isNotEmpty ? fullAddress : 'Location not specified';
  }

  static String formatPhoneNumber(String fullNumber, String countryCode) {
    countryCode = countryCode.replaceAll('+', '');
    fullNumber = fullNumber.replaceAll('+', '');

    if (!fullNumber.startsWith(countryCode)) {
      fullNumber = countryCode + fullNumber;
    }

    return '+' + fullNumber;
  }

  static String formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} min ago';
        }
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  static String formatExperienceDateTime(DateTime? dateTime) => dateTime != null ? DateFormat('MMMM d, y, h:mm a').format(dateTime) : '';

  static bool isItemAddedByMe(ItemModel model) => _isItemAddedByMe(model);

  static void navigateToProviderDetails(BuildContext context, ItemModel model) {
    Navigator.pushNamed(
      context,
      Routes.sellerProfileScreen,
      arguments: {
        'providerId': model.user?.id ?? model.userId,
        'provider': model.user,
      },
    );
  }

  static Future<void> refreshData(BuildContext context, String? slug, ItemModel model, int? categoryId) async {
    try {
      if (slug != null) {
        context.read<FetchItemFromSlugCubit>().fetchItemFromSlug(slug: slug);
      }

      initVariables(context, model);

      if (categoryId != null) {
        context.read<FetchRelatedItemsCubit>().fetchRelatedItems(
              categoryId: categoryId,
              city: HiveUtils.getCityName(),
              areaId: HiveUtils.getAreaId(),
              country: HiveUtils.getCountryName(),
              state: HiveUtils.getStateName(),
            );
      }
    } catch (e) {
      log('Error refreshing data: $e');
    }
  }
}
