import 'package:flutter/material.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/widgets/location_autocomplete.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/buttons/unelevated_regular_button.dart';
import 'package:tlobni/ui/widgets/location_picker_widget.dart';
import 'package:tlobni/utils/extensions/extensions.dart';

class LocationFieldSelector extends StatefulWidget {
  const LocationFieldSelector({
    super.key,
    this.city,
    this.country,
    this.state,
    this.longitude,
    this.latitude,
    required this.required,
    required this.onLocationSelected,
  });

  final String? city, country, state;
  final double? longitude, latitude;
  final bool required;
  final LocationDataChanged onLocationSelected;

  @override
  State<LocationFieldSelector> createState() => _LocationFieldSelectorState();
}

class _LocationFieldSelectorState extends State<LocationFieldSelector> {
  String? get city => widget.city;
  String? get country => widget.country;
  late final controller = TextEditingController()..text = city != null && country != null ? '$city, $country': city ?? country ?? '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocationAutocomplete(
      controller: controller,
      hintText: 'Select Location',
      onSelected: (data) {},
      onLocationSelected: (data) {
        widget.onLocationSelected(
          data['latitude'],
          data['longitude'],
          data['city'],
          data['country'],
          data['state'],
        );
      },
    );
    return UnelevatedRegularButton(
      onPressed: () => _openLocationPicker(context),
      padding: const EdgeInsets.all(16),
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: context.color.borderColor.darken(50)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: context.color.primary),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.longitude != null && widget.latitude != null && (widget.city != null || widget.country != null)) ...[
                  Text(
                    'Selected Location',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.color.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    _formattedAddress ?? '',
                    style: context.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  Text(
                    'Select location${widget.required ? ' *' : ''}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.color.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: context.color.textColorDark,
          ),
        ],
      ),
    );
  }

  String get _formattedAddress =>
      widget.city != null && widget.country != null ? '${widget.city}, ${widget.country}' : widget.city ?? widget.country ?? '';

  void _openLocationPicker(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerWidget(
          title: 'Select Your Location',
          initialLatitude: widget.latitude,
          initialLongitude: widget.longitude,
          initialCity: widget.city,
          initialCountry: widget.country,
          initialState: widget.state,
          onLocationSelected: widget.onLocationSelected,
        ),
      ),
    );
  }
}
