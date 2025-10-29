import 'dart:convert';

import 'package:tlobni/data/cubits/item/search_item_cubit.dart';
import 'package:tlobni/data/cubits/user/search_providers_cubit.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/utils/extensions/lib/iterable.dart';
import 'package:tlobni/utils/hive_utils.dart';

class ItemFilterModel {
  final String? maxPrice;
  final String? minPrice;
  final String? categoryId;
  final String? postedSince;
  final String? city;
  final String? state;
  final String? country;
  final String? area;
  final int? areaId;
  final int? radius;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? customFields;
  final String? userType;
  final String? gender;
  final String? serviceType;
  final Map<String, String>? specialTags;
  final double? rating;
  final int? organizationId;
  final double? minRating;
  final double? maxRating;
  final List<CategoryModel>? categories;
  final SearchItemSortBy? itemSortBy;
  final SearchProviderSortBy? providerSortBy;
  final bool? featuredOnly;
  final bool? claimedByMe;
  final bool? havingAtLeastOneClaim;
  final int? userId;
  final bool? publicOnly;
  final bool? privateSpacesOnly;

  ItemFilterModel({
    this.maxPrice,
    this.minPrice,
    this.categoryId,
    this.postedSince,
    this.city,
    this.state,
    this.country,
    this.area,
    this.radius,
    this.areaId,
    this.latitude,
    this.longitude,
    this.customFields,
    this.userType,
    this.gender,
    this.serviceType,
    this.specialTags,
    this.rating,
    this.organizationId,
    this.claimedByMe,
    this.havingAtLeastOneClaim,
    this.userId,
    this.minRating,
    this.maxRating,
    this.categories,
    this.itemSortBy,
    this.providerSortBy,
    this.featuredOnly,
    this.publicOnly,
    this.privateSpacesOnly,
  });

  ItemFilterModel copyWith({
    String? maxPrice,
    String? minPrice,
    String? categoryId,
    String? postedSince,
    String? city,
    String? state,
    String? country,
    String? area,
    int? areaId,
    int? radius,
    double? latitude,
    int? organizationId,
    bool? claimedByMe,
    bool? havingAtLeastOneClaim,
    int? userId,
    double? longitude,
    Map<String, dynamic>? customFields,
    String? userType,
    String? gender,
    String? serviceType,
    Map<String, String>? specialTags,
    double? rating,
    double? minRating,
    double? maxRating,
    List<CategoryModel>? categories,
    SearchItemSortBy? itemSortBy,
    bool resetItemSortBy = false,
    SearchProviderSortBy? providerSortBy,
    bool resetProviderSortBy = false,
    bool? featuredOnly,
    bool? publicOnly,
    bool? privateSpacesOnly,
  }) {
    return ItemFilterModel(
      maxPrice: maxPrice ?? this.maxPrice,
      minPrice: minPrice ?? this.minPrice,
      categoryId: categoryId ?? this.categoryId,
      postedSince: postedSince ?? this.postedSince,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      area: area ?? this.area,
      radius: radius ?? this.radius,
      areaId: areaId ?? this.areaId,
      organizationId: organizationId ?? this.organizationId,
      claimedByMe: claimedByMe ?? this.claimedByMe,
      havingAtLeastOneClaim: havingAtLeastOneClaim ?? this.havingAtLeastOneClaim,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      customFields: customFields ?? this.customFields,
      userType: userType ?? this.userType,
      gender: gender ?? this.gender,
      serviceType: serviceType ?? this.serviceType,
      specialTags: specialTags ?? this.specialTags,
      rating: rating ?? this.rating,
      minRating: minRating ?? this.minRating,
      maxRating: maxRating ?? this.maxRating,
      categories: categories ?? this.categories,
      featuredOnly: featuredOnly ?? this.featuredOnly,
      itemSortBy: resetItemSortBy ? null : itemSortBy ?? this.itemSortBy,
      providerSortBy: resetProviderSortBy ? null : providerSortBy ?? this.providerSortBy,
      publicOnly: publicOnly ?? this.publicOnly,
      privateSpacesOnly: privateSpacesOnly ?? this.privateSpacesOnly,
    );
  }

  Map<String, dynamic> toMap() {
    print("DEBUG: ServiceType value being sent to API: $serviceType");
    print("DEBUG: Gender value being sent to API: $gender");
    return <String, dynamic>{
      'max_price': maxPrice,
      'min_price': minPrice,
      'category_id': categoryId,
      'posted_since': postedSince,
      'city': city,
      'state': state,
      'country': country,
      'area': area,
      'radius': radius,
      'area_id': areaId,
      'longitude': longitude,
      'latitude': latitude,
      'user_type': userType,
      'gender': gender,
      'provider_item_type': serviceType,
      'special_tags': specialTags,
      'rating': rating,
      'min_rating': minRating,
      'max_rating': maxRating,
      'organization_id': organizationId,
      'claimed_by_me': claimedByMe,
      'having_at_least_one_claim': havingAtLeastOneClaim,
      'user_id': userId,
      'my_email': HiveUtils.getUserDetails().email,
      'my_id': HiveUtils.getUserIdInt(),
      'private_spaces_only': privateSpacesOnly,
      'categories': categories,
      'item_sort_by': itemSortBy?.jsonName,
      'provider_sort_by': providerSortBy?.jsonName,
      'featured_only': featuredOnly,
      'public_only': publicOnly,
    };
  }

