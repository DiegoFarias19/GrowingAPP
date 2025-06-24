class Farm {
  final String farmId;
  final String farmName;
  final String? imageUrl;

  Farm({required this.farmId, required this.farmName, this.imageUrl});

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      farmId: json['farm_id'] as String,
      farmName: json['farm_name'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }
}
