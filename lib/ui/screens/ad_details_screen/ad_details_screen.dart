// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:developer';

import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/add_user_review_cubit.dart';
import 'package:tlobni/data/cubits/chat/delete_message_cubit.dart';
import 'package:tlobni/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:tlobni/data/cubits/chat/load_chat_messages.dart';
import 'package:tlobni/data/cubits/chat/make_an_offer_item_cubit.dart';
import 'package:tlobni/data/cubits/chat/send_message.dart';
import 'package:tlobni/data/cubits/favorite/favorite_cubit.dart';
import 'package:tlobni/data/cubits/favorite/manage_fav_cubit.dart';
import 'package:tlobni/data/cubits/item/create_featured_ad_cubit.dart';
import 'package:tlobni/data/cubits/item/delete_item_cubit.dart';
import 'package:tlobni/data/cubits/item/fetch_item_from_slug_cubit.dart';
import 'package:tlobni/data/cubits/item/fetch_item_reviews_cubit.dart';
import 'package:tlobni/data/cubits/item/fetch_my_item_cubit.dart';
import 'package:tlobni/data/cubits/item/item_total_click_cubit.dart';
import 'package:tlobni/data/cubits/item/related_item_cubit.dart';
import 'package:tlobni/data/cubits/renew_item_cubit.dart';
import 'package:tlobni/data/cubits/report/fetch_item_report_reason_list.dart';
import 'package:tlobni/data/cubits/report/item_report_cubit.dart';
import 'package:tlobni/data/cubits/report/update_report_items_list_cubit.dart';
import 'package:tlobni/data/cubits/safety_tips_cubit.dart';
import 'package:tlobni/data/cubits/seller/fetch_seller_ratings_cubit.dart';
import 'package:tlobni/data/cubits/subscription/fetch_ads_listing_subscription_packages_cubit.dart';
import 'package:tlobni/data/cubits/subscription/fetch_user_package_limit_cubit.dart';
import 'package:tlobni/data/cubits/user_has_rated_item_cubit.dart';
import 'package:tlobni/data/helper/widgets.dart';
import 'package:tlobni/data/model/chat/chat_user_model.dart' as chat_models;
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/report_item/reason_model.dart';
import 'package:tlobni/data/model/safety_tips_model.dart';
import 'package:tlobni/data/model/seller_ratings_model.dart';
import 'package:tlobni/data/model/subscription_pacakage_model.dart';
import 'package:tlobni/ui/screens/ad_details_screen/widgets/custom_web_video_player.dart';
import 'package:tlobni/ui/screens/ad_details_screen/widgets/reviews_stars.dart';
import 'package:tlobni/ui/screens/chat/chat_screen.dart';
import 'package:tlobni/ui/screens/google_map_screen.dart';
import 'package:tlobni/ui/screens/home/widgets/grid_list_adapter.dart';
import 'package:tlobni/ui/screens/home/widgets/home_sections_adapter.dart';
import 'package:tlobni/ui/screens/home/widgets/provider_home_screen_container.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/models/post_type.dart';
import 'package:tlobni/ui/screens/subscription/widget/featured_ads_subscription_plan_item.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_data_found.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_internet.dart';
import 'package:tlobni/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:tlobni/ui/screens/widgets/item_pricing_container.dart';
import 'package:tlobni/ui/screens/widgets/review_dialog.dart';
import 'package:tlobni/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:tlobni/ui/screens/widgets/side_colored_border_container.dart';
import 'package:tlobni/ui/screens/widgets/video_view_screen.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/buttons/primary_button.dart';
import 'package:tlobni/ui/widgets/buttons/regular_button.dart';
import 'package:tlobni/ui/widgets/buttons/unelevated_regular_button.dart';
import 'package:tlobni/ui/widgets/pagination/pagination_next_previous.dart';
import 'package:tlobni/ui/widgets/reviews/review_container.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/cloud_state/cloud_state.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/extensions/lib/currency_formatter.dart';
import 'package:tlobni/utils/extensions/lib/widget_iterable.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:tlobni/utils/validator.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

part 'widgets/business_logic_extension.dart';

enum _AdDetailsTab {
  details,
  reviews;

  @override
  String toString() => switch (this) {
        _AdDetailsTab.details => 'Details',
        _AdDetailsTab.reviews => 'Reviews',
      };
}

class AdDetailsScreen extends StatefulWidget {
  final ItemModel? model;
  final String? slug;

  const AdDetailsScreen({
    super.key,
    this.model,
    this.slug,
  });

  @override
  AdDetailsScreenState createState() => AdDetailsScreenState();

  static Route route(RouteSettings routeSettings) {
    Map? arguments = routeSettings.arguments as Map?;
    return BlurredRouter(
        builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => FetchMyItemsCubit(),
                ),
                BlocProvider(
                  create: (context) => CreateFeaturedAdCubit(),
                ),
                BlocProvider(
                  create: (context) => FetchItemReportReasonsListCubit(),
                ),
                BlocProvider(
                  create: (context) => ItemReportCubit(),
                ),
                BlocProvider(
                  create: (context) => MakeAnOfferItemCubit(),
                ),
                BlocProvider(create: (context) => FetchItemFromSlugCubit()),
                BlocProvider(create: (context) => FetchItemReviewsCubit()),
              ],
              child: AdDetailsScreen(
                model: arguments?['model'],
                slug: arguments?['slug'],
                // from: arguments?['from'],
              ),
            ));
  }
}

class AdDetailsScreenState extends CloudState<AdDetailsScreen> {
  //ImageView
  int currentPage = 0;
  bool? isFeaturedLimit;
  List<String> selectedFeaturedAdsOptions = [];

  final PageController pageController = PageController();
  final List<String?> images = [];
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  late final ScrollController _pageScrollController = ScrollController();
  List<ReportReason>? reasons = [];
  final TextEditingController _reportmessageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _makeAnOffermessageController = TextEditingController();
  final GlobalKey<FormState> _offerFormKey = GlobalKey();
  int? _selectedPackageIndex;

  _AdDetailsTab _tab = _AdDetailsTab.details;

  late ItemModel model;

  bool get isAddedByMe => (model.user?.id != null ? model.user!.id.toString() : model.userId) == HiveUtils.getUserId();
  bool isFeaturedWidget = true;
  String youtubeVideoThumbnail = "";
  int? categoryId;
  FlickManager? flickManager;

  @override
  void initState() {
    super.initState();
    if (widget.model != null) {
      model = widget.model!;
      initVariables(widget.model!);
    }
    _onRefresh();
    pageController.addListener(() {
      setState(() {
        currentPage = pageController.page!.round();
      });
    });
    _pageScrollController.addListener(_pageScroll);
  }

  late final CameraPosition _kInitialPlace = CameraPosition(
    target: LatLng(
      model.latitude ?? 0,
      model.longitude ?? 0,
    ),
    zoom: 14.4746,
  );

  @override
  void dispose() {
    super.dispose();
  }

  PreferredSize _appBar() => UiUtils.buildAppBar(
        context,
        title: '${widget.model?.type == 'experience' ? 'Experience' : 'Service'} Details',
        showBackButton: true,
      );

