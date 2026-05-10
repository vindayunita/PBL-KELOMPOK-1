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

  bool get isPending  => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

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
        if (city            != null) 'city':            city,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
        if (reviewedAt      != null) 'reviewedAt':      reviewedAt,
      };
}