  factory ItemFilterModel.fromMap(Map<String, dynamic> map) {
    return ItemFilterModel(
      city: map['city']?.toString(),
      state: map['state']?.toString(),
      country: map['country']?.toString(),
      maxPrice: map['max_price']?.toString(),
      minPrice: map['min_price']?.toString(),
      categoryId: map['category_id']?.toString(),
      postedSince: map['posted_since']?.toString(),
      area: map['area']?.toString(),
      radius: map['radius'] != null ? int.tryParse(map['radius'].toString()) : null,
      areaId: map['area_id'] != null ? int.tryParse(map['area_id'].toString()) : null,
      latitude: map['latitude'] != null ? map['latitude'] : null,
      longitude: map['longitude'] != null ? map['longitude'] : null,
      customFields: Map<String, dynamic>.from(map['custom_fields'] ?? {}),
      userType: map['user_type']?.toString(),
      organizationId: map['organization_id'],
      claimedByMe: map['claimed_by_me'],
      gender: map['gender']?.toString(),
      serviceType: map['provider_item_type']?.toString(),
      specialTags: map['special_tags'] != null ? Map<String, String>.from(map['special_tags']) : null,
      rating: map['rating'] != null ? double.tryParse(map['rating'].toString()) : null,
      minRating: map['min_rating'] != null ? double.tryParse(map['min_rating'].toString()) : null,
      maxRating: map['max_rating'] != null ? double.tryParse(map['max_rating'].toString()) : null,
      categories: map['categories'] != null ? List<CategoryModel>.from(map['categories'].map((x) => CategoryModel.fromJson(x))) : [],
      itemSortBy: SearchItemSortBy.values.firstWhereOrNull((e) => e.jsonName == map['item_sort_by']),
      providerSortBy: SearchProviderSortBy.values.firstWhereOrNull((e) => e.jsonName == map['provider_sort_by']),
      featuredOnly: map['featured_only'] ?? false,
      publicOnly: map['public_only'] ?? false,
      privateSpacesOnly: map['private_spaces_only'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ItemFilterModel.fromJson(String source) => ItemFilterModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ItemFilterModel(maxPrice: $maxPrice, minPrice: $minPrice, organizationId: $organizationId, categoryId: $categoryId, postedSince: $postedSince, city: $city, state: $state, country: $country, area: $area, areaId: $areaId, custom_fields: $customFields, radius: $radius, latitude: $latitude, longitude: $longitude, userType: $userType, gender: $gender, serviceType: $serviceType, specialTags: $specialTags, rating: $rating, minRating: $minRating, maxRating: $maxRating)';
  }

  factory ItemFilterModel.createEmpty() {
    return ItemFilterModel(
      maxPrice: "",
      minPrice: "",
      categoryId: "",
      postedSince: "",
      city: '',
      state: '',
      country: '',
      area: null,
      areaId: null,
      radius: null,
      latitude: null,
      longitude: null,
      customFields: {},
      userType: null,
      gender: null,
      serviceType: null,
      specialTags: {},
      rating: null,
      minRating: null,
      maxRating: null,
    );
  }

  @override
  bool operator ==(covariant ItemFilterModel other) {
    if (identical(this, other)) return true;

    return other.maxPrice == maxPrice &&
        other.minPrice == minPrice &&
        other.categoryId == categoryId &&
        other.postedSince == postedSince &&
        other.city == city &&
        other.state == state &&
        other.country == country &&
        other.area == area &&
        other.radius == radius &&
        other.areaId == areaId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.customFields == customFields &&
        other.userType == userType &&
        other.gender == gender &&
        other.serviceType == serviceType &&
        other.specialTags.toString() == specialTags.toString() &&
        other.rating == rating &&
        other.minRating == minRating &&
        other.maxRating == maxRating &&
        other.publicOnly == publicOnly &&
        other.organizationId == other.organizationId &&
        other.itemSortBy == itemSortBy;
  }

  @override
  int get hashCode {
    return maxPrice.hashCode ^
        minPrice.hashCode ^
        categoryId.hashCode ^
        postedSince.hashCode ^
        city.hashCode ^
        state.hashCode ^
        country.hashCode ^
        area.hashCode ^
        radius.hashCode ^
        areaId.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        customFields.hashCode ^
        userType.hashCode ^
        gender.hashCode ^
        serviceType.hashCode ^
        specialTags.hashCode ^
        rating.hashCode ^
        organizationId.hashCode ^
        publicOnly.hashCode ^
        minRating.hashCode ^
        maxRating.hashCode ^
        itemSortBy.hashCode;
  }
}
