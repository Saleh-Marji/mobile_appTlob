import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tlobni/data/model/google_place_model.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/google_maps_service.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';

class LocationPickerScreen extends StatefulWidget {
  final String? initialLocation;
  final bool showSearchBar;
  final bool allowManualInput;
  final String title;

  const LocationPickerScreen({
    Key? key,
    this.initialLocation,
    this.showSearchBar = true,
    this.allowManualInput = true,
    this.title = 'Select Location',
  }) : super(key: key);

  static Route route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) => LocationPickerScreen(
        initialLocation: arguments?['initialLocation'],
        showSearchBar: arguments?['showSearchBar'] ?? true,
        allowManualInput: arguments?['allowManualInput'] ?? true,
        title: arguments?['title'] ?? 'Select Location',
      ),
    );
  }

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final GoogleMapsService _mapsService = GoogleMapsService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  GoogleMapController? _mapController;
  CameraPosition? _cameraPosition;
  Set<Marker> _markers = {};
  
  bool _isLoading = true;
  bool _isSearching = false;
  List<GooglePlaceModel> _searchResults = [];
  Timer? _searchDebounce;
  
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAddress;
  Map<String, String>? _addressComponents;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      // Try to get current location first
      Position? currentPosition = await _mapsService.getCurrentLocation();
      
      if (currentPosition != null) {
        _cameraPosition = CameraPosition(
          target: LatLng(currentPosition.latitude, currentPosition.longitude),
          zoom: 15.0,
        );
        _addMarker(
          LatLng(currentPosition.latitude, currentPosition.longitude),
          'current_location',
          'Current Location',
        );
        _selectedLatitude = currentPosition.latitude;
        _selectedLongitude = currentPosition.longitude;
        await _getAddressFromCoordinates(currentPosition.latitude, currentPosition.longitude);
      } else {
        // Use default location
        _cameraPosition = _mapsService.getDefaultCameraPosition();
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing map: $e');
      _cameraPosition = _mapsService.getDefaultCameraPosition();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addMarker(LatLng position, String markerId, String title) {
    setState(() {
      _markers.clear();
      _markers.add(
        _mapsService.createMarker(
          markerId: markerId,
          position: position,
          title: title,
        ),
      );
    });
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      Map<String, String>? address = await _mapsService.getAddressFromCoordinates(lat, lng);
      if (address != null) {
        setState(() {
          _addressComponents = address;
          _selectedAddress = address['formatted_address'];
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _searchPlaces(_searchController.text);
      } else {
        setState(() {
          _searchResults.clear();
        });
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) return;
    
    setState(() {
      _isSearching = true;
    });

    try {
      List<GooglePlaceModel> results = await _mapsService.searchPlaces(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      HelperUtils.showSnackBarMessage(context, 'Error searching places: $e');
    }
  }

  Future<void> _selectPlace(GooglePlaceModel place) async {
    try {
      Map<String, double>? details = await _mapsService.getPlaceDetails(place.placeId);
      if (details != null) {
        double lat = details['lat']!;
        double lng = details['lng']!;
        
        _selectedLatitude = lat;
        _selectedLongitude = lng;
        
        _addMarker(LatLng(lat, lng), 'selected_location', place.city);
        
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(lat, lng), zoom: 15.0),
          ),
        );
        
        await _getAddressFromCoordinates(lat, lng);
        
        setState(() {
          _searchResults.clear();
        });
        _searchController.clear();
        _searchFocusNode.unfocus();
      }
    } catch (e) {
      HelperUtils.showSnackBarMessage(context, 'Error selecting place: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position? position = await _mapsService.getCurrentLocation();
      if (position != null) {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
        
        _addMarker(
          LatLng(position.latitude, position.longitude),
          'current_location',
          'Current Location',
        );
        
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 15.0),
          ),
        );
        
        await _getAddressFromCoordinates(position.latitude, position.longitude);
      } else {
        HelperUtils.showSnackBarMessage(context, 'Unable to get current location');
      }
    } catch (e) {
      HelperUtils.showSnackBarMessage(context, 'Error getting current location: $e');
    }
  }

  void _confirmLocation() {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      Map<String, dynamic> result = {
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
        'address': _selectedAddress,
        'address_components': _addressComponents,
      };
      Navigator.pop(context, result);
    } else {
      HelperUtils.showSnackBarMessage(context, 'Please select a location first');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiUtils.buildAppBar(
        context,
        title: widget.title,
        showBackButton: true,
        actions: [
          if (_selectedLatitude != null && _selectedLongitude != null)
            TextButton(
              onPressed: _confirmLocation,
              child: CustomText(
                'Confirm',
                color: context.color.secondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (widget.showSearchBar) _buildSearchBar(),
          if (_searchResults.isNotEmpty) _buildSearchResults(),
          Expanded(
            child: _buildMap(),
          ),
          if (_selectedAddress != null) _buildLocationInfo(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        backgroundColor: context.color.secondaryColor,
        child: Icon(
          Icons.my_location,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search for a place...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: _isSearching
              ? Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      height: 200,
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          GooglePlaceModel place = _searchResults[index];
          return ListTile(
            leading: Icon(Icons.location_on, color: context.color.secondaryColor),
            title: CustomText(place.city),
            subtitle: CustomText(place.description),
            onTap: () => _selectPlace(place),
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    if (_isLoading || _cameraPosition == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: _cameraPosition!,
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          onTap: (LatLng position) async {
            _selectedLatitude = position.latitude;
            _selectedLongitude = position.longitude;
            
            _addMarker(position, 'selected_location', 'Selected Location');
            await _getAddressFromCoordinates(position.latitude, position.longitude);
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Selected Location',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          SizedBox(height: 8),
          CustomText(
            _selectedAddress ?? 'Address not available',
            color: Colors.grey[600],
          ),
          if (_selectedLatitude != null && _selectedLongitude != null) ...[
            SizedBox(height: 4),
            CustomText(
              'Coordinates: ${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}',
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ],
        ],
      ),
    );
  }
} 