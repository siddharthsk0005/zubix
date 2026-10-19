// Brand Registration Application Model
// Status lifecycle: pending → approved | rejected → (if rejected, can reapply)
class BrandRegistrationModel {
  final String id;
  String brandName;
  String ownerName;
  String ownerPhone;
  String ownerEmail;
  String password;
  String brandType; // 'online_d2c' or 'local_store'
  String? websiteUrl;
  String? instagramUrl;
  String? description;
  String categoryId;
  // Physical store fields (only if local_store)
  String? city;
  String? area;
  String? address;
  String? operatingHours;
  // Status lifecycle
  String status; // 'pending', 'approved', 'rejected'
  String? rejectionReason;
  String? adminNotes;
  DateTime appliedAt;
  DateTime? reviewedAt;
  String? reviewedBy;

  BrandRegistrationModel({
    required this.id,
    required this.brandName,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.password,
    required this.brandType,
    required this.categoryId,
    this.websiteUrl,
    this.instagramUrl,
    this.description,
    this.city,
    this.area,
    this.address,
    this.operatingHours,
    this.status = 'pending',
    this.rejectionReason,
    this.adminNotes,
    DateTime? appliedAt,
    this.reviewedAt,
    this.reviewedBy,
  }) : appliedAt = appliedAt ?? DateTime.now();

  BrandRegistrationModel copyWith({
    String? id,
    String? brandName,
    String? ownerName,
    String? ownerPhone,
    String? ownerEmail,
    String? password,
    String? brandType,
    String? categoryId,
    String? websiteUrl,
    String? instagramUrl,
    String? description,
    String? city,
    String? area,
    String? address,
    String? operatingHours,
    String? status,
    String? rejectionReason,
    String? adminNotes,
    DateTime? appliedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return BrandRegistrationModel(
      id: id ?? this.id,
      brandName: brandName ?? this.brandName,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      password: password ?? this.password,
      brandType: brandType ?? this.brandType,
      categoryId: categoryId ?? this.categoryId,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      description: description ?? this.description,
      city: city ?? this.city,
      area: area ?? this.area,
      address: address ?? this.address,
      operatingHours: operatingHours ?? this.operatingHours,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      adminNotes: adminNotes ?? this.adminNotes,
      appliedAt: appliedAt ?? this.appliedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brandName': brandName,
    'ownerName': ownerName,
    'ownerPhone': ownerPhone,
    'ownerEmail': ownerEmail,
    'brandType': brandType,
    'categoryId': categoryId,
    'websiteUrl': websiteUrl,
    'instagramUrl': instagramUrl,
    'description': description,
    'city': city,
    'area': area,
    'address': address,
    'operatingHours': operatingHours,
    'status': status,
    'rejectionReason': rejectionReason,
    'adminNotes': adminNotes,
    'appliedAt': appliedAt.toIso8601String(),
    'reviewedAt': reviewedAt?.toIso8601String(),
    'reviewedBy': reviewedBy,
  };

  factory BrandRegistrationModel.fromJson(Map<String, dynamic> json) {
    return BrandRegistrationModel(
      id: json['id'] as String,
      brandName: json['brandName'] as String,
      ownerName: json['ownerName'] as String? ?? '',
      ownerPhone: json['ownerPhone'] as String? ?? '',
      ownerEmail: json['ownerEmail'] as String? ?? '',
      password: json['password'] as String? ?? '',
      brandType: json['brandType'] as String? ?? 'online_d2c',
      categoryId: json['categoryId'] as String? ?? 'cat_fashion',
      websiteUrl: json['websiteUrl'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      description: json['description'] as String?,
      city: json['city'] as String?,
      area: json['area'] as String?,
      address: json['address'] as String?,
      operatingHours: json['operatingHours'] as String?,
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejectionReason'] as String?,
      adminNotes: json['adminNotes'] as String?,
      appliedAt: json['appliedAt'] != null ? DateTime.parse(json['appliedAt'] as String) : DateTime.now(),
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt'] as String) : null,
      reviewedBy: json['reviewedBy'] as String?,
    );
  }
}
