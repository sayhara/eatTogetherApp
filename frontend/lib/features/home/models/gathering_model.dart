class GatheringModel {
  final int id;
  final int hostId;
  final String hostNickname;
  final String title;
  final String? description;
  final String restaurantName;
  final double latitude;
  final double longitude;
  final String? address;
  final String? category;
  final int maxParticipants;
  final int currentParticipants;
  final DateTime mealTime;
  final String status;

  const GatheringModel({
    required this.id,
    required this.hostId,
    required this.hostNickname,
    required this.title,
    this.description,
    required this.restaurantName,
    required this.latitude,
    required this.longitude,
    this.address,
    this.category,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.mealTime,
    required this.status,
  });

  factory GatheringModel.fromJson(Map<String, dynamic> json) => GatheringModel(
        id: json['id'] as int,
        hostId: json['hostId'] as int,
        hostNickname: json['hostNickname'] as String? ?? '',
        title: json['title'] as String,
        description: json['description'] as String?,
        restaurantName: json['restaurantName'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] as String?,
        category: json['category'] as String?,
        maxParticipants: json['maxParticipants'] as int,
        currentParticipants: json['currentParticipants'] as int? ?? 0,
        mealTime: DateTime.parse(json['mealTime'] as String),
        status: json['status'] as String,
      );

  bool get isOpen => status == 'OPEN';
  bool get isFull => currentParticipants >= maxParticipants;
}
