class PoolCouponTier {
  final String key;
  final String label;
  final int slots;
  final int discountPct;
  final int allottedCount;

  const PoolCouponTier({
    required this.key,
    required this.label,
    required this.slots,
    this.discountPct = 0,
    this.allottedCount = 0,
  });

  int get slotsLeft => (slots - allottedCount).clamp(0, slots);

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'slots': slots,
    'discountPct': discountPct,
  };

  factory PoolCouponTier.fromJson(Map<String, dynamic> json) {
    return PoolCouponTier(
      key: json['key'].toString(),
      label: json['label'] as String? ?? 'Tier',
      slots: (json['slots'] as num?)?.toInt() ?? 0,
      discountPct: (json['discountPct'] as num?)?.toInt() ?? 0,
      allottedCount: (json['allottedCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class PoolParticipant {
  final String id;
  final String userId;
  final String name;
  final String? phone;
  final String? email;
  final String status; // waiting, pooled, allotted
  final DateTime joinedAt;
  final DateTime? acceptAt;
  final String? tierKey;

  const PoolParticipant({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.email,
    required this.status,
    required this.joinedAt,
    this.acceptAt,
    this.tierKey,
  });

  factory PoolParticipant.fromJson(Map<String, dynamic> json) {
    return PoolParticipant(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Customer',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      status: json['status'] as String? ?? 'waiting',
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      acceptAt: json['acceptAt'] != null
          ? DateTime.parse(json['acceptAt'] as String)
          : null,
      tierKey: json['tierKey']?.toString(),
    );
  }
}

class SessionPoolData {
  final List<PoolCouponTier> tiers;
  final List<PoolParticipant> participants;

  const SessionPoolData({required this.tiers, required this.participants});

  factory SessionPoolData.fromJson(Map<String, dynamic> json) {
    return SessionPoolData(
      tiers: (json['tiers'] as List<dynamic>? ?? [])
          .map((t) => PoolCouponTier.fromJson(t as Map<String, dynamic>))
          .toList(),
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((p) => PoolParticipant.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
