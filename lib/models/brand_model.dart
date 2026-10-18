class BrandModel {
  final String id;
  String name;
  String tagline;
  String bio;
  String logoUrl;
  List<String> showcaseImages;
  String websiteUrl;
  Map<String, String> socialLinks;
  String contactEmail;
  String contactPhone;
  String categoryId;
  String sessionCreatedBy;
  bool isApproved;
  DateTime registeredAt;

  BrandModel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.bio,
    required this.logoUrl,
    required this.showcaseImages,
    required this.websiteUrl,
    required this.socialLinks,
    required this.contactEmail,
    required this.contactPhone,
    required this.categoryId,
    this.sessionCreatedBy = 'Zubix Curators',
    this.isApproved = true,
    DateTime? registeredAt,
  }) : registeredAt = registeredAt ?? DateTime.now();

  BrandModel copyWith({
    String? id,
    String? name,
    String? tagline,
    String? bio,
    String? logoUrl,
    List<String>? showcaseImages,
    String? websiteUrl,
    Map<String, String>? socialLinks,
    String? contactEmail,
    String? contactPhone,
    String? categoryId,
    String? sessionCreatedBy,
    bool? isApproved,
    DateTime? registeredAt,
  }) {
    return BrandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      bio: bio ?? this.bio,
      logoUrl: logoUrl ?? this.logoUrl,
      showcaseImages: showcaseImages ?? this.showcaseImages,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      socialLinks: socialLinks ?? this.socialLinks,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      categoryId: categoryId ?? this.categoryId,
      sessionCreatedBy: sessionCreatedBy ?? this.sessionCreatedBy,
      isApproved: isApproved ?? this.isApproved,
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
    'websiteUrl': websiteUrl,
    'socialLinks': socialLinks,
    'contactEmail': contactEmail,
    'contactPhone': contactPhone,
    'categoryId': categoryId,
    'sessionCreatedBy': sessionCreatedBy,
    'isApproved': isApproved,
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
      websiteUrl: json['websiteUrl'] as String? ?? '',
      socialLinks: (json['socialLinks'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {},
      contactEmail: json['contactEmail'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      sessionCreatedBy: json['sessionCreatedBy'] as String? ?? 'Zubix Curators',
      isApproved: json['isApproved'] as bool? ?? false,
      registeredAt: json['registeredAt'] != null ? DateTime.parse(json['registeredAt'] as String) : DateTime.now(),
    );
  }
}
