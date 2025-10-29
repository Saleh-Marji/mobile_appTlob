import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/receipts/receipts_cubit.dart';
import 'package:tlobni/data/helper/designs.dart';
import 'package:tlobni/data/model/receipt_model.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_data_found.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_internet.dart';
import 'package:tlobni/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:tlobni/ui/screens/widgets/intertitial_ads_screen.dart';
import 'package:tlobni/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key, required this.showBack});

  final bool showBack;

  static Route route(RouteSettings settings) {
    return BlurredRouter(
      builder: (context) {
        return ReceiptsScreen(
          showBack: (settings.arguments as Map<String, dynamic>?)?['showBack'] ?? false,
        );
      },
    );
  }

  @override
  ReceiptsScreenState createState() => ReceiptsScreenState();
}

class ReceiptsScreenState extends State<ReceiptsScreen> {
  late final ScrollController _controller = ScrollController()
    ..addListener(
      () {
        if (_controller.offset >= _controller.position.maxScrollExtent) {
          if (context.read<ReceiptsCubit>().hasMoreReceipts()) {
            setState(() {});
            context.read<ReceiptsCubit>().getMoreReceipts();
          }
        }
      },
    );

  @override
  void initState() {
    super.initState();
    AdHelper.loadInterstitialAd();
    getReceipts();
  }

  void getReceipts() async {
    context.read<ReceiptsCubit>().getReceipts();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showReceiptDetails(BuildContext context, ReceiptModel receipt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReceiptDetailBottomSheet(receipt: receipt),
    );
  }

