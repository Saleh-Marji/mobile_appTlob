import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/buttons/unelevated_regular_button.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/google_maps_service.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ItemLocationScreen extends StatefulWidget {
  final ItemModel item;
  final List<ItemModel>? nearbyItems;
  final bool showNearbyItems;

  const ItemLocationScreen({
    Key? key,
    required this.item,
    this.nearbyItems,
    this.showNearbyItems = false,
  }) : super(key: key);

  static Route route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) => ItemLocationScreen(
        item: arguments?['item'],
        nearbyItems: arguments?['nearbyItems'],
        showNearbyItems: arguments?['showNearbyItems'] ?? false,
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
      if (widget.item.latitude != null && widget.item.longitude != null) {
        // Set camera position to item location
        _cameraPosition = CameraPosition(
          target: LatLng(widget.item.latitude!, widget.item.longitude!),
          zoom: 15.0,
        );

        // Add main item marker
        _addItemMarker(widget.item, isMainItem: true);

        // Add nearby items markers if available
        if (widget.showNearbyItems && widget.nearbyItems != null) {
          for (ItemModel nearbyItem in widget.nearbyItems!) {
            if (nearbyItem.id != widget.item.id && nearbyItem.latitude != null && nearbyItem.longitude != null) {
              _addItemMarker(nearbyItem, isMainItem: false);
            }
          }
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        // Use default location if item has no coordinates
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

  void _addItemMarker(ItemModel item, {required bool isMainItem}) {
    BitmapDescriptor icon = isMainItem
        ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
        : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

    Marker marker = _mapsService.createMarker(
      markerId: 'item_${item.id}',
      position: LatLng(item.latitude!, item.longitude!),
      title: item.name,
      snippet: '${item.price} ${item.priceType}',
      icon: icon,
      onTap: () => _showItemInfo(item),
    );

    setState(() {
      _markers.add(marker);
    });
  }

  void _showItemInfo(ItemModel item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              item.name ?? 'Unknown Item',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            SizedBox(height: 8),
            if (item.price != null)
              CustomText(
                'Price: ${item.price} ${item.priceType}',
                color: context.color.secondaryColor,
                fontWeight: FontWeight.w600,
              ),
            SizedBox(height: 8),
            if (item.address != null)
              CustomText(
                'Address: ${item.address}',
                color: Colors.grey[600],
              ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _getDirections(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.color.secondaryColor,
                    ),
                    child: CustomText(
                      'Get Directions',
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _openInMaps(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: CustomText(
                      'Open in Maps',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getDirections(ItemModel item) async {
    try {
      // Get current user location
      var userLocation = _mapsService.getUserLocation();
      double? userLat = userLocation['latitude'];
      double? userLng = userLocation['longitude'];

      if (userLat == null || userLng == null) {
        HelperUtils.showSnackBarMessage(context, 'Please set your location first');
        return;
      }

      if (item.latitude == null || item.longitude == null) {
        HelperUtils.showSnackBarMessage(context, 'Item location not available');
        return;
      }

      // Calculate distance and estimated time
      Map<String, dynamic>? directions = await _mapsService.getDirections(
        originLat: userLat,
        originLng: userLng,
        destinationLat: item.latitude!,
        destinationLng: item.longitude!,
      );

      if (directions != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: CustomText('Directions'),
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
                  _openInMaps(item);
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

  Future<void> _openInMaps(ItemModel item) async {
    if (item.latitude == null || item.longitude == null) {
      HelperUtils.showSnackBarMessage(context, 'Item location not available');
      return;
    }

    try {
      String url = 'https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        HelperUtils.showSnackBarMessage(context, 'Could not open maps');
      }
    } catch (e) {
      HelperUtils.showSnackBarMessage(context, 'Error opening maps: $e');
    }
  }

  void _centerOnItem() {
    if (widget.item.latitude != null && widget.item.longitude != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(widget.item.latitude!, widget.item.longitude!),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  void _centerOnUserLocation() async {
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
    return Scaffold(
      appBar: UiUtils.buildAppBar(
        context,
        title: 'Item Location',
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: _centerOnItem,
            icon: Icon(Icons.center_focus_strong, color: kColorNavyBlue),
            tooltip: 'Center on item',
          ),
          IconButton(
            onPressed: _centerOnUserLocation,
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
          if (!_isLoading && widget.item.latitude != null && widget.item.longitude != null)
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.item.name ?? 'Unknown Item',
            style: context.textTheme.bodyMedium?.copyWith(
              color: kColorNavyBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          if (widget.item.address != null)
            Text(
              widget.item.address!,
              style: context.textTheme.bodyMedium?.copyWith(
                color: kColorNavyBlue.withOpacity(0.8),
              ),
            ),
          if (widget.item.latitude != null && widget.item.longitude != null) ...[
            SizedBox(height: 4),
            Text(
              'Coordinates: ${widget.item.latitude!.toStringAsFixed(6)}, ${widget.item.longitude!.toStringAsFixed(6)}',
              style: context.textTheme.bodySmall?.copyWith(
                color: kColorNavyBlue.withOpacity(0.6),
              ),
            ),
          ],
          SizedBox(height: 12),
          UnelevatedRegularButton(
            onPressed: () => _openInMaps(widget.item),
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
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
