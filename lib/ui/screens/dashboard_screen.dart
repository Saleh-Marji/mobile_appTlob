import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/data/cubits/invitation_link_cubit.dart';
import 'package:tlobni/data/helper/designs.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/custom_text_form_field.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_data_found.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_internet.dart';
import 'package:tlobni/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/buttons/primary_button.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static Route route(RouteSettings settings) {
    return BlurredRouter(
      builder: (context) {
        return const DashboardScreen();
      },
    );
  }

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool get isBusiness => HiveUtils.isBusiness();

  final emailController = TextEditingController();

  ItemAudience _audience = ItemAudience.clients;

  final _formKey = GlobalKey<FormState>();

  List<ItemAudience> get audienceTypes => [
        ItemAudience.clients,
        ItemAudience.employees,
        ItemAudience.students,
      ];

  @override
  void initState() {
    super.initState();
    _onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiUtils.buildAppBar(context, title: 'Dashboard', showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _getChildren(),
        ),
      ),
    );
  }

  List<Widget> _getChildren() {
    if (isBusiness) return _businessChildren();
    return _expertChildren();
  }

  List<Widget> _expertChildren() => [
        HeadingText('Analytics'),
        Expanded(
            child: NoDataFound(
          mainMessage: 'No Analytics',
          subMessage: 'No new analytics exist for now',
        ))
      ];

  List<Widget> _businessChildren() => [
        HeadingText('Analytics'),
        DescriptionText('No new analytics exist for now'),
        const Divider(height: 1, thickness: 1),
        HeadingText('Members Management'),
        DescriptionText('No members invited yet'),
        const Divider(height: 1, thickness: 1),
        HeadingText('Invite Users'),
        Expanded(
          child: BlocBuilder<InvitationLinkCubit, InvitationLinkState>(builder: (BuildContext context, InvitationLinkState state) {
            if (state is InvitationLinkInProgress) {
              return Center(
                child: UiUtils.progress(),
              );
            }
            if (state is InvitationLinkFailure) {
              if (state.error is ApiException) {
                if (state.error.errorMessage == "no-internet") {
                  return NoInternet(
                    onRetry: _onRefresh,
                  );
                }
              }
              return RefreshIndicator(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: const SomethingWentWrong(),
                  ),
                ),
                onRefresh: _onRefresh,
              );
            }
            if (state is InvitationLinkSuccess) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 20,
                children: [
                  DescriptionText('Invitation link for ${state.email} is ready!'),
                  _button('Copy Link', _onCopyLinkPressed),
                  _button('Share Link', _onShareLinkPressed),
                  _button('Invite Another User', _onRefresh),
                ],
              );
            }
            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 20,
                  children: [
                    /// Email
                    CustomTextFormField(
                      controller: emailController,
                      fillColor: context.color.secondaryColor,
                      borderColor: context.color.borderColor.darken(30),
                      keyboard: TextInputType.emailAddress,
                      validator: CustomTextFieldValidator.email,
                      hintText: "emailAddress".translate(context),
                    ),
                    DescriptionText('User type:'),
                    Wrap(
                      runSpacing: 10,
                      spacing: 10,
                      children: audienceTypes
                          .map((e) => _buildRadioOption(
                                context,
                                title: (switch (e) {
                                  ItemAudience.public => 'Any',
                                  ItemAudience.employees => 'Employee',
                                  ItemAudience.students => 'Student',
                                  ItemAudience.clients => 'Client',
                                }),
                                value: e,
                                groupValue: _audience,
                                onChanged: (val) => setState(() => val == null ? null : _audience = val),
                              ))
                          .toList(),
                    ),
                    _button('Invite', _onInvitePressed),
                  ],
                ),
              ),
            );
          }),
        )
      ];

  Future<void> _onRefresh() async {
    context.read<InvitationLinkCubit>().onRefresh();
    emailController.clear();
    _audience = ItemAudience.clients;
  }

  Widget _button(String text, VoidCallback onPressed) => PrimaryButton.text(
        text,
        onPressed: onPressed,
        padding: EdgeInsets.all(20),
      );

  void _onCopyLinkPressed() => context.read<InvitationLinkCubit>().copyLink(context);

  void _onShareLinkPressed() => context.read<InvitationLinkCubit>().shareLink();

  Widget _buildRadioOption<T>(
    BuildContext context, {
    required String title,
    required T value,
    required T groupValue,
    required Function(T?) onChanged,
  }) {
    bool isSelected = groupValue == value;

    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8) + EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? kColorNavyBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: kColorNavyBlue,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: RadioGroup<T>(
          groupValue: groupValue,
          onChanged: onChanged,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Theme(
                data: ThemeData(
                  unselectedWidgetColor: context.color.borderColor,
                ),
                child: Radio<T>(
                  value: value,
                  side: BorderSide(width: 1.5),
                  fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return kColorSecondaryBeige;
                    }
                    return kColorNavyBlue;
                  }),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              Flexible(
                child: DescriptionText(
                  title.translate(context),
                  color: isSelected ? kColorSecondaryBeige : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onInvitePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<InvitationLinkCubit>().invite(emailController.text, _audience);
  }
}
