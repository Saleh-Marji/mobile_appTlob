import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/category/fetch_all_categories_cubit.dart';
import 'package:tlobni/data/cubits/custom_field/fetch_custom_fields_cubit.dart';
import 'package:tlobni/data/cubits/item/fetch_my_item_cubit.dart';
import 'package:tlobni/data/cubits/item/manage_item_cubit.dart';
import 'package:tlobni/data/helper/widgets.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/models/post_type.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/widgets/image_adapter.dart';
import 'package:tlobni/ui/screens/item/my_items/my_item_tab_screen.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:tlobni/ui/screens/widgets/dynamic_field.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/buttons/primary_button.dart';
import 'package:tlobni/ui/widgets/buttons/regular_button.dart';
import 'package:tlobni/ui/widgets/buttons/unelevated_regular_button.dart';
import 'package:tlobni/ui/widgets/dropdown/form_dropdown.dart';
import 'package:tlobni/ui/widgets/location_field_selector.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';
import 'package:tlobni/utils/cloud_state/cloud_state.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/extensions/lib/iterable_iterable.dart';
import 'package:tlobni/utils/extensions/lib/widget_iterable.dart';
import 'package:tlobni/utils/google_maps_service.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/image_picker.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:tlobni/utils/validator.dart';

class AddItemDetails extends StatefulWidget {
  final List<CategoryModel>? breadCrumbItems;
  final bool? isEdit;
  final PostType postType;
  final ItemModel? item;

  const AddItemDetails({
    super.key,
    this.breadCrumbItems,
    required this.isEdit,
    required this.postType,
    this.item,
  });

  static Route route(RouteSettings settings) {
    Map<String, dynamic>? arguments = settings.arguments as Map<String, dynamic>?;
    return BlurredRouter(
      builder: (context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => FetchCustomFieldsCubit()),
            BlocProvider(create: (context) => ManageItemCubit()),
          ],
          child: AddItemDetails(
            breadCrumbItems: arguments?['breadCrumbItems'],
            isEdit: arguments?['isEdit'],
            postType: arguments?['postType'],
            item: arguments?['item'],
          ),
        );
      },
    );
  }

  @override
  CloudState<AddItemDetails> createState() => _AddItemDetailsState();
}

class _AddItemDetailsState extends CloudState<AddItemDetails> {
  final PickImage _pickTitleImage = PickImage();
  final PickImage itemImagePicker = PickImage();
  String titleImageURL = "";
  List<dynamic> mixedItemImageList = [];
  List<int> deleteItemImageList = [];
  late final GlobalKey<FormState> _formKey;

  // Compression method moved to correct position
  Future<File?> compressImage(File file) async {
    try {
      final dir = await path_provider.getTemporaryDirectory();
      final targetPath = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70, // Adjust quality (0-100)
        minWidth: 1024,
        minHeight: 1024,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      print('Error compressing image: $e');
      return file; // Return original file if compression fails
    }
  }

  // Variables for service and experience fields
  Map<String, bool> _specialTags = {"exclusive_women": false, "corporate_package": false};
  String? _priceType;
  bool _atClientLocation = false;
  bool _atPublicVenue = false;
  bool _atMyLocation = false;
  bool _isVirtual = false;
  Set<String> _locationTypes = {};
  DateTime? _date = DateTime.now();
  TimeOfDay? _time = TimeOfDay.now();
  AddressComponent? formattedAddress;
  bool _isSubmitting = false; // Add loading state for submit button
  CategoryModel? _selectedCategory;
  bool _forACause = false;
  int? _slotsAvailable = 1;
  late EndTimerOption? _endTimerOption = isEdit ? null : EndTimerOption.h24;
  ItemAudience? _audience = ItemAudience.public;

  // Add missing controllers
  final TextEditingController cityTextController = TextEditingController();
  final TextEditingController stateTextController = TextEditingController();
  final TextEditingController countryTextController = TextEditingController();
  final TextEditingController forACauseTextController = TextEditingController();

  // Location autocomplete
  final TextEditingController locationController = TextEditingController();

  // Location coordinates
  double? _selectedLatitude;
  double? _selectedLongitude;

  //Text Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController adPriceController = TextEditingController();
  final TextEditingController adPhoneNumberController = TextEditingController();
  final TextEditingController _videoLinkController = TextEditingController();

  void _onBreadCrumbItemTap(int index) {
    int popTimes = (widget.breadCrumbItems!.length - 1) - index;
    int current = index;
    int length = widget.breadCrumbItems!.length;

    for (int i = length - 1; i >= current + 1; i--) {
      widget.breadCrumbItems!.removeAt(i);
    }

    for (int i = 0; i < popTimes; i++) {
      Navigator.pop(context);
    }
    setState(() {});
  }

  late List selectedCategoryList;
  late ItemModel? item = widget.item;

  Future<void> _onRefresh() async {
    context.read<FetchAllCategoriesCubit>().fetchCategories();
  }

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _initFields(widget.item);
    _onRefresh();
    _pickTitleImage.listener((p0) {
      titleImageURL = "";
      WidgetsBinding.instance.addPersistentFrameCallback((timeStamp) {
        if (mounted) setState(() {});
      });
    });

