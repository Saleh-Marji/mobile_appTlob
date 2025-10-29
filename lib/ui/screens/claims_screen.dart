import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/claims_item_list_cubit.dart';
import 'package:tlobni/data/helper/designs.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/ui/screens/widgets/claims_item_list_container.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_data_found.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_internet.dart';
import 'package:tlobni/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:tlobni/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';

class ClaimsScreen extends StatefulWidget {
  const ClaimsScreen({super.key});

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> {
  final _pageScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _onRefresh();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  bool get isProvider => HiveUtils.isProvider();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(context: context, statusBarColor: context.color.secondaryColor),
      child: Scaffold(
        appBar: UiUtils.buildAppBar(
          context,
          title: 'Claims',
        ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: BlocBuilder<ClaimsItemListCubit, ClaimsItemListState>(
            builder: (BuildContext context, ClaimsItemListState state) {
              if (state is ClaimsItemListInProgress) {
                return shimmerEffect();
              }

              if (state is ClaimsItemListFailure) {
                if (state.error is ApiException) {
                  if (state.error.error == "no-internet") {
                    return NoInternet(
                      onRetry: () => _onRefresh(),
                    );
                  }
                }

                return const SomethingWentWrong();
              }

              if (state is ClaimsItemListSuccess) {
                if (state.items.isEmpty) {
                  return NoDataFound(
                    mainMessage: 'No Claims Found',
                    subMessage: 'No claims found at the moment, check back soon!',
                    onTap: () => _onRefresh(),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: AlwaysScrollableScrollPhysics(),
                        controller: _pageScrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        separatorBuilder: (context, index) {
                          return Container(
                            height: 8,
                          );
                        },
                        itemBuilder: (context, index) {
                          ItemModel item = state.items[index];
                          return ClaimsItemListContainer(
                            item,
                            refreshData: _onRefresh,
                            showSlots: isProvider,
                            onPressed: () async {
                              if (isProvider) {
                                await Navigator.pushNamed(context, Routes.viewClaimedUsersOfItem, arguments: {
                                  'model': item,
                                });
                              } else {
                                await Navigator.pushNamed(context, Routes.adDetailsScreen, arguments: {
                                  'model': item,
                                });
                              }
                            },
                          );
                        },
                        itemCount: state.items.length,
                      ),
                    ),
                    if (state.isLoadingMore) UiUtils.progress()
                  ],
                );
              }
              return Container();
            },
          ),
        ),
      ),
    );
  }

  ListView shimmerEffect() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        vertical: defaultPadding,
        horizontal: defaultPadding,
      ),
      itemCount: 5,
      separatorBuilder: (context, index) {
        return const SizedBox(
          height: 12,
        );
      },
      itemBuilder: (context, index) {
        return Container(
          width: double.maxFinite,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const ClipRRect(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                borderRadius: BorderRadius.all(Radius.circular(15)),
                child: CustomShimmer(height: 90, width: 90),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: LayoutBuilder(builder: (context, c) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(
                        height: 10,
                      ),
                      CustomShimmer(
                        height: 10,
                        width: c.maxWidth - 50,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const CustomShimmer(
                        height: 10,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      CustomShimmer(
                        height: 10,
                        width: c.maxWidth / 1.2,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: CustomShimmer(
                          width: c.maxWidth / 4,
                        ),
                      ),
                    ],
                  );
                }),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    context.read<ClaimsItemListCubit>().fetchItems('');
  }
}
