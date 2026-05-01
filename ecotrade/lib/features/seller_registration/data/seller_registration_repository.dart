import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'seller_registration_repository.g.dart';

@riverpod
SellerRegistrationRepository sellerRegistrationRepository(Ref ref) {
  return SellerRegistrationRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );
}

class SellerRegistrationRepository {
  const SellerRegistrationRepository(this._auth, this._firestore, this._storage);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<void> submitRegistration({
    required String businessName,
    required String address,
    required String commodityType,
    required String commodityDescription,
    required int stock,
    required double pricePerKg,
    File? commodityImage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // 1. Upload image to Firebase Storage (if provided)
    String imageUrl = 'https://via.placeholder.com/400x300.png?text=No+Image';
    
    if (commodityImage != null) {
      try {
        final imageRef = _storage.ref().child(
          'seller_registrations/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await imageRef.putFile(commodityImage);
        imageUrl = await imageRef.getDownloadURL();
      } catch (e) {
        // If Firebase Storage is not enabled, use placeholder
        print('Firebase Storage error: $e. Using placeholder image.');
      }
    }

    // 2. Create registration document in Firestore
    try {
      await _firestore.collection('seller_registrations').add({
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName ?? user.email,
        'businessName': businessName,
        'address': address,
        'commodityType': commodityType,
        'commodityDescription': commodityDescription,
        'stock': stock,
        'pricePerKg': pricePerKg,
        'commodityImageUrl': imageUrl,
        'status': 'pending', // pending, approved, rejected
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception(
          'Permission denied: Firestore rules belum dikonfigurasi. '
          'Silakan update Firestore Security Rules di Firebase Console.',
        );
      }
      rethrow;
    }
  }
}
