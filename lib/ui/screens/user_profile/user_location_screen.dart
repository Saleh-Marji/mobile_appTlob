import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/google_maps_service.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';

class UserLocationScreen extends StatefulWidget {
  final User? user;
  final bool isCurrentUser;

  const UserLocationScreen({
    Key? key,
    this.user,
    this.isCurrentUser = false,
  }) : super(key: key);

  static Route route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) => UserLocationScreen(
        user: arguments?['user'],
        isCurrentUser: arguments?['isCurrentUser'] ?? false,
      ),
    );
  }

  @override
  State<UserLocationScreen> createState() => _UserLocationScreenState();
}

class _UserLocationScreenState extends State<UserLocationScreen> {
  final GoogleMapsService _mapsService = GoogleMapsService();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  CameraPosition? _cameraPosition;
  bool _isLoading = true;
  Map<String, String>? _addressComponents;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      double? latitude;
      double? longitude;
      String? userName;

      if (widget.isCurrentUser) {
        // Get current user's location from Hive
        var userLocation = _mapsService.getUserLocation();
        latitude = userLocation['latitude'];
        longitude = userLocation['longitude'];
        userName = HiveUtils.getUserDetails().name ?? 'Current User';
      } else if (widget.user != null) {
        // Get location from user model
        latitude = widget.user!.latitude;
        longitude = widget.user!.longitude;
        userName = widget.user!.name ?? 'User';
      }

      if (latitude != null && longitude != null) {
        // Set camera position to user location
        _cameraPosition = CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 15.0,
        );

        // Add user marker
        _addUserMarker(latitude, longitude, userName ?? 'User');

        // Get address components
        await _getAddressFromCoordinates(latitude, longitude);

        setState(() {
          _isLoading = false;
        });
      } else {
        // Use default location if user has no coordinates
        _cameraPosition = _mapsService.getDefaultCameraPosition();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing map: $e');
      _cameraPosition = _mapsService.getDefaultCameraPosition();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addUserMarker(double latitude, double longitude, String userName) {
    Marker marker = _mapsService.createMarker(
      markerId: 'user_location',
      position: LatLng(latitude, longitude),
      title: userName,
      snippet: 'User Location',
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    setState(() {
      _markers.add(marker);
    });
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      Map<String, String>? address = await _mapsService.getAddressFromCoordinates(lat, lng);
      if (address != null) {
        setState(() {
          _addressComponents = address;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  Future<void> _openInMaps() async {
    double? latitude;
    double? longitude;

    if (widget.isCurrentUser) {
      var userLocation = _mapsService.getUserLocation();
      latitude = userLocation['latitude'];
      longitude = userLocation['longitude'];
    } else if (widget.user != null) {
      latitude = widget.user!.latitude;
      longitude = widget.user!.longitude;
    }

    if (latitude == null || longitude == null) {
      HelperUtils.showSnackBarMessage(context, 'User location not available');
      return;
    }

    try {
      String url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        HelperUtils.showSnackBarMessage(context, 'Could not open maps');
      }
    } catch (e) {
      HelperUtils.showSnackBarMessage(context, 'Error opening maps: $e');
    }
  }

  Future<void> _getDirections() async {
    try {
      double? userLat;
      double? userLng;

      if (widget.isCurrentUser) {
        var userLocation = _mapsService.getUserLocation();
        userLat = userLocation['latitude'];
        userLng = userLocation['longitude'];
      } else if (widget.user != null) {
        userLat = widget.user!.latitude;
        userLng = widget.user!.longitude;
      }

      if (userLat == null || userLng == null) {
        HelperUtils.showSnackBarMessage(context, 'User location not available');
        return;
      }

      // Get current device location
      var currentPosition = await _mapsService.getCurrentLocation();
      if (currentPosition == null) {
        HelperUtils.showSnackBarMessage(context, 'Unable to get current location');
        return;
      }

      // Calculate distance and estimated time
      Map<String, dynamic>? directions = await _mapsService.getDirections(
        originLat: currentPosition.latitude,
        originLng: currentPosition.longitude,
        destinationLat: userLat,
        destinationLng: userLng,
      );

      if (directions != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: CustomText('Directions to User'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText('Distance: ${directions['distance_text']}'),
                CustomText('Estimated Time: ${directions['duration_text']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: CustomText('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openInMaps();
                },
                child: CustomText('Open in Maps'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      HelperUtils.showSnackBarMessage(context, 'Error getting directions: $e');
    }
  }

  void _centerOnUser() {
    double? latitude;
    double? longitude;

    if (widget.isCurrentUser) {
      var userLocation = _mapsService.getUserLocation();
      latitude = userLocation['latitude'];
      longitude = userLocation['longitude'];
    } else if (widget.user != null) {
      latitude = widget.user!.latitude;
      longitude = widget.user!.longitude;
    }

    if (latitude != null && longitude != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  void _centerOnCurrentLocation() async {
    try {
      var position = await _mapsService.getCurrentLocation();
      if (position != null) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15.0,
            ),
          ),
        );
      } else {
        HelperUtils.showSnackBarMessage(context, 'Unable to get current location');
      }
    } catch (e) {
      HelperUtils.showSnackBarMessage(context, 'Error getting current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String userName = widget.isCurrentUser 
        ? (HiveUtils.getUserDetails().name ?? 'Current User')
        : (widget.user?.name ?? 'User');

    return Scaffold(
      appBar: UiUtils.buildAppBar(
        context,
        title: '$userName\'s Location',
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: _centerOnUser,
            icon: Icon(Icons.center_focus_strong),
            tooltip: 'Center on user',
          ),
          IconButton(
            onPressed: _centerOnCurrentLocation,
            icon: Icon(Icons.my_location),
            tooltip: 'My location',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading || _cameraPosition == null)
            Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              initialCameraPosition: _cameraPosition!,
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          if (!_isLoading && _markers.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildLocationInfo(),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    double? latitude;
    double? longitude;

    if (widget.isCurrentUser) {
      var userLocation = _mapsService.getUserLocation();
      latitude = userLocation['latitude'];
      longitude = userLocation['longitude'];
    } else if (widget.user != null) {
      latitude = widget.user!.latitude;
      longitude = widget.user!.longitude;
    }

    String userName = widget.isCurrentUser 
        ? (HiveUtils.getUserDetails().name ?? 'Current User')
        : (widget.user?.name ?? 'User');

    return Container(
      padding: EdgeInsets.all(16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            userName,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          SizedBox(height: 8),
          if (_addressComponents != null) ...[
            if (_addressComponents!['city']?.isNotEmpty == true)
              CustomText(
                'City: ${_addressComponents!['city']}',
                color: Colors.grey[600],
              ),
            if (_addressComponents!['state']?.isNotEmpty == true)
              CustomText(
                'State: ${_addressComponents!['state']}',
                color: Colors.grey[600],
              ),
            if (_addressComponents!['country']?.isNotEmpty == true)
              CustomText(
                'Country: ${_addressComponents!['country']}',
                color: Colors.grey[600],
              ),
          ],
          if (latitude != null && longitude != null) ...[
            SizedBox(height: 4),
            CustomText(
              'Coordinates: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ],
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _getDirections,
                  icon: Icon(Icons.directions, size: 18),
                  label: CustomText('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.color.secondaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openInMaps,
                  icon: Icon(Icons.map, size: 18),
                  label: CustomText('Open Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 