  Widget _imagesViewer() => PageView.builder(
        itemCount: images.length,
        // Increase itemCount if videoLink is present
        controller: pageController,
        itemBuilder: (context, index) {
          if (index == images.length - 1 && model.videoLink != "" && model.videoLink != null) {
            return Stack(
              children: [
                // Thumbnail Image
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return VideoViewScreen(
                            videoUrl: model.videoLink ?? "",
                            flickManager: flickManager,
                          );
                        },
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: UiUtils.getImage(
                      youtubeVideoThumbnail,
                      fit: BoxFit.cover,
                      height: 250,
                      width: double.maxFinite,
                    ),
                  ),
                ),
                // Play Button
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return VideoViewScreen(
                              videoUrl: model.videoLink ?? "",
                              flickManager: flickManager,
                            );
                          },
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.3),
                          ),
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Display image
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x7F060606)],
                ).createShader(bounds);
                //TODO: change black color to some other app color if required
              },
              blendMode: BlendMode.darken,
              child: InkWell(
                child: UiUtils.getImage(
                  images[index]!,
                  fit: BoxFit.cover,
                  height: 250,
                ),
                onTap: () {
                  UiUtils.imageGallaryView(context, images: images, initalIndex: index);
                },
              ),
            );
          }
        },
      );

  Widget _imagesIndex() => Align(
        alignment: AlignmentDirectional.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              // Increase number of dots if videoLink is present
              (index) => buildDot(index),
            ),
          ),
        ),
      );

  Widget _actionIcon(IconData icon, VoidCallback onPressed) => _action(Icon(icon, color: context.color.onPrimary, size: 30), onPressed);

  Widget _action(Widget child, VoidCallback onPressed) => UnelevatedRegularButton(
        onPressed: onPressed,
        shape: CircleBorder(),
        padding: EdgeInsets.all(10),
        color: context.color.primary,
        child: child,
      );

  Widget _featuredBanner() => Builder(builder: (context) {
        return setTopRowItem(
          alignment: AlignmentDirectional.topStart,
          marginVal: 15,
          cornerRadius: 5,
          backgroundColor: context.color.territoryColor,
          child: CustomText(
            "featured".translate(context),
            fontSize: context.font.small,
            color: context.color.backgroundColor,
          ),
        );
      });

  Widget _shareButton() => _actionIcon(Icons.share, _shareItem);

  Widget _favouriteButton() {
    return BlocBuilder<FavoriteCubit, FavoriteState>(
      bloc: context.read<FavoriteCubit>(),
      builder: (context, favState) {
        bool isLike = context.select((FavoriteCubit cubit) => cubit.isItemFavorite(model.id!));

        return BlocConsumer<UpdateFavoriteCubit, UpdateFavoriteState>(
          bloc: context.read<UpdateFavoriteCubit>(),
          listener: _favoriteCubitListener,
          builder: (context, state) {
            if (state is UpdateFavoriteInProgress) {
              double size = 30.0;
              return _action(UiUtils.progress(height: size, width: size, color: context.color.onPrimary), () {});
            }
            return _actionIcon(
              isLike ? Icons.favorite : Icons.favorite_border,
              () => _updateFavorite(isLike),
            );
          },
        );
      },
    );
  }

  Widget _topRightActions() => setTopRowItem(
        alignment: AlignmentDirectional.topEnd,
        marginVal: 10,
        cornerRadius: 0,
        backgroundColor: null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            _favouriteButton(),
            _shareButton(),
          ],
        ),
      );

  Widget _images() => Stack(children: [
        _imagesViewer(),
        _imagesIndex(),
        // if (model.isFeature ?? false) _featuredBanner(),
        _topRightActions(),
      ]);

  Widget _title() => HeadingText(model.name ?? '', maxLines: 4);

  Widget _pricing() => ItemPricingContainer(
        price: model.price ?? 0,
        priceType: model.priceType ?? '',
        priceFontSize: 22,
      );

  Widget _progressIndicator() => Center(child: UiUtils.progress());

  Widget _somethingWentWrong() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SomethingWentWrong(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _onRefresh(),
              child: DescriptionText("retryBtnLbl".translate(context)),
            ),
          ],
        ),
      );

  Widget _reviewsTopSummary() {
    return BlocBuilder<FetchItemReviewsCubit, FetchItemReviewsState>(
      bloc: context.read<FetchItemReviewsCubit>(),
      builder: (context, state) {
        if (state is! FetchItemReviewsSuccess) return SizedBox();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 5,
          children: [
            Icon(Icons.star, color: context.color.secondary, size: 20),
            Expanded(child: SmallText('${state.averageRating.toStringAsFixed(1)} (${state.total} reviews)')),
          ],
        );
      },
    );
  }

  Widget _tags() => Builder(builder: (context) {
        final List<(Color? borderColor, Color backgroundColor, Widget child)> tagsWithColors = [];
        if (model.category != null) {
          tagsWithColors.add((Color(0xffe1e1e1), Color(0xfff2f2f2), SmallText(model.category?.name ?? '')));
        }
        if (model.isWomenExclusive) {
          tagsWithColors.add((Color(0xffffc8de), Color(0xfffeeef3), SmallText('Women Only', color: Color(0xffd2398e))));
        }
        if (model.isCorporatePackage) {
          tagsWithColors.add((
            kColorNavyBlue.withValues(alpha: 0.2),
            kColorNavyBlue.withValues(alpha: 0.1),
            SmallText('Corporate Package', color: kColorNavyBlue)
          ));
        }
        if (model.isFeature ?? false) {
          tagsWithColors.add((
            context.color.secondary,
            context.color.secondary,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 15),
                SizedBox(width: 5),
                SmallText('Featured', color: Colors.white),
              ],
            )
          ));
        }
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final (borderColor, backgroundColor, child) in tagsWithColors)
              Container(
                decoration: BoxDecoration(
                  border: borderColor == null ? null : Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(5),
                  color: backgroundColor,
                ),
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: child,
              )
          ],
        );
      });

  Widget _iconAndText(IconData icon, String text) => Row(
        children: [
          Icon(icon),
          SizedBox(width: 5),
          SmallText(text),
        ],
      );

  Widget _address() => _iconAndText(Icons.location_pin, model.location ?? '');

  Widget _locationType() => _iconAndText(
        Icons.local_offer_outlined,
        model.locationType?.map(ItemModel.locationTypeString).join(', ') ?? '',
      );

  Widget _divider() => const Divider(height: 1.5, thickness: 0.8);

  Widget _tabsHeader() => Row(
        children: _AdDetailsTab.values
            .map(
              (e) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UnelevatedRegularButton(
                    padding: EdgeInsets.all(20),
                    color: Colors.transparent,
                    onPressed: () => setState(() => _tab = e),
                    child: DescriptionText(e.toString(), color: _tab == e ? context.color.primary : Colors.grey),
                  ),
                  Divider(height: 2, thickness: 2, color: _tab == e ? context.color.primary : Colors.transparent),
                ],
              ),
            )
            .mapExpandedSpaceBetween(0),
      );

  Widget _tabContent() => switch (_tab) {
        _AdDetailsTab.details => _itemDetailsTabContent(),
        _AdDetailsTab.reviews => _itemReviewsTabContent(),
      };

  Widget _itemDetailsTabContent() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          if (model.description != null) _itemDetailsSection(title: 'Description', child: SmallText(model.description ?? '')),
          if (model.videoLink != null)
            _itemDetailsSection(
              title: 'Video Preview',
              child: SizedBox(
                height: 200,
                child: CustomWebVideoPlayer(model.videoLink!),
              ),
            ),
          if (model.price != null && model.priceType != null)
            _itemDetailsSection(
              title: 'Pricing',
              child: Row(
                children: [
                  Expanded(child: SmallText('Base Price', color: Colors.grey)),
                  SizedBox(width: 10),
                  SmallText('\$${model.price} / ${model.priceType}', weight: FontWeight.bold)
                ],
              ),
            ),
          if (model.isForACause) _forACause(),
          _divider(),
          _aboutTheProvider(),
        ],
      );

  Widget _forACause() {
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
            model.forACauseText ?? '',
            color: greenColor,
          ),
        ],
      ),
    );
  }

  Widget _aboutTheProvider() => model.user == null
      ? SizedBox()
      : _elevatedContainer(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HeadingText('About the Provider', fontSize: 20, weight: FontWeight.bold),
                SizedBox(height: 20),
                _divider(),
                SizedBox(height: 20),
                ProviderHomeScreenContainer(
                  user: model.user!,
                  withBorder: false,
                  goToProviderDetailsScreenOnPressed: false,
                  padding: EdgeInsets.zero,
                  additionalDetails: GestureDetector(
                    onTap: _goToProviderDetails,
                    child: DescriptionText(
                      'Visit Profile',
                      decoration: TextDecoration.underline,
                      fontSize: 15,
                      weight: FontWeight.bold,
                    ),
                  ),
                ),
                if (model.user?.bio != null) ...[
                  SizedBox(height: 10),
                  SideColoredBorderContainer(
                    sideBorderColor: kColorSecondaryBeige,
                    child: SmallText(
                      model.user?.bio ?? '',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

  Widget _limitedTimeExperience() {
    final isExpired = model.expirationDate?.difference(DateTime.now()).isNegative;
    if (isExpired == null) return SizedBox();
    return _elevatedContainer(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.event, color: isExpired ? Colors.red : context.color.secondary),
                SizedBox(width: 10),
                Expanded(child: HeadingText(isExpired ? 'This experience has expired' : 'Limited Time Experience', fontSize: 18)),
              ],
            ),
            SizedBox(height: 10),
            _divider(),
            SizedBox(height: 10),
            Column(
              spacing: 12,
              children: [
                _limitedExperienceItem(
                  Icons.event_busy,
                  'End Date',
                  _formatExperienceDateTime(model.expirationDate),
                ),
                if (!isExpired)
                  _limitedExperienceItem(
                    Icons.hourglass_bottom,
                    'Countdown',
                    '${model.expirationDate?.difference(DateTime.now()).abs().inDays} days left',
                  )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _limitedExperienceItem(IconData icon, String title, String content) => Row(
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

  Widget _itemDetailsSection({
    required String title,
    required Widget child,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeadingText(title, fontSize: 18, weight: FontWeight.bold),
          SizedBox(height: 10),
          child,
        ],
      );

  Widget _elevatedContainer({required Widget child}) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: kElevationToShadow[2],
        ),
        child: child,
      );

  Widget _reviewsBottomSummary(FetchItemReviewsSuccess state) => Row(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.color.primary,
            ),
            child: DescriptionText(
              state.averageRating.toStringAsFixed(1),
              color: Colors.white,
              weight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReviewsStars(rating: state.averageRating, iconSize: 26, spacing: 0),
                SizedBox(height: 5),
                SmallText('${state.total} reviews'),
              ],
            ),
          ),
        ],
      );

  Widget _reviewsList(FetchItemReviewsSuccess state) => Builder(builder: (context) {
        final reviews = state.reviews;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: context.screenHeight * 0.5),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                for (int i = 0; i < reviews.length; i++) IntrinsicHeight(child: ReviewContainer(reviews[i])),
                if (state.total > state.reviews.length) IntrinsicHeight(child: _reviewsPaginationDetails(state)),
              ],
            ),
          ),
        );
      });

  Widget _addReviewButton() => _userHasRatedItemBuilder(
        child: PrimaryButton.text(
          '+ Add Your Review',
          padding: EdgeInsets.all(16),
          fontSize: 16,
          onPressed: () {
            _showServiceReviewDialog(
              serviceId: model.id!,
              userId: model.userId!,
              name: model.name ?? "Service",
              image: model.image ?? model.user?.profile,
              isExperience: model.itemType == "experience",
            );
          },
        ),
      );

  Widget _itemReviewsTabContent() => BlocBuilder<FetchItemReviewsCubit, FetchItemReviewsState>(builder: (context, state) {
        return switch (state) {
          FetchItemReviewsInitial() => SizedBox(),
          FetchItemReviewsInProgress() => Center(child: UiUtils.progress()),
          FetchItemReviewsFailure() => _reviewsFailure(),
          FetchItemReviewsSuccess() => IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _reviewsBottomSummary(state),
                  SizedBox(height: 20),
                  _reviewsList(state),
                  if (!isAddedByMe) ...[
                    SizedBox(height: 20),
                    _addReviewButton(),
                  ]
                ],
              ),
            ),
        };
      });

  Widget _reviewsPaginationDetails(FetchItemReviewsSuccess state) => PaginationNextPrevious(
        currentPage: state.currentPage,
        lastPage: state.lastPage,
        onButtonPressed: (newPage) => context.read<FetchItemReviewsCubit>().fetchItemReviews(itemId: model.id!, page: newPage),
      )
      // Row(
      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //   children: [
      //     if (state.currentPage != 1) (-1, 'Previous') else SizedBox(),
      //     if (state.currentPage != state.lastPage) (1, 'Next') else SizedBox(),
      //   ].map<Widget>((e) {
      //     if (e is Widget) return e;
      //     final (add, text) = e as (int, String);
      //     return TextButton(
      //       onPressed: () {
      //         context.read<FetchItemReviewsCubit>().fetchItemReviews(itemId: model.id!, page: state.currentPage + add);
      //       },
      //       child: Text(text),
      //     );
      //   }).toList(),
      // )
      ;

  Widget _reviewsFailure() => Column(
        children: [
          Center(child: DescriptionText("Failed to load reviews. Tap to retry.")),
          Center(
            child: TextButton(
              onPressed: () {
                if (model.id != null) context.read<FetchItemReviewsCubit>().fetchItemReviews(itemId: model.id!);
              },
              child: DescriptionText("Retry"),
            ),
          ),
        ],
      );

  Widget _bottomButtons() => Column(
        children: [
          _divider(),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: (isAddedByMe
                      ? [
                          ('Edit', _onEditPressed),
                          ('Delete', _onDeletePressed),
                        ]
                      : [
                          if (model.user?.showPersonalDetails == 1 && model.user?.mobile != null) ('WhatsApp', _onWhatsappPressed),
                          ('Chat', _onChatPressed),
                        ])
                  .map((e) {
                    final (text, onPressed) = e;
                    return PrimaryButton.text(
                      text,
                      onPressed: onPressed,
                      fontSize: 16,
                      padding: EdgeInsets.all(20),
                    );
                  })
                  .mapExpandedSpaceBetween(10)
                  .toList(),
            ),
          ),
        ],
      );

  Widget reportItem() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.color.textDefaultColor.withOpacity(0.1)),

        // Background color
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.report, size: 20, color: Colors.red),
              SizedBox(width: 5),
              Expanded(child: SmallText("didYouFindAnyProblemWithThisItem".translate(context))),
            ],
          ),
          SizedBox(height: 15),
          BlocListener<ItemReportCubit, ItemReportState>(
            listener: (context, state) {
              if (state is ItemReportFailure) {
                HelperUtils.showSnackBarMessage(context, state.error.toString());
              }
              if (state is ItemReportInSuccess) {
                HelperUtils.showSnackBarMessage(context, state.responseMessage.toString());
                context.read<UpdatedReportItemCubit>().addItem(model);
              }
            },
            child: RegularButton(
              color: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              padding: EdgeInsets.all(15),
              onPressed: () => UiUtils.checkUser(onNotGuest: () => _showReportItemDialog(model.id!), context: context),
              child: SmallText('reportThisAd'.translate(context)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: BlocConsumer<DeleteItemCubit, DeleteItemState>(
        listener: (context, deleteState) {
          if (deleteState is DeleteItemInProgress) {
            Widgets.showLoader(context);
          } else {
            Widgets.hideLoder(context);
          }
          if (deleteState is DeleteItemSuccess) {
            HelperUtils.showSnackBarMessage(context, "deleteItemSuccessMsg".translate(context));
            context.read<FetchMyItemsCubit>().deleteItem(model);

            // Return to previous screen with refresh signal
            Navigator.pop(context, "refresh");
          } else if (deleteState is DeleteItemFailure) {
            HelperUtils.showSnackBarMessage(context, deleteState.errorMessage);
          }
        },
        builder: (context, deleteState) => BlocConsumer<FetchItemFromSlugCubit, FetchItemFromSlugState>(
          listener: _rootListener,
          builder: (context, state) {
            if (state is FetchItemFromSlugLoading) return _progressIndicator();
            if (state is FetchItemFromSlugFailure && widget.slug != null) return _somethingWentWrong();
            return BlocConsumer<MakeAnOfferItemCubit, MakeAnOfferItemState>(
                listener: _makeOfferListener,
                builder: (context, makeAnOfferItemState) {
                  return Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _onRefresh,
                          child: ListView(
                            children: [
                              SizedBox(
                                height: 300,
                                child: _images(),
                              ),
                              Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _title(),
                                    SizedBox(height: 20),
                                    _pricing(),
                                    SizedBox(height: 20),
                                    _reviewsTopSummary(),
                                    SizedBox(height: 20),
                                    _tags(),
                                    SizedBox(height: 20),
                                    _address(),
                                    SizedBox(height: 10),
                                    if (model.locationType?.isNotEmpty ?? false) _locationType(),
                                    if (!isAddedByMe && !(model.isAlreadyReported ?? false)) ...[
                                      const SizedBox(height: 20),
                                      reportItem(),
                                    ],
                                    if (model.expirationDate != null) ...[
                                      const SizedBox(height: 20),
                                      _divider(),
                                      const SizedBox(height: 20),
                                      _limitedTimeExperience(),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              _divider(),
                              _tabsHeader(),
                              _divider(),
                              SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: _tabContent(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _bottomButtons(),
                    ],
                  );
                });
          },
        ),
      ),
    );
  }

  Widget reportedAdsWidget() {
    return BlocBuilder<UpdatedReportItemCubit, UpdatedReportItemState>(
      builder: (context, state) {
        if (model.isAlreadyReported == null || !model.isAlreadyReported!) {
          return reportItem();
        }
        return SizedBox();
      },
    );
  }

  // Display service reviews in the item details
  Widget buildServiceReviews() {
    return BlocBuilder<FetchItemReviewsCubit, FetchItemReviewsState>(
      builder: (context, state) {
        if (state is FetchItemReviewsInProgress) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "Reviews",
                  fontWeight: FontWeight.bold,
                  fontSize: context.font.large,
                ),
                SizedBox(height: 10),
                Center(
                  child: UiUtils.progress(),
                ),
              ],
            ),
          );
        }

        if (state is FetchItemReviewsFailure) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "Reviews",
                  fontWeight: FontWeight.bold,
                  fontSize: context.font.large,
                ),
                SizedBox(height: 10),
                Center(
                  child: CustomText(
                    "Failed to load reviews. Tap to retry.",
                    color: context.color.textDefaultColor.withOpacity(0.6),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      if (model.id != null) {
                        context.read<FetchItemReviewsCubit>().fetchItemReviews(itemId: model.id!);
                      }
                    },
                    child: CustomText(
                      "Retry",
                      color: context.color.territoryColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is FetchItemReviewsSuccess) {
          if (state.reviews.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Reviews",
                    fontWeight: FontWeight.bold,
                    fontSize: context.font.large,
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: CustomText(
                      "No reviews yet. Be the first to write a review!",
                      color: context.color.textDefaultColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          // If reviews exist, display them (limited to 3)
          int displayCount = state.reviews.length > 3 ? 3 : state.reviews.length;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      "Reviews (${state.total})",
                      fontWeight: FontWeight.bold,
                      fontSize: context.font.large,
                    ),
                    if (state.reviews.length > 3)
                      GestureDetector(
                        onTap: () {
                          // Show all reviews in a modal
                          _showAllReviews(state.reviews);
                        },
                        child: CustomText(
                          "See All",
                          color: context.color.territoryColor,
                          showUnderline: true,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: displayCount,
                  itemBuilder: (context, index) {
                    final review = state.reviews[index];

                    // Use either reviewer or buyer field
                    final userDetails = review.reviewer ?? review.buyer;

                    final hasProfile = userDetails != null && userDetails.profile != null && userDetails.profile!.isNotEmpty;

                    final reviewerName = userDetails != null && userDetails.name != null ? userDetails.name! : "Anonymous";

                    // Add a subtle "You" indicator if this is your own review
                    final isOwnReview = userDetails != null && userDetails.id != null && userDetails.id.toString() == HiveUtils.getUserId();

                    return Card(
                      color: context.color.secondaryColor,
                      margin: EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Reviewer Profile Image
                            hasProfile
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      userDetails.profile!,
                                    ),
                                  )
                                : CircleAvatar(
                                    backgroundColor: context.color.territoryColor,
                                    child: Icon(
                                      Icons.person,
                                      color: context.color.buttonColor,
                                    ),
                                  ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      CustomText(
                                        isOwnReview ? "$reviewerName (You)" : reviewerName,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      if (review.createdAt != null)
                                        CustomText(
                                          _formatDate(review.createdAt!),
                                          fontSize: context.font.small,
                                          color: context.color.textDefaultColor.withOpacity(0.6),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    children: [
                                      for (int i = 0; i < 5; i++)
                                        Icon(
                                          i < (review.ratings ?? 0).floor() ? Icons.star : Icons.star_border,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                      SizedBox(width: 5),
                                      CustomText(
                                        "${review.ratings}",
                                        fontSize: context.font.small,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  CustomText(
                                    review.review ?? "",
                                    color: context.color.textDefaultColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Show loading indicator if more data is being loaded
                if (state.isLoadingMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(child: UiUtils.progress()),
                  ),

                // Show "Load More" button if there are more reviews
                if (state.hasMoreData && !state.isLoadingMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          if (model.id != null) {
                            context.read<FetchItemReviewsCubit>().fetchMoreItemReviews(itemId: model.id!);
                          }
                        },
                        child: CustomText(
                          "Load More",
                          color: context.color.territoryColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        // Fallback to using model.review if the FetchItemReviewsCubit hasn't loaded yet
        if (model.review == null || model.review!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "Reviews",
                  fontWeight: FontWeight.bold,
                  fontSize: context.font.large,
                ),
                SizedBox(height: 10),
                Center(
                  child: CustomText(
                    "No reviews yet. Be the first to write a review!",
                    color: context.color.textDefaultColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        // If reviews exist in the model as a fallback
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                "Reviews (${model.review!.length})",
                fontWeight: FontWeight.bold,
                fontSize: context.font.large,
              ),
              SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: model.review!.length,
                itemBuilder: (context, index) {
                  final review = model.review![index];

                  // Use either reviewer or buyer field
                  final userDetails = review.reviewer ?? review.buyer;

                  final hasProfile = userDetails != null && userDetails.profile != null && userDetails.profile!.isNotEmpty;

                  final reviewerName = userDetails != null && userDetails.name != null ? userDetails.name! : "Anonymous";

                  // Add a subtle "You" indicator if this is your own review
                  final isOwnReview = userDetails != null && userDetails.id != null && userDetails.id.toString() == HiveUtils.getUserId();

                  return Card(
                    color: context.color.secondaryColor,
                    margin: EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reviewer Profile Image
                          hasProfile
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    userDetails.profile!,
                                  ),
                                )
                              : CircleAvatar(
                                  backgroundColor: context.color.territoryColor,
                                  child: Icon(
                                    Icons.person,
                                    color: context.color.buttonColor,
                                  ),
                                ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomText(
                                      isOwnReview ? "$reviewerName (You)" : reviewerName,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    if (review.createdAt != null)
                                      CustomText(
                                        _formatDate(review.createdAt!),
                                        fontSize: context.font.small,
                                        color: context.color.textDefaultColor.withOpacity(0.6),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Row(
                                  children: [
                                    for (int i = 0; i < 5; i++)
                                      Icon(
                                        i < (review.ratings ?? 0).floor() ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                    SizedBox(width: 5),
                                    CustomText(
                                      "${review.ratings}",
                                      fontSize: context.font.small,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                CustomText(
                                  review.review ?? "",
                                  color: context.color.textDefaultColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget relatedAds() {
    return BlocBuilder<FetchRelatedItemsCubit, FetchRelatedItemsState>(builder: (context, state) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<FetchRelatedItemsCubit>().fetchRelatedItems(
              categoryId: categoryId!,
              city: HiveUtils.getCityName(),
              areaId: HiveUtils.getAreaId(),
              country: HiveUtils.getCountryName(),
              state: HiveUtils.getStateName());
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (state is FetchRelatedItemsInProgress)
                relatedItemShimmer()
              else if (state is FetchRelatedItemsFailure)
                _buildFailureWidget(state)
              else
                _buildSuccessWidget(state),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFailureWidget(FetchRelatedItemsFailure state) {
    if (state.errorMessage is ApiException) {
      if (state.errorMessage == "no-internet") {
        return NoInternet(
          onRetry: () {
            context.read<FetchRelatedItemsCubit>().fetchRelatedItems(
                categoryId: categoryId!,
                city: HiveUtils.getCityName(),
                areaId: HiveUtils.getAreaId(),
                country: HiveUtils.getCountryName(),
                state: HiveUtils.getStateName());
          },
        );
      }
    }
    return const SomethingWentWrong();
  }

  Widget _buildSuccessWidget(FetchRelatedItemsState state) {
    if (state is FetchRelatedItemsSuccess) {
      if (state.itemModel.isEmpty || state.itemModel.length == 1) {
        return SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              "relatedAds".translate(context),
              fontSize: context.font.large,
              fontWeight: FontWeight.w600,
              maxLines: 1,
            ),
            SizedBox(
              height: 15,
            ),
            GridListAdapter(
              type: ListUiType.List,
              height: MediaQuery.of(context).size.height / 3.5,
              controller: _pageScrollController,
              listAxis: Axis.horizontal,
              listSeparator: (BuildContext p0, int p1) => const SizedBox(
                width: 14,
              ),
              isNotSidePadding: true,
              builder: (context, int index, bool) {
                ItemModel? item = state.itemModel[index];

                if (item.id != model.id) {
                  return ItemCard(
                    item: item,
                    width: 162,
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
              total: state.itemModel.length,
            ),
          ],
        ),
      );
    }

    return const SizedBox.square();
  }

  Widget relatedItemShimmer() {
    return SizedBox(
        height: 200,
        child: ListView.builder(
            itemCount: 5,
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
                // horizontal: sidePadding,
                ),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 8),
                child: const CustomShimmer(
                  height: 200,
                  width: 300,
                ),
              );
            }));
  }

  Widget createFeaturesAds() {
    if (model.status == "active" || model.status == "approved") {
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => CreateFeaturedAdCubit(),
          ),
          BlocProvider(
            create: (context) => FetchUserPackageLimitCubit(),
          ),
        ],
        child: Builder(builder: (context) {
          return BlocListener<CreateFeaturedAdCubit, CreateFeaturedAdState>(
            listener: (context, state) {
              if (state is CreateFeaturedAdInSuccess) {
                HelperUtils.showSnackBarMessage(context, state.responseMessage.toString(), messageDuration: 3);

                Navigator.pop(context, "refresh");
              }
              if (state is CreateFeaturedAdFailure) {
                HelperUtils.showSnackBarMessage(context, state.error.toString(), messageDuration: 3);
              }
            },
            child: BlocListener<FetchUserPackageLimitCubit, FetchUserPackageLimitState>(
              listener: (context, state) async {
                if (state is FetchUserPackageLimitFailure) {
                  UiUtils.noPackageAvailableDialog(context);
                }
                if (state is FetchUserPackageLimitInSuccess) {
                  await UiUtils.showBlurredDialoge(
                    context,
                    dialoge: BlurredDialogBox(
                        title: "createFeaturedAd".translate(context),
                        content: CustomText(
                          "areYouSureToCreateThisItemAsAFeaturedAd".translate(context),
                        ),
                        isAcceptContainerPush: true,
                        onAccept: () => Future.value().then((_) {
                              Future.delayed(
                                Duration.zero,
                                () {
                                  context.read<CreateFeaturedAdCubit>().createFeaturedAds(
                                        itemId: model.id!,
                                      );
                                  Navigator.pop(context);
                                  return;
                                },
                              );
                            })),
                  );
                }
              },
              child: AnimatedCrossFade(
                duration: Duration(milliseconds: 500),
                crossFadeState: isFeaturedWidget ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(12),
                  //height: 116,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: context.color.territoryColor.withOpacity(0.1),
                    border: Border.all(color: context.color.borderColor.darken(30)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 12),
                        child: SvgPicture.asset(
                          AppIcons.createAddIcon,
                          height: 74,
                          width: 62,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              "${"featureYourAdsAttractMore".translate(context)}\n${"clientsAndSellFaster".translate(context)}",
                              color: context.color.textDefaultColor.withOpacity(0.7),
                              fontSize: context.font.large,
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                context.read<FetchUserPackageLimitCubit>().fetchUserPackageLimit(packageType: "advertisement");
                              },
                              child: Container(
                                height: 33,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: context.color.territoryColor,
                                ),
                                child: CustomText(
                                  "createFeaturedAd".translate(context),
                                  color: context.color.secondaryColor,
                                  fontSize: context.font.small,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                secondChild: SizedBox.shrink(),
              ),
            ),
          );
        }),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget customFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Wrap(
        children: [
          ...List.generate(model.customFields!.length, (index) {
            if (model.customFields![index].value!.isNotEmpty) {
              return DecoratedBox(
                decoration: BoxDecoration(border: Border.all(color: Colors.red.withOpacity(0))),
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * .45,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 33,
                        width: 33,
                        alignment: Alignment.center,
                        child: UiUtils.imageType(model.customFields![index].image!, fit: BoxFit.contain),
                      ),
                      SizedBox(width: 7),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: model.customFields![index].name,
                            child: CustomText((model.customFields?[index].name) ?? "",
                                maxLines: 1, fontSize: context.font.small, color: context.color.textLightColor),
                          ),
                          valueContent(model.customFields![index].value),
                          const SizedBox(
                            height: 12,
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return SizedBox();
            }
          }),
        ],
      ),
    );
  }

  Widget valueContent(List<dynamic>? value) {
    if (((value![0].toString()).startsWith("http") || (value[0].toString()).startsWith("https"))) {
      if ((value[0].toString()).toLowerCase().endsWith(".pdf")) {
        // Render PDF link as clickable text
        return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, Routes.pdfViewerScreen, arguments: {"url": value[0]});
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: UiUtils.getSvg(AppIcons.pdfIcon, color: context.color.textColorDark),
            ));
      } else if ((value[0]).toLowerCase().endsWith(".png") ||
          (value[0]).toLowerCase().endsWith(".jpg") ||
          (value[0]).toLowerCase().endsWith(".jpeg") ||
          (value[0]).toLowerCase().endsWith(".svg")) {
        // Render image
        return InkWell(
          onTap: () {
            UiUtils.showFullScreenImage(
              context,
              provider: NetworkImage(
                value[0],
              ),
            );
          },
          child: Container(
              width: 50,
              height: 50,
              margin: EdgeInsets.only(top: 2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: context.color.territoryColor.withOpacity(0.1)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: UiUtils.imageType(
                  value[0],
                  color: context.color.territoryColor,
                  fit: BoxFit.cover,
                ),
              )),
        );
      }
    }

    // Default text if not a supported format or not a URL
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * .3,
      child: CustomText(
        value.length == 1 ? value[0].toString() : value.join(','),
        softWrap: true,
        color: context.color.textDefaultColor,
      ),
    );
  }

  Widget itemData(int index, SubscriptionPackageModel model, StateSetter stateSetter) {
    return Padding(
      padding: const EdgeInsets.only(top: 7.0),
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          if (model.isActive!)
            Padding(
              padding: EdgeInsetsDirectional.only(start: 13.0),
              child: ClipPath(
                clipper: CapShapeClipper(),
                child: Container(
                    color: context.color.territoryColor,
                    width: MediaQuery.of(context).size.width / 3,
                    height: 17,
                    padding: EdgeInsets.only(top: 3),
                    child: CustomText(
                      'activePlanLbl'.translate(context),
                      color: context.color.secondaryColor,
                      textAlign: TextAlign.center,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    )),
              ),
            ),
          InkWell(
            onTap: () {
              _selectedPackageIndex = index;
              stateSetter(() {});
              setState(() {});
            },
            child: Container(
              margin: EdgeInsets.only(top: 17),
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                      color:
                          index == _selectedPackageIndex ? context.color.territoryColor : context.color.textDefaultColor.withOpacity(0.1),
                      width: 1.5)),
              child: !model.isActive! ? adsWidget(model) : activeAdsWidget(model),
            ),
          ),
        ],
      ),
    );
  }

  Widget adsWidget(SubscriptionPackageModel model) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                model.name!,
                firstUpperCaseWidget: true,
                fontWeight: FontWeight.w600,
                fontSize: context.font.large,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    '${model.limit == "unlimited" ? "unlimitedLbl".translate(context) : model.limit.toString()}\t${"adsLbl".translate(context)}\t\t·\t\t',
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    color: context.color.textDefaultColor.withOpacity(0.3),
                  ),
                  Flexible(
                    child: CustomText(
                      '${model.duration.toString()}\t${"days".translate(context)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      color: context.color.textDefaultColor.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(start: 10.0),
          child: CustomText(
            model.finalPrice! > 0 ? "${model.finalPrice!.currencyFormat}" : "free".translate(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget activeAdsWidget(SubscriptionPackageModel model) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                model.name!,
                firstUpperCaseWidget: true,
                fontWeight: FontWeight.w600,
                fontSize: context.font.large,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text:
                          model.limit == "unlimited" ? "${"unlimitedLbl".translate(context)}\t${"adsLbl".translate(context)}\t\t·\t\t" : '',
                      style: TextStyle(
                        color: context.color.textDefaultColor.withOpacity(0.3),
                      ),
                      children: [
                        if (model.limit != "unlimited")
                          TextSpan(
                            text: '${model.userPurchasedPackages![0].remainingItemLimit}',
                            style: TextStyle(color: context.color.textDefaultColor),
                          ),
                        if (model.limit != "unlimited")
                          TextSpan(
                            text: '/${model.limit.toString()}\t${"adsLbl".translate(context)}\t\t·\t\t',
                          ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text: model.duration == "unlimited" ? "${"unlimitedLbl".translate(context)}\t${"days".translate(context)}" : '',
                        style: TextStyle(
                          color: context.color.textDefaultColor.withOpacity(0.3),
                        ),
                        children: [
                          if (model.duration != "unlimited")
                            TextSpan(
                              text: '${model.userPurchasedPackages![0].remainingDays}',
                              style: TextStyle(color: context.color.textDefaultColor),
                            ),
                          if (model.duration != "unlimited")
                            TextSpan(
                              text: '/${model.duration.toString()}\t${"days".translate(context)}',
                            ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(start: 10.0),
          child: CustomText(
            model.finalPrice! > 0 ? "${model.finalPrice!.currencyFormat}" : "free".translate(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void showPackageSelectBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.color.secondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15.0),
          topRight: Radius.circular(15.0),
        ),
      ),
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxHeight: context.screenHeight * 0.85),
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: context.color.borderColor,
                    ),
                    height: 6,
                    width: 60,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 17, horizontal: 20),
                child: CustomText(
                  'selectPackage'.translate(context),
                  textAlign: TextAlign.start,
                  fontWeight: FontWeight.bold,
                  fontSize: context.font.large,
                ),
              ),

              Divider(height: 1), // Add some space between title and options
              Expanded(child: packageList()),
            ],
          ),
        );
      },
    );
  }

  Widget packageList() {
    return BlocBuilder<FetchAdsListingSubscriptionPackagesCubit, FetchAdsListingSubscriptionPackagesState>(
      builder: (context, state) {
        print("state package***$state");
        if (state is FetchAdsListingSubscriptionPackagesInProgress) {
          return Center(
            child: UiUtils.progress(),
          );
        }
        if (state is FetchAdsListingSubscriptionPackagesFailure) {
          if (state.errorMessage is ApiException) {
            if (state.errorMessage == "no-internet") {
              return NoInternet(
                onRetry: () {
                  context.read<FetchAdsListingSubscriptionPackagesCubit>().fetchPackages();
                },
              );
            }
          }

          return const SomethingWentWrong();
        }
        if (state is FetchAdsListingSubscriptionPackagesSuccess) {
          print("subscription plan list***${state.subscriptionPackages.length}");
          if (state.subscriptionPackages.isEmpty) {
            return NoDataFound(
              onTap: () {
                context.read<FetchAdsListingSubscriptionPackagesCubit>().fetchPackages();
              },
            );
          }

          return StatefulBuilder(builder: (BuildContext context, StateSetter setStater) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      itemBuilder: (context, index) {
                        return itemData(index, state.subscriptionPackages[index], setStater);
                      },
                      itemCount: state.subscriptionPackages.length),
                ),
                Builder(builder: (context) {
                  return BlocListener<RenewItemCubit, RenewItemState>(
                    listener: (context, changeState) {
                      if (changeState is RenewItemInSuccess) {
                        HelperUtils.showSnackBarMessage(context, changeState.responseMessage);
                        Future.delayed(Duration.zero, () {
                          Navigator.pop(context);
                          Navigator.pop(context, "refresh");
                        });
                      } else if (changeState is RenewItemFailure) {
                        Navigator.pop(context);
                        HelperUtils.showSnackBarMessage(context, changeState.error);
                      }
                    },
                    child: UiUtils.buildButton(context, onPressed: () {
                      if (state.subscriptionPackages[_selectedPackageIndex!].isActive!) {
                        Future.delayed(Duration.zero, () {
                          context
                              .read<RenewItemCubit>()
                              .renewItem(packageId: state.subscriptionPackages[_selectedPackageIndex!].id!, itemId: model.id!);
                        });
                      } else {
                        Navigator.pop(context);
                        HelperUtils.showSnackBarMessage(context, "pleasePurchasePackage".translate(context));
                        Navigator.pushNamed(context, Routes.subscriptionPackageListRoute);
                      }
                    },
                        radius: 10,
                        height: 46,
                        disabled: _selectedPackageIndex == null,
                        disabledColor: context.color.textLightColor.withOpacity(0.3),
                        fontSize: context.font.large,
                        buttonColor: context.color.territoryColor,
                        textColor: context.color.secondaryColor,
                        buttonTitle: "renewItem".translate(context),

                        //TODO: change title to Your Current Plan according to condition
                        outerPadding: const EdgeInsets.all(20)),
                  );
                })
              ],
            );
          });
        }

        return Container();
      },
    );
  }

  Widget bottomButtonWidget() {
    if (isAddedByMe) {
      final contextColor = context.color;

      if (model.status == "review") {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _editButton(contextColor),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _deleteButton(),
            ),
          ],
        );
      } else if (model.status == "active" || model.status == "approved") {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _editButton(contextColor),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _deleteButton(),
            ),
          ],
        );
      } else if (model.status == "sold out" || model.status == "inactive" || model.status == "rejected") {
        return _deleteButton();
      } else if (model.status == "expired") {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildButton("renew".translate(context), () {
                // selectPackageDialog();
                showPackageSelectBottomSheet();
              }, contextColor.secondaryColor, contextColor.territoryColor),
            ),
            SizedBox(width: 10),
            Expanded(child: _deleteButton()),
          ],
        );
      } else {
        return const SizedBox();
      }
    } else {
      return BlocBuilder<GetBuyerChatListCubit, GetBuyerChatListState>(
        bloc: context.read<GetBuyerChatListCubit>(),
        builder: (context, State) {
          chat_models.ChatUser? chatedUser = context.select((GetBuyerChatListCubit cubit) => cubit.getOfferForItem(model.id!));

          return BlocListener<MakeAnOfferItemCubit, MakeAnOfferItemState>(
            listener: (context, state) {
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
                    seller: chat_models.Seller.fromJson(data['seller'])));

                if (state.from == 'offer') {
                  HelperUtils.showSnackBarMessage(
                    context,
                    state.message.toString(),
                  );
                }

                Navigator.push(context, BlurredRouter(
                  builder: (context) {
                    return MultiBlocProvider(
                      providers: [
                        BlocProvider(
                          create: (context) => SendMessageCubit(),
                        ),
                        BlocProvider(
                          create: (context) => LoadChatMessagesCubit(),
                        ),
                        BlocProvider(
                          create: (context) => DeleteMessageCubit(),
                        ),
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
                        itemOfferId: state.data['id'] is String ? int.parse(state.data['id']) : state.data['id'],
                        itemPrice: model.price!,
                        status: model.status!,
                        buyerId: HiveUtils.getUserId(),
                        itemOfferPrice: state.data['amount'] != null ? double.parse(state.data['amount'].toString()) : null,
                        isPurchased: model.isPurchased ?? 0,
                        alreadyReview: model.review == null
                            ? false
                            : model.review!.isEmpty
                                ? false
                                : true,
                        isFromBuyerList: true,
                      ),
                    );
                  },
                ));
              }
              if (state is MakeAnOfferItemFailure) {
                HelperUtils.showSnackBarMessage(
                  context,
                  state.errorMessage.toString(),
                );
              }
            },
            child: Row(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (model.user?.showPersonalDetails == 1 && model.user?.mobile != null)
                  Expanded(
                    child: _buildButton(
                      'WhatsApp',
                      _onWhatsappPressed,
                      null,
                      null,
                    ),
                  ),
                if (chatedUser == null)
                  Expanded(
                    child: _buildButton('chat'.translate(context), () {
                      UiUtils.checkUser(
                          onNotGuest: () {
                            context.read<MakeAnOfferItemCubit>().makeAnOfferItem(id: model.id!, from: "chat");
                          },
                          context: context);
                    }, null, null),
                  ),
                if (chatedUser != null)
                  Expanded(
                    child: _buildButton("chat".translate(context), () {
                      UiUtils.checkUser(
                          onNotGuest: () {
                            Navigator.push(context, BlurredRouter(
                              builder: (context) {
                                return MultiBlocProvider(
                                  providers: [
                                    BlocProvider(
                                      create: (context) => SendMessageCubit(),
                                    ),
                                    BlocProvider(
                                      create: (context) => LoadChatMessagesCubit(),
                                    ),
                                    BlocProvider(
                                      create: (context) => DeleteMessageCubit(),
                                    ),
                                  ],
                                  child: ChatScreen(
                                    itemId: chatedUser.itemId.toString(),
                                    profilePicture:
                                        chatedUser.seller != null && chatedUser.seller!.profile != null ? chatedUser.seller!.profile! : "",
                                    userName: chatedUser.seller != null && chatedUser.seller!.name != null ? chatedUser.seller!.name! : "",
                                    date: chatedUser.createdAt!,
                                    itemOfferId: chatedUser.id!,
                                    itemPrice: chatedUser.item != null && chatedUser.item!.price != null ? chatedUser.item!.price! : 0.0,
                                    itemOfferPrice: chatedUser.amount != null ? chatedUser.amount! : null,
                                    itemImage: chatedUser.item != null && chatedUser.item!.image != null ? chatedUser.item!.image! : "",
                                    itemTitle: chatedUser.item != null && chatedUser.item!.name != null ? chatedUser.item!.name! : "",
                                    userId: chatedUser.sellerId.toString(),
                                    buyerId: chatedUser.buyerId.toString(),
                                    status: chatedUser.item!.status,
                                    from: "item",
                                    isPurchased: model.isPurchased ?? 0,
                                    alreadyReview: model.review == null
                                        ? false
                                        : model.review!.isEmpty
                                            ? false
                                            : true,
                                    isFromBuyerList: true,
                                  ),
                                );
                              },
                            ));
                          },
                          context: context);
                    }, null, null),
                  ),
              ],
            ),
          );
        },
      );
    }
  }

  void safetyTipsBottomSheet() {
    List<SafetyTipsModel>? tipsList = context.read<FetchSafetyTipsListCubit>().getList();
    if (tipsList == null || tipsList.isEmpty) {
      makeOfferBottomSheet(model);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.0),
          topRight: Radius.circular(18.0),
        ),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: context.color.textColorDark.withOpacity(0.1),
                    ),
                    height: 6,
                    width: 60,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: UiUtils.getSvg(
                  AppIcons.safetyTipsIcon,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 5),
                child: CustomText(
                  'safetyTips'.translate(context),
                  fontWeight: FontWeight.w600,
                  fontSize: context.font.larger,
                  textAlign: TextAlign.center,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: tipsList.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return checkmarkPoint(
                    context,
                    tipsList[index].translatedName!,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildButton(
                  "continueToOffer".translate(context),
                  () {
                    Navigator.pop(context);
                    makeOfferBottomSheet(model);
                  },
                  context.color.territoryColor,
                  context.color.secondaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget checkmarkPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiUtils.getSvg(
            AppIcons.active_mark,
          ),
          const SizedBox(width: 12),
          Expanded(
              child: CustomText(
            text.firstUpperCase(),
            textAlign: TextAlign.start,
            color: context.color.textDefaultColor,
            fontSize: context.font.large,
          )),
        ],
      ),
    );
  }

  Widget _buildButton(String title, VoidCallback onPressed, Color? buttonColor, Color? textColor) {
    return UiUtils.buildButton(
      context,
      onPressed: onPressed,
      radius: 10,
      height: 46,
      border: buttonColor != null ? BorderSide(color: context.color.territoryColor) : null,
      buttonColor: buttonColor,
      textColor: textColor,
      buttonTitle: title,
      width: 50,
    );
  }

