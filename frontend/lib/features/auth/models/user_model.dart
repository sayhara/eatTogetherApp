class UserModel {
  final int id;
  final String nickname;
  final String? email;
  final String? profileImageUrl;
  final String provider;
  final double? latitude;
  final double? longitude;
  final bool notificationEnabled;

  const UserModel({
    required this.id,
    required this.nickname,
    this.email,
    this.profileImageUrl,
    required this.provider,
    this.latitude,
    this.longitude,
    this.notificationEnabled = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        nickname: json['nickname'] as String,
        email: json['email'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
        provider: json['provider'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      );

  UserModel copyWith({
    String? nickname,
    bool? notificationEnabled,
  }) =>
      UserModel(
        id: id,
        nickname: nickname ?? this.nickname,
        email: email,
        profileImageUrl: profileImageUrl,
        provider: provider,
        latitude: latitude,
        longitude: longitude,
        notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      );
}
