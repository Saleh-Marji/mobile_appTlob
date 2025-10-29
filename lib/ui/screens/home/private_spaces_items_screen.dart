import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/item/private_spaces_cubit.dart';
import 'package:tlobni/data/cubits/item/space_items_cubit.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/item_filter_model.dart';
import 'package:tlobni/ui/screens/home/search_screen.dart';
import 'package:tlobni/ui/screens/home/widgets/home_list.dart';
import 'package:tlobni/ui/screens/home/widgets/home_shimmer_effect.dart';
import 'package:tlobni/ui/screens/home/widgets/item_container.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/models/post_type.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_internet.dart';
import 'package:tlobni/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';

class PrivateSpacesItemsScreen extends StatefulWidget {
  const PrivateSpacesItemsScreen({super.key});

  @override
  State<PrivateSpacesItemsScreen> createState() => _PrivateSpacesItemsScreenState();
}

class _PrivateSpacesItemsScreenState extends State<PrivateSpacesItemsScreen> {
  @override
  void initState() {
    super.initState();
    _onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiUtils.buildAppBar(context, title: 'Private Spaces', showBackButton: true),
      body: BlocBuilder<PrivateSpacesCubit, PrivateSpacesState>(
        builder: (context, state) {
          if (state is PrivateSpacesInProgress) {
            return Center(child: UiUtils.progress());
          }
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              physics: AlwaysScrollableScrollPhysics(),
              child: Builder(builder: (context) {
                if (state is PrivateSpacesFailure) {
                  if (state.error is ApiException) {
                    if (state.error.error == "no-internet") {
                      return NoInternet(
                        onRetry: _onRefresh,
                      );
                    }
                  }
                  return const SomethingWentWrong();
                }
                if (state is PrivateSpacesSuccess) {
                  final blocs = state.spacesCubits;
                  return Column(
                    children: [
                      for (var space in state.spaces)
                        BlocBuilder<SpaceItemsCubit, SpaceItemsState>(
                          bloc: blocs[space.id],
                          builder: (context, state) => HomeList(
                            title: space.name,
                            onViewAll: () => _goToItemListingSearch(context,
                                filter: ItemFilterModel(
                                  serviceType: PostType.experience.name,
                                  organizationId: space.id,
                                  privateSpacesOnly: true,
                                )),
                            error: state is SpaceItemsFailure ? state.error?.toString() : null,
                            isLoading: state is SpaceItemsInProgress,
                            shimmerEffect: _itemShimmerEffect(),
                            children: state is SpaceItemsSuccess ? state.items.map(_itemContainer).toList() : [],
                          ),
                        ),
                    ],
                  );
                }
                return SizedBox();
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _itemContainer(ItemModel item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ItemContainer(small: false, item: item),
          ],
        ),
      );

  Widget _itemShimmerEffect() => HomeShimmerEffect(
        itemCount: 3,
        width: context.screenWidth * 0.85,
        height: 400,
        padding: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.05),
      );
  void _goToItemListingSearch(BuildContext context, {ItemFilterModel? filter}) {
    _goToSearchPage(context, SearchScreenType.itemListing, filter: filter);
  }

  void _goToSearchPage(BuildContext context, SearchScreenType type, {ItemFilterModel? filter}) {
    Navigator.pushNamed(
      context,
      Routes.searchScreenRoute,
      arguments: {'autoFocus': true, 'screenType': type, 'itemFilter': filter},
    );
  }

  Future<void> _onRefresh() async {
    context.read<PrivateSpacesCubit>().fetchPrivateSpaces();
  }
}
