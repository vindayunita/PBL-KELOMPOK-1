class SellerApplicationModel {
  const SellerApplicationModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.businessName,
    required this.commodityType,
    required this.businessDescription,
    required this.status,
    required this.submittedAt,
    this.productName = '',
    this.city,
    this.stock = 0,
    this.pricePerKg = 0.0,
    this.commodityImageUrl = '',
    this.rejectionReason,
    this.reviewedAt,
    // ── KYC Fields ──────────────────────────────────────────────────────────
    this.ktpImageUrl,
    this.selfieWithKtpImageUrl,
    this.ktpName,
    this.bankName,
    this.bankAccountName,
    this.bankAccountNumber,
    this.kycStatus = 'pending_kyc',
  });

  final String uid;
  final String name;
  final String email;
  final String businessName;
  final String commodityType;
  final String businessDescription;
  final String status;
  final String submittedAt;
  final String productName;
  final String? city;
  final int    stock;
  final double pricePerKg;
  final String commodityImageUrl;
  final String? rejectionReason;
  final String? reviewedAt;

  // ── KYC Fields ────────────────────────────────────────────────────────────
  /// URL foto KTP yang diupload ke Firebase Storage
  final String? ktpImageUrl;

  /// URL foto selfie bersama KTP
  final String? selfieWithKtpImageUrl;

  /// Nama sesuai KTP (diisi manual oleh seller)
  final String? ktpName;

  /// Nama bank rekening tujuan pencairan
  final String? bankName;

  /// Nama pemilik rekening (harus sama persis dengan nama KTP)
  final String? bankAccountName;

  /// Nomor rekening tujuan pencairan
  final String? bankAccountNumber;

  /// Status KYC:
  /// - `pending_kyc`  : belum ada data KTP/bank
  /// - `pending`      : sudah upload, menunggu review admin
  /// - `verified`     : sudah diverifikasi admin
  /// - `rejected`     : ditolak admin (biasanya nama tidak cocok)
  final String kycStatus;

  bool get isPending  => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  bool get isKycVerified  => kycStatus == 'verified';
  bool get isKycPending   => kycStatus == 'pending' || kycStatus == 'pending_kyc';
  bool get isKycRejected  => kycStatus == 'rejected';

  factory SellerApplicationModel.fromJson(Map<String, dynamic> json, String uid) {
    return SellerApplicationModel(
      uid:                 uid,
      name:                json['name']                as String? ?? '',
      email:               json['email']               as String? ?? '',
      businessName:        json['businessName']        as String? ?? '',
      commodityType:       json['commodityType']       as String? ?? '',
      businessDescription: json['businessDescription'] as String? ?? '',
      status:              json['status']              as String? ?? 'pending',
      submittedAt:         json['submittedAt']         as String? ?? '',
      productName:         json['productName']         as String? ?? '',
      city:                json['city']                as String?,
      stock:               (json['stock']      as num?)?.toInt()    ?? 0,
      pricePerKg:          (json['pricePerKg'] as num?)?.toDouble() ?? 0.0,
      commodityImageUrl:   json['commodityImageUrl']   as String? ?? '',
      rejectionReason:     json['rejectionReason']     as String?,
      reviewedAt:          json['reviewedAt']          as String?,
      // KYC
      ktpImageUrl:          json['ktpImageUrl']          as String?,
      selfieWithKtpImageUrl:json['selfieWithKtpImageUrl']as String?,
      ktpName:              json['ktpName']              as String?,
      bankName:             json['bankName']             as String?,
      bankAccountName:      json['bankAccountName']      as String?,
      bankAccountNumber:    json['bankAccountNumber']    as String?,
      kycStatus:            json['kycStatus']            as String? ?? 'pending_kyc',
    );
  }

  Map<String, dynamic> toJson() => {
        'name':                name,
        'email':               email,
        'businessName':        businessName,
        'commodityType':       commodityType,
        'businessDescription': businessDescription,
        'status':              status,
        'submittedAt':         submittedAt,
        'productName':         productName,
        'stock':               stock,
        'pricePerKg':          pricePerKg,
        'commodityImageUrl':   commodityImageUrl,
        'kycStatus':           kycStatus,
        if (city              != null) 'city':                  city,
        if (rejectionReason   != null) 'rejectionReason':       rejectionReason,
        if (reviewedAt        != null) 'reviewedAt':            reviewedAt,
        if (ktpImageUrl       != null) 'ktpImageUrl':           ktpImageUrl,
        if (selfieWithKtpImageUrl != null) 'selfieWithKtpImageUrl': selfieWithKtpImageUrl,
        if (ktpName           != null) 'ktpName':               ktpName,
        if (bankName          != null) 'bankName':              bankName,
        if (bankAccountName   != null) 'bankAccountName':       bankAccountName,
        if (bankAccountNumber != null) 'bankAccountNumber':     bankAccountNumber,
      };
}
