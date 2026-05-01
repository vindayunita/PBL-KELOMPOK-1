class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.roles,
    required this.activeRole,
    this.photoUrl,
    this.phoneNumber,
    this.addresses = const [],
  });

  final String uid;
  final String name;
  final String email;
  final List<String> roles;
  final String activeRole;
  final String? photoUrl;
  final String? phoneNumber;
  final List<Map<String, dynamic>> addresses;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid:        json['uid']         as String,
      name:       json['name']        as String,
      email:      json['email']       as String,
      roles:      List<String>.from(json['roles'] as List? ?? ['buyer']),
      activeRole: json['activeRole']  as String? ?? 'buyer',
      photoUrl:   json['photoUrl']    as String?,
      phoneNumber:json['phoneNumber'] as String?,
      addresses:  (json['addresses'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'uid':        uid,
        'name':       name,
        'email':      email,
        'roles':      roles,
        'activeRole': activeRole,
        if (photoUrl    != null) 'photoUrl':    photoUrl,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (addresses.isNotEmpty) 'addresses':  addresses,
      };

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    List<String>? roles,
    String? activeRole,
    String? photoUrl,
    String? phoneNumber,
    List<Map<String, dynamic>>? addresses,
  }) =>
      UserModel(
        uid:        uid        ?? this.uid,
        name:       name       ?? this.name,
        email:      email      ?? this.email,
        roles:      roles      ?? this.roles,
        activeRole: activeRole ?? this.activeRole,
        photoUrl:   photoUrl   ?? this.photoUrl,
        phoneNumber:phoneNumber ?? this.phoneNumber,
        addresses:  addresses  ?? this.addresses,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && uid == other.uid && activeRole == other.activeRole;

  @override
  int get hashCode => Object.hash(uid, activeRole);

  @override
  String toString() =>
      'UserModel(uid: $uid, name: $name, roles: $roles, activeRole: $activeRole)';
}
