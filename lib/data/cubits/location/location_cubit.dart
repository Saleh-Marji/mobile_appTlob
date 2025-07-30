import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tlobni/data/model/google_place_model.dart';
import 'package:tlobni/data/repositories/google_place_repository.dart';
import 'package:tlobni/utils/google_maps_service.dart';

// Events
abstract class LocationEvent {}

class GetCurrentLocationEvent extends LocationEvent {}

class SearchPlacesEvent extends LocationEvent {
  final String query;
  SearchPlacesEvent(this.query);
}

class SaveUserLocationEvent extends LocationEvent {
  final double latitude;
  final double longitude;
  final String? address;
  SaveUserLocationEvent({
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

class GetUserLocationEvent extends LocationEvent {}

// States
abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationLoaded extends LocationState {
  final Position position;
  final String? address;
  LocationLoaded({required this.position, this.address});
}

class LocationError extends LocationState {
  final String message;
  LocationError(this.message);
}

class PlacesSearching extends LocationState {}

class PlacesLoaded extends LocationState {
  final List<GooglePlaceModel> places;
  PlacesLoaded(this.places);
}

class PlacesError extends LocationState {
  final String message;
  PlacesError(this.message);
}

class UserLocationSaved extends LocationState {
  final double latitude;
  final double longitude;
  final String? address;
  UserLocationSaved({
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

class UserLocationLoaded extends LocationState {
  final Map<String, dynamic> location;
  UserLocationLoaded(this.location);
}

class LocationCubit extends Cubit<LocationState> {
  final GoogleMapsService _mapsService = GoogleMapsService();
  final GooglePlaceRepository _placeRepository = GooglePlaceRepository();

  LocationCubit() : super(LocationInitial());

  Future<void> getCurrentLocation() async {
    emit(LocationLoading());
    try {
      Position? position = await _mapsService.getCurrentLocation();
      if (position != null) {
        // Get address from coordinates
        Map<String, String>? address = await _mapsService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        String? formattedAddress;
        if (address != null) {
          List<String> addressParts = [];
          if (address['street']?.isNotEmpty == true) addressParts.add(address['street']!);
          if (address['city']?.isNotEmpty == true) addressParts.add(address['city']!);
          if (address['state']?.isNotEmpty == true) addressParts.add(address['state']!);
          if (address['country']?.isNotEmpty == true) addressParts.add(address['country']!);
          formattedAddress = addressParts.join(', ');
        }

        emit(LocationLoaded(position: position, address: formattedAddress));
      } else {
        emit(LocationError('Unable to get current location'));
      }
    } catch (e) {
      emit(LocationError('Error getting location: $e'));
    }
  }

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      emit(PlacesLoaded([]));
      return;
    }

    emit(PlacesSearching());
    try {
      List<GooglePlaceModel> places = await _placeRepository.searchCities(query);
      emit(PlacesLoaded(places));
    } catch (e) {
      emit(PlacesError('Error searching places: $e'));
    }
  }

  Future<void> saveUserLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      // Parse address components if address is provided
      String? city, state, country, area;
      if (address != null && address.isNotEmpty) {
        List<String> parts = address.split(',');
        if (parts.length >= 1) city = parts[0].trim();
        if (parts.length >= 2) state = parts[1].trim();
        if (parts.length >= 3) country = parts[2].trim();
        area = city; // Use city as area
      }
      
      await _mapsService.saveUserLocation(
        latitude: latitude,
        longitude: longitude,
        city: city,
        state: state,
        country: country,
        area: area,
      );
      emit(UserLocationSaved(
        latitude: latitude,
        longitude: longitude,
        address: address,
      ));
    } catch (e) {
      emit(LocationError('Error saving location: $e'));
    }
  }

  Future<void> getUserLocation() async {
    try {
      Map<String, dynamic> location = _mapsService.getUserLocation();
      emit(UserLocationLoaded(location));
    } catch (e) {
      emit(LocationError('Error getting user location: $e'));
    }
  }

  Future<Map<String, dynamic>?> getDirections({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    try {
      return await _mapsService.getDirections(
        originLat: originLat,
        originLng: originLng,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
      );
    } catch (e) {
      emit(LocationError('Error getting directions: $e'));
      return null;
    }
  }

  Future<Map<String, String>?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      return await _mapsService.getAddressFromCoordinates(lat, lng);
    } catch (e) {
      emit(LocationError('Error getting address: $e'));
      return null;
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await _mapsService.getCurrentLocation();
    } catch (e) {
      emit(LocationError('Error getting current position: $e'));
      return null;
    }
  }
} 