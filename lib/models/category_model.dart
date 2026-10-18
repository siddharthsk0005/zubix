class CategoryModel {
  final String id;
  String name;
  String slug;
  String iconName;
  int displayOrder;
  bool isActive;
  Map<String, dynamic>? metadata;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.iconName = 'category',
    this.displayOrder = 0,
    this.isActive = true,
    this.metadata,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? iconName,
    int? displayOrder,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      iconName: iconName ?? this.iconName,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'iconName': iconName,
    'displayOrder': displayOrder,
    'isActive': isActive,
    'metadata': metadata,
  };

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      iconName: json['iconName'] as String? ?? 'category',
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
