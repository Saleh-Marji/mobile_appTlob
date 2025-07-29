// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:developer';

import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:tlobni/data/cubits/report/fetch_item_report_reason_list.dart';
import 'package:tlobni/data/cubits/report/item_report_cubit.dart';
import 'package:tlobni/data/cubits/report/update_report_items_list_cubit.dart';
import 'package:tlobni/data/cubits/safety_tips_cubit.dart';
import 'package:tlobni/data/cubits/seller/fetch_seller_ratings_cubit.dart';
import 'package:tlobni/data/cubits/subscription/fetch_ads_listing_subscription_packages_cubit.dart';
import 'package:tlobni/data/cubits/user_has_rated_item_cubit.dart';
import 'package:tlobni/data/helper/widgets.dart';
import 'package:tlobni/data/model/chat/chat_user_model.dart' as chat_models;
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/report_item/reason_model.dart';
import 'package:tlobni/ui/screens/ad_details_screen/controllers/ad_details_controller.dart';
import 'package:tlobni/ui/screens/ad_details_screen/mixins/ad_details_mixins.dart';
import 'package:tlobni/ui/screens/ad_details_screen/widgets/ad_details_widgets.dart';
import 'package:tlobni/ui/screens/ad_details_screen/widgets/custom_web_video_player.dart';
import 'package:tlobni/ui/screens/ad_details_screen/widgets/reviews_stars.dart';
import 'package:tlobni/ui/screens/chat/chat_screen.dart';
import 'package:tlobni/ui/screens/home/widgets/provider_home_screen_container.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/models/post_type.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:tlobni/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:tlobni/ui/screens/widgets/item_pricing_container.dart';
import 'package:tlobni/ui/screens/widgets/review_dialog.dart';
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
import 'package:tlobni/utils/cloud_state/cloud_state.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/extensions/lib/widget_iterable.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
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
                BlocProvider(create: (context) => FetchMyItemsCubit()),
                BlocProvider(create: (context) => CreateFeaturedAdCubit()),
                BlocProvider(create: (context) => FetchItemReportReasonsListCubit()),
                BlocProvider(create: (context) => ItemReportCubit()),
                BlocProvider(create: (context) => MakeAnOfferItemCubit()),
                BlocProvider(create: (context) => FetchItemFromSlugCubit()),
                BlocProvider(create: (context) => FetchItemReviewsCubit()),
              ],
              child: AdDetailsScreen(
                model: arguments?['model'],
                slug: arguments?['slug'],
              ),
            ));
  }
}

class AdDetailsScreenState extends CloudState<AdDetailsScreen> with AdDetailsMixins {
  // State variables
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
  bool isFeaturedWidget = true;
  String youtubeVideoThumbnail = "";
  int? categoryId;
  FlickManager? flickManager;

  // Computed properties
  bool get isAddedByMe => AdDetailsController.isItemAddedByMe(model);

  @override
  void initState() {
    super.initState();
    if (widget.model != null) {
      model = widget.model!;
      AdDetailsController.initVariables(context, widget.model!);
    }
    _onRefresh();
    _setupControllers();
  }

  void _setupControllers() {
    pageController.addListener(() {
      setState(() {
        currentPage = pageController.page!.round();
      });
    });
    _pageScrollController.addListener(_pageScroll);
  }

  late final CameraPosition _kInitialPlace = AdDetailsController.getInitialCameraPosition(model);

  @override
  void dispose() {
    super.dispose();
  }

  // UI Components
  PreferredSize _appBar() => UiUtils.buildAppBar(
        context,
        title: '${widget.model?.type == 'experience' ? 'Experience' : 'Service'} Details',
        showBackButton: true,
      );

  Widget _imagesViewer() => PageView.builder(
        itemCount: images.length,
        controller: pageController,
        itemBuilder: (context, index) => _buildImageItem(index),
      );

  Widget _buildImageItem(int index) {
    if (index == images.length - 1 && model.videoLink != "" && model.videoLink != null) {
      return _buildVideoThumbnail();
    } else {
      return _buildImageThumbnail(index);
    }
  }

