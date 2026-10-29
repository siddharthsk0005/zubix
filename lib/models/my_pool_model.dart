// One session the signed-in customer has joined, as shown on the Pool tab.
class MyPoolEntry {
  final String id;
  final String sessionId;
  final String sessionTitle;
  final String sessionCreatedBy;
  final String brandName;
  final String brandLogoUrl;
  // waiting | pooled | allotted
  final String status;
  final DateTime joinedAt;
  final DateTime acceptAt;
  final DateTime? acknowledgedAt;
  final String? tierLabel;
  final String discountValue;
  final DateTime? releaseAt;

  const MyPoolEntry({
    required this.id,
    required this.sessionId,
    required this.sessionTitle,
    required this.sessionCreatedBy,
    required this.brandName,
    required this.brandLogoUrl,
    required this.status,
    required this.joinedAt,
    required this.acceptAt,
    this.acknowledgedAt,
    this.tierLabel,
    required this.discountValue,
    this.releaseAt,
  });

  bool get isWaiting => status == 'waiting';
  bool get isPooled => status == 'pooled';
  bool get isAllotted => status == 'allotted';
  // Accepted into the pool but the customer hasn't pressed "Okay" yet.
  bool get needsAcknowledgement => isPooled && acknowledgedAt == null;

  factory MyPoolEntry.fromJson(Map<String, dynamic> json) {
    return MyPoolEntry(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      sessionTitle: (json['sessionTitle'] ?? '') as String,
      sessionCreatedBy: (json['sessionCreatedBy'] ?? '') as String,
      brandName: (json['brandName'] ?? 'Partner Brand') as String,
      brandLogoUrl: (json['brandLogoUrl'] ?? '') as String,
      status: (json['status'] ?? 'waiting') as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String).toLocal(),
      acceptAt: DateTime.parse(json['acceptAt'] as String).toLocal(),
      acknowledgedAt: json['acknowledgedAt'] == null
          ? null
          : DateTime.parse(json['acknowledgedAt'] as String).toLocal(),
      tierLabel: json['tierLabel'] as String?,
      discountValue: (json['discountValue'] ?? '') as String,
      releaseAt: json['releaseAt'] == null
          ? null
          : DateTime.parse(json['releaseAt'] as String).toLocal(),
    );
  }
}
