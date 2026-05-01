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
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
        if (reviewedAt      != null) 'reviewedAt':      reviewedAt,
      };
}
