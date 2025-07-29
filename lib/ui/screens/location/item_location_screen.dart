import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/widgets/buttons/unelevated_regular_button.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/google_maps_service.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ItemLocationScreen extends StatefulWidget {
  final double? longitude, latitude;
  final String? city, country, name;

  const ItemLocationScreen({Key? key, required this.longitude, required this.latitude, this.city, this.country, this.name})
      : super(key: key);

  static Route route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) => ItemLocationScreen(
        longitude: arguments?['longitude'],
        latitude: arguments?['latitude'],
        city: arguments?['city'],
        country: arguments?['country'],
        name: arguments?['name'],
      ),
    );
  }

  @override
  State<ItemLocationScreen> createState() => _ItemLocationScreenState();
}

class _ItemLocationScreenState extends State<ItemLocationScreen> {
  final GoogleMapsService _mapsService = GoogleMapsService();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  CameraPosition? _cameraPosition;
  bool _isLoading = true;

  double? get latitude => widget.latitude;
  double? get longitude => widget.longitude;
  String? get name => widget.name;
  String? get city => widget.city;
  String? get country => widget.country;

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
      double? latitude = this.latitude, longitude = this.longitude;
      if (latitude != null && longitude != null) {
        // Set camera position to location
        _cameraPosition = CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 15.0,
        );

        // Add marker
        _addLocationMarker(latitude, longitude, name!);

        setState(() {
          _isLoading = false;
        });
      } else {
        // Use default location if no coordinates
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

  void _addLocationMarker(double latitude, double longitude, String name) {
    String snippet = 'Location';

    Marker marker = _mapsService.createMarker(
      markerId: 'location_marker',
      position: LatLng(latitude, longitude),
      title: name,
      snippet: snippet,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      _markers.add(marker);
    });
  }

  Future<void> _openInMaps() async {
    double? latitude = this.latitude;
    double? longitude = this.longitude;

    if (latitude == null || longitude == null) {
      HelperUtils.showSnackBarMessage(context, 'Location not available');
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

  void _centerOnLocation() {
    double? latitude = this.latitude;
    double? longitude = this.longitude;

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
    String title = 'Location';

    return Scaffold(
      appBar: UiUtils.buildAppBar(
        context,
        title: title,
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: _centerOnLocation,
            icon: Icon(Icons.center_focus_strong, color: kColorNavyBlue),
            tooltip: 'Center on location',
          ),
          IconButton(
            onPressed: _centerOnCurrentLocation,
            icon: Icon(Icons.my_location, color: kColorNavyBlue),
            tooltip: 'My location',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading || _cameraPosition == null)
            Center(child: CircularProgressIndicator(color: kColorNavyBlue))
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
    double? latitude = this.latitude;
    double? longitude = this.longitude;
    String? name = this.name;
    String? address = this.country == null
        ? this.city
        : this.city == null
            ? this.country
            : '${this.city}, ${this.country}';

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
          Text(
            name ?? 'Unknown Location',
            style: context.textTheme.bodyMedium?.copyWith(
              color: kColorNavyBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          if (address != null)
            Text(
              address,
              style: context.textTheme.bodyMedium?.copyWith(
                color: kColorNavyBlue.withOpacity(0.8),
              ),
            ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: UnelevatedRegularButton(
                  onPressed: _openInMaps,
                  padding: EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 18, color: kColorSecondaryBeige),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Open Maps',
                          style: context.textTheme.bodySmall?.copyWith(color: kColorSecondaryBeige),
                        ),
                      ),
                    ],
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
