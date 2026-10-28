class BrandMediaItem {
  final String id;
  final String kind; // 'image' or 'video'
  final String url;
  final int position;

  const BrandMediaItem({
    required this.id,
    required this.kind,
    required this.url,
    required this.position,
  });

  bool get isVideo => kind == 'video';

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'url': url,
    'position': position,
  };

  factory BrandMediaItem.fromJson(Map<String, dynamic> json) {
    return BrandMediaItem(
      id: json['id'] as String,
      kind: json['kind'] as String? ?? 'image',
      url: json['url'] as String? ?? '',
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }
}