//ImageView
  Widget setImageViewer() {
    return Container(
      height: 250,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(vertical: 10),
      // decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(children: [
          PageView.builder(
            itemCount: images.length,
            // Increase itemCount if videoLink is present
            controller: pageController,
            itemBuilder: (context, index) {
              if (index == images.length - 1 && model.videoLink != "" && model.videoLink != null) {
                return Stack(
                  children: [
                    // Thumbnail Image
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return VideoViewScreen(
                                videoUrl: model.videoLink ?? "",
                                flickManager: flickManager,
                              );
                            },
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: UiUtils.getImage(
                          youtubeVideoThumbnail,
                          fit: BoxFit.cover,
                          height: 250,
                          width: double.maxFinite,
                        ),
                      ),
                    ),
                    // Play Button
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return VideoViewScreen(
                                  videoUrl: model.videoLink ?? "",
                                  flickManager: flickManager,
                                );
                              },
                            ),
                          );
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.3),
                              ),
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 25,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Display image
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x7F060606)],
                    ).createShader(bounds);
                    //TODO: change black color to some other app color if required
                  },
                  blendMode: BlendMode.darken,
                  child: InkWell(
                    child: UiUtils.getImage(
                      images[index]!,
                      fit: BoxFit.cover,
                      height: 250,
                    ),
                    onTap: () {
                      UiUtils.imageGallaryView(context, images: images, initalIndex: index);
                    },
                  ),
                );
              }
            },
          ),
          Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  // Increase number of dots if videoLink is present
                  (index) => buildDot(index),
                ),
              ),
            ),
          ),
          if (model.isFeature != null)
            if (model.isFeature!)
              setTopRowItem(
                alignment: AlignmentDirectional.topStart,
                marginVal: 15,
                cornerRadius: 5,
                backgroundColor: context.color.territoryColor,
                child: CustomText(
                  "featured".translate(context),
                  fontSize: context.font.small,
                  color: context.color.backgroundColor,
                ),
              ),
          _favouriteButton()
        ]),
      ),
    );
  }

  Widget setTopRowItem({
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
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(cornerRadius), color: backgroundColor),
        child: child,
      ),
    );
  }

  Widget buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3.0),
      width: currentPage == index ? 12.0 : 8.0,
      height: 8.0,
      decoration: BoxDecoration(shape: BoxShape.circle, color: currentPage == index ? Colors.white : Colors.grey),
    );
  }

