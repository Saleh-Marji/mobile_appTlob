import 'package:dio/dio.dart';
import 'package:tlobni/data/model/google_place_model.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/constant.dart';

class GooglePlaceRepository {
  final Dio _dio = Dio();

  /// Search for cities/places using Google Places API
  Future<List<GooglePlaceModel>> searchCities(String query) async {
    try {
      final response = await _dio.get(
        Api.placeAPI,
        queryParameters: {
          'input': query,
          'key': Constant.googlePlaceAPIkey,
          'types': '(cities)',
          'language': 'en',
        },
      );

      if (response.data['status'] == 'OK') {
        List<dynamic> predictions = response.data['predictions'];
        List<GooglePlaceModel> places = [];

        for (var prediction in predictions) {
          String city = prediction['structured_formatting']['main_text'] ?? '';
          String description = prediction['description'] ?? '';
          String placeId = prediction['place_id'] ?? '';

          // Extract state and country from description
          String state = '';
          String country = '';

          if (description.contains(',')) {
            List<String> parts = description.split(',');
            if (parts.length >= 2) {
              state = parts[parts.length - 2].trim();
              country = parts[parts.length - 1].trim();
            }
          }

          places.add(GooglePlaceModel(
            city: city,
            description: description,
            placeId: placeId,
            latitude: 0, // Will be filled when getting place details
            longitude: 0, // Will be filled when getting place details
            state: state,
            country: country,
          ));
        }

        return places;
      } else {
        throw Exception('Failed to search places: ${response.data['status']}');
      }
    } catch (e) {
      throw Exception('Error searching places: $e');
    }
  }

  /// Get place details from place ID
  Future<Map<String, double>> getPlaceDetailsFromPlaceId(String placeId) async {
    try {
      final response = await _dio.get(
        Api.placeApiDetails,
        queryParameters: {
          'place_id': placeId,
          'key': Constant.googlePlaceAPIkey,
          'fields': 'geometry',
        },
      );

      if (response.data['status'] == 'OK') {
        var location = response.data['result']['geometry']['location'];
        return {
          'lat': location['lat'].toDouble(),
          'lng': location['lng'].toDouble(),
        };
      } else {
        throw Exception('Failed to get place details: ${response.data['status']}');
      }
    } catch (e) {
      throw Exception('Error getting place details: $e');
    }
  }

  /// Reverse geocoding - get address from coordinates
  Future<Map<String, String>> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': Constant.googlePlaceAPIkey,
          'language': 'en',
        },
      );

      if (response.data['status'] == 'OK' && response.data['results'].isNotEmpty) {
        var result = response.data['results'][0];
        var addressComponents = result['address_components'] as List;

        String city = '';
        String state = '';
        String country = '';
        String area = '';

        for (var component in addressComponents) {
          var types = component['types'] as List;
          var longName = component['long_name'];

          if (types.contains('locality')) {
            city = longName;
          } else if (types.contains('administrative_area_level_1')) {
            state = longName;
          } else if (types.contains('country')) {
            country = longName;
          } else if (types.contains('sublocality')) {
            area = longName;
          }
        }

        return {
          'city': city,
          'state': state,
          'country': country,
          'area': area,
          'formatted_address': result['formatted_address'],
        };
      } else {
        throw Exception('Failed to get address: ${response.data['status']}');
      }
    } catch (e) {
      throw Exception('Error getting address: $e');
    }
  }

  /// Search for nearby places
  Future<List<GooglePlaceModel>> searchNearbyPlaces(double lat, double lng, String type, {int radius = 5000}) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
        queryParameters: {
          'location': '$lat,$lng',
          'radius': radius,
          'type': type,
          'key': Constant.googlePlaceAPIkey,
        },
      );

      if (response.data['status'] == 'OK') {
        List<dynamic> results = response.data['results'];
        List<GooglePlaceModel> places = [];

        for (var result in results) {
          var location = result['geometry']['location'];

          places.add(GooglePlaceModel(
            city: result['name'] ?? '',
            description: result['vicinity'] ?? '',
            placeId: result['place_id'] ?? '',
            latitude: location['lat'],
            longitude: location['lng'],
            state: '', // Will be filled if needed
            country: '', // Will be filled if needed
          ));
        }

        return places;
      } else {
        throw Exception('Failed to search nearby places: ${response.data['status']}');
      }
    } catch (e) {
      throw Exception('Error searching nearby places: $e');
    }
  }
}
