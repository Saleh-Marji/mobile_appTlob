import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tlobni/data/model/google_place_model.dart';
import 'package:tlobni/data/repositories/google_place_repository.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/hive_utils.dart';

class GoogleMapsService {
  static final GoogleMapsService _instance = GoogleMapsService._internal();
  factory GoogleMapsService() => _instance;
  GoogleMapsService._internal();

  final GooglePlaceRepository _placeRepository = GooglePlaceRepository();

  /// Get current user location with permission handling
  Future<Position?> getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Get address from coordinates (reverse geocoding)
  Future<Map<String, String>?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        return {
          'city': placemark.locality ?? '',
          'state': placemark.administrativeArea ?? '',
          'country': placemark.country ?? '',
          'area': placemark.subLocality ?? '',
          'street': placemark.street ?? '',
          'postal_code': placemark.postalCode ?? '',
          'formatted_address': '${placemark.street}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}',
        };
      }
      return null;
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return null;
    }
  }

  /// Search for places using Google Places API
  Future<List<GooglePlaceModel>> searchPlaces(String query) async {
    try {
      return await _placeRepository.searchCities(query);
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  /// Get place details from place ID
  Future<Map<String, double>?> getPlaceDetails(String placeId) async {
    try {
      return await _placeRepository.getPlaceDetailsFromPlaceId(placeId);
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }

  /// Save user location to local storage
  Future<void> saveUserLocation({
    required double latitude,
    required double longitude,
    String? city,
    String? state,
    String? country,
    String? area,
  }) async {
    try {
      // Save to Hive storage
      HiveUtils.setLocation(
        latitude: latitude,
        longitude: longitude,
        city: city,
        state: state,
        country: country,
        area: area,
      );

      // Also save as current location
      HiveUtils.setCurrentLocation(
        city: city,
        state: state,
        country: country,
        latitude: latitude,
        longitude: longitude,
        area: area,
      );
    } catch (e) {
      print('Error saving user location: $e');
    }
  }

  /// Get user's saved location
  Map<String, dynamic> getUserLocation() {
    return {
      'latitude': HiveUtils.getLatitude(),
      'longitude': HiveUtils.getLongitude(),
      'city': HiveUtils.getCityName(),
      'state': HiveUtils.getStateName(),
      'country': HiveUtils.getCountryName(),
      'area': HiveUtils.getAreaName(),
    };
  }

  /// Calculate distance between two points
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  /// Open app settings for location permission
  Future<void> openLocationSettings() async {
    await openAppSettings();
  }

  /// Create a marker for Google Maps
  Marker createMarker({
    required String markerId,
    required LatLng position,
    String? title,
    String? snippet,
    BitmapDescriptor? icon,
    VoidCallback? onTap,
  }) {
    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
      icon: icon ?? BitmapDescriptor.defaultMarker,
      onTap: onTap,
    );
  }

  /// Create a custom marker icon
  Future<BitmapDescriptor> createCustomMarkerIcon({
    required String text,
    Color backgroundColor = Colors.red,
    Color textColor = Colors.white,
  }) async {
    // This is a simplified version - in a real app you might want to create
    // a custom widget and convert it to a bitmap
    return BitmapDescriptor.defaultMarkerWithHue(
      backgroundColor == Colors.red ? BitmapDescriptor.hueRed :
      backgroundColor == Colors.blue ? BitmapDescriptor.hueBlue :
      backgroundColor == Colors.green ? BitmapDescriptor.hueGreen :
      backgroundColor == Colors.yellow ? BitmapDescriptor.hueYellow :
      backgroundColor == Colors.orange ? BitmapDescriptor.hueOrange :
      backgroundColor == Colors.purple ? BitmapDescriptor.hueViolet :
      backgroundColor == Colors.cyan ? BitmapDescriptor.hueCyan :
      backgroundColor == Colors.pink ? BitmapDescriptor.hueMagenta :
      backgroundColor == Colors.red ? BitmapDescriptor.hueRose :
      BitmapDescriptor.hueRed,
    );
  }

  /// Get camera position for a location
  CameraPosition getCameraPosition({
    required double latitude,
    required double longitude,
    double zoom = 15.0,
    double tilt = 0.0,
    double bearing = 0.0,
  }) {
    return CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: zoom,
      tilt: tilt,
      bearing: bearing,
    );
  }

  /// Get default camera position (app's default location)
  CameraPosition getDefaultCameraPosition() {
    double lat = double.tryParse(Constant.defaultLatitude) ?? 0.0;
    double lng = double.tryParse(Constant.defaultLongitude) ?? 0.0;
    return getCameraPosition(latitude: lat, longitude: lng, zoom: 10.0);
  }

  /// Search for nearby places
  Future<List<GooglePlaceModel>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    required String type,
    int radius = 5000,
  }) async {
    try {
      return await _placeRepository.searchNearbyPlaces(latitude, longitude, type, radius: radius);
    } catch (e) {
      print('Error searching nearby places: $e');
      return [];
    }
  }

  /// Get directions between two points (simplified - returns distance and duration)
  Future<Map<String, dynamic>?> getDirections({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    try {
      double distance = calculateDistance(originLat, originLng, destinationLat, destinationLng);
      
      // Estimate travel time (assuming average speed of 30 km/h for driving)
      double estimatedTimeMinutes = (distance / 1000) / 30 * 60;
      
      return {
        'distance': distance,
        'distance_text': '${(distance / 1000).toStringAsFixed(1)} km',
        'duration_minutes': estimatedTimeMinutes.round(),
        'duration_text': '${estimatedTimeMinutes.round()} min',
      };
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }

  /// Validate coordinates
  bool isValidCoordinates(double latitude, double longitude) {
    return latitude >= -90 && latitude <= 90 && 
           longitude >= -180 && longitude <= 180;
  }

  /// Format coordinates for display
  String formatCoordinates(double latitude, double longitude) {
    String latDirection = latitude >= 0 ? 'N' : 'S';
    String lngDirection = longitude >= 0 ? 'E' : 'W';
    
    return '${latitude.abs().toStringAsFixed(6)}° $latDirection, ${longitude.abs().toStringAsFixed(6)}° $lngDirection';
  }

  /// Get location permission status text
  String getPermissionStatusText(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return 'Location permission denied';
      case LocationPermission.deniedForever:
        return 'Location permission permanently denied';
      case LocationPermission.whileInUse:
        return 'Location permission granted (while in use)';
      case LocationPermission.always:
        return 'Location permission granted (always)';
      case LocationPermission.unableToDetermine:
        return 'Unable to determine location permission';
    }
  }
} 