# Google Maps Integration Features

This document outlines the comprehensive Google Maps functionality that has been added to the Tlobni mobile app.

## Overview

The app now includes enhanced Google Maps functionality that allows users to:
- Add and manage their location via Google Maps
- View item/service locations on interactive maps
- Get directions to items and users
- View user profiles with location information
- Search for places using Google Places API

## Features Implemented

### 1. Location Picker Screen (`LocationPickerScreen`)
- **Purpose**: Allows users to select their location via Google Maps
- **Features**:
  - Interactive Google Map for location selection
  - Search functionality using Google Places API
  - Current location detection
  - Address reverse geocoding
  - Location confirmation with address details

**Usage**:
```dart
Navigator.pushNamed(
  context,
  Routes.locationPickerScreen,
  arguments: {
    'title': 'Select Your Location',
    'showSearchBar': true,
    'onLocationSelected': (lat, lng, address) {
      // Handle selected location
    },
  },
);
```

### 2. Item Location Screen (`ItemLocationScreen`)
- **Purpose**: Displays item/service locations on Google Maps
- **Features**:
  - Interactive map showing item location
  - Get directions from user's location to item
  - Open location in external maps app
  - Show nearby items (optional)
  - Distance and travel time calculations

**Usage**:
```dart
Navigator.pushNamed(
  context,
  Routes.itemLocationScreen,
  arguments: {
    'item': itemModel,
    'nearbyItems': nearbyItemsList, // Optional
    'showNearbyItems': true, // Optional
  },
);
```

### 3. User Location Screen (`UserLocationScreen`)
- **Purpose**: Displays user profile locations on Google Maps
- **Features**:
  - Show current user's location or other user's location
  - Get directions to user
  - Open location in external maps app
  - Address information display
  - Location centering controls

**Usage**:
```dart
// For current user
Navigator.pushNamed(
  context,
  Routes.userLocationScreen,
  arguments: {
    'isCurrentUser': true,
  },
);

// For other user
Navigator.pushNamed(
  context,
  Routes.userLocationScreen,
  arguments: {
    'user': userModel,
    'isCurrentUser': false,
  },
);
```

### 4. Google Maps Service (`GoogleMapsService`)
- **Purpose**: Central service for all Google Maps operations
- **Features**:
  - Current location detection
  - Address geocoding and reverse geocoding
  - Directions calculation
  - User location storage and retrieval
  - Marker creation utilities
  - Permission handling

### 5. Location Cubit (`LocationCubit`)
- **Purpose**: State management for location operations
- **Features**:
  - Location state management
  - Places search functionality
  - User location saving and retrieval
  - Directions calculation
  - Error handling

### 6. Google Place Repository (`GooglePlaceRepository`)
- **Purpose**: Handles Google Places API interactions
- **Features**:
  - City/place search
  - Place details retrieval
  - Address components extraction

## Integration Points

### 1. User Profile Screen
- Added "My Location" button in the profile settings
- Allows users to view their saved location on Google Maps

### 2. Item Details Screen
- Enhanced existing location map with fullscreen button
- Users can tap the fullscreen button to open the enhanced item location screen

### 3. Backend Integration
- Updated User model to include latitude and longitude fields
- Backend already supports location coordinates for both users and items

## Configuration

### Required API Keys
1. **Google Maps API Key**: For map display and basic functionality
2. **Google Places API Key**: For place search and autocomplete
3. **Google Directions API Key**: For route calculations

### Setup Instructions
1. Add your Google API keys to `lib/settings.dart`:
```dart
class AppSettings {
  // ... existing settings ...
  
  /// Google Maps API Keys
  static const String googleMapsAPIKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  static const String googlePlacesAPIKey = 'YOUR_GOOGLE_PLACES_API_KEY';
  static const String googleDirectionsAPIKey = 'YOUR_GOOGLE_DIRECTIONS_API_KEY';
}
```

2. The API keys are automatically used by the services and repositories.

## Dependencies

The following packages are already included in the project:
- `google_maps_flutter`: For Google Maps display
- `geolocator`: For location services
- `geocoding`: For address geocoding
- `permission_handler`: For location permissions
- `url_launcher`: For opening external maps

## Usage Examples

### Adding Location to User Profile
```dart
// Navigate to location picker
Navigator.pushNamed(
  context,
  Routes.locationPickerScreen,
  arguments: {
    'title': 'Set Your Location',
    'showSearchBar': true,
    'onLocationSelected': (lat, lng, address) {
      // Save location to user profile
      context.read<LocationCubit>().saveUserLocation(
        latitude: lat,
        longitude: lng,
        address: address,
      );
    },
  },
);
```

### Viewing Item Location
```dart
// From item details screen
Navigator.pushNamed(
  context,
  Routes.itemLocationScreen,
  arguments: {
    'item': itemModel,
  },
);
```

### Getting Directions
```dart
// Get directions from current location to item
final directions = await context.read<LocationCubit>().getDirections(
  originLat: currentLat,
  originLng: currentLng,
  destinationLat: itemLat,
  destinationLng: itemLng,
);
```

## Error Handling

The implementation includes comprehensive error handling for:
- Location permission denials
- Network connectivity issues
- API rate limiting
- Invalid coordinates
- Missing API keys

## Future Enhancements

Potential future improvements:
1. **Offline Maps**: Cache map tiles for offline use
2. **Real-time Location**: Live location sharing between users
3. **Location History**: Track user location history
4. **Geofencing**: Location-based notifications
5. **Route Optimization**: Multi-stop route planning
6. **Location Analytics**: Usage statistics and insights

## Support

For technical support or questions about the Google Maps integration, please refer to:
- Google Maps Flutter documentation
- Google Places API documentation
- Google Directions API documentation 