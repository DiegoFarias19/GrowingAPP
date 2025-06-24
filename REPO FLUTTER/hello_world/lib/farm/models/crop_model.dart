class Crop {
  final String cropId;
  final String? farmId;
  final String cropName;
  final String? imageUrl;
  final String? status;

  Crop({
    required this.cropId,
    this.farmId,
    required this.cropName,
    this.imageUrl,
    this.status,
  });

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      cropId: json['crop_id'] as String,
      farmId: json['farm_id'] as String,
      cropName: json['crop_name'] as String,
      imageUrl:
          json['image_url'] as String? ?? 'assets/images/farm_default.jpg',
      status: json['status'] as String?,
    );
  }
}
