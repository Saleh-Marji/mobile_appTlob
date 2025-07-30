import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/data/model/google_place_model.dart';
import 'package:tlobni/data/repositories/google_place_repository.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/google_maps_service.dart';
import 'package:tlobni/utils/ui_utils.dart';

typedef LocationDataChanged = void Function(double latitude, double longitude, String? city, String? country, String? state);

class LocationPickerWidget extends StatefulWidget {
  final String title;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialCity, initialCountry, initialState;
  final LocationDataChanged onLocationSelected;

  const LocationPickerWidget({
    Key? key,
    required this.title,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
    this.initialCity,
    this.initialCountry,
    this.initialState,
  }) : super(key: key);

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  late GoogleMapController _mapController;
  final Completer<GoogleMapController> _controller = Completer();
  final GoogleMapsService _mapsService = GoogleMapsService();
  final GooglePlaceRepository _placeRepository = GooglePlaceRepository();
  final TextEditingController _searchController = TextEditingController();

  bool get showSearchBar => true;

  LatLng? _selectedLocation;
  String? _city;
  String? _country;
  String? _state;
  bool _isLoading = false;
  List<GooglePlaceModel> _searchResults = [];
  bool _showSearchResults = false;

  String get _formattedAddress => _city != null && _country != null ? '$_city, $_country' : _city ?? _country ?? '';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  void _initializeLocation() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _city = widget.initialCity;
      _country = widget.initialCountry;
      _state = widget.initialState;
      setState(() {});
    } else {
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      Position? position = await _mapsService.getCurrentLocation();

      if (position != null) {
        _selectedLocation = LatLng(position.latitude, position.longitude);

        // Get address for current location
        Map<String, String>? addressData = await _mapsService.getAddressFromCoordinates(position.latitude, position.longitude);

        if (addressData != null) {
          formatFromAddressData(addressData);
        }

        setState(() {});
      } else {
        _useDefaultLocation();
      }
    } catch (e) {
      print('Error getting current location: $e');
      _useDefaultLocation();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    _mapController = controller;
  }

  void _onMapTapped(LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _isLoading = true;
      _showSearchResults = false;
    });

    try {
      // Get address for selected location
      Map<String, String>? addressData = await _mapsService.getAddressFromCoordinates(location.latitude, location.longitude);

      if (addressData != null) {
        formatFromAddressData(addressData);
      } else {
        throw 'Cannot get address for location';
      }
    } catch (e) {
      print('Error getting address: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void formatFromAddressData(Map<String, String> addressData) {
    _city = addressData['city'];
    _country = addressData['country'];
    _state = addressData['state'];
  }

  void _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    try {
      List<GooglePlaceModel> results = await _placeRepository.searchCities(query);
      setState(() {
        _searchResults = results;
        _showSearchResults = true;
      });
    } catch (e) {
      print('Error searching places: $e');
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
    }
  }

  void _selectPlace(GooglePlaceModel place) async {
    setState(() => _isLoading = true);

    try {
      // Get place details to get coordinates
      Map<String, double> coordinates = await _placeRepository.getPlaceDetailsFromPlaceId(place.placeId);

      LatLng location = LatLng(coordinates['lat']!, coordinates['lng']!);

      setState(() {
        _selectedLocation = location;
        _country = place.country;
        _city = place.city;
        _state = place.state;
        _searchController.text = place.description;
        _showSearchResults = false;
      });

      // Move camera to selected location
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15.0),
      );
    } catch (e) {
      print('Error selecting place: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      widget.onLocationSelected(_selectedLocation!.latitude, _selectedLocation!.longitude, _city, _country, _state);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: context.color.primaryColor,
        foregroundColor: kColorNavyBlue,
        actions: [
          TextButton(
            onPressed: _selectedLocation != null ? _confirmLocation : null,
            child: Text(
              'Confirm'.translate(context),
              style: TextStyle(
                color: _selectedLocation != null ? Colors.black : Colors.white60,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          _selectedLocation != null
              ? GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation!,
                    zoom: 15.0,
                  ),
                  onTap: _onMapTapped,
                  markers: {
                    if (_selectedLocation != null)
                      Marker(
                        markerId: const MarkerId('selected_location'),
                        position: _selectedLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                )
              : Center(child: UiUtils.progress()),

          // Search Bar
          if (showSearchBar)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: context.textTheme.bodyMedium?.copyWith(color: kColorNavyBlue),
                      decoration: InputDecoration(
                        hintText: 'Search for a place...'.translate(context),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: Icon(Icons.search),
                      ),
                      onChanged: _searchPlaces,
                      onTap: () {
                        if (_searchResults.isNotEmpty) {
                          setState(() => _showSearchResults = true);
                        }
                      },
                    ),
                  ),

                  // Search Results
                  if (_showSearchResults && _searchResults.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      constraints: BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final place = _searchResults[index];
                          return ListTile(
                            title: Text(place.city, style: context.textTheme.bodyMedium),
                            subtitle: Text(place.description, style: context.textTheme.bodySmall),
                            onTap: () => _selectPlace(place),
                            dense: true,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(child: UiUtils.progress()),
            ),

          // Selected Address Display
          if (_city != null || _country != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Selected Location'.translate(context),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kColorNavyBlue,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formattedAddress,
                      style: TextStyle(color: kColorNavyBlue),
                    ),
                  ],
                ),
              ),
            ),

          // Current Location Button
          Positioned(
            bottom: 160,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _getCurrentLocation,
              backgroundColor: context.color.primaryColor,
              child: Icon(Icons.my_location, color: kColorNavyBlue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _useDefaultLocation() {
    // Use default location if current location is not available
    _selectedLocation = LatLng(33.8869, 35.5131); // Beirut, Lebanon as default
    _city = 'Beirut';
    _country = 'Lebanon';
    setState(() {});
  }
}