//ImageView

  Widget setLikesAndViewsCount() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(width: 1, color: context.color.textDefaultColor.withOpacity(0.1))),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  height: 46,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      UiUtils.getSvg(AppIcons.eye, color: context.color.textDefaultColor),
                      const SizedBox(
                        width: 8,
                      ),
                      CustomText(
                        model.views != null ? model.views!.toString() : "0",
                        color: context.color.textDefaultColor.withOpacity(0.8),
                        fontSize: context.font.large,
                      )
                    ],
                  ))),
          SizedBox(width: 20),
          Expanded(
              child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(width: 1, color: context.color.textDefaultColor.withOpacity(0.1))),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  height: 46,
                  //alignment: AlignmentDirectional.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      UiUtils.getSvg(AppIcons.like, color: context.color.textDefaultColor),
                      const SizedBox(
                        width: 8,
                      ),
                      CustomText(model.totalLikes == null ? "0" : model.totalLikes.toString(),
                          color: context.color.textDefaultColor.withOpacity(0.8), fontSize: context.font.large)
                    ],
                  ))),
        ],
      ),
    );
  }

  Widget setRejectedReason() {
    if (model.status == "rejected" && (model.rejectedReason != null || model.rejectedReason != "")) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.color.textDefaultColor.withOpacity(0.1)),

          // Background color
        ),
        margin: const EdgeInsets.symmetric(vertical: 15),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        child: Row(
            //crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.report,
                size: 20,
                color: Colors.red, // Icon color can be adjusted
              ),
              SizedBox(
                width: 5,
              ),
              Expanded(
                child: CustomText(
                  '${"rejection_reason".translate(context)}: ${model.rejectedReason ?? 'N/A'}',
                  color: context.color.textDefaultColor,
                  fontSize: context.font.large,
                ),
              ),
            ]),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget setPriceAndStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: CustomText(
            model.price!.currencyFormat,
            fontSize: context.font.larger,
            color: context.color.territoryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (model.status != null && isAddedByMe)
          Container(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _getStatusColor(model.status),
            ),
            child: CustomText(
              _getStatusCustomText(model.status)!,
              fontSize: context.font.normal,
              color: _getStatusTextColor(model.status),
            ),
          )

        //TODO: change color according to status - confirm,pending,etc..
      ],
    );
  }

  String? _getStatusCustomText(String? status) {
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

  Color _getStatusColor(String? status) {
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

  Color _getStatusTextColor(String? status) {
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

  Widget setAddress({required bool isDate}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: (isDate) ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            AppIcons.location,
            colorFilter: ColorFilter.mode(context.color.territoryColor, BlendMode.srcIn),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: 5.0),
              child: CustomText(
                model.address!,
                color: context.color.textDefaultColor.withOpacity(0.3),
              ),
            ),
          ),
          (isDate)
              ? Expanded(
                  flex: 2,
                  child: CustomText(
                    model.created!.formatDate(format: "d MMM yyyy", withJM: false),
                    maxLines: 1,
                    textAlign: TextAlign.end,
                    color: context.color.textDefaultColor.withOpacity(0.3),
                  ))
              : const SizedBox.shrink()
          //TODO: add DATE from model
        ],
      ),
    );
  }

  Widget setDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "aboutThisItemLbl".translate(context),
          fontWeight: FontWeight.bold,
          fontSize: context.font.large,
        ), //TODO: replace label with your own - aboutThisPropLbl
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: CustomText(
            model.description!,
            color: context.color.textDefaultColor.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  void _navigateToGoogleMapScreen(BuildContext context) {
    Navigator.push(
      context,
      BlurredRouter(
        barrierDismiss: true,
        builder: (context) {
          return GoogleMapScreen(
            item: model,
            kInitialPlace: _kInitialPlace,
            controller: _controller,
          );
        },
      ),
    );
  }

  Widget setLocation() {
    final LatLng currentPosition = LatLng(model.latitude!, model.longitude!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "locationLbl".translate(context),
          fontWeight: FontWeight.bold,
          fontSize: context.font.large,
        ),
        setAddress(isDate: false),
        SizedBox(
          height: 5,
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 200,
            child: GoogleMap(
              zoomControlsEnabled: false,
              zoomGesturesEnabled: false,
              onTap: (latLng) {
                _navigateToGoogleMapScreen(context);
              },
              initialCameraPosition: CameraPosition(target: currentPosition, zoom: 13),
              mapType: MapType.normal,
              markers: {
                Marker(
                  markerId: MarkerId('currentPosition'),
                  position: currentPosition,
                  onTap: () {
                    // Navigate on marker tap
                    _navigateToGoogleMapScreen(context);
                  },
                )
              },
            ),
          ),
        ),
      ],
    );
  }

  void makeOfferBottomSheet(ItemModel model) async {
    await UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        content: makeAnOffer(),
        onCancel: () {
          _makeAnOffermessageController.clear();
        },
        acceptButtonName: "send".translate(context),
        isAcceptContainerPush: true,
        onAccept: () => Future.value().then((_) {
          if (_offerFormKey.currentState!.validate()) {
            context
                .read<MakeAnOfferItemCubit>()
                .makeAnOfferItem(id: model.id!, from: "offer", amount: double.parse(_makeAnOffermessageController.text.trim()));
            Navigator.pop(context);
            return;
          }
        }),
      ),
    );
  }

  Widget makeAnOffer() {
    double bottomPadding = (MediaQuery.of(context).viewInsets.bottom - 50);
    bool isBottomPaddingNegative = bottomPadding.isNegative;
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Form(
          key: _offerFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                "makeAnOffer".translate(context),
                fontSize: context.font.larger,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
              Divider(
                thickness: 1,
                color: context.color.borderColor.darken(30),
              ),
              const SizedBox(
                height: 15,
              ),
              RichText(
                text: TextSpan(
                  text: '${"sellerPrice".translate(context)} ',
                  style: TextStyle(color: context.color.textDefaultColor.withOpacity(0.3), fontSize: 16),
                  children: <TextSpan>[
                    TextSpan(
                      text: model.price!.currencyFormat,
                      style: TextStyle(color: context.color.textDefaultColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(bottom: isBottomPaddingNegative ? 0 : bottomPadding, start: 20, end: 20, top: 18),
                child: TextFormField(
                  maxLines: null,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: context.color.textDefaultColor),
                  controller: _makeAnOffermessageController,
                  cursorColor: context.color.territoryColor,
                  //autovalidateMode: AutovalidateMode.always,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return Validator.nullCheckValidator(val, context: context);
                    } else {
                      double parsedVal = double.parse(val);
                      if (parsedVal <= 0.0) {
                        return "valueMustBeGreaterThanZeroLbl".translate(context);
                      } else if (parsedVal > model.price!) {
                        return "offerPriceWarning".translate(context);
                      }
                      return null;
                    }
                  },
                  decoration: InputDecoration(
                      fillColor: context.color.borderColor.darken(20),
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      hintText: "yourOffer".translate(context),
                      hintStyle:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: context.color.textDefaultColor.withOpacity(0.3)),
                      focusColor: context.color.territoryColor,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.color.borderColor.darken(60))),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.color.borderColor.darken(60))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.color.territoryColor))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showReportItemDialog(int itemId) async {
    // await context.read<FetchItemReportReasonsListCubit>().fetch(forceRefresh: true);
    await UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
          title: "reportItem".translate(context),
          content: reportReason(),
          isAcceptContainerPush: true,
          onAccept: () => Future.value().then((_) async {
                final selectedId = (context.read<FetchItemReportReasonsListCubit>().state as FetchItemReportReasonsSuccess).selectedId;
                String? message = _formKey.currentState!.validate() && selectedId.isNegative ? _reportmessageController.text : null;

                await context.read<ItemReportCubit>().report(item_id: model.id!, reason_id: selectedId, message: message);
                _onRefresh();
                Navigator.pop(context);
              })),
    );
  }

  String formatPhoneNumber(String fullNumber, String countryCode) {
    // Normalize the country code (remove '+' if present)
    countryCode = countryCode.replaceAll('+', '');

    // Remove '+' from fullNumber if present
    fullNumber = fullNumber.replaceAll('+', '');

    // Check if the fullNumber already starts with the country code
    if (!fullNumber.startsWith(countryCode)) {
      // If not, prepend the country code
      fullNumber = countryCode + fullNumber;
    }

    // Add '+' to the beginning of the full number
    fullNumber = '+' + fullNumber;

    return fullNumber;
  }

  Widget setSellerDetails() {
    return InkWell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            Row(children: [
              SizedBox(
                  height: 60,
                  width: 60,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: model.user!.profile != null && model.user!.profile != ""
                          ? UiUtils.getImage(model.user!.profile!, fit: BoxFit.fill)
                          : UiUtils.getSvg(
                              AppIcons.defaultPersonLogo,
                              color: context.color.territoryColor,
                              fit: BoxFit.none,
                            ))),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (model.user!.isVerified == 1)
                      Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: context.color.forthColor),
                        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            UiUtils.getSvg(AppIcons.verifiedIcon, width: 14, height: 14),
                            SizedBox(
                              width: 4,
                            ),
                            CustomText(
                              "verifiedLbl".translate(context),
                              color: context.color.secondaryColor,
                              fontWeight: FontWeight.w500,
                            )
                          ],
                        ),
                      ),
                    CustomText(model.user!.name!, fontWeight: FontWeight.bold, fontSize: context.font.large),
                    if (context.watch<FetchSellerRatingsCubit>().sellerData() != null)
                      if (context.watch<FetchSellerRatingsCubit>().sellerData()!.averageRating != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                WidgetSpan(
                                  child: Icon(Icons.star_rounded, size: 17, color: context.color.textDefaultColor), // Star icon
                                ),
                                TextSpan(
                                  text:
                                      '\t${context.watch<FetchSellerRatingsCubit>().sellerData()!.averageRating!.toStringAsFixed(2).toString()}',
                                  // Rating value
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.color.textDefaultColor,
                                  ),
                                ),
                                TextSpan(
                                  text: '  |  ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.color.textDefaultColor.withOpacity(0.3),
                                  ),
                                ),
                                TextSpan(
                                  text: '${context.watch<FetchSellerRatingsCubit>().totalSellerRatings()}\t${"ratings".translate(context)}',
                                  // Rating count text
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.color.textDefaultColor.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (model.user!.showPersonalDetails == 1)
                      if (model.user!.email != null || model.user!.email != "")
                        CustomText(model.user!.email!, color: context.color.textLightColor, fontSize: context.font.small),
                  ]),
                ),
              ),
              if (model.user!.showPersonalDetails == 1)
                if (model.user!.mobile != null || model.user!.mobile != "")
                  setIconButtons(
                      assetName: AppIcons.message,
                      onTap: () {
                        HelperUtils.launchPathURL(
                            isTelephone: false,
                            isSMS: true,
                            isMail: false,
                            value: formatPhoneNumber(model.user!.mobile!, Constant.defaultCountryCode),
                            context: context);
                      }),
              SizedBox(width: 10),
              if (model.user!.showPersonalDetails == 1)
                if (model.user!.mobile != null || model.user!.mobile != "")
                  setIconButtons(
                      assetName: AppIcons.call,
                      onTap: () {
                        HelperUtils.launchPathURL(
                            isTelephone: true,
                            isSMS: false,
                            isMail: false,
                            value: formatPhoneNumber(model.user!.mobile!, Constant.defaultCountryCode),
                            context: context);
                      })
            ]),

            // View profile and review buttons
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.sellerProfileScreen, arguments: {
                        "model": model.user!,
                        "total": context.read<FetchSellerRatingsCubit>().totalSellerRatings() ?? 0,
                        "rating": context.read<FetchSellerRatingsCubit>().sellerData()?.averageRating,
                      });
                    },
                    icon: Icon(Icons.person, color: context.color.buttonColor),
                    label: CustomText(
                      "View Profile",
                      color: context.color.buttonColor,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.color.territoryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                _userHasRatedItemBuilder(child: SizedBox(width: 10)),
                _userHasRatedItemBuilder(
                  child: Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showServiceReviewDialog(
                            serviceId: model.id!,
                            userId: model.userId!,
                            name: model.name ?? "Service",
                            image: model.image,
                            isExperience: model.itemType == "experience");
                      },
                      icon: Icon(Icons.rate_review, color: context.color.buttonColor),
                      label: CustomText(
                        "Write Review",
                        color: context.color.buttonColor,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.color.territoryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.pushNamed(context, Routes.sellerProfileScreen, arguments: {
          "model": model.user!,
          "total": context.read<FetchSellerRatingsCubit>().totalSellerRatings() ?? 0,
          "rating": context.read<FetchSellerRatingsCubit>().sellerData()!.averageRating,
        });
      },
    );
  }

  Widget _userHasRatedItemBuilder({required Widget child}) => BlocBuilder<UserHasRatedItemCubit, UserHasRatedItemState>(
        builder: (context, state) {
          if (state is! UserHasRatedItemInSuccess || state.userHasRatedItem) return Container();
          return child;
        },
      );

  // Show service/experience review dialog
  void _showServiceReviewDialog({
    required int serviceId,
    required int userId,
    required String name,
    String? image,
    bool isExperience = false,
  }) {
    UiUtils.checkUser(
      onNotGuest: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return BlocProvider(
              create: (context) => AddUserReviewCubit(),
              child: ReviewDialog(
                targetId: serviceId,
                userId: userId,
                reviewType: isExperience ? ReviewType.experience : ReviewType.service,
                name: name,
                image: image,
              ),
            );
          },
        ).then((value) {
          if (value == true) {
            // Refresh reviews after adding a new one
            if (mounted) {
              if (model.id != null) {
                // Refresh the reviews from the API
                context.read<FetchItemReviewsCubit>().fetchItemReviews(itemId: model.id!);
                context.read<UserHasRatedItemCubit>().userHasRatedItem(itemId: model.id!);
              }
            }
          }
        });
      },
      context: context,
    );
  }

  // Show login required dialog
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.color.secondaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Center(
            child: Text(
              "Login Required",
              style: TextStyle(
                fontSize: context.font.larger,
                fontWeight: FontWeight.bold,
                color: context.color.textDefaultColor,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 60,
                color: context.color.territoryColor,
              ),
              const SizedBox(height: 20),
              Text(
                "You need to be logged in to write a review",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.color.textDefaultColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: context.color.textColorDark,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.color.territoryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.login);
              },
              child: Text(
                "Login",
                style: TextStyle(
                  color: context.color.buttonColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show all reviews in a modal
  void _showAllReviews(List<UserRatings> reviews) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.color.secondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 5,
                      width: 40,
                      decoration: BoxDecoration(
                        color: context.color.borderColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        "All Reviews (${reviews.length})",
                        fontWeight: FontWeight.bold,
                        fontSize: context.font.larger,
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];

                        // Use either reviewer or buyer field
                        final userDetails = review.reviewer ?? review.buyer;

                        final hasProfile = userDetails != null && userDetails.profile != null && userDetails.profile!.isNotEmpty;

                        final reviewerName = userDetails != null && userDetails.name != null ? userDetails.name! : "Anonymous";

                        // Add a subtle "You" indicator if this is your own review
                        final isOwnReview =
                            userDetails != null && userDetails.id != null && userDetails.id.toString() == HiveUtils.getUserId();

                        return Card(
                          color: context.color.secondaryColor,
                          margin: EdgeInsets.symmetric(vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Reviewer Profile Image
                                hasProfile
                                    ? CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          userDetails.profile!,
                                        ),
                                      )
                                    : CircleAvatar(
                                        backgroundColor: context.color.territoryColor,
                                        child: Icon(
                                          Icons.person,
                                          color: context.color.buttonColor,
                                        ),
                                      ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          CustomText(
                                            isOwnReview ? "$reviewerName (You)" : reviewerName,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          if (review.createdAt != null)
                                            CustomText(
                                              _formatDate(review.createdAt!),
                                              fontSize: context.font.small,
                                              color: context.color.textDefaultColor.withOpacity(0.6),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Row(
                                        children: [
                                          for (int i = 0; i < 5; i++)
                                            Icon(
                                              i < (review.ratings ?? 0).floor() ? Icons.star : Icons.star_border,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                          SizedBox(width: 5),
                                          CustomText(
                                            "${review.ratings}",
                                            fontSize: context.font.small,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      CustomText(
                                        review.review ?? "",
                                        color: context.color.textDefaultColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to format date
  String _formatDate(String dateString) {
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

  Widget setIconButtons({
    required String assetName,
    required void Function() onTap,
    Color? color,
    double? height,
    double? width,
  }) {
    return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: context.color.borderColor.darken(30))),
        child: Padding(
            padding: const EdgeInsets.all(5),
            child: InkWell(
                onTap: onTap,
                child: SvgPicture.asset(
                  assetName,
                  colorFilter: color == null
                      ? ColorFilter.mode(context.color.territoryColor, BlendMode.srcIn)
                      : ColorFilter.mode(color, BlendMode.srcIn),
                ))));
  }

  Widget reportReason() {
    double bottomPadding = MediaQuery.of(context).viewInsets.bottom - 50;
    bool isBottomPaddingNegative = bottomPadding.isNegative;
    return BlocBuilder<FetchItemReportReasonsListCubit, FetchItemReportReasonsListState>(builder: (context, state) {
      if (state is FetchItemReportReasonsInitial) {
        context.read<FetchItemReportReasonsListCubit>().fetch(forceRefresh: true);
        return UiUtils.progress();
      }
      if (state is FetchItemReportReasonsInProgress) return UiUtils.progress();
      if (state is FetchItemReportReasonsFailure) return Center(child: DescriptionText(state.error));
      final reasons = (state is! FetchItemReportReasonsSuccess) ? <ReportReason>[] : state.reasons;
      final selectedId = state is! FetchItemReportReasonsSuccess ? -10 : state.selectedId;
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((reasons.length ?? 0) > 1)
                  ListView.separated(
                    shrinkWrap: true,
                    itemCount: reasons.length ?? 0,
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 10);
                    },
                    itemBuilder: (context, index) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          context.read<FetchItemReportReasonsListCubit>().selectId(reasons[index].id);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.color.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selectedId == reasons[index].id ? context.color.primary : Colors.grey.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: DescriptionText(reasons[index].reason.firstUpperCase()),
                          ),
                        ),
                      );
                    },
                  ),
                if (selectedId.isNegative)
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      bottom: isBottomPaddingNegative ? 0 : bottomPadding,
                      start: 0,
                      end: 0,
                    ),
                    child: TextFormField(
                      maxLines: null,
                      controller: _reportmessageController,
                      cursorColor: context.color.territoryColor,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return "addReportReason".translate(context);
                        } else {
                          return null;
                        }
                      },
                      style: context.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: "writeReasonHere".translate(context),
                        focusColor: context.color.territoryColor,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: context.color.territoryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget setSpecialTagsAndPriceType() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Price type tag
          if (model.priceType != null && model.priceType!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.color.territoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomText(
                model.priceType!,
                fontSize: context.font.small,
                color: context.color.territoryColor,
              ),
            ),

          // For women tag
          if (model.specialTags != null &&
              model.specialTags!.containsKey('exclusive_women') &&
              (model.specialTags!['exclusive_women'] == true || model.specialTags!['exclusive_women'] == "true"))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.female, size: 16, color: Colors.pink),
                  const SizedBox(width: 4),
                  CustomText(
                    "For women".translate(context),
                    fontSize: context.font.small,
                    color: Colors.pink,
                  ),
                ],
              ),
            ),

          // Category tag
          if (model.category != null && model.category!.name != null && model.category!.name!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.color.territoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UiUtils.getSvg(AppIcons.categoryIcon, width: 16, height: 16, color: context.color.territoryColor),
                  const SizedBox(width: 4),
                  CustomText(
                    model.category!.name!,
                    fontSize: context.font.small,
                    color: context.color.territoryColor,
                  ),
                ],
              ),
            ),

          // Corporate tag
          if (model.specialTags != null &&
              model.specialTags!.containsKey('corporate_package') &&
              (model.specialTags!['corporate_package'] == true || model.specialTags!['corporate_package'] == "true"))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  CustomText(
                    "Corporate".translate(context),
                    fontSize: context.font.small,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _deleteButton() => BlocProvider(
        create: (context) => DeleteItemCubit(),
        child: Builder(builder: (context) {
          return BlocListener<DeleteItemCubit, DeleteItemState>(
            listener: (context, deleteState) {
              if (deleteState is DeleteItemSuccess) {
                HelperUtils.showSnackBarMessage(context, "deleteItemSuccessMsg".translate(context));

                context.read<FetchMyItemsCubit>().deleteItem(model);
                Navigator.pop(context, "refresh");
              } else if (deleteState is DeleteItemFailure) {
                HelperUtils.showSnackBarMessage(context, deleteState.errorMessage);
              }
            },
            child: _buildButton("lblremove".translate(context), () async {
              await UiUtils.showBlurredDialoge(
                context,
                dialoge: BlurredDialogBox(
                  title: 'Delete Listing',
                  content: DescriptionText(
                    'Are you sure you want to delete this item?',
                  ),
                  isAcceptContainerPush: true,
                  onAccept: () async {
                    context.read<DeleteItemCubit>().deleteItem(model.id!);
                    Navigator.pop(context);
                  },
                ),
              );
            }, null, null),
          );
        }),
      );

  Widget _editButton(ColorScheme contextColor) => _buildButton("editBtnLbl".translate(context), () {
        addCloudData("edit_request", model);
        addCloudData("edit_from", model.status);
        Navigator.pushNamed(context, Routes.addItemDetails, arguments: {"isEdit": true, 'item': model}).then((value) {
          // When we return from edit screen, refresh the detail view with the latest data
          if (value == "refresh" || value == true) {
            // Force cache reset and refresh the current screen with updated data
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print("Refreshing item details after edit with slug: ${model.slug}");

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Refreshing..."),
                  duration: Duration(seconds: 1),
                ),
              );
              // Get a reference to the current cubit
              final cubit = BlocProvider.of<FetchItemFromSlugCubit>(context, listen: false);

              // First set it to initial state to force a full refresh
              cubit.emit(FetchItemFromSlugInitial());

              // Then trigger a new fetch with a slight delay
              Future.delayed(Duration(milliseconds: 300), () {
                if (mounted) {
                  cubit.fetchItemFromSlug(slug: model.slug ?? "");
                }
              });
            });

            // Update related items cubit if needed
            if (model.categoryId != null) {
              context.read<FetchRelatedItemsCubit>().fetchRelatedItems(
                    categoryId: model.categoryId!,
                    country: model.country,
                    state: model.state,
                    city: model.city,
                    areaId: model.areaId,
                  );
            }
          }
        });
      }, contextColor.secondaryColor, contextColor.territoryColor);
}
