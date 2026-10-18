class VoucherModel {
  final String id;
  final String code;
  final String brandName;
  final String brandLogoUrl;
  final String brandWebsite;
  final String discountValue;
  final String categoryName;
  final DateTime claimedAt;
  final DateTime expiresAt;
  bool isRedeemed;
  final String? terms;

  VoucherModel({
    required this.id,
    required this.code,
    required this.brandName,
    required this.brandLogoUrl,
    required this.brandWebsite,
    required this.discountValue,
    required this.categoryName,
    required this.claimedAt,
    required this.expiresAt,
    this.isRedeemed = false,
    this.terms,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'brandName': brandName,
    'brandLogoUrl': brandLogoUrl,
    'brandWebsite': brandWebsite,
    'discountValue': discountValue,
    'categoryName': categoryName,
    'claimedAt': claimedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'isRedeemed': isRedeemed,
    'terms': terms,
  };

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'] as String,
      code: json['code'] as String,
      brandName: json['brandName'] as String,
      brandLogoUrl: json['brandLogoUrl'] as String? ?? '',
      brandWebsite: json['brandWebsite'] as String? ?? '',
      discountValue: json['discountValue'] as String,
      categoryName: json['categoryName'] as String? ?? 'General',
      claimedAt: DateTime.parse(json['claimedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isRedeemed: json['isRedeemed'] as bool? ?? false,
      terms: json['terms'] as String?,
    );
  }
}