  Widget _buildVideoThumbnail() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _navigateToVideoScreen(),
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
        Positioned.fill(
          child: GestureDetector(
            onTap: () => _navigateToVideoScreen(),
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.3),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 25),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(int index) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x7F060606)],
        ).createShader(bounds);
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

  void _navigateToVideoScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoViewScreen(
          videoUrl: model.videoLink ?? "",
          flickManager: flickManager,
        ),
      ),
    );
  }

  Widget _imagesIndex() => Align(
        alignment: AlignmentDirectional.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => AdDetailsWidgets.buildDot(currentPage, index),
            ),
          ),
        ),
      );

  Widget _favouriteButton() {
    return BlocBuilder<FavoriteCubit, FavoriteState>(
      bloc: context.read<FavoriteCubit>(),
      builder: (context, favState) {
        bool isLike = context.select((FavoriteCubit cubit) => cubit.isItemFavorite(model.id!));

        return BlocConsumer<UpdateFavoriteCubit, UpdateFavoriteState>(
          bloc: context.read<UpdateFavoriteCubit>(),
          listener: AdDetailsController.favoriteCubitListener,
          builder: (context, state) {
            if (state is UpdateFavoriteInProgress) {
              double size = 30.0;
              return AdDetailsWidgets.buildActionButton(
                icon: Icons.favorite,
                onPressed: () {},
                context: context,
              );
            }
            return AdDetailsWidgets.buildActionButton(
              icon: isLike ? Icons.favorite : Icons.favorite_border,
              onPressed: () => AdDetailsController.updateFavorite(context, model, isLike),
              context: context,
            );
          },
        );
      },
    );
  }

  Widget _topRightActions() => AdDetailsWidgets.buildTopRowItem(
        alignment: AlignmentDirectional.topEnd,
        marginVal: 10,
        cornerRadius: 0,
        backgroundColor: null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            _favouriteButton(),
            AdDetailsWidgets.buildActionButton(
              icon: Icons.share,
              onPressed: () => AdDetailsController.shareItem(context, model),
              context: context,
            ),
          ],
        ),
      );

  Widget _images() => Stack(children: [
        _imagesViewer(),
        _imagesIndex(),
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

  Widget _address() => AdDetailsWidgets.buildIconAndText(
        icon: Icons.location_pin,
        text: AdDetailsController.buildFullAddress(model),
      );

  Widget _locationType() => AdDetailsWidgets.buildIconAndText(
        icon: Icons.local_offer_outlined,
        text: model.locationType?.map(ItemModel.locationTypeString).join(', ') ?? '',
      );

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
          if (model.description != null)
            AdDetailsWidgets.buildItemDetailsSection(
              title: 'Description',
              child: SmallText(model.description ?? ''),
            ),
          if (model.videoLink != null)
            AdDetailsWidgets.buildItemDetailsSection(
              title: 'Video Preview',
              child: SizedBox(
                height: 200,
                child: CustomWebVideoPlayer(model.videoLink!),
              ),
            ),
          if (model.price != null && model.priceType != null)
            AdDetailsWidgets.buildItemDetailsSection(
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
          if (model.latitude != null && model.longitude != null && model.city != null && model.country != null) _locationDetailsSection(),
          AdDetailsWidgets.buildDivider(),
          _aboutTheProvider(),
        ],
      );

  Widget _forACause() => AdDetailsWidgets.buildForACauseSection(
        forACauseText: model.forACauseText ?? '',
        context: context,
      );

  Widget _locationDetailsSection() {
    return AdDetailsWidgets.buildItemDetailsSection(
      title: 'Location Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          if (model.city != null && model.country != null) ...[
            AdDetailsWidgets.buildCoordinatesDisplay(
              city: model.city!,
              country: model.country!,
              onViewOnMaps: () => _openLocationOnGoogleMaps(),
            ),
          ],
          if (model.locationType != null && model.locationType!.isNotEmpty) ...[
            SizedBox(height: 8),
            SmallText('Service Location Types:', weight: FontWeight.w600),
            SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: model.locationType!
                  .map((type) => Chip(
                        label: SmallText(
                          ItemModel.locationTypeString(type),
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        backgroundColor: context.color.secondaryColor,
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _aboutTheProvider() => model.user == null
      ? SizedBox()
      : AdDetailsWidgets.buildElevatedContainer(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HeadingText('About the Provider', fontSize: 20, weight: FontWeight.bold),
                SizedBox(height: 20),
                AdDetailsWidgets.buildDivider(),
                SizedBox(height: 20),
                ProviderHomeScreenContainer(
                  user: model.user!,
                  withBorder: false,
                  goToProviderDetailsScreenOnPressed: false,
                  padding: EdgeInsets.zero,
                  additionalDetails: GestureDetector(
                    onTap: () => AdDetailsController.navigateToProviderDetails(context, model),
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

    return AdDetailsWidgets.buildElevatedContainer(
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
            AdDetailsWidgets.buildDivider(),
            SizedBox(height: 10),
            Column(
              spacing: 12,
              children: [
                AdDetailsWidgets.buildLimitedExperienceItem(
                  icon: Icons.event_busy,
                  title: 'End Date',
                  content: AdDetailsController.formatExperienceDateTime(model.expirationDate),
                  context: context,
                ),
                if (!isExpired)
                  AdDetailsWidgets.buildLimitedExperienceItem(
                    icon: Icons.hourglass_bottom,
                    title: 'Countdown',
                    content: '${model.expirationDate?.difference(DateTime.now()).abs().inDays} days left',
                    context: context,
                  )
              ],
            )
          ],
        ),
      ),
    );
  }

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
      );

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
          AdDetailsWidgets.buildDivider(),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: (isAddedByMe
                      ? [
                          ('Edit', () => AdDetailsController.onEditPressed(context, model)),
                          ('Delete', () => AdDetailsController.onDeletePressed(context, model)),
                        ]
                      : [
                          if (model.user?.showPersonalDetails == 1 && model.user?.mobile != null)
                            ('WhatsApp', () => AdDetailsController.onWhatsappPressed(model)),
                          ('Chat', () => AdDetailsController.onChatPressed(context, model)),
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
        listener: (context, deleteState) => AdDetailsController.deleteItemListener(context, deleteState, model),
        builder: (context, deleteState) => BlocConsumer<FetchItemFromSlugCubit, FetchItemFromSlugState>(
          listener: AdDetailsController.rootListener,
          builder: (context, state) {
            if (state is FetchItemFromSlugLoading) return _progressIndicator();
            if (state is FetchItemFromSlugFailure && widget.slug != null) return _somethingWentWrong();
            return BlocConsumer<MakeAnOfferItemCubit, MakeAnOfferItemState>(
                listener: (context, state) => AdDetailsController.makeOfferListener(context, state, model),
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
                                      AdDetailsWidgets.buildDivider(),
                                      const SizedBox(height: 20),
                                      _limitedTimeExperience(),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              AdDetailsWidgets.buildDivider(),
                              _tabsHeader(),
                              AdDetailsWidgets.buildDivider(),
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

  // Helper methods
  Widget _userHasRatedItemBuilder({required Widget child}) => BlocBuilder<UserHasRatedItemCubit, UserHasRatedItemState>(
        builder: (context, state) {
          if (state is! UserHasRatedItemInSuccess || state.userHasRatedItem) return Container();
          return child;
        },
      );

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
          if (value == true && mounted) {
            if (model.id != null) {
              context.read<FetchItemReviewsCubit>().fetchItemReviews(itemId: model.id!);
              context.read<UserHasRatedItemCubit>().userHasRatedItem(itemId: model.id!);
            }
          }
        });
      },
      context: context,
    );
  }

  Future<void> _showReportItemDialog(int itemId) async {
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

  void _pageScroll() {
    if (_pageScrollController.isEndReached()) {
      if (context.read<FetchRelatedItemsCubit>().hasMoreData()) {
        context.read<FetchRelatedItemsCubit>().fetchRelatedItemsMore(
            categoryId: categoryId!,
            city: HiveUtils.getCityName(),
            areaId: HiveUtils.getAreaId(),
            country: HiveUtils.getCountryName(),
            state: HiveUtils.getStateName());
      }
    }
  }

  Future<void> _onRefresh() async {
    await AdDetailsController.refreshData(context, widget.slug, model, categoryId);
  }

  void _openLocationOnGoogleMaps() {
    if (model.latitude != null && model.longitude != null) {
      Navigator.pushNamed(
        context,
        Routes.itemLocationScreen,
        arguments: {
          'latitude': model.latitude,
          'longitude': model.longitude,
          'name': model.name,
          'city': model.city,
          'country': model.country,
        },
      );
    }
  }
}
