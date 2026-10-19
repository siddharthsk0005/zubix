// Coupon Tier — defines how many slots get what discount level
class CouponTier {
  int slots;        // number of people who can claim
  int discountPct;  // discount percentage (e.g. 90, 50, 30)
  String label;     // display label e.g. "90% OFF"

  CouponTier({
    required this.slots,
    required this.discountPct,
  }) : label = '$discountPct% OFF';

  CouponTier copyWith({int? slots, int? discountPct}) {
    return CouponTier(
      slots: slots ?? this.slots,
      discountPct: discountPct ?? this.discountPct,
    );
  }

  Map<String, dynamic> toJson() => {
    'slots': slots,
    'discountPct': discountPct,
  };

  factory CouponTier.fromJson(Map<String, dynamic> json) {
    return CouponTier(
      slots: json['slots'] as int? ?? 100,
      discountPct: json['discountPct'] as int? ?? 20,
    );
  }
}

// Session Request — submitted by an approved brand to schedule a generative session
// Status lifecycle: pending_approval → approved | dates_proposed → brand_confirmed → live
class SessionRequestModel {
  final String id;
  final String brandId;
  final String brandName;
  final String brandType; // 'online_d2c' or 'local_store'
  DateTime requestedDate;
  List<CouponTier> couponTiers;
  String? additionalNotes;
  // Status
  String status; // 'pending_approval', 'approved', 'rejected', 'dates_proposed', 'brand_confirmed'
  String? rejectionReason;
  List<DateTime> proposedDates; // admin proposes alternatives
  DateTime? confirmedDate; // final date after brand picks
  // Audit
  final DateTime submittedAt;
  DateTime? reviewedAt;
  String? reviewedBy;

  SessionRequestModel({
    required this.id,
    required this.brandId,
    required this.brandName,
    required this.brandType,
    required this.requestedDate,
    required this.couponTiers,
    this.additionalNotes,
    this.status = 'pending_approval',
    this.rejectionReason,
    List<DateTime>? proposedDates,
    this.confirmedDate,
    DateTime? submittedAt,
    this.reviewedAt,
    this.reviewedBy,
  }) : submittedAt = submittedAt ?? DateTime.now(),
       proposedDates = proposedDates ?? [];

  int get totalSlots => couponTiers.fold(0, (sum, t) => sum + t.slots);

  DateTime get effectiveDate => confirmedDate ?? requestedDate;

  SessionRequestModel copyWith({
    String? id,
    String? brandId,
    String? brandName,
    String? brandType,
    DateTime? requestedDate,
    List<CouponTier>? couponTiers,
    String? additionalNotes,
    String? status,
    String? rejectionReason,
    List<DateTime>? proposedDates,
    DateTime? confirmedDate,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return SessionRequestModel(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      brandType: brandType ?? this.brandType,
      requestedDate: requestedDate ?? this.requestedDate,
      couponTiers: couponTiers ?? this.couponTiers,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      proposedDates: proposedDates ?? this.proposedDates,
      confirmedDate: confirmedDate ?? this.confirmedDate,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brandId': brandId,
    'brandName': brandName,
    'brandType': brandType,
    'requestedDate': requestedDate.toIso8601String(),
    'couponTiers': couponTiers.map((t) => t.toJson()).toList(),
    'additionalNotes': additionalNotes,
    'status': status,
    'rejectionReason': rejectionReason,
    'proposedDates': proposedDates.map((d) => d.toIso8601String()).toList(),
    'confirmedDate': confirmedDate?.toIso8601String(),
    'submittedAt': submittedAt.toIso8601String(),
    'reviewedAt': reviewedAt?.toIso8601String(),
    'reviewedBy': reviewedBy,
  };

  factory SessionRequestModel.fromJson(Map<String, dynamic> json) {
    return SessionRequestModel(
      id: json['id'] as String,
      brandId: json['brandId'] as String,
      brandName: json['brandName'] as String? ?? '',
      brandType: json['brandType'] as String? ?? 'online_d2c',
      requestedDate: DateTime.parse(json['requestedDate'] as String),
      couponTiers: (json['couponTiers'] as List<dynamic>?)
          ?.map((t) => CouponTier.fromJson(t as Map<String, dynamic>))
          .toList() ?? [CouponTier(slots: 100, discountPct: 30)],
      additionalNotes: json['additionalNotes'] as String?,
      status: json['status'] as String? ?? 'pending_approval',
      rejectionReason: json['rejectionReason'] as String?,
      proposedDates: (json['proposedDates'] as List<dynamic>?)
          ?.map((d) => DateTime.parse(d as String))
          .toList() ?? [],
      confirmedDate: json['confirmedDate'] != null
          ? DateTime.parse(json['confirmedDate'] as String) : null,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String) : DateTime.now(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String) : null,
      reviewedBy: json['reviewedBy'] as String?,
    );
  }
}