    itemImagePicker.listener((images) {
      try {
        mixedItemImageList.addAll(List<dynamic>.from(images));
      } catch (e) {}

      setState(() {});
    });
  }

  bool get isEdit => widget.isEdit == true;

  Widget _section({required String title, required List<Widget> children}) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          border: Border.all(color: Color(0xffededed)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeadingText(title, fontSize: 22),
            SizedBox(height: 10),
            Divider(height: 2.5, color: context.color.secondary, thickness: 2),
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: children,
            ),
          ],
        ),
      );

  Widget _field({required String label, required Widget child, bool? required = true}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DescriptionText(
            '${label}${required == null ? '' : required ? ' *' : ' (Optional)'}',
            weight: FontWeight.w500,
          ),
          SizedBox(height: 10),
          child,
        ],
      );

  InputDecoration _textFieldDecorationTheme({required Color borderColor, required String? hint}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: borderColor),
    );
    return InputDecoration(
      border: border,
      disabledBorder: border,
      focusedBorder: border,
      enabledBorder: border,
      contentPadding: EdgeInsets.all(10),
      hintText: hint,
      hintStyle: context.textTheme.bodyMedium?.copyWith(color: Colors.grey),
    );
  }

  Builder _customTextField({
    required Color borderColor,
    required String hint,
    required TextEditingController controller,
    TextInputType? textInputType,
    InputDecoration Function(InputDecoration decoration)? decorationBuilder,
    int maxLines = 1,
    bool readOnly = false,
    FocusNode? focusNode,
  }) {
    decorationBuilder ??= (e) => e;
    return Builder(builder: (context) {
      return TextFormField(
        focusNode: focusNode,
        controller: controller,
        style: context.textTheme.bodyMedium,
        readOnly: readOnly,
        keyboardType: textInputType,
        maxLines: maxLines,
        decoration: decorationBuilder?.call(_textFieldDecorationTheme(
          borderColor: borderColor,
          hint: hint,
        )),
      );
    });
  }

  Widget _serviceTitle() {
    return _field(
      label: 'Title',
      child: _customTextField(
        borderColor: context.color.secondary,
        hint: 'Enter ${widget.postType.toString().toLowerCase()} title',
        controller: _titleController,
      ),
    );
  }

  Widget _description() => _field(
        label: 'Description',
        child: _customTextField(
          borderColor: context.color.secondary,
          hint: 'Describe your ${widget.postType.toString()}...',
          controller: _descriptionController,
          maxLines: 4,
          textInputType: TextInputType.multiline,
        ),
      );

  Widget _selectCategory() => _field(
        label: 'Category',
        child: BlocBuilder<FetchAllCategoriesCubit, FetchAllCategoriesState>(builder: (context, state) {
          if (state is FetchAllCategoriesInProgress) return UiUtils.progress();
          if (state is FetchAllCategoriesFailure) return DescriptionText(state.errorMessage);
          if (state is! FetchAllCategoriesSuccess) return SizedBox();
          return FormDropdown(
            hint: 'Select Category',
            allowSearch: true,
            entries: state.categories
                .where((e) => e.type == CategoryType.serviceExperience && e.parentId == null)
                .map((e) => [e, ...?e.children])
                .reduceToSingleIterable()
                .map((e) {
              final isParent = e.parentId == null;
              final enabled = !isParent || (e.children?.isEmpty ?? false);
              return DropdownMenuEntry(
                value: e,
                label: '${e.name ?? ''}',
                style: ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.all(10)),
                  backgroundColor: WidgetStatePropertyAll(!enabled ? context.color.secondary : Colors.transparent),
                ),
                enabled: enabled,
              );
            }).toList(),
            selectedValue: _selectedCategory,
            onSelected: (value) {
              FocusScope.of(context).unfocus();
              setState(() => _selectedCategory = value);
              return true;
            },
          );
        }),
      );

  Color get _greyBorderColor => Color(0xffe6e6e6);

  List<int> get _slotsAvailableOptions => List.generate(25, (index) => index + 1);

  Widget _price() => _field(
        label: 'Price',
        child: _customTextField(
          borderColor: _greyBorderColor,
          hint: '0.00',
          controller: adPriceController,
          textInputType: TextInputType.numberWithOptions(signed: false, decimal: true),
          decorationBuilder: (e) => e.copyWith(
            // prefixText: '\$',
            // prefixStyle: context.textTheme.bodyMedium,
            prefix: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: DescriptionText('\$'),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),
      );

  Widget _priceTypeDropdown() => _field(
        label: 'Price Type',
        child: FormDropdown(
          hint: 'Select type',
          items: ItemModel.paymentTypesWithTitles,
          selectedValue: _priceType,
          onSelected: (value) {
            setState(() => _priceType = value);
            return true;
          },
        ),
      );

  Widget _pricing() => IntrinsicHeight(
        child: Row(
          children: [
            _price(),
            _priceTypeDropdown(),
          ].mapExpandedSpaceBetween(10),
        ),
      );

  Widget _location() => _field(
        label: 'Location',
        child: LocationFieldSelector(
          required: true,
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
          city: formattedAddress?.city,
          country: formattedAddress?.country,
          state: formattedAddress?.state,
          onLocationSelected: (latitude, longitude, city, country, state) => setState(() {
            _selectedLatitude = latitude;
            _selectedLongitude = longitude;
            formattedAddress = AddressComponent(
              city: city,
              country: country,
              state: state,
            );
          }),
        ),
      );

  Widget _basicInformation() => _section(
        title: 'Basic Information',
        // child: Column(
        //   spacing: 20,
        //   crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _serviceTitle(),
          _description(),
          _selectCategory(),
          _pricing(),
          _location(),
        ],
        // )
      );

  Widget _endDateButton(String text, VoidCallback onPressed) => UnelevatedRegularButton(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: _greyBorderColor),
        ),
        onPressed: onPressed,
        padding: EdgeInsets.all(15),
        child: DescriptionText(text),
      );

  Widget _dateField() => _endDateButton(_formatDate(), _pickDate);

  String _formatDate() {
    if (_date == null) return 'Select Date';
    return DateFormat('MMM d, y').format(_date!);
  }

  Widget _dateAndTimeField() => _endDateButton(_formatTime(), _pickTime);

  String _formatTime() {
    if (_time == null) return 'Select Time';
    return _time!.format(context);
  }

  Widget _dateAndTime() => _field(
        label: 'Date & Time',
        child: Row(
          children: [
            _dateField(),
            _dateAndTimeField(),
          ].mapExpandedSpaceBetween(10),
        ),
      );

  void _onServiceLocationTypePressed(String type) {
    setState(() => _locationTypes.contains(type) ? _locationTypes.remove(type) : _locationTypes.add(type));
  }

  Widget _serviceLocation() => _field(
        label: 'Locations',
        child: Column(
          children: ItemModel.locationTypes.map((e) {
            return UnelevatedRegularButton(
              color: Colors.transparent,
              onPressed: () => _onServiceLocationTypePressed(e),
              child: Row(
                children: [
                  Checkbox(
                    value: _locationTypes.contains(e),
                    onChanged: (val) => _onServiceLocationTypePressed(e),
                  ),
                  SizedBox(width: 5),
                  Expanded(child: DescriptionText(ItemModel.locationTypeString(e))),
                ],
              ),
            );
          }).toList(),
        ),
      );

  Widget _specialTagField(String specialTag) => _switchField(_specialTags[specialTag] == true, (val) => _specialTags[specialTag] = val);

  Widget _switchField(bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: (value) {
            setState(() => onChanged(value));
          },
        ),
        SizedBox(width: 5),
        Expanded(child: DescriptionText(value ? 'Yes' : 'No')),
      ],
    );
  }

  Widget _exclusiveForWomen() => _field(
        label: 'Exclusive for Women',
        required: null,
        child: _specialTagField('exclusive_women'),
      );

  Widget _corporatePackage() => _field(
        label: 'Corporate Package',
        required: null,
        child: _specialTagField('corporate_package'),
      );

  Widget _forACauseWidget() => _field(
        label: 'Philanthropic Event',
        required: null,
        child: _switchField(_forACause, (val) => _forACause = val),
      );

  Widget _forACauseText() => _field(
        label: 'Philanthropic Description',
        child: _customTextField(
          borderColor: kColorSecondaryBeige,
          maxLines: 4,
          hint: 'Describe the philanthropic aspects of this opportunity',
          controller: forACauseTextController,
        ),
      );

  Widget _slotsAvailableWidget() => _field(
        label: 'Slots Available',
        child: FormDropdown<int>(
          selectedValue: _slotsAvailable,
          items: _slotsAvailableOptions.map((e) => (e, e.toString())).toList(),
          onSelected: (slots) {
            setState(() => _slotsAvailable = slots);
            return true;
          },
        ),
      );

  Widget _endTimerOptionWidget() => _field(
      label: 'End Timer',
      child: FormDropdown<EndTimerOption?>(
        selectedValue: _endTimerOption,
        items: [if (isEdit) null, ...EndTimerOption.values].map((e) => (e, e == null ? 'Keep as is' : e.toString())).toList(),
        onSelected: (value) {
          setState(() => _endTimerOption = value);
          return true;
        },
      ));

  Widget _audienceWidget() => _field(
        label: 'Audience',
        child: Wrap(
              runSpacing: 10,
              spacing: 10,
              children: ItemAudience.values
                  .map((e) => _buildRadioOption(
                        context,
                        title: e.toString(),
                        value: e,
                        groupValue: _audience,
                        onChanged: (val) => setState(() => _audience = val),
                      ))
                  .toList(),
            ) ??
            FormDropdown<ItemAudience>(
              selectedValue: _audience,
              items: ItemAudience.values.map((e) => (e, e.toString())).toList(),
              onSelected: (value) {
                setState(() => _audience = value);
                return true;
              },
            ),
      );

  Widget _itemDetails() => _section(
        title: 'Details',
        children: [
          if (widget.postType == PostType.experience) _dateAndTime() else _serviceLocation(),
          _exclusiveForWomen(),
          _corporatePackage(),
          _slotsAvailableWidget(),
          _endTimerOptionWidget(),
          if (HiveUtils.isBusiness()) _audienceWidget(),
          if (widget.postType == PostType.experience) ...[
            _forACauseWidget(),
            if (_forACause) _forACauseText(),
          ]
        ],
      );

  void _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _time) {
      setState(() {
        _time = picked;
      });
    }
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  Widget _mainImage() => _field(
        label: 'mainPicture'.translate(context),
        child: Column(
          children: [titleImageListener(), SmallText('This will be the main image shown in listings (Max 3MB)')],
        ),
      );

  Widget _additionalImages() => _field(
        label: 'Additional Images',
        required: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            itemImagesListener(),
            SmallText('These images will appear in the slider in the ${widget.postType.toString().toLowerCase()} details page, ' +
                'max5Images'.translate(context)),
          ],
        ),
      );

  Widget _videoLink() => _field(
        label: 'Video Link',
        required: false,
        child: _customTextField(
          borderColor: context.color.secondary,
          hint: 'https://www.youtube.com/watch?v=...',
          controller: _videoLinkController,
        ),
      );

  Widget _mediaSection() => _section(
        title: 'Media',
        children: [
          _mainImage(),
          _additionalImages(),
          _videoLink(),
        ],
      );

  Widget _submitButton() => PrimaryButton.text(
        '${isEdit ? 'Update' : 'Create'}',
        padding: EdgeInsets.all(20),
        onPressed: _onSubmitPressed,
      );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ManageItemCubit, ManageItemState>(
      listener: _rootListener,
      builder: (context, state) {
        return Scaffold(
          appBar: UiUtils.buildAppBar(
            context,
            showBackButton: true,
            title: '${isEdit ? 'Edit' : 'Create'} ${widget.postType == PostType.experience ? 'an Opportunity' : 'a Service'}',
          ),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(20).add(EdgeInsets.only(bottom: 70)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 20,
                children: [
                  _basicInformation(),
                  _itemDetails(),
                  _mediaSection(),
                  SizedBox(),
                  _submitButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onSubmitPressed() async {
    // Return early if already submitting to prevent multiple submissions
    if (_isSubmitting) return;

    // Set loading state
    setState(() {
      _isSubmitting = true;
    });

    // Get post type
    PostType postType = widget.postType;

    // Validate required fields for both types
    if (!_validateRequiredFields(postType)) {
      // Reset loading state if validation fails
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    // Set up location check
    bool isEdit = widget.isEdit == true;
    bool hasLocationData = false;

    // Check if the item already has location data in edit mode
    if (isEdit && item != null) {
      hasLocationData = (item!.city != null && item!.city!.isNotEmpty) ||
          (item!.area != null && item!.area!.isNotEmpty) ||
          (item!.country != null && item!.country!.isNotEmpty);
    }

    // For experience type OR if location is valid for service type
    if (postType == PostType.experience ||
        hasLocationData ||
        (formattedAddress != null &&
            !((formattedAddress!.city == "" || formattedAddress!.city == null) &&
                (formattedAddress!.area == "" || formattedAddress!.area == null)) &&
            !(formattedAddress!.country == "" || formattedAddress!.country == null))) {
      try {
        // Create a fresh cloudData map to ensure we're collecting current values
        // This avoids using potentially stale data from getCloudData("with_more_details")
        Map<String, dynamic> cloudData = {};

        // Merge any existing custom fields data which might have been set in more_details screen
        Map<String, dynamic> existingData = getCloudData("with_more_details") ?? {};
        if (existingData.containsKey('custom_fields')) {
          cloudData['custom_fields'] = existingData['custom_fields'];
        } else if (AbstractField.fieldsData.isNotEmpty) {
          // If we have data in AbstractField.fieldsData but it wasn't in more_details,
          // encode it directly
          cloudData['custom_fields'] = json.encode(AbstractField.fieldsData);
          print("Using AbstractField.fieldsData directly: ${AbstractField.fieldsData}");
        }

        // Preserve any file references or binary data from the previous screen
        existingData.forEach((key, value) {
          if (key.startsWith('custom_file_') || value is File) {
            cloudData[key] = value;
          }
        });

        // Add form data to cloudData
        cloudData['name'] = _titleController.text;
        cloudData['description'] = _descriptionController.text;
        cloudData['price'] = adPriceController.text;
        cloudData['contact'] = adPhoneNumberController.text;

        if (widget.postType == PostType.experience) {
          cloudData['for_a_cause_text'] = _forACause ? forACauseTextController.text : null;
        }

        if (_audience != null) cloudData['audience'] = _audience?.name;

        if (_slotsAvailable != null) cloudData['slots'] = _slotsAvailable;

        if (_endTimerOption != null) {
          final hours = _endTimerOption!.toHours();
          DateTime endDateTime = DateTime.now().add(Duration(hours: hours));
          cloudData['expiration_date'] = DateTime(endDateTime.year, endDateTime.month, endDateTime.day).toIso8601String();
          cloudData['expiration_time'] = DateFormat('HH:mm').format(endDateTime);
          cloudData['end_timer_option'] = _endTimerOption!.name;
        }

        // Handle the video link - validate URL format or set to empty
        String videoLink = _videoLinkController.text.trim();
        if (videoLink.isEmpty) {
          cloudData['video_link'] = '';
        } else if (videoLink.startsWith('http://') || videoLink.startsWith('https://')) {
          cloudData['video_link'] = videoLink;
        } else {
          // Show error for invalid URL and return
          setState(() {
            _isSubmitting = false;
          });
          HelperUtils.showSnackBarMessage(context, "Please enter a valid URL starting with http:// or https://");
          return;
        }

        // Add category_id - critical for API request
        cloudData['category_id'] = _selectedCategory?.id.toString();
        // if (widget.isEdit == true) {
        //   // For edit, use the item's existing category IDs
        //   if (item != null && item!.allCategoryIds != null) {
        //     cloudData['category_id'] = item!.allCategoryIds;
        //   }
        // } else {
        //   // For new item, get the last (most specific) category ID from the breadcrumb
        //   if (widget.breadCrumbItems != null && widget.breadCrumbItems!.isNotEmpty) {
        //     // Get the most specific category (last one in breadcrumb)
        //
        //     // If the API requires the full category path, we can also add it
        //     if (selectedCategoryList.isNotEmpty) {
        //       cloudData['category_hierarchy'] = selectedCategoryList.join(',');
        //     }
        //   }
        // }

        // Add special tags and price type
        // Format special tags as strings to match database format
        Map<String, String> formattedSpecialTags = {};
        _specialTags.forEach((key, value) {
          formattedSpecialTags[key] = value.toString();
        });

        print("Saving special tags: $formattedSpecialTags");
        cloudData['special_tags'] = formattedSpecialTags;
        cloudData['price_type'] = _priceType;

        // Add post type
        cloudData['post_type'] = postType.name;

        // Add service location options if applicable
        if (postType == PostType.service) {
          List<String> locationTypes = _locationTypes.toList();
          // Create a list to gather location types
          print("Saving location types: $locationTypes");

          // Store location types in the format expected by the API
          // The API might expect different formats for new vs edit
          if (locationTypes.isNotEmpty) {
            if (widget.isEdit == true) {
              // For edit, send as array/list (original format from loaded item)
              cloudData['location_type'] = locationTypes.join(',');
            } else {
              // For new posts, try both formats to ensure compatibility
              cloudData['location_type'] = locationTypes.join(',');
            }
          }

          // Add individual flags for backward compatibility
          cloudData['at_client_location'] = _atClientLocation;
          cloudData['at_public_venue'] = _atPublicVenue;
          cloudData['at_my_location'] = _atMyLocation;
          cloudData['is_virtual'] = _isVirtual;
        }

        // Add expiration date/time if applicable
        if (postType == PostType.experience) {
          if (_date != null) {
            cloudData['item_date'] = _date!.toIso8601String();
          }
          if (_time != null) {
            cloudData['item_time'] = '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';
          }
        }

        // Add location data if available
        if (formattedAddress != null) {
          cloudData['address'] = formattedAddress?.mixed;
          cloudData['country'] = formattedAddress!.country;
          cloudData['city'] = (formattedAddress!.city == "" || formattedAddress!.city == null)
              ? (formattedAddress!.area == "" || formattedAddress!.area == null ? null : formattedAddress!.area)
              : formattedAddress!.city;
          cloudData['state'] = formattedAddress!.state;
          if (formattedAddress!.areaId != null) cloudData['area_id'] = formattedAddress!.areaId;
        }

        // Add coordinates if available
        if (_selectedLatitude != null && _selectedLongitude != null) {
          cloudData['latitude'] = _selectedLatitude;
          cloudData['longitude'] = _selectedLongitude;
        }

        // Get main image with compression
        File? mainImage;
        if (_pickTitleImage.pickedFile != null) {
          try {
            // Check if pickedFile is a List<File> or a single File
            if (_pickTitleImage.pickedFile is List<File> && (_pickTitleImage.pickedFile as List<File>).isNotEmpty) {
              File originalFile = (_pickTitleImage.pickedFile as List<File>).first;
              mainImage = await compressImage(originalFile);
            } else if (_pickTitleImage.pickedFile is File) {
              File originalFile = _pickTitleImage.pickedFile as File;
              mainImage = await compressImage(originalFile);
            }

            if (mainImage == null) {
              throw Exception("Failed to process main image");
            }
          } catch (e) {
            print("Error processing main image: $e");
            setState(() {
              _isSubmitting = false;
            });
            HelperUtils.showSnackBarMessage(context, "Failed to process main image. Try a different image.");
            return;
          }
        }

        // Get other images with compression
        List<File> otherImages = [];
        try {
          for (var item in mixedItemImageList) {
            if (item is File) {
              File? compressed = await compressImage(item);
              if (compressed != null) {
                otherImages.add(compressed);
              }
            }
          }
        } catch (e) {
          print("Error processing additional images: $e");
          setState(() {
            _isSubmitting = false;
          });
          HelperUtils.showSnackBarMessage(context, "Failed to process some additional images.");
          return;
        }

        // Add deleted image IDs if editing
        if (isEdit && deleteItemImageList.isNotEmpty) {
          cloudData['deleted_images'] = deleteItemImageList;
        }

        // Add error handling for the cubit call
        try {
          if (isEdit) {
            // Add item ID for editing
            cloudData['id'] = item?.id;

            context.read<ManageItemCubit>().manage(ManageItemType.edit, cloudData, mainImage, otherImages);
          } else {
            context.read<ManageItemCubit>().manage(ManageItemType.add, cloudData, mainImage, otherImages);
          }
        } catch (e) {
          print("Error during API call: $e");
          setState(() {
            _isSubmitting = false;
          });
          HelperUtils.showSnackBarMessage(context, "Failed to upload. Please try again.");
          return;
        }
      } catch (e, st) {
        print("Error submitting form: $e");
        // Reset loading state on error
        setState(() {
          _isSubmitting = false;
        });
        HelperUtils.showSnackBarMessage(context, "An error occurred. Please try again.");
      }
    } else {
      // Reset loading state when validation fails
      setState(() {
        _isSubmitting = false;
      });
      HelperUtils.showSnackBarMessage(context, "cityRequired".translate(context));
      Future.delayed(Duration(seconds: 2), () {
        dialogueBottomSheet(
            controller: cityTextController, title: "enterCity".translate(context), hintText: "city".translate(context), from: 1);
      });
    }

    return;
  }

  // Safely update location data without immediate setState
  void _updateLocationData(Map<String, String> locationData) {
    if (locationData.isEmpty) return;
    // Update the address component directly
    formattedAddress = AddressComponent(
      city: locationData['city'] ?? formattedAddress?.city,
      state: locationData['state'] ?? formattedAddress?.state,
      country: locationData['country'] ?? formattedAddress?.country,
      area: locationData['city'] ?? formattedAddress?.area,
      mixed: "${locationData['city'] ?? ''}, ${locationData['country'] ?? ''}",
      areaId: formattedAddress?.areaId,
    );

    // Always ensure the locationController has the consistent value
    if (formattedAddress != null && formattedAddress!.mixed != null && formattedAddress!.mixed!.isNotEmpty) {
      // Only update if it's different to avoid unnecessary text controller changes
      if (locationController.text != formattedAddress!.mixed) {
        locationController.text = formattedAddress!.mixed!;
      }
    }

    // Schedule a rebuild for after the current call stack is complete
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          // This empty setState will trigger a rebuild with the updated data
        });
      });
    }

    // Add debug log
    print("Location updated to: ${locationController.text}");
    print("FormatedAddress: $formattedAddress");
  }

  // Get current location
  void _getCurrentLocation() async {
    try {
      // Show loading indicator
      HelperUtils.showSnackBarMessage(context, 'Getting your location...');

      // Get current location using the Google Maps service
      final GoogleMapsService mapsService = GoogleMapsService();
      final position = await mapsService.getCurrentLocation();

      if (position != null) {
        // Store coordinates
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;

        // Get address from coordinates
        final addressData = await mapsService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (addressData != null) {
          // Update location data
          _updateLocationData(addressData);

          // Update the location controller with formatted address
          String formattedAddress = addressData['formatted_address'] ?? "${addressData['city'] ?? ''}, ${addressData['country'] ?? ''}";
          locationController.text = formattedAddress;

          HelperUtils.showSnackBarMessage(context, 'Location updated successfully!');
        } else {
          HelperUtils.showSnackBarMessage(context, 'Could not get address for current location');
        }
      } else {
        HelperUtils.showSnackBarMessage(context, 'Could not get current location. Please check permissions.');
      }
    } catch (e) {
      HelperUtils.showSnackBarMessage(context, 'Error getting location: $e');
    }
  }

  void _rootListener(BuildContext context, ManageItemState state) {
    if (state is ManageItemInProgress) {
      Widgets.showLoader(context);
    } else {
      Widgets.hideLoder(context);
    }
    if (state is ManageItemSuccess) {
      // Get the updated item
      ItemModel updatedItem = state.model;

      if (widget.isEdit == true) {
        // If we're editing, update other BLoCs with this item
        try {
          // If we have myAdsCubitReference (from MyItemTabScreen)
          String? statusKey = getCloudData('edit_from') as String?;
          if (statusKey != null && myAdsCubitReference.containsKey(statusKey)) {
            // Update the specific tab's cubit
            FetchMyItemsCubit tabCubit = myAdsCubitReference[statusKey]!;
            tabCubit.edit(updatedItem);
            print("Successfully updated MyItemTab with status: $statusKey");
          }

          // Also try to update the cubit in the current context
          context.read<ManageItemCubit>().updateItemInOtherBlocs(updatedItem, context);
        } catch (e) {
          print("Error updating other BLoCs: $e");
        }
      }

      // Show success message
      HelperUtils.showSnackBarMessage(context,
          widget.isEdit == true ? "Item updated successfully" : "Your listing is under review — we'll notify you once it's approved!");

      // Navigate based on edit or new item
      if (widget.isEdit == true) {
        // For edit mode, return to previous screen with refresh value
        setState(() {
          _isSubmitting = false;
        });

        // Pop and return refresh value to trigger update in ad_details_screen
        Navigator.of(context).pop("refresh");
      } else {
        // For new item, navigate to the details page of the newly created service
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).popUntil((route) => route.isFirst);

          // Navigate to the details page of the newly created service
          Navigator.pushNamed(context, Routes.adDetailsScreen, arguments: {
            'model': updatedItem,
          });
        });
      }
    } else if (state is ManageItemFail) {
      // Show error message with more detail
      String errorMessage = "Failed to process request: ${state.error}";
      print("Error updating/adding item: ${state.error}");

      // Reset the submitting state
      setState(() {
        _isSubmitting = false;
      });

      // Show error message to user
      HelperUtils.showSnackBarMessage(context, errorMessage);
    }
  }

  Future<void> showImageSourceDialog(BuildContext context, Function(ImageSource) onSelected) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: HeadingText('selectImageSource'.translate(context), fontSize: 25),
          content: SingleChildScrollView(
            child: ListBody(
              children: [('camera', ImageSource.camera), ('gallery', ImageSource.gallery)]
                  .map((e) {
                    return RegularButton(
                      color: Colors.white,
                      padding: EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onSelected(e.$2);
                      },
                      child: DescriptionText(e.$1.translate(context)),
                    );
                  })
                  .spaceBetween(10)
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget dialogueWidget(String title, TextEditingController controller, String hintText) {
    double bottomPadding = (MediaQuery.of(context).viewInsets.bottom - 50);
    bool isBottomPaddingNagative = bottomPadding.isNegative;
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                title,
                fontSize: context.font.larger,
                textAlign: TextAlign.center,
                fontWeight: FontWeight.bold,
              ),
              Divider(
                thickness: 1,
                color: context.color.borderColor.darken(30),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(bottom: isBottomPaddingNagative ? 0 : bottomPadding, start: 20, end: 20, top: 18),
                child: TextFormField(
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: context.color.textDefaultColor.withOpacity(0.3)),
                  controller: controller,
                  cursorColor: context.color.territoryColor,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return Validator.nullCheckValidator(val, context: context);
                    } else {
                      return null;
                    }
                  },
                  decoration: InputDecoration(
                      fillColor: context.color.borderColor.darken(20),
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      hintText: hintText,
                      hintStyle: TextStyle(fontWeight: FontWeight.bold, color: context.color.textDefaultColor.withOpacity(0.3)),
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

  void dialogueBottomSheet(
      {required String title, required TextEditingController controller, required String hintText, required int from}) async {
    await UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        content: dialogueWidget(title, controller, hintText),
        acceptButtonName: "add".translate(context),
        isAcceptContainerPush: true,
        onAccept: () => Future.value().then((_) {
          if (_formKey.currentState!.validate()) {
            setState(() {
              if (formattedAddress != null) {
                // Update existing formatedAddress
                if (from == 1) {
                  formattedAddress = AddressComponent.copyWithFields(formattedAddress!, newCity: controller.text);
                } else if (from == 2) {
                  formattedAddress = AddressComponent.copyWithFields(formattedAddress!, newState: controller.text);
                } else if (from == 3) {
                  formattedAddress = AddressComponent.copyWithFields(formattedAddress!, newCountry: controller.text);
                }
              } else {
                // Create a new AddressComponent if formatedAddress is null
                if (from == 1) {
                  formattedAddress = AddressComponent(
                    area: "",
                    areaId: null,
                    city: controller.text,
                    country: "",
                    state: "",
                  );
                } else if (from == 2) {
                  formattedAddress = AddressComponent(
                    area: "",
                    areaId: null,
                    city: "",
                    country: "",
                    state: controller.text,
                  );
                } else if (from == 3) {
                  formattedAddress = AddressComponent(
                    area: "",
                    areaId: null,
                    city: "",
                    country: controller.text,
                    state: "",
                  );
                }
              }
              Navigator.pop(context);
            });
          }
        }),
      ),
    );
  }

  Widget titleImageListener() {
    return _pickTitleImage.listenChangesInUI((context, List<File>? files) {
      Widget currentWidget = Container();
      File? file = files?.isNotEmpty == true ? files![0] : null;

      if (titleImageURL.isNotEmpty) {
        currentWidget = GestureDetector(
          onTap: () {
            UiUtils.showFullScreenImage(context, provider: NetworkImage(titleImageURL));
          },
          child: Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.all(5),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: UiUtils.getImage(
              titleImageURL,
              fit: BoxFit.cover,
            ),
          ),
        );
      }
      double size = 180;

      if (file != null) {
        currentWidget = GestureDetector(
          onTap: () {
            UiUtils.showFullScreenImage(context, provider: FileImage(file));
          },
          child: Container(
            width: double.infinity,
            height: size,
            margin: const EdgeInsets.all(5),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.file(
              file,
              fit: BoxFit.cover,
            ),
          ),
        );
      }

      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          if (file == null && titleImageURL.isEmpty)
            DottedBorder(
              color: context.color.textLightColor,
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: GestureDetector(
                onTap: () {
                  showImageSourceDialog(context, (source) {
                    _pickTitleImage.resumeSubscription();
                    _pickTitleImage.pick(
                      pickMultiple: false,
                      context: context,
                      source: source,
                    );
                    _pickTitleImage.pauseSubscription();
                    titleImageURL = "";
                    setState(() {});
                  });
                },
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  alignment: AlignmentDirectional.center,
                  height: size,
                  child: DescriptionText(
                    "addMainPicture".translate(context),
                    // color: context.color.textDefaultColor,
                    fontSize: context.font.large,
                  ),
                ),
              ),
            ),
          Stack(
            children: [
              currentWidget,
              closeButton(context, () {
                _pickTitleImage.clearImage();
                titleImageURL = "";
                setState(() {});
              })
            ],
          ),
          if (file == null && titleImageURL.isNotEmpty)
            uploadPhotoCard(context, onTap: () {
              showImageSourceDialog(context, (source) {
                _pickTitleImage.resumeSubscription();
                _pickTitleImage.pick(
                  pickMultiple: false,
                  context: context,
                  source: source,
                );
                _pickTitleImage.pauseSubscription();
                titleImageURL = "";
                setState(() {});
              });
            }),
        ],
      );
    });
  }

  Widget itemImagesListener() {
    return itemImagePicker.listenChangesInUI((context, files) {
      List<Widget> current = [];

      current = List.generate(mixedItemImageList.length, (index) {
        final image = mixedItemImageList[index];
        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                HelperUtils.unfocus();
                if (image is String) {
                  UiUtils.showFullScreenImage(context, provider: NetworkImage(image));
                } else {
                  UiUtils.showFullScreenImage(context, provider: FileImage(image));
                }
              },
              child: Container(
                width: 100,
                height: 100,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ImageAdapter(image: image),
              ),
            ),
            closeButton(context, () {
              if (image is String) {
                final matchingIndex = item!.galleryImages!.indexWhere(
                  (galleryImage) => galleryImage.image == image,
                );

                if (matchingIndex != -1) {
                  print("Matching index: $matchingIndex");
                  print("Gallery Image ID: ${item!.galleryImages![matchingIndex].id}");

                  deleteItemImageList.add(item!.galleryImages![matchingIndex].id!);

                  setState(() {});
                } else {
                  print("No matching image found.");
                }
              }

              mixedItemImageList.removeAt(index);
              setState(() {});
            }),
          ],
        );
      });

      return Wrap(
        spacing: 10,
        runSpacing: 10,
        runAlignment: WrapAlignment.start,
        children: [
          if ((files == null || files.isEmpty) && mixedItemImageList.isEmpty)
            DottedBorder(
              color: context.color.textLightColor,
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: GestureDetector(
                onTap: () {
                  showImageSourceDialog(context, (source) {
                    itemImagePicker.pick(
                        pickMultiple: source == ImageSource.gallery,
                        context: context,
                        imageLimit: 5,
                        maxLength: mixedItemImageList.length,
                        source: source);
                  });
                },
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  alignment: AlignmentDirectional.center,
                  height: 48,
                  child: DescriptionText("addOtherPicture".translate(context), fontSize: context.font.large),
                ),
              ),
            ),
          ...current,
          if (mixedItemImageList.length < 5)
            if (files != null && files.isNotEmpty || mixedItemImageList.isNotEmpty)
              uploadPhotoCard(context, onTap: () {
                showImageSourceDialog(context, (source) {
                  itemImagePicker.pick(
                      pickMultiple: source == ImageSource.gallery,
                      context: context,
                      imageLimit: 5,
                      maxLength: mixedItemImageList.length,
                      source: source);
                });
              })
        ],
      );
    });
  }

  Widget closeButton(BuildContext context, Function onTap) {
    return PositionedDirectional(
      top: 6,
      end: 6,
      child: GestureDetector(
        onTap: () {
          onTap.call();
        },
        child: Container(
          decoration: BoxDecoration(color: context.color.primaryColor.withOpacity(0.7), borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(
              Icons.close,
              size: 24,
              color: context.color.textDefaultColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget uploadPhotoCard(BuildContext context, {required Function onTap}) {
    return GestureDetector(
      onTap: () {
        onTap.call();
      },
      child: Container(
        width: 100,
        height: 100,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: DottedBorder(
            color: context.color.primary.withOpacity(0.3),
            borderType: BorderType.RRect,
            radius: const Radius.circular(10),
            child: Container(
              alignment: AlignmentDirectional.center,
              child: DescriptionText("uploadPhoto".translate(context)),
            )),
      ),
    );
  }

  // Special Tags Section - Changed to use switches
  Widget _buildSpecialTagsSection(BuildContext context) {
    // Check if we're in service or experience mode
    dynamic rawPostType = getCloudData("post_type");
    PostType? postType;

    if (rawPostType is PostType) {
      postType = rawPostType;
    } else {
      // Handle the case where post_type is not properly cast
      return SizedBox.shrink();
    }

    if (postType == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15),
        _buildSwitchOption(
          context,
          title: "Exclusive for Women",
          value: _specialTags["exclusive_women"] ?? false,
          onChanged: (value) {
            setState(() {
              _specialTags["exclusive_women"] = value;
            });
          },
        ),
        _buildSwitchOption(
          context,
          title: "Corporate Package",
          value: _specialTags["corporate_package"] ?? false,
          onChanged: (value) {
            setState(() {
              _specialTags["corporate_package"] = value;
            });
          },
        ),
        SizedBox(height: 15),
      ],
    );
  }

  // Helper widget for switch options
  Widget _buildSwitchOption(
    BuildContext context, {
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: CustomText(
              title.translate(context),
              color: value ? context.color.textColorDark : context.color.textColorDark,
              fontWeight: value ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            inactiveTrackColor: const Color(0xFF0F2137),
            activeColor: const Color(0xFF0F2137),
            activeTrackColor: const Color(0xFF0F2137).withOpacity(0.5),
            thumbIcon: WidgetStateProperty.resolveWith<Icon?>((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return const Icon(Icons.check, color: Colors.white, size: 16);
              }
              return null;
            }),
          ),
        ],
      ),
    );
  }

  // Price Type Section - Fixed radio button appearance
  Widget _buildPriceTypeSection(BuildContext context) {
    // Check if we're in service or experience mode
    dynamic rawPostType = getCloudData("post_type");
    PostType? postType;

    if (rawPostType is PostType) {
      postType = rawPostType;
    } else {
      // Handle the case where post_type is not properly cast
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "Price Type".translate(context) + " *",
          fontSize: context.font.large,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: ItemModel.paymentTypesWithTitles.map((e) {
            final (value, title) = e;
            return _buildRadioOption(
              context,
              title: title,
              value: value,
              groupValue: _priceType,
              onChanged: (value) {
                setState(() {
                  _priceType = value;
                });
              },
            );
          }).toList(),
        ),
        SizedBox(height: 15),
      ],
    );
  }

  // Service Location Options
  Widget _buildServiceLocationOptions(BuildContext context) {
    // Only show for Service type
    dynamic rawPostType = getCloudData("post_type");
    PostType? postType;

    if (rawPostType is PostType) {
      postType = rawPostType;
    } else {
      // Handle the case where post_type is not properly cast
      return SizedBox.shrink();
    }

    if (postType != PostType.service) return SizedBox.shrink();

    // Debug the current state of location options
    print("Current service location options:");
    print("At Client's Location: $_atClientLocation");
    print("At Public Venue: $_atPublicVenue");
    print("At My Location: $_atMyLocation");
    print("Virtual: $_isVirtual");
    print("Current location text: ${locationController.text}");
    if (formattedAddress != null) {
      print("Formatted address - City: ${formattedAddress!.city}, Country: ${formattedAddress!.country}");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "Service Location Options".translate(context) + " *",
          fontSize: context.font.large,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 10),

        // Location field (read-only display)
        CustomText("Service Location".translate(context) + " *"),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[50],
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 18),
              SizedBox(width: 8),
              Expanded(
                child: CustomText(
                  locationController.text.isEmpty ? 'No location selected' : locationController.text,
                  color: locationController.text.isEmpty ? Colors.grey[500] : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        // Coordinates display
        if (_selectedLatitude != null && _selectedLongitude != null)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
              color: Colors.blue.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                Icon(Icons.gps_fixed, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Latitude: ${_selectedLatitude!.toStringAsFixed(6)}',
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                      CustomText(
                        'Longitude: ${_selectedLongitude!.toStringAsFixed(6)}',
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 15),

        // Location type options with improved visibility
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: context.color.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                "Service Delivery Methods".translate(context),
                fontWeight: FontWeight.w500,
              ),
              SizedBox(height: 5),
              _buildCheckboxOption(
                context,
                title: "At the Client's Location",
                value: _atClientLocation,
                onChanged: (value) {
                  setState(() {
                    _atClientLocation = value ?? false;
                  });
                },
              ),
              _buildCheckboxOption(
                context,
                title: "At a Public Venue",
                value: _atPublicVenue,
                onChanged: (value) {
                  setState(() {
                    _atPublicVenue = value ?? false;
                  });
                },
              ),
              _buildCheckboxOption(
                context,
                title: "At My Location",
                value: _atMyLocation,
                onChanged: (value) {
                  setState(() {
                    _atMyLocation = value ?? false;
                  });
                },
              ),
              _buildCheckboxOption(
                context,
                title: "Online (Virtual)",
                value: _isVirtual,
                onChanged: (value) {
                  setState(() {
                    _isVirtual = value ?? false;
                  });
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 15),
      ],
    );
  }

  // Helper widgets - Fixed radio button appearance
  Widget _buildRadioOption<T>(
    BuildContext context, {
    required String title,
    required T value,
    required T? groupValue,
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

  Widget _buildCheckboxOption(
    BuildContext context, {
    required String title,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    // Debug print to help diagnose the issue
    print("Building checkbox for $title with value $value");

    return InkWell(
      onTap: () {
        print("Checkbox tapped: $title - changing from $value to ${!value}");
        onChanged(!value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Theme(
              data: ThemeData(
                unselectedWidgetColor: context.color.borderColor,
              ),
              child: Checkbox(
                value: value,
                onChanged: (newValue) {
                  print("Checkbox changed via checkbox: $title - to $newValue");
                  onChanged(newValue);
                },
                activeColor: const Color(0xFF0F2137),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            Flexible(
              child: CustomText(
                title.translate(context),
                color: value ? context.color.textColorDark : context.color.textColorDark,
                fontWeight: value ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateRequiredFields(PostType postType) {
    // Validate common required fields for both service and experience
    List<String> missingFields = [];

    // Check title
    if (_titleController.text.isEmpty) {
      missingFields.add("Ad Title");
    }

    // Check description (required for both types)
    if (_descriptionController.text.isEmpty) {
      missingFields.add("Description");
    }

    // Check price
    if (adPriceController.text.isEmpty) {
      missingFields.add("Price");
    }

    if (_selectedCategory == null) {
      missingFields.add("Category");
    }

    // Check price type
    if (_priceType == null) {
      missingFields.add("Price Type");
    }

    // Check main picture
    bool hasMainPicture = (_pickTitleImage.pickedFile != null) || titleImageURL.isNotEmpty;
    if (!hasMainPicture) {
      missingFields.add("Main Picture");
    }

    // In edit mode, we may have already retrieved the location from the item
    bool isEdit = widget.isEdit == true;

    if (postType == PostType.experience && _forACause) {
      if (forACauseTextController.text.trim().isEmpty) {
        missingFields.add("Philanthropic Description");
      }
    }

    // Location check for both types
    if (formattedAddress == null) {
      // In edit mode, check if the item has location data
      missingFields.add('Location');
    }

    // For experience type, check expiration date and time
    if (postType == PostType.experience) {
      if (_date == null) {
        missingFields.add("Date");
      }
      if (_time == null) {
        missingFields.add("Time");
      }
      if (_slotsAvailable == null) {
        missingFields.add("Slots Available");
      }
      if (_endTimerOption == null && !isEdit) {
        missingFields.add("End Timer Option");
      }
    }

    if (postType == PostType.service && _locationTypes.isEmpty) {
      missingFields.add("Location Type");
    }

    // If we have missing fields, show an error and return false
    if (missingFields.isNotEmpty) {
      String fieldList = missingFields.join(", ");
      HelperUtils.showSnackBarMessage(context, "Please complete the following required fields: $fieldList");
      return false;
    }

    return true;
  }

  void _initFields(ItemModel? item) {
    if (item == null) return;
    _titleController.text = item.name ?? '';
    _descriptionController.text = item.description ?? '';
    adPriceController.text = item.price?.toStringAsFixed(2) ?? '';
    _selectedCategory = item.category;
    _priceType = item.priceType;
    _date = item.itemDate;
    if (item.itemTime != null) {
      final split = item.itemTime!.split(':');
      _time = TimeOfDay(hour: int.parse(split[0]), minute: int.parse(split[1]));
    }
    _slotsAvailable = item.slots;
    _endTimerOption = null;
    _audience = item.audience;
    if (item.location != null) {
      locationController.text = item.location!;
      _updateLocationData({
        if (item.country != null) 'country': item.country!,
        if (item.city != null) 'city': item.city!,
        if (item.state != null) 'state': item.state!,
      });
    }

    // Initialize coordinates from existing item
    if (item.latitude != null && item.longitude != null) {
      _selectedLatitude = item.latitude;
      _selectedLongitude = item.longitude;
    }
    _locationTypes = (item.locationType ?? []).toSet();
    _specialTags = item.specialTags?.map((key, value) => MapEntry(key, value == 'true' || value == true)) ?? {};
    titleImageURL = item.image ?? '';
    mixedItemImageList = item.galleryImages?.map((e) => e.image).toList() ?? [];
    _videoLinkController.text = item.videoLink ?? '';
    _forACause = item.isForACause;
    forACauseTextController.text = item.forACauseText ?? '';
  }
}

class AddressComponent {
  String? city;
  String? state;
  String? country;
  String? area;
  int? areaId;
  String? mixed;

  AddressComponent({
    this.city,
    this.state,
    this.country,
    this.area,
    this.areaId,
    this.mixed,
  }) {
    // Automatically set mixed if not provided but we have city and country
    if (mixed == null && city != null && country != null && city!.isNotEmpty && country!.isNotEmpty) {
      mixed = "$city, $country";
    }
  }

  static AddressComponent copyWithFields(
    AddressComponent original, {
    String? newCity,
    String? newState,
    String? newCountry,
  }) {
    String? newMixed;
    if (newCity != null && original.country != null) {
      newMixed = "$newCity, ${original.country}";
    } else if (original.city != null && newCountry != null) {
      newMixed = "${original.city}, $newCountry";
    }

    return AddressComponent(
      city: newCity ?? original.city,
      state: newState ?? original.state,
      country: newCountry ?? original.country,
      area: original.area,
      areaId: original.areaId,
      mixed: newMixed ?? original.mixed,
    );
  }

  @override
  String toString() {
    return 'AddressComponent{city: $city, country: $country, state: $state, area: $area, areaId: $areaId, mixed: $mixed}';
  }
}
