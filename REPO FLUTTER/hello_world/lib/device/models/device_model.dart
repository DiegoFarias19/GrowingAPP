class Device {
  final String deviceId;
  final String deviceName;
  String? cropId;
  bool state;

  Device({
    required this.deviceId,
    required this.deviceName,
    this.cropId,
    required this.state,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      deviceId: json['device_id'] ?? json['id'] as String,
      deviceName: json['device_name'] ?? json['name'] as String,
      cropId: json['crop_id'] as String?,
      state: json['state'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'crop_id': cropId,
      'state': state,
    };
  }
}
