import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_buttons/social_media_buttons.dart';
import 'package:tlobni/data/cubits/auth/authentication_cubit.dart';
import 'package:tlobni/data/cubits/category/fetch_all_categories_cubit.dart';
import 'package:tlobni/data/cubits/user/current_user_profile_cubit.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/widgets/location_autocomplete.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/image_cropper.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/buttons/unelevated_regular_button.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/extensions/lib/widget_iterable.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';

enum UserType {
  client,
  expert,
  business;
}

enum EditProfileScreenTab {
  basicInfo,
  about,
  portfolio,
  ;

  @override
  String toString() => switch (this) {
        basicInfo => 'Basic Info',
        about => 'About',
        portfolio => 'Portfolio',
      };
}

class UserProfileScreen extends StatefulWidget {
  final String from;
  final bool? navigateToHome;
  final bool? popToCurrent;
  final AuthenticationType? type;
  final Map<String, dynamic>? extraData;

  const UserProfileScreen({
    super.key,
    required this.from,
    this.navigateToHome,
    this.popToCurrent,
    required this.type,
    this.extraData,
  });

  @override
  State<UserProfileScreen> createState() => UserProfileScreenState();

  static Route route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return BlurredRouter(
      builder: (_) => UserProfileScreen(
        from: arguments['from'] as String,
        popToCurrent: arguments['popToCurrent'] as bool?,
        type: arguments['type'],
        navigateToHome: arguments['navigateToHome'] as bool?,
        extraData: arguments['extraData'],
      ),
    );
  }
}

