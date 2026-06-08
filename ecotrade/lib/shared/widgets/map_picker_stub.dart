import 'package:flutter/material.dart';

import '../services/geocoding_service.dart';

/// Stub untuk platform non-web (Android/iOS).
/// Tidak akan pernah dipanggil karena map_picker_screen.dart
/// menggunakan kondisi kIsWeb untuk memilih antara WebMapView dan GoogleMap.
class WebMapView extends StatelessWidget {
  const WebMapView({
    super.key,
    required this.lat,
    required this.lng,
    required this.onLocationChanged,
    this.onGeocodeResult,
  });

  final double lat;
  final double lng;
  final void Function(double lat, double lng) onLocationChanged;
  final void Function(MapPickResult result)? onGeocodeResult;

  @override
  Widget build(BuildContext context) {
    // Tidak akan pernah dirender di mobile — placeholder saja
    return const SizedBox.shrink();
  }
}
