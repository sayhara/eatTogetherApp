class UserModel {
  final int id;
  final String nickname;
  final String? email;
  final String? profileImageUrl;
  final String provider;
  final double? latitude;
  final double? longitude;

  const UserModel({
    required this.id,
    required this.nickname,
    this.email,
    this.profileImageUrl,
    required this.provider,
    this.latitude,
    this.longitude,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        nickname: json['nickname'] as String,
        email: json['email'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
        provider: json['provider'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}
