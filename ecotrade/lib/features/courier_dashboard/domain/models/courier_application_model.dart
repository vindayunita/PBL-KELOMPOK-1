class CourierApplicationModel {
  const CourierApplicationModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.area,
    required this.ktpImageUrl,
    required this.simImageUrl,
    required this.agreedTerms,
    required this.status,
    required this.submittedAt,
    this.rejectionReason,
    this.reviewedAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String area;
  final String ktpImageUrl;
  final String simImageUrl;
  final bool agreedTerms;
  final String status;
  final String submittedAt;
  final String? rejectionReason;
  final String? reviewedAt;

  bool get isPending  => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory CourierApplicationModel.fromJson(Map<String, dynamic> json, String uid) {
    return CourierApplicationModel(
      uid:             uid,
      fullName:        json['fullName']        as String? ?? '',
      email:           json['email']           as String? ?? '',
      phone:           json['phone']           as String? ?? '',
      area:            json['area']            as String? ?? '',
      ktpImageUrl:     json['ktpImageUrl']     as String? ?? '',
      simImageUrl:     json['simImageUrl']     as String? ?? '',
      agreedTerms:     json['agreedTerms']     as bool?   ?? false,
      status:          json['status']          as String? ?? 'pending',
      submittedAt:     json['submittedAt']     as String? ?? '',
      rejectionReason: json['rejectionReason'] as String?,
      reviewedAt:      json['reviewedAt']      as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'fullName':    fullName,
    'email':       email,
    'phone':       phone,
    'area':        area,
    'ktpImageUrl': ktpImageUrl,
    'simImageUrl': simImageUrl,
    'agreedTerms': agreedTerms,
    'status':      status,
    'submittedAt': submittedAt,
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
    if (reviewedAt      != null) 'reviewedAt':      reviewedAt,
  };
}
