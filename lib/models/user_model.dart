class UserModel {
  final String id;
  final String? email;
  final String? phone;
  final String displayName;
  final String? name;
  final String? country;
  final String? state;
  final String? district;
  final String role; // 'consumer', 'brand', 'admin'
  final bool isProfileComplete;
  final DateTime createdAt;

  UserModel({
    required this.id,
    this.email,
    this.phone,
    required this.displayName,
    this.name,
    this.country,
    this.state,
    this.district,
    this.role = 'consumer',
    this.isProfileComplete = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'displayName': displayName,
    'name': name,
    'country': country,
    'state': state,
    'district': district,
    'role': role,
    'isProfileComplete': isProfileComplete,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as String? ?? json['displayName'] as String?;
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      displayName: rawName?.isNotEmpty == true ? rawName! : (json['phone'] as String? ?? 'Zubix Member'),
      name: rawName,
      country: json['country'] as String?,
      state: json['state'] as String?,
      district: json['district'] as String?,
      role: json['role'] as String? ?? 'consumer',
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? displayName,
    String? name,
    String? country,
    String? state,
    String? district,
    String? role,
    bool? isProfileComplete,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      name: name ?? this.name,
      country: country ?? this.country,
      state: state ?? this.state,
      district: district ?? this.district,
      role: role ?? this.role,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt,
    );
  }
}