class UserProfileScreenState extends State<UserProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Common controllers
  late final TextEditingController phoneController = TextEditingController(text: widget.extraData?['email']);
  late final TextEditingController nameController = TextEditingController(text: widget.extraData?['username']);
  late final TextEditingController emailController = TextEditingController(text: widget.extraData?['email']);
  final TextEditingController addressController = TextEditingController();

  // Additional controllers for different user types
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  // Social media controllers
  final TextEditingController facebookController = TextEditingController();
  final TextEditingController twitterController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController tiktokController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  String? city, state, country;
  double? latitude, longitude;
  String? name, email, address, gender;
  File? fileUserimg;
  bool isNotificationsEnabled = true;
  bool isPersonalDetailShow = true;
  bool? isLoading;
  String? countryCode = "+${Constant.defaultCountryCode}";

  Set<int> _selectedCategoryIds = {};

  EditProfileScreenTab _tab = EditProfileScreenTab.basicInfo;

  UserType? _type;

  void _updateUserData(User user) {
    phoneController.text = user.mobile ?? '';
    nameController.text = user.name ?? '';
    emailController.text = user.email ?? '';
    addressController.text = user.address ?? '';
    gender = user.gender;
    if (user.hasLocation) {
      locationController.text = user.location ?? '';
      country = user.country;
      city = user.city;
      state = user.state;
    }
    isNotificationsEnabled = user.enableNotifications ?? false;
    isPersonalDetailShow = user.showPersonalDetails == 1;
    bioController.text = user.bio ?? '';
    facebookController.text = user.facebook ?? '';
    twitterController.text = user.twitter ?? '';
    instagramController.text = user.instagram ?? '';
    tiktokController.text = user.tiktok ?? '';
    _selectedCategoryIds = (user.categoriesIds ?? []).toSet();
    countryCode = user.countryCode;
    _type = switch (user.type) {
      'Client' => UserType.client,
      'Expert' => UserType.expert,
      'Business' => UserType.business,
      _ => null,
    };
  }

  @override
  void initState() {
    super.initState();
    context.read<CurrentUserProfileCubit>().fetchCurrentUser();
    _fetchCategories();
  }

  // Fetch categories from repository
  Future<void> _fetchCategories() async {
    context.read<FetchAllCategoriesCubit>().fetchCategories();
  }

  @override
  void dispose() {
    super.dispose();
    phoneController.dispose();
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
  }

  Widget _buildEditProfileBody() => Padding(
        padding: EdgeInsets.all(16.0),
        child: BlocConsumer<CurrentUserProfileCubit, CurrentUserProfileState>(
          listener: (context, state) {
            if (state is CurrentUserProfileSuccess) _updateUserData(state.user);
            setState(() {});
          },
          builder: (context, state) {
            if (state is CurrentUserProfileFetchProgress) {
              return SizedBox(
                height: context.screenHeight * 0.6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        UiUtils.progress(),
                      ],
                    ),
                  ],
                ),
              );
            }
            if (state is CurrentUserProfileFailure) return Center(child: DescriptionText(state.errorMessage));
            if (state is! CurrentUserProfileSuccess) return SizedBox();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_type != UserType.client) ...[
                  _tabsHeading(),
                  SizedBox(height: 16.0),
                  Expanded(child: _tabBody()),
                ] else ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _tabContent(),
                    ),
                  ),
                ],
                SizedBox(height: 20.0),
                _buttons(),
              ],
            );
          },
        ),
      );

  Widget _tabsHeading() {
    final values = [
      EditProfileScreenTab.basicInfo,
      EditProfileScreenTab.about,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Color(0xfffafafa),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xfff8f3ed)),
      ),
      padding: EdgeInsets.all(5),
      child: Row(
        children: values.map(
          (e) {
            final isSelected = _tab == e;
            return UnelevatedRegularButton(
              onPressed: () => setState(() => _tab = e),
              padding: EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: isSelected ? context.color.primary : Colors.transparent,
              child: HeadingText(
                e.toString(),
                fontSize: 16,
                color: isSelected ? context.color.onPrimary : null,
              ),
            );
          },
        ).mapExpandedSpaceBetween(10),
      ),
    );
  }

  Widget _tabBody() => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xffede9e5)),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(16),
        child: _tabContent(),
      );

  Widget _tabContent() => RefreshIndicator(
        onRefresh: () async => context.read<CurrentUserProfileCubit>().fetchCurrentUser(),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
            children: switch (_tab) {
              EditProfileScreenTab.basicInfo => _basicInfoBody(),
              EditProfileScreenTab.about => _aboutBody(),
              EditProfileScreenTab.portfolio => _portfolioBody(),
            },
          ),
        ),
      );

  Widget getProfileImage() {
    if (fileUserimg != null) {
      return Image.file(
        fileUserimg!,
        fit: BoxFit.cover,
      );
    } else {
      if (widget.from == "login") {
        if (HiveUtils.getUserDetails().profile != "" && HiveUtils.getUserDetails().profile != null) {
          return UiUtils.getImage(
            HiveUtils.getUserDetails().profile!,
            fit: BoxFit.cover,
          );
        }

        return UiUtils.getSvg(
          AppIcons.defaultPersonLogo,
          color: context.color.territoryColor,
          fit: BoxFit.none,
        );
      } else {
        if ((HiveUtils.getUserDetails().profile ?? "").isEmpty) {
          return UiUtils.getSvg(
            AppIcons.defaultPersonLogo,
            color: context.color.territoryColor,
            fit: BoxFit.none,
          );
        } else {
          return UiUtils.getImage(
            HiveUtils.getUserDetails().profile!,
            fit: BoxFit.cover,
          );
        }
      }
    }
  }

  Widget _profilePicture() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                alignment: AlignmentDirectional.center,
                height: 106,
                width: 106,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: context.color.territoryColor.withValues(alpha: 0.2),
                  border: Border.all(color: context.color.secondary, width: 2),
                  shape: BoxShape.circle,
                ),
                child: getProfileImage(),
              ),
              PositionedDirectional(
                bottom: 0,
                end: 0,
                child: UnelevatedRegularButton(
                  onPressed: showPicker,
                  padding: EdgeInsets.all(10),
                  color: context.color.primary,
                  shape: CircleBorder(),
                  child: SizedBox(width: 15, height: 15, child: UiUtils.getSvg(AppIcons.edit)),
                ),
              )
            ],
          ),
        ],
      );

  Widget _section(String title, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeadingText(title, fontSize: 16),
          SizedBox(height: 10),
          child,
        ],
      );

  Widget _textFieldSection(
    String title,
    TextEditingController controller,
    String hint, {
    TextInputType? type,
    Widget? prefix,
    int? maxLines,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: _sectionBorderColor),
    );
    return IntrinsicHeight(
      child: _section(
        title,
        textFormField(controller, type, maxLines, prefix, border, hint),
      ),
    );
  }

  TextFormField textFormField(
    TextEditingController controller,
    TextInputType? type,
    int? maxLines,
    Widget? prefix,
    OutlineInputBorder? border,
    String hint, {
    Color? fillColor,
  }) {
    return TextFormField(
      controller: controller,
      style: context.textTheme.bodyMedium,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefix: prefix,
        isCollapsed: true,
        isDense: true,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIconConstraints: BoxConstraints(),
        filled: true,
        fillColor: fillColor ?? _textFieldFillColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        hintText: hint,
      ),
    );
  }

  Widget _switchSection(String title, bool value, ValueChanged<bool> onChanged) => _section(
        title,
        UnelevatedRegularButton(
          onPressed: () => onChanged(!value),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _sectionBorderColor)),
          color: _textFieldFillColor,
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: DescriptionText(value ? 'Enabled' : 'Disabled')),
              SizedBox(height: 10, child: Switch(value: value, onChanged: onChanged)),
            ],
          ),
        ),
      );

  Color get _textFieldFillColor => Color(0xfff9f9f9);

  Color get _sectionBorderColor => Color(0xffeeeeee);

  Widget _fullName() => _textFieldSection(
        'Full Name',
        nameController,
        'Enter your full name',
      );

  Widget _gender() => _section(
      'Gender',
      Row(
        children: [
          (Icons.man, 'Male'),
          (Icons.woman, 'Female'),
        ].map((e) {
          final (icon, value) = e;
          final isSelected = gender == value;
          final textColor = isSelected ? context.color.onPrimary : context.color.primary;
          final backgroundColor = isSelected ? context.color.primary : Colors.transparent;
          return UnelevatedRegularButton(
            padding: EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: context.color.primary),
            ),
            onPressed: () => setState(() => gender = value),
            color: backgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: textColor),
                SizedBox(width: 5),
                Text(value, style: context.textTheme.bodyMedium?.copyWith(color: textColor)),
              ],
            ),
          );
        }).mapExpandedSpaceBetween(5),
      ));

  Widget _phoneCountryCodePrefix() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            child: GestureDetector(
              onTap: () {
                if (HiveUtils.getUserDetails().type != AuthenticationType.phone.name) {
                  showCountryCode();
                }
              },
              child: Center(
                child: DescriptionText(
                  formatCountryCode(countryCode!),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      );

  Widget _phoneNumber() => _textFieldSection(
        'Phone Number',
        phoneController,
        'Enter your phone number',
        type: TextInputType.phone,
        prefix: _phoneCountryCodePrefix(),
      );

  Widget _location() => _section(
        'Location',
        LocationAutocomplete(
          controller: locationController,
          onSelected: (_) {},
          fillColor: _textFieldFillColor,
          radius: BorderRadius.circular(8),
          borderColor: _sectionBorderColor,
          hintText: 'Select your location',
          onLocationSelected: (data) {
            if (!mounted) return;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                city = data['city'];
                state = data['state'];
                country = data['country'];
              });
            });
          },
        ),
      );

  Widget _notificationSwitch() =>
      _switchSection('Notifications', isNotificationsEnabled, (val) => setState(() => isNotificationsEnabled = val));

  Widget _showContactInfoSwitch() =>
      _switchSection('Show Contact Info', isPersonalDetailShow, (val) => setState(() => isPersonalDetailShow = val));

  List<Widget> _basicInfoBody() => [
        _profilePicture(),
        _fullName(),
        _gender(),
        if (_type != UserType.client) _phoneNumber(),
        _location(),
        _notificationSwitch(),
        if (_type != UserType.client) _showContactInfoSwitch(),
      ];

  Widget _aboutMe() => _textFieldSection(
        'About Me',
        bioController,
        'Tell us about your services and expertise...',
        type: TextInputType.multiline,
        maxLines: 5,
      );

  Widget _categoriesMenu() => _section(
        'Categories',
        UnelevatedRegularButton(
          onPressed: () => _showCategorySelectionDialog(),
          padding: const EdgeInsets.all(16),
          color: _textFieldFillColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: _sectionBorderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: DescriptionText(
                  _selectedCategoryIds.isEmpty ? "Choose Categories" : "${_selectedCategoryIds.length} categories selected",
                  color: context.color.primary.withValues(alpha: _selectedCategoryIds.isEmpty ? 0.5 : 1),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: context.color.textColorDark,
              ),
            ],
          ),
        ),
      );

  Widget _socialLinks() => _section(
      'Social Links',
      Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _textFieldFillColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _sectionBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            (SocialMediaIcons.facebook, 'Facebook', facebookController),
            (SocialMediaIcons.instagram, 'Instagram', instagramController),
            (Icons.music_note, 'Tiktok', tiktokController),
            (SocialMediaIcons.twitter, 'Twitter', twitterController),
          ].map((e) {
            final (icon, text, controller) = e;
            return Row(
              children: [
                Icon(icon, color: context.color.primary),
                SizedBox(width: 10),
                Expanded(
                    child: textFormField(
                  controller,
                  TextInputType.url,
                  1,
                  null,
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _sectionBorderColor)),
                  'Your $text profile URL',
                  fillColor: Colors.white,
                ))
              ],
            );
          }).toList(),
        ),
      ));

  List<Widget> _aboutBody() => [
        _aboutMe(),
        _categoriesMenu(),
        // _categoriesMultiSelect(),
        _socialLinks()
      ];

  List<Widget> _portfolioBody() => [];

  Widget _buttons() => Row(
        children: [
          (context.color.primary, Colors.transparent, context.color.primary, 'Cancel', _onCancelPressed),
          (context.color.primary, context.color.primary, context.color.onPrimary, 'Save Changes', _onSaveChangesPressed),
        ].map((e) {
          final (borderColor, backgroundColor, textColor, text, onPressed) = e;
          return UnelevatedRegularButton(
            onPressed: onPressed,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: borderColor)),
            color: backgroundColor,
            padding: EdgeInsets.all(12),
            child: DescriptionText(text, color: textColor),
          );
        }).mapExpandedSpaceBetween(10),
      );

  void _onCancelPressed() {
    Navigator.pop(context);
  }

  void _onSaveChangesPressed() {
    if (!validateData()) return;
    String? fcmToken = HiveUtils.getFcmToken();
    final String categoriesString = _selectedCategoryIds.isEmpty ? "" : _selectedCategoryIds.map((id) => id.toString()).join(',');

    context.read<CurrentUserProfileCubit>().updateUserProfile(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          fileUserimg: fileUserimg,
          state: state,
          city: city,
          bio: bioController.text.trim(),
          mobile: phoneController.text,
          notification: isNotificationsEnabled == true ? "1" : "0",
          countryCode: countryCode,
          personalDetail: isPersonalDetailShow == true ? 1 : 0,
          country: country,
          gender: gender,
          fcmToken: fcmToken,
          categories: categoriesString,
          facebook: facebookController.text.trim(),
          twitter: twitterController.text.trim(),
          instagram: instagramController.text.trim(),
          tiktok: tiktokController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: UiUtils.buildAppBar(context, showBackButton: true, title: 'Edit Profile'),
          backgroundColor: Colors.white,
          body: _buildEditProfileBody(),
        ),
      ),
    );
  }

  // Client fields

  // Expert fields

  // Business fields

  // Social media links section

  // Optional phone widget

  // Gender dropdown

  // Country selector

  // Categories multi-select

  // Show category selection dialog

  void _showCategorySelectionDialog() {
    // Search controller
    final TextEditingController searchController = TextEditingController();
    // Track expanded panels in the dialog

    Set<int> expandedCategoryIds = {};

    _fetchCategories();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BlocBuilder<FetchAllCategoriesCubit, FetchAllCategoriesState>(builder: (context, state) {
          List<CategoryModel> categories = state is FetchAllCategoriesSuccess ? state.categories : [];
          return StatefulBuilder(builder: (context, setState) {
            // Load categories when dialog opens

            // Filter function
            List<CategoryModel> filterCategories(String query) {
              List<CategoryModel> filteredCategories = [];
              if (query.isEmpty) {
                // Only include categories with type 'providers'
                return categories.where((category) => category.type == CategoryType.providers).toList();
              }

              query = query.toLowerCase();
              filteredCategories = categories.where((category) {
                // Only include categories with type 'providers'
                if (category.type != CategoryType.providers) {
                  return false;
                }

                final matchesMainCategory = category.name?.toLowerCase().contains(query) ?? false;

                // Check if any subcategory matches
                final hasMatchingSubcategory =
                    category.children?.any((subcategory) => subcategory.name?.toLowerCase().contains(query) ?? false) ?? false;

                return matchesMainCategory || hasMatchingSubcategory;
              }).toList();

              // Auto-expand categories with matching subcategories
              for (int i = 0; i < filteredCategories.length; i++) {
                final category = filteredCategories[i];
                final originalIndex = categories.indexOf(category);
                final hasSubcategories = category.children != null && category.children!.isNotEmpty;

                final hasMatchingSubcategory =
                    category.children?.any((subcategory) => subcategory.name?.toLowerCase().contains(query) ?? false) ?? false;

                if (hasMatchingSubcategory) {
                  expandedCategoryIds.add(category.id ?? -1);
                }
              }

              return filteredCategories;
            }

            return Dialog(
              insetPadding: EdgeInsets.zero, // Remove default padding
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Column(
                  children: [
                    // Header with title and close button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.color.secondaryColor,
                        border: Border(
                          bottom: BorderSide(
                            color: context.color.borderColor.darken(10),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Expanded(
                            child: Text(
                              "Select Categories",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Update the main state with selected categories
                              this.setState(() {});
                              Navigator.of(context).pop();
                            },
                            child: const Text("Done"),
                          ),
                        ],
                      ),
                    ),

                    // Search field
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: searchController,
                        style: context.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: "Search categories or subcategories",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),
                    ),

                    // Loading indicator or categories list
                    Expanded(
                      child: Builder(builder: (context) {
                        if (state is FetchAllCategoriesInProgress) return UiUtils.progress();
                        if (state is FetchAllCategoriesFailure) {
                          return Center(child: DescriptionText("Error"));
                        }
                        final filteredCategories =
                            filterCategories(searchController.text).where((e) => (e.subcategoriesCount ?? 0) > 0).toList();
                        return filteredCategories.isEmpty
                            ? const Center(child: DescriptionText("No matching categories found"))
                            : ListView.builder(
                                itemCount: filteredCategories.length,
                                itemBuilder: (context, index) {
                                  final category = filteredCategories[index];
                                  final hasSubcategories = category.children != null && category.children!.isNotEmpty;

                                  return Column(
                                    children: [
                                      // Parent category
                                      Container(
                                        decoration: BoxDecoration(
                                          color: context.color.secondaryColor,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: context.color.borderColor.darken(10),
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: ListTile(
                                          title: DescriptionText(category.name ?? "Unknown"),
                                          leading: Checkbox(
                                            value: _isCategorySelected(category.id ?? 0),
                                            onChanged: (bool? value) {
                                              if (category.id != null) {
                                                setState(() {
                                                  if (value == true) {
                                                    if (!_selectedCategoryIds.contains(category.id!)) {
                                                      _selectedCategoryIds.add(category.id!);
                                                    }

                                                    // Also select all subcategories
                                                    if (hasSubcategories) {
                                                      for (var subcategory in category.children!) {
                                                        if (subcategory.id != null && !_selectedCategoryIds.contains(subcategory.id!)) {
                                                          _selectedCategoryIds.add(subcategory.id!);
                                                        }
                                                      }
                                                    }
                                                  } else {
                                                    _selectedCategoryIds.remove(category.id!);

                                                    // Also deselect all subcategories
                                                    if (hasSubcategories) {
                                                      for (var subcategory in category.children!) {
                                                        if (subcategory.id != null) {
                                                          _selectedCategoryIds.remove(subcategory.id!);
                                                        }
                                                      }
                                                    }
                                                  }
                                                });
                                              }
                                            },
                                          ),
                                          // Only show trailing arrow if there are subcategories
                                          trailing: hasSubcategories
                                              ? Icon(
                                                  expandedCategoryIds.contains(category.id)
                                                      ? Icons.keyboard_arrow_up
                                                      : Icons.keyboard_arrow_down,
                                                  color: context.color.textColorDark,
                                                )
                                              : null,
                                          // Make the entire row clickable to expand/collapse if it has subcategories
                                          onTap: hasSubcategories
                                              ? () {
                                                  setState(() {
                                                    if (expandedCategoryIds.contains(category.id)) {
                                                      expandedCategoryIds.remove(category.id);
                                                    } else {
                                                      expandedCategoryIds.add(category.id ?? -1);
                                                    }
                                                  });
                                                }
                                              : null,
                                        ),
                                      ),

                                      // Subcategories (if expanded and has subcategories)
                                      if (hasSubcategories && expandedCategoryIds.contains(category.id))
                                        Container(
                                          color: context.color.secondaryColor.withValues(alpha: 0.5),
                                          child: Column(
                                            children: category.children!.map((subcategory) {
                                              // Filter subcategories if search is active
                                              if (searchController.text.isNotEmpty) {
                                                final query = searchController.text.toLowerCase();
                                                if (!(subcategory.name?.toLowerCase().contains(query) ?? false)) {
                                                  return Container(); // Skip non-matching subcategories
                                                }
                                              }

                                              final hasNestedSubcategories =
                                                  subcategory.children != null && subcategory.children!.isNotEmpty;

                                              return Column(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 20.0),
                                                    child: ListTile(
                                                      title: Text(
                                                        subcategory.name ?? "Unknown",
                                                        style: context.textTheme.bodyMedium,
                                                      ),
                                                      leading: Checkbox(
                                                        value: _isCategorySelected(subcategory.id ?? 0),
                                                        onChanged: (bool? value) {
                                                          if (subcategory.id != null) {
                                                            setState(() {
                                                              if (value == true) {
                                                                if (!_selectedCategoryIds.contains(subcategory.id!)) {
                                                                  _selectedCategoryIds.add(subcategory.id!);
                                                                }
                                                              } else {
                                                                _selectedCategoryIds.remove(subcategory.id!);
                                                              }
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  // Nested subcategories
                                                  if (hasNestedSubcategories)
                                                    Container(
                                                      color: context.color.secondaryColor.withOpacity(0.3),
                                                      child: Column(
                                                        children: subcategory.children!.map((subcategory) {
                                                          return Padding(
                                                            padding: const EdgeInsets.only(left: 40.0),
                                                            child: ListTile(
                                                              title: Text(subcategory.name ?? "Unknown"),
                                                              leading: Checkbox(
                                                                value: _isCategorySelected(subcategory.id ?? 0),
                                                                onChanged: (bool? value) {
                                                                  if (subcategory.id != null) {
                                                                    setState(() {
                                                                      if (value == true) {
                                                                        if (!_selectedCategoryIds.contains(subcategory.id!)) {
                                                                          _selectedCategoryIds.add(subcategory.id!);
                                                                        }
                                                                      } else {
                                                                        _selectedCategoryIds.remove(subcategory.id!);
                                                                      }
                                                                    });
                                                                  }
                                                                },
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              );
                      }),
                    ),
                  ],
                ),
              ),
            );
          });
        });
      },
    );
  }

  // Helper function to check if a category is selected

  bool _isCategorySelected(int categoryId) {
    return _selectedCategoryIds.contains(categoryId);
  }

  // Load categories for dialog
  String formatCountryCode(String countryCode) {
    if (!countryCode.startsWith('+')) {
      return '+$countryCode';
    }
    return countryCode;
  }

  void showPicker() {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent), borderRadius: BorderRadius.circular(10)),
        builder: (BuildContext bc) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: CustomText("gallery".translate(context)),
                    onTap: () {
                      _imgFromGallery(ImageSource.gallery);
                      Navigator.of(context).pop();
                    }),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: CustomText("camera".translate(context)),
                  onTap: () {
                    _imgFromGallery(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
                if (fileUserimg != null && widget.from == 'login')
                  ListTile(
                    leading: const Icon(Icons.clear_rounded),
                    title: CustomText("lblremove".translate(context)),
                    onTap: () {
                      fileUserimg = null;

                      Navigator.of(context).pop();
                      setState(() {});
                    },
                  ),
              ],
            ),
          );
        });
  }

  void _imgFromGallery(ImageSource imageSource) async {
    CropImage.init(context);

    final pickedFile = await ImagePicker().pickImage(source: imageSource);

    if (pickedFile != null) {
      CroppedFile? croppedFile;
      croppedFile = await CropImage.crop(
        filePath: pickedFile.path,
      );
      if (croppedFile == null) {
        fileUserimg = null;
      } else {
        fileUserimg = File(croppedFile.path);
      }
    } else {
      fileUserimg = null;
    }
    setState(() {});
  }

  void showCountryCode() {
    showCountryPicker(
      context: context,
      showWorldWide: false,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(borderRadius: BorderRadius.circular(11)),
      exclude: ['IL'],
      favorite: ['LB'],
      onSelect: (Country value) {
        countryCode = value.phoneCode;
        setState(() {});
      },
    );
  }

  bool validateData() {
    try {
      validateNonEmptyField('full name', controller: nameController);
      if (_type == UserType.expert) {
        validateNonEmptyField('gender', text: gender);
      }
      validateNonEmptyField('location', controller: locationController);
      validateNonEmptyField('location', text: country);
      validateNonEmptyField('location', text: city);
      if (_type != UserType.client) {
        validateNonEmptyField('phone number', controller: phoneController);
        // validateNonEmptyField('bio', controller: bioController);
        if (_selectedCategoryIds.isEmpty) {
          throw 'Kindly select at least one category';
        }
      }
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      return false;
    }
  }

  void validateNonEmptyField(String fieldName, {String? text, TextEditingController? controller}) {
    text ??= controller?.text;
    if (text?.trim().isEmpty ?? true) {
      throw 'Kindly enter the your $fieldName';
    }
  }
}