  @override
  Widget build(BuildContext context) {
    AdHelper.showInterstitialAd();
    return Scaffold(
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: widget.showBack,
        title: "My Receipts",
      ),
      body: !HiveUtils.isUserAuthenticated()
          ? _buildLoginRequiredMessage()
          : BlocBuilder<ReceiptsCubit, ReceiptsState>(
              builder: (context, state) {
                if (state is ReceiptsFetchInProgress) {
                  return shimmerEffect();
                } else if (state is ReceiptsFetchSuccess) {
                  if (state.receipts.isEmpty) {
                    return Center(
                      child: NoDataFound(
                        onTap: getReceipts,
                      ),
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Builder(builder: (context) {
                          final receipts = state.receipts;
                          final rowCount = (receipts.length / 2).ceil();
                          final spacing = 10.0;
                          return RefreshIndicator(
                            onRefresh: () async {
                              getReceipts();
                            },
                            child: ListView.separated(
                              controller: _controller,
                              separatorBuilder: (_, __) => SizedBox.square(dimension: spacing * 2),
                              padding: EdgeInsets.all(spacing * 2),
                              itemCount: rowCount,
                              itemBuilder: (context, index) {
                                final start = index * 2;
                                final end = start + 1;
                                final items = [
                                  if (start < receipts.length) receipts[start],
                                  if (end < receipts.length) receipts[end],
                                ];
                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: items.length == 1
                                        ? [
                                            Expanded(child: SizedBox()),
                                            Expanded(
                                              flex: 2,
                                              child: _buildReceiptCard(context, items[0]),
                                            ),
                                            Expanded(child: SizedBox()),
                                          ]
                                        : [
                                            Expanded(
                                              child: _buildReceiptCard(context, items[0]),
                                            ),
                                            SizedBox(width: spacing),
                                            Expanded(
                                              child: _buildReceiptCard(context, items[1]),
                                            ),
                                          ],
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ),
                      if (state.isLoadingMore)
                        UiUtils.progress(
                          color: context.color.territoryColor,
                        )
                    ],
                  );
                } else if (state is ReceiptsFetchFailure) {
                  if (state.errorMessage is ApiException && (state.errorMessage as ApiException).errorMessage == "no-internet") {
                    return NoInternet(
                      onRetry: getReceipts,
                    );
                  }
                  return const SomethingWentWrong();
                }
                return Container();
              },
            ),
    );
  }

  Widget _buildReceiptCard(BuildContext context, ReceiptModel receipt) {
    return GestureDetector(
      onTap: () => _showReceiptDetails(context, receipt),
      child: Container(
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Item Title
            Padding(
              padding: const EdgeInsets.all(12),
              child: HeadingText(
                receipt.itemTitle ?? 'Untitled',
                fontSize: 14,
                maxLines: 2,
                weight: FontWeight.w600,
              ),
            ),
            // Receipt Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: receipt.url ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: context.color.territoryColor.withOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: context.color.territoryColor,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: context.color.territoryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.receipt_long,
                      size: 50,
                      color: context.color.textLightColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to show when user is not logged in
  Widget _buildLoginRequiredMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 80,
              color: context.color.territoryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 20),
            Text(
              "loginIsRequiredForAccessingThisFeatures".translate(context),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.color.textDefaultColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "tapOnLoginToAuthorize".translate(context),
              style: TextStyle(
                color: context.color.textDefaultColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            UiUtils.buildButton(
              context,
              onPressed: () {
                Navigator.pushNamed(context, Routes.login);
              },
              buttonTitle: "loginNow".translate(context),
              height: 45,
              fontSize: 16,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  ListView shimmerEffect() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        vertical: 10 + defaultPadding,
        horizontal: defaultPadding,
      ),
      itemCount: 6,
      separatorBuilder: (context, index) {
        return const SizedBox(
          height: 12,
        );
      },
      itemBuilder: (context, index) {
        return Row(
          children: [
            Expanded(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const CustomShimmer(height: 200),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const CustomShimmer(height: 200),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Receipt Detail Bottom Sheet
class ReceiptDetailBottomSheet extends StatelessWidget {
  final ReceiptModel receipt;

  const ReceiptDetailBottomSheet({super.key, required this.receipt});

  Future<void> _shareReceipt(BuildContext context) async {
    try {
      if (receipt.url == null || receipt.url!.isEmpty) {
        HelperUtils.showSnackBarMessage(
          context,
          'No receipt image available to share',
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: UiUtils.progress(),
        ),
      );

      // Download the image
      final response = await http.get(Uri.parse(receipt.url!));
      final bytes = response.bodyBytes;

      // Get temporary directory
      final temp = await getTemporaryDirectory();
      final path = '${temp.path}/receipt_${receipt.id}_${DateTime.now().millisecondsSinceEpoch}.png';

      // Write to file
      final file = File(path);
      await file.writeAsBytes(bytes);

      // Close loading dialog
      Navigator.of(context).pop();

      // Share the file with text
      final shareText = '''
Receipt Details:
Opportunity: ${receipt.itemTitle ?? 'N/A'}
Organization: ${receipt.organizationName ?? 'N/A'}
Date: ${receipt.itemDate ?? 'N/A'}
Location: ${receipt.itemLocation ?? 'N/A'}
''';

      await Share.shareXFiles(
        [XFile(path)],
        text: shareText,
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      HelperUtils.showSnackBarMessage(
        context,
        'Failed to share receipt: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.color.textLightColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header with close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    HeadingText(
                      'Receipt Details',
                      fontSize: 20,
                      weight: FontWeight.bold,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: context.color.textDefaultColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Receipt Image
                      GestureDetector(
                        onTap: () {
                          UiUtils.imageGallaryView(context,
                              images: [
                                receipt.url ?? '',
                              ],
                              initalIndex: 0);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CachedNetworkImage(
                            imageUrl: receipt.url ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 300,
                              color: context.color.territoryColor.withOpacity(0.1),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: context.color.territoryColor,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 300,
                              color: context.color.territoryColor.withOpacity(0.1),
                              child: Icon(
                                Icons.receipt_long,
                                size: 100,
                                color: context.color.textLightColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Item Title
                      _buildDetailItem(
                        context,
                        'Opportunity',
                        receipt.itemTitle ?? 'N/A',
                        Icons.inventory_2_outlined,
                      ),
                      const SizedBox(height: 16),
                      // Organization
                      _buildDetailItem(
                        context,
                        'Organization',
                        receipt.organizationName ?? 'N/A',
                        Icons.business_outlined,
                      ),
                      const SizedBox(height: 16),
                      // Date
                      _buildDetailItem(
                        context,
                        'Date',
                        receipt.itemDate ?? 'N/A',
                        Icons.calendar_today_outlined,
                      ),
                      const SizedBox(height: 16),
                      // Location
                      _buildDetailItem(
                        context,
                        'Location',
                        receipt.itemLocation ?? 'N/A',
                        Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 24),
                      // Share Button
                      UiUtils.buildButton(
                        context,
                        onPressed: () => _shareReceipt(context),
                        buttonTitle: 'Share Receipt',
                        height: 50,
                        fontSize: 16,
                        prefixWidget: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: const Icon(
                            Icons.share,
                            color: kColorSecondaryBeige,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value, [
    IconData? icon,
    Color? valueColor,
  ]) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.primaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.color.textLightColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.color.territoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: context.color.territoryColor,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.color.textLightColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor ?? context.color.textDefaultColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
