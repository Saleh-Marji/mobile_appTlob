import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tlobni/data/model/google_place_model.dart';
import 'package:tlobni/data/repositories/google_place_repository.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';

class LocationAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSelected;
  final Function(Map<String, dynamic>)? onLocationSelected;
  final String hintText;
  final BorderRadius? radius;
  final EdgeInsets? padding;
  final double? fontSize;
  final Color? borderColor;
  final Color? fillColor;

  const LocationAutocomplete({
    Key? key,
    required this.controller,
    required this.onSelected,
    this.fillColor,
    this.onLocationSelected,
    this.radius,
    this.padding,
    required this.hintText,
    this.fontSize = 14,
    this.borderColor,
  }) : super(key: key);

  @override
  State<LocationAutocomplete> createState() => _LocationAutocompleteState();
}

class _LocationAutocompleteState extends State<LocationAutocomplete> {
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GooglePlaceRepository _googlePlaceRepository = GooglePlaceRepository();

  List<GooglePlaceModel> _filteredLocations = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    });

    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = widget.controller.text.trim();

    // Cancel previous timer
    _debounceTimer?.cancel();

    if (text.isEmpty) {
      setState(() {
        _filteredLocations = [];
        _isLoading = false;
      });
      if (_overlayEntry != null) {
        _updateOverlay();
      }
      return;
    }

    if (text.length < 2) {
      setState(() {
        _filteredLocations = [];
        _isLoading = false;
      });
      if (_overlayEntry != null) {
        _updateOverlay();
      }
      return;
    }

    // Set up debounce timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchLocations(text);
    });
  }

  Future<void> _searchLocations(String text) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locations = await _googlePlaceRepository.searchCities(text);
      setState(() {
        _filteredLocations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _filteredLocations = [];
        _isLoading = false;
      });
      print('Error searching locations: $e');
    }

    if (_overlayEntry != null) {
      _updateOverlay();
    }
  }

  void _updateOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final theme = Theme.of(context);

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height),
          child: Material(
            elevation: 4.0,
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 200,
              ),
              child: _isLoading
                  ? Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.primaryColor,
                            ),
                          ),
                          SizedBox(width: 8),
                          DescriptionText(
                            "Searching...",
                            color: theme.hintColor,
                          ),
                        ],
                      ),
                    )
                  : _filteredLocations.isEmpty
                      ? Container(
                          padding: EdgeInsets.all(16),
                          child: DescriptionText(
                            "No locations found",
                            color: theme.hintColor,
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _filteredLocations.length,
                          itemBuilder: (context, index) {
                            final location = _filteredLocations[index];
                            final displayText = location.city + ', ' + location.country;

                            return ListTile(
                              title: DescriptionText(displayText),
                              onTap: () {
                                widget.controller.text = displayText;
                                widget.onSelected(displayText);

                                if (widget.onLocationSelected != null) {
                                  widget.onLocationSelected!({
                                    'city': location.city,
                                    'country': location.country,
                                    'longitude': location.longitude,
                                    'latitude': location.latitude,
                                    'state': location.state,
                                  });
                                }

                                _hideOverlay();
                                FocusScope.of(context).unfocus();
                              },
                            );
                          },
                        ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(() {});
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final border = OutlineInputBorder(
      borderRadius: widget.radius ?? BorderRadius.circular(5),
      borderSide: BorderSide(color: widget.borderColor ?? Colors.grey.withValues(alpha: 0.35)),
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onSubmitted: (value) {
          _hideOverlay();
          FocusScope.of(context).unfocus();
          for (var location in _filteredLocations) {
            if (value.toLowerCase() == location.description.toLowerCase()) {
              widget.controller.text = location.description;
              widget.onSelected(location.description);
              widget.onLocationSelected?.call({
                'city': location.city,
                'country': location.country,
                'longitude': location.longitude,
                'latitude': location.latitude,
                'state': location.state,
              });
            }
          }
        },
        style: context.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: context.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          prefixIcon: Container(
            margin: EdgeInsets.only(left: 10),
            alignment: Alignment.centerLeft,
            child: Icon(
              Icons.location_on_outlined,
              color: theme.iconTheme.color,
              size: 18,
            ),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 35, maxWidth: 35),
          contentPadding: widget.padding ?? EdgeInsets.only(right: 35),
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          fillColor: widget.fillColor ?? theme.cardColor,
          filled: true,
        ),
      ),
    );
  }
}
