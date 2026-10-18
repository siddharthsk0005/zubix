class SessionModel {
  final String id;
  final String title;
  final String brandId;
  final String sessionCreatedBy;
  final int waitingDurationSeconds;
  final String discountValue;
  final String couponCode;
  final String status; // active, upcoming, completed
  final int totalVouchersPool;
  int claimedVouchersCount;
  final DateTime createdAt;
  final DateTime? expiresAt;

  SessionModel({
    required this.id,
    this.title = 'Generative Sessions',
    required this.brandId,
    required this.sessionCreatedBy,
    required this.waitingDurationSeconds,
    required this.discountValue,
    required this.couponCode,
    this.status = 'active',
    this.totalVouchersPool = 100,
    this.claimedVouchersCount = 0,
    DateTime? createdAt,
    this.expiresAt,
  }) : createdAt = createdAt ?? DateTime.now();

  SessionModel copyWith({
    String? id,
    String? title,
    String? brandId,
    String? sessionCreatedBy,
    int? waitingDurationSeconds,
    String? discountValue,
    String? couponCode,
    String? status,
    int? totalVouchersPool,
    int? claimedVouchersCount,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return SessionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      brandId: brandId ?? this.brandId,
      sessionCreatedBy: sessionCreatedBy ?? this.sessionCreatedBy,
      waitingDurationSeconds: waitingDurationSeconds ?? this.waitingDurationSeconds,
      discountValue: discountValue ?? this.discountValue,
      couponCode: couponCode ?? this.couponCode,
      status: status ?? this.status,
      totalVouchersPool: totalVouchersPool ?? this.totalVouchersPool,
      claimedVouchersCount: claimedVouchersCount ?? this.claimedVouchersCount,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'brandId': brandId,
    'sessionCreatedBy': sessionCreatedBy,
    'waitingDurationSeconds': waitingDurationSeconds,
    'discountValue': discountValue,
    'couponCode': couponCode,
    'status': status,
    'totalVouchersPool': totalVouchersPool,
    'claimedVouchersCount': claimedVouchersCount,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
  };

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Generative Sessions',
      brandId: json['brandId'] as String,
      sessionCreatedBy: json['sessionCreatedBy'] as String? ?? 'Zubix Team',
      waitingDurationSeconds: json['waitingDurationSeconds'] as int? ?? 30,
      discountValue: json['discountValue'] as String? ?? '20% OFF',
      couponCode: json['couponCode'] as String? ?? 'ZUBIX20',
      status: json['status'] as String? ?? 'active',
      totalVouchersPool: json['totalVouchersPool'] as int? ?? 100,
      claimedVouchersCount: json['claimedVouchersCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
    );
  }
}
