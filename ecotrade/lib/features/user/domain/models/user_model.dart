class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.roles,
    required this.activeRole,
    this.username,
    this.photoUrl,
    this.phoneNumber,
    this.addresses = const [],
    this.refundBalance = 0.0,
    this.bankName,
    this.bankAccountName,
    this.bankAccountNumber,
    this.sellerWithdrawnAmount = 0.0,
    // ── KYC Fields ──────────────────────────────────────────────────────────
    this.kycStatus = 'unverified',
    this.bankVerifiedAt,
  });

  final String uid;
  final String name;
  final String email;
  final List<String> roles;
  final String activeRole;
  /// Username unik (auto-generate dari name saat registrasi, lowercase tanpa spasi)
  final String? username;
  final String? photoUrl;
  final String? phoneNumber;
  final List<Map<String, dynamic>> addresses;
  final double refundBalance;
  final String? bankName;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final double sellerWithdrawnAmount;

  // ── KYC Fields ────────────────────────────────────────────────────────────
  /// Status KYC seller:
  /// - `unverified` : belum pernah daftar seller / belum upload KTP
  /// - `pending`    : sudah upload, menunggu review admin
  /// - `verified`   : sudah diverifikasi (bisa cairkan dana)
  /// - `rejected`   : ditolak (nama KTP ≠ nama rekening, dll.)
  final String kycStatus;

  /// Timestamp terakhir kali data bank diverifikasi oleh admin (ISO 8601)
  final String? bankVerifiedAt;

  bool get isKycVerified => kycStatus == 'verified';
  bool get isKycPending  => kycStatus == 'pending';
  bool get isKycRejected => kycStatus == 'rejected';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid:        json['uid']         as String,
      name:       json['name']        as String,
      email:      json['email']       as String,
      roles:      List<String>.from(json['roles'] as List? ?? ['buyer']),
      activeRole: json['activeRole']  as String? ?? 'buyer',
      username:   json['username']    as String?,
      photoUrl:   json['photoUrl']    as String?,
      phoneNumber:json['phoneNumber'] as String?,
      addresses:  (json['addresses'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      refundBalance: (json['refundBalance'] as num?)?.toDouble() ?? 0.0,
      bankName: json['bankName'] as String?,
      bankAccountName: json['bankAccountName'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      sellerWithdrawnAmount: (json['sellerWithdrawnAmount'] as num?)?.toDouble() ?? 0.0,
      kycStatus:      json['kycStatus']      as String? ?? 'unverified',
      bankVerifiedAt: json['bankVerifiedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid':        uid,
        'name':       name,
        'email':      email,
        'roles':      roles,
        'activeRole': activeRole,
        if (username    != null) 'username':    username,
        if (photoUrl    != null) 'photoUrl':    photoUrl,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (addresses.isNotEmpty) 'addresses':  addresses,
        'refundBalance': refundBalance,
        if (bankName          != null) 'bankName':          bankName,
        if (bankAccountName   != null) 'bankAccountName':   bankAccountName,
        if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
        'sellerWithdrawnAmount': sellerWithdrawnAmount,
        'kycStatus': kycStatus,
        if (bankVerifiedAt != null) 'bankVerifiedAt': bankVerifiedAt,
      };

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    List<String>? roles,
    String? activeRole,
    String? username,
    String? photoUrl,
    String? phoneNumber,
    List<Map<String, dynamic>>? addresses,
    double? refundBalance,
    String? bankName,
    String? bankAccountName,
    String? bankAccountNumber,
    double? sellerWithdrawnAmount,
    String? kycStatus,
    String? bankVerifiedAt,
  }) =>
      UserModel(
        uid:        uid        ?? this.uid,
        name:       name       ?? this.name,
        email:      email      ?? this.email,
        roles:      roles      ?? this.roles,
        activeRole: activeRole ?? this.activeRole,
        username:   username   ?? this.username,
        photoUrl:   photoUrl   ?? this.photoUrl,
        phoneNumber:phoneNumber ?? this.phoneNumber,
        addresses:  addresses  ?? this.addresses,
        refundBalance: refundBalance ?? this.refundBalance,
        bankName: bankName ?? this.bankName,
        bankAccountName: bankAccountName ?? this.bankAccountName,
        bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
        sellerWithdrawnAmount: sellerWithdrawnAmount ?? this.sellerWithdrawnAmount,
        kycStatus:      kycStatus      ?? this.kycStatus,
        bankVerifiedAt: bankVerifiedAt ?? this.bankVerifiedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && uid == other.uid && activeRole == other.activeRole;

  @override
  int get hashCode => Object.hash(uid, activeRole);

  @override
  String toString() =>
      'UserModel(uid: $uid, name: $name, roles: $roles, activeRole: $activeRole, kycStatus: $kycStatus)';
}
