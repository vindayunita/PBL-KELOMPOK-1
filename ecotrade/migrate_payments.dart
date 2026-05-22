import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'lib/core/firebase/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final db = FirebaseFirestore.instance;
  final ordersSnap = await db.collection('orders').get();
  
  print('Found ${ordersSnap.docs.length} orders. Migrating to payments...');
  
  final batch = db.batch();
  int count = 0;
  
  for (final doc in ordersSnap.docs) {
    final data = doc.data();
    final orderId = data['orderId'] ?? doc.id;
    final paymentProofUrl = data['paymentProofUrl'] ?? '';
    if (paymentProofUrl.isEmpty) continue; // Skip orders without payment proof
    
    final paymentRef = db.collection('payments').doc();
    String status = data['status'] ?? 'pending';
    
    // Convert order status to payment status
    String paymentStatus = 'pending';
    if (status == 'verified' || status == 'processing' || status == 'completed' || status == 'shipped' || status == 'picked_up') {
      paymentStatus = 'verified';
    } else if (status == 'rejected' || status == 'cancelled') {
      paymentStatus = 'rejected';
    }

    batch.set(paymentRef, {
      'paymentId': paymentRef.id,
      'orderId': orderId,
      'buyerId': data['buyerId'] ?? '',
      'buyerName': data['buyerName'] ?? '',
      'total': data['total'] ?? 0.0,
      'paymentProofUrl': paymentProofUrl,
      'status': paymentStatus,
      'paymentMethod': data['paymentMethod'] ?? 'bank_transfer',
      'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
      if (paymentStatus == 'verified' && data['verifiedAt'] != null)
        'verifiedAt': data['verifiedAt'],
      if (paymentStatus == 'rejected' && data['rejectedAt'] != null)
        'rejectedAt': data['rejectedAt'],
      if (paymentStatus == 'rejected' && data['rejectionReason'] != null)
        'rejectionReason': data['rejectionReason'],
    });
    count++;
  }
  
  if (count > 0) {
    await batch.commit();
    print('Successfully migrated $count payments!');
  } else {
    print('No payments to migrate.');
  }
}
