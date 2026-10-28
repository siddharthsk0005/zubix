import 'brand_media_model.dart';

class BrandModel {
  final String id;
  String name;
  String tagline;
  String bio;
  String logoUrl;
  List<String> showcaseImages;
  List<BrandMediaItem> media; // ordered uploads from the brand; shown on the Brands page
  String websiteUrl;
  Map<String, String> socialLinks;
  String contactEmail;
  String contactPhone;
  String categoryId;
  String sessionCreatedBy;
  bool isApproved;
  bool isPhysicalStore;
  String storeType; // 'online_d2c' or 'local_store'
  String? city;
  String? area;
  String? address;
  double? latitude;
  double? longitude;
  String? googleMapsUrl;
  String? timings;
  double? distanceKm;
  DateTime registeredAt;

  BrandModel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.bio,
    required this.logoUrl,
    required this.showcaseImages,
    this.media = const [],
    required this.websiteUrl,
    required this.socialLinks,
    required this.contactEmail,
    required this.contactPhone,
    required this.categoryId,
    this.sessionCreatedBy = 'Zubix Curators',
    this.isApproved = true,
    this.isPhysicalStore = false,
    this.storeType = 'online_d2c',
    this.city,
    this.area,
    this.address,
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
    this.timings = '10:00 AM - 9:30 PM',
    this.distanceKm,
    DateTime? registeredAt,
  }) : registeredAt = registeredAt ?? DateTime.now();

  BrandModel copyWith({
    String? id,
    String? name,
    String? tagline,
    String? bio,
    String? logoUrl,
    List<String>? showcaseImages,
    List<BrandMediaItem>? media,
    String? websiteUrl,
    Map<String, String>? socialLinks,
    String? contactEmail,
    String? contactPhone,
    String? categoryId,
    String? sessionCreatedBy,
    bool? isApproved,
    bool? isPhysicalStore,
    String? storeType,
    String? city,
    String? area,
    String? address,
    double? latitude,
    double? longitude,
    String? googleMapsUrl,
    String? timings,
    double? distanceKm,
    DateTime? registeredAt,
  }) {
    return BrandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      bio: bio ?? this.bio,
      logoUrl: logoUrl ?? this.logoUrl,
      showcaseImages: showcaseImages ?? this.showcaseImages,
      media: media ?? this.media,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      socialLinks: socialLinks ?? this.socialLinks,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      categoryId: categoryId ?? this.categoryId,
      sessionCreatedBy: sessionCreatedBy ?? this.sessionCreatedBy,
      isApproved: isApproved ?? this.isApproved,
      isPhysicalStore: isPhysicalStore ?? this.isPhysicalStore,
      storeType: storeType ?? this.storeType,
      city: city ?? this.city,
      area: area ?? this.area,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      timings: timings ?? this.timings,
      distanceKm: distanceKm ?? this.distanceKm,
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tagline': tagline,
    'bio': bio,
    'logoUrl': logoUrl,
    'showcaseImages': showcaseImages,
    'media': media.map((m) => m.toJson()).toList(),
    'websiteUrl': websiteUrl,
    'socialLinks': socialLinks,
    'contactEmail': contactEmail,
    'contactPhone': contactPhone,
    'categoryId': categoryId,
    'sessionCreatedBy': sessionCreatedBy,
    'isApproved': isApproved,
    'isPhysicalStore': isPhysicalStore,
    'storeType': storeType,
    'city': city,
    'area': area,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'googleMapsUrl': googleMapsUrl,
    'timings': timings,
    'distanceKm': distanceKm,
    'registeredAt': registeredAt.toIso8601String(),
  };

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] as String,
      name: json['name'] as String,
      tagline: json['tagline'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
      showcaseImages: (json['showcaseImages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      media: (json['media'] as List<dynamic>?)
              ?.map((e) => BrandMediaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      websiteUrl: json['websiteUrl'] as String? ?? '',
      socialLinks: (json['socialLinks'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {},
      contactEmail: json['contactEmail'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      sessionCreatedBy: json['sessionCreatedBy'] as String? ?? 'Zubix Curators',
      isApproved: json['isApproved'] as bool? ?? false,
      isPhysicalStore: json['isPhysicalStore'] as bool? ?? false,
      storeType: json['storeType'] as String? ?? 'online_d2c',
      city: json['city'] as String?,
      area: json['area'] as String?,
      address: json['address'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      googleMapsUrl: json['googleMapsUrl'] as String?,
      timings: json['timings'] as String? ?? '10:00 AM - 9:30 PM',
      distanceKm: json['distanceKm'] != null ? (json['distanceKm'] as num).toDouble() : null,
      registeredAt: json['registeredAt'] != null ? DateTime.parse(json['registeredAt'] as String) : DateTime.now(),
    );
  }
}
