import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/cubits/users_that_claimed_item_cubit.dart';
import 'package:tlobni/data/helper/designs.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/user_model.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/claims_item_list_container.dart';
import 'package:tlobni/ui/screens/widgets/claims_user_list_container.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_data_found.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_internet.dart';
import 'package:tlobni/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:tlobni/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/ui_utils.dart';

class ViewClaimedUsersOfItemScreen extends StatefulWidget {
  final ItemModel model;

  const ViewClaimedUsersOfItemScreen({
    super.key,
    required this.model,
  });

  static Route route(RouteSettings routeSettings) {
    Map? arguments = routeSettings.arguments as Map?;
    assert(arguments != null);
    return BlurredRouter(
      builder: (_) => ViewClaimedUsersOfItemScreen(
        model: arguments!['model'],
      ),
    );
  }

  @override
  State<ViewClaimedUsersOfItemScreen> createState() => _ViewClaimedUsersOfItemScreenState();
}

class _ViewClaimedUsersOfItemScreenState extends State<ViewClaimedUsersOfItemScreen> {
  @override
  void initState() {
    super.initState();
    _onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiUtils.buildAppBar(context, title: 'Claimed Users', showBackButton: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: EdgeInsets.all(defaultPadding), child: _itemContainer()),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(defaultPadding) - EdgeInsets.only(bottom: defaultPadding),
            child: HeadingText('Users:'),
          ),
          Expanded(child: _usersList()),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    if (widget.model.id == null) return;
    context.read<UsersThatClaimedItemCubit>().fetchUsers(itemId: widget.model.id!);
  }

  Widget _itemContainer() => ClaimsItemListContainer(
        widget.model,
        refreshData: _onRefresh,
        showSlots: true,
        onPressed: null,
      );

  Widget _usersList() => RefreshIndicator(
        onRefresh: _onRefresh,
        child: BlocBuilder<UsersThatClaimedItemCubit, UsersThatClaimedItemState>(
          builder: (context, state) {
            if (state is UsersThatClaimedItemInProgress) {
              return _shimmerEffect();
            }

            if (state is UsersThatClaimedItemFailure) {
              if (state.error is ApiException) {
                if (state.error.error == "no-internet") {
                  return NoInternet(
                    onRetry: () => _onRefresh(),
                  );
                }
              }

              return const SomethingWentWrong();
            }

            if (state is UsersThatClaimedItemSuccess) {
              if (state.users.isEmpty) {
                return NoDataFound(
                  mainMessage: 'No Users Found',
                  subMessage: 'No users found at the moment, check back soon!',
                  onTap: () => _onRefresh(),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding,
                  vertical: 8,
                ),
                separatorBuilder: (context, index) {
                  return Container(
                    height: 8,
                  );
                },
                itemCount: state.users.length,
                itemBuilder: (context, index) {
                  UserModel user = state.users[index];
                  return ClaimsUserListContainer(user);
                },
              );
            }
            return Container();
          },
        ),
      );

  ListView _shimmerEffect() {
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
}
