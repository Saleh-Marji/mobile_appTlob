import 'dart:async';
import 'dart:developer';

import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tlobni/data/cubits/chat/delete_message_cubit.dart';
import 'package:tlobni/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:tlobni/data/cubits/chat/load_chat_messages.dart';
import 'package:tlobni/data/cubits/chat/make_an_offer_item_cubit.dart';
import 'package:tlobni/data/cubits/chat/send_message.dart';
import 'package:tlobni/data/cubits/favorite/favorite_cubit.dart';
import 'package:tlobni/data/cubits/favorite/manage_fav_cubit.dart';
import 'package:tlobni/data/cubits/item/fetch_item_from_slug_cubit.dart';
import 'package:tlobni/data/cubits/item/fetch_item_reviews_cubit.dart';
import 'package:tlobni/data/cubits/item/item_total_click_cubit.dart';
import 'package:tlobni/data/cubits/item/related_item_cubit.dart';
import 'package:tlobni/data/cubits/user_has_rated_item_cubit.dart';
import 'package:tlobni/data/helper/widgets.dart';
import 'package:tlobni/data/model/chat/chat_user_model.dart' as chat_models;
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/ui/screens/chat/chat_screen.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

mixin AdDetailsMixins {
  // Image and Video Management
  void combineImages(List<String?> images, ItemModel model, FlickManager? flickManager, String youtubeVideoThumbnail) {
    images.add(model.image);
    if (model.galleryImages != null && model.galleryImages!.isNotEmpty) {
      for (var element in model.galleryImages!) {
        images.add(element.image);
      }
    }

    if (model.videoLink != null && model.videoLink!.isNotEmpty) {
      images.add(model.videoLink);
    }

    if (model.videoLink != "" && model.videoLink != null && !HelperUtils.isYoutubeVideo(model.videoLink ?? "")) {
      flickManager = FlickManager(
        videoPlayerController: VideoPlayerController.networkUrl(
          Uri.parse(model.videoLink!),
        ),
      );
      flickManager?.onVideoEnd = () {};
    }
    if (model.videoLink != "" && model.videoLink != null && HelperUtils.isYoutubeVideo(model.videoLink ?? "")) {
      String? videoId = YoutubePlayer.convertUrlToId(model.videoLink!);
      if (videoId != null) {
        String thumbnail = YoutubePlayer.getThumbnail(videoId: videoId);
        youtubeVideoThumbnail = thumbnail;
      }
    }
  }

  void setItemClick(BuildContext context, ItemModel model, bool isAddedByMe) {
    if (!isAddedByMe) {
      context.read<ItemTotalClickCubit>().itemTotalClick(model.id!);
    }
  }

  // Date Formatting
  String formatExperienceDateTime(DateTime? dateTime) => dateTime != null ? DateFormat('MMMM d, y, h:mm a').format(dateTime) : '';

  String formatDate(String dateString) {
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

  // Phone Number Formatting
  String formatPhoneNumber(String fullNumber, String countryCode) {
    countryCode = countryCode.replaceAll('+', '');
    fullNumber = fullNumber.replaceAll('+', '');

    if (!fullNumber.startsWith(countryCode)) {
      fullNumber = countryCode + fullNumber;
    }

    return '+' + fullNumber;
  }

  // Navigation Methods
  void navigateToProviderDetails(BuildContext context, ItemModel model) {
    Navigator.pushNamed(
      context,
      'sellerProfileScreen', // Replace with actual route
      arguments: {
        "model": model.user,
        "rating": model.user?.averageRating ?? 0.0,
        "total": model.user?.totalReviews ?? 0,
      },
    );
  }

  void navigateToGoogleMapScreen(
      BuildContext context, ItemModel model, CameraPosition kInitialPlace, Completer<GoogleMapController> controller) {
    Navigator.push(
      context,
      BlurredRouter(
        barrierDismiss: true,
        builder: (context) {
          return Container(); // Replace with actual GoogleMapScreen
        },
      ),
    );
  }

  // Chat and Offer Methods
  void makeOfferItem(BuildContext context, ItemModel model) {
    UiUtils.checkUser(
      onNotGuest: () {
        context.read<MakeAnOfferItemCubit>().makeAnOfferItem(id: model.id!, from: "chat");
      },
      context: context,
    );
  }

  void navigateToChat(BuildContext context, ItemModel model, chat_models.ChatUser? chatedUser) {
    if (chatedUser == null) {
      makeOfferItem(context, model);
    } else {
      Navigator.push(context, BlurredRouter(
        builder: (context) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => SendMessageCubit()),
              BlocProvider(create: (context) => LoadChatMessagesCubit()),
              BlocProvider(create: (context) => DeleteMessageCubit()),
            ],
            child: ChatScreen(
              itemId: chatedUser.itemId.toString(),
              profilePicture: chatedUser.seller?.profile ?? "",
              userName: chatedUser.seller?.name ?? "",
              date: chatedUser.createdAt!,
              itemOfferId: chatedUser.id!,
              itemPrice: chatedUser.item?.price ?? 0.0,
              itemOfferPrice: chatedUser.amount,
              itemImage: chatedUser.item?.image ?? "",
              itemTitle: chatedUser.item?.name ?? "",
              userId: chatedUser.sellerId.toString(),
              buyerId: chatedUser.buyerId.toString(),
              status: chatedUser.item?.status ?? "",
              from: "item",
              isPurchased: model.isPurchased ?? 0,
              alreadyReview: model.review?.isNotEmpty ?? false,
              isFromBuyerList: true,
            ),
          );
        },
      ));
    }
  }

  // Favorite Management
  void updateFavorite(BuildContext context, ItemModel model, bool isLike) {
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

  // Refresh Methods
  Future<void> refreshData(BuildContext context, String? slug, ItemModel model, int? categoryId) async {
    try {
      if (slug != null || model.slug != null) {
        String slugToUse = slug ?? model.slug!;
        final cubit = context.read<FetchItemFromSlugCubit>();
        cubit.fetchItemFromSlug(slug: slugToUse);
      }

      if (categoryId != null) {
        context.read<FetchRelatedItemsCubit>().fetchRelatedItems(
              categoryId: categoryId,
              city: HiveUtils.getCityName(),
              areaId: HiveUtils.getAreaId(),
              country: HiveUtils.getCountryName(),
              state: HiveUtils.getStateName(),
            );
      }

      context.read<FetchItemReviewsCubit>().fetchItemReviews(itemId: model.id!);
      context.read<UserHasRatedItemCubit>().userHasRatedItem(itemId: model.id!);
    } catch (e) {
      log('Error refreshing: $e');
    }
  }

  // Utility Methods
  bool isItemAddedByMe(ItemModel model) => (model.user?.id != null ? model.user!.id.toString() : model.userId) == HiveUtils.getUserId();

  String buildFullAddress(ItemModel model) {
    List<String> addressParts = [];

    if (model.address != null && model.address!.isNotEmpty) {
      addressParts.add(model.address!);
    }

    if (model.city != null && model.city!.isNotEmpty) {
      addressParts.add(model.city!);
    }

    if (model.state != null && model.state!.isNotEmpty) {
      addressParts.add(model.state!);
    }

    if (model.country != null && model.country!.isNotEmpty) {
      addressParts.add(model.country!);
    }

    String fullAddress = addressParts.join(', ');
    return fullAddress.isNotEmpty ? fullAddress : 'Location not specified';
  }

  // Listener Methods
  void favoriteCubitListener(BuildContext context, UpdateFavoriteState? state) {
    if (state is UpdateFavoriteSuccess) {
      if (state.wasProcess) {
        context.read<FavoriteCubit>().addFavoriteitem(state.item);
      } else {
        context.read<FavoriteCubit>().removeFavoriteItem(state.item);
      }
    }
  }

  void makeOfferListener(BuildContext context, MakeAnOfferItemState state, ItemModel model) {
    if (state is MakeAnOfferItemInProgress) {
      Widgets.showLoader(context);
    }
    if (state is MakeAnOfferItemSuccess || state is MakeAnOfferItemFailure) {
      Widgets.hideLoder(context);
    }
    if (state is MakeAnOfferItemSuccess) {
      dynamic data = state.data;

      context.read<GetBuyerChatListCubit>().addOrUpdateChat(chat_models.ChatUser(
            itemId: data['item_id'] is String ? int.parse(data['item_id']) : data['item_id'],
            amount: data['amount'] != null ? double.parse(data['amount'].toString()) : null,
            buyerId: data['buyer_id'] is String ? int.parse(data['buyer_id']) : data['buyer_id'],
            createdAt: data['created_at'],
            id: data['id'] is String ? int.parse(data['id']) : data['id'],
            sellerId: data['seller_id'] is String ? int.parse(data['seller_id']) : data['seller_id'],
            updatedAt: data['updated_at'],
            buyer: chat_models.Buyer.fromJson(data['buyer']),
            item: chat_models.Item.fromJson(data['item']),
            seller: chat_models.Seller.fromJson(data['seller']),
          ));

      if (state.from == 'offer') {
        HelperUtils.showSnackBarMessage(context, state.message.toString());
      }

      navigateToChatScreen(context, model, state.data);
    }
    if (state is MakeAnOfferItemFailure) {
      HelperUtils.showSnackBarMessage(context, state.errorMessage.toString());
    }
  }

  void navigateToChatScreen(BuildContext context, ItemModel model, dynamic data) {
    Navigator.push(context, BlurredRouter(
      builder: (context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => SendMessageCubit()),
            BlocProvider(create: (context) => LoadChatMessagesCubit()),
            BlocProvider(create: (context) => DeleteMessageCubit()),
          ],
          child: ChatScreen(
            profilePicture: model.user!.profile ?? "",
            userName: model.user!.name!,
            userId: model.user!.id!.toString(),
            from: "item",
            itemImage: model.image!,
            itemId: model.id.toString(),
            date: model.created!,
            itemTitle: model.name!,
            itemOfferId: data['id'] is String ? int.parse(data['id']) : data['id'],
            itemPrice: model.price!,
            status: model.status!,
            buyerId: HiveUtils.getUserId(),
            itemOfferPrice: data['amount'] != null ? double.parse(data['amount'].toString()) : null,
            isPurchased: model.isPurchased ?? 0,
            alreadyReview: model.review?.isNotEmpty ?? false,
            isFromBuyerList: true,
          ),
        );
      },
    ));
  }
}
