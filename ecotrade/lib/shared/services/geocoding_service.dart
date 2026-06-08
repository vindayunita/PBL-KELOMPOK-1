import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Hasil reverse geocoding yang akan dipakai untuk auto-fill form alamat.
class MapPickResult {
  final double lat;
  final double lng;
  final String detail;      // Detail jalan + kelurahan/kecamatan
  final String city;        // Kota / Kabupaten
  final String postalCode;  // Kode pos

  const MapPickResult({
    required this.lat,
    required this.lng,
    required this.detail,
    required this.city,
    required this.postalCode,
  });

  @override
  String toString() =>
      'MapPickResult(lat: $lat, lng: $lng, detail: $detail, city: $city, postalCode: $postalCode)';
}


/// Service untuk reverse geocoding: koordinat (lat, lng) → komponen alamat teks.
/// Mendukung alamat Indonesia dengan parsing yang robust:
///   - route + street_number
///   - neighborhood / sublocality / administrative_area_level_4 (Kelurahan)
///   - administrative_area_level_3 (Kecamatan)
///   - Fallback: strip kota/provinsi/negara dari formatted_address
class GeocodingService {
  // Dibaca dari .env — tidak pernah hardcoded di source code
  static String get _apiKey => dotenv.env['MAPS_API_KEY'] ?? '';
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  /// Mengubah koordinat menjadi komponen alamat.
  static Future<MapPickResult> reverseGeocode(double lat, double lng) async {
    final uri = Uri.parse('$_baseUrl?latlng=$lat,$lng&key=$_apiKey&language=id');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return MapPickResult(lat: lat, lng: lng, detail: '', city: '', postalCode: '');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final status = body['status'] as String?;

      if (status != 'OK') {
        return MapPickResult(lat: lat, lng: lng, detail: '', city: '', postalCode: '');
      }

      final results = body['results'] as List<dynamic>;
      if (results.isEmpty) {
        return MapPickResult(lat: lat, lng: lng, detail: '', city: '', postalCode: '');
      }

      // Gunakan result pertama (paling granular)
      final firstResult = results.first as Map<String, dynamic>;
      final components  = firstResult['address_components'] as List<dynamic>;
      final formatted   = firstResult['formatted_address'] as String? ?? '';

      // ── Kumpulkan komponen ────────────────────────────────────────────────
      String streetNumber = '';
      String route        = '';
      String neighborhood = '';
      String sublocality  = '';
      String adminLv4     = ''; // Kelurahan
      String adminLv3     = ''; // Kecamatan
      String city         = '';
      String province     = '';
      String country      = '';
      String postalCode   = '';

      for (final comp in components) {
        final types    = List<String>.from(comp['types'] as List);
        final longName = comp['long_name'] as String? ?? '';

        if (types.contains('street_number'))               streetNumber = longName;
        if (types.contains('route'))                       route        = longName;
        if (types.contains('neighborhood'))                neighborhood = longName;
        if (types.contains('sublocality_level_1') ||
            types.contains('sublocality'))                 sublocality  = longName;
        if (types.contains('administrative_area_level_4')) adminLv4     = longName;
        if (types.contains('administrative_area_level_3')) adminLv3     = longName;
        if (types.contains('administrative_area_level_2') ||
            types.contains('locality')) {
          // Level 2 lebih spesifik → prioritas
          if (city.isEmpty || types.contains('administrative_area_level_2')) {
            city = longName;
          }
        }
        if (types.contains('administrative_area_level_1')) province  = longName;
        if (types.contains('country'))                     country   = longName;
        if (types.contains('postal_code'))                 postalCode = longName;
      }

      // ── Bangun detail dari komponen ───────────────────────────────────────
      final parts = <String>[];

      // 1. Nama jalan + nomor
      if (route.isNotEmpty) {
        parts.add(streetNumber.isNotEmpty ? '$route No. $streetNumber' : route);
      }

      // 2. Kelurahan / Neighborhood (pilih yang tersedia, hindari duplikat)
      final kelurahan = sublocality.isNotEmpty
          ? sublocality
          : (adminLv4.isNotEmpty ? adminLv4 : neighborhood);
      if (kelurahan.isNotEmpty) parts.add(kelurahan);

      // 3. Kecamatan
      if (adminLv3.isNotEmpty) parts.add('Kec. $adminLv3');

      String detail = parts.join(', ');

      // ── Fallback 1: strip kota/prov/negara dari formatted_address ─────────
      // formatted: "Jl. X No.1, Kelurahan, Kecamatan, Kota, Prov XXXXX, Indonesia"
      if (detail.isEmpty && formatted.isNotEmpty) {
        detail = _stripSuffixFromFormatted(
          formatted,
          city: city,
          province: province,
          country: country,
        );
      }

      // ── Fallback 2: 3 segmen pertama formatted_address ────────────────────
      if (detail.isEmpty && formatted.isNotEmpty) {
        final segs = formatted.split(',');
        detail = segs.take(segs.length < 3 ? segs.length : 3).join(',').trim();
      }

      return MapPickResult(
        lat: lat,
        lng: lng,
        detail: detail,
        city: city,
        postalCode: postalCode,
      );
    } catch (_) {
      return MapPickResult(lat: lat, lng: lng, detail: '', city: '', postalCode: '');
    }
  }

  /// Menghapus bagian kota, provinsi, kode pos, dan negara dari
  /// [formatted] agar tersisa bagian detail jalan/kelurahan saja.
  ///
  /// Contoh:
  ///   Input:  "Jl. Merdeka No.1, Keputih, Sukolilo, Surabaya, Jawa Timur 60111, Indonesia"
  ///   Output: "Jl. Merdeka No.1, Keputih, Sukolilo"
  static String _stripSuffixFromFormatted(
    String formatted, {
    required String city,
    required String province,
    required String country,
  }) {
    // Hapus ", [Negara]" di akhir
    String result = formatted;
    if (country.isNotEmpty) {
      result = result.replaceAll(
          RegExp(',?\\s*${RegExp.escape(country)}\$'), '');
    }

    // Hapus kode pos (4-6 digit angka, termasuk spasi sebelumnya)
    result = result.replaceAll(RegExp(r'\s*\d{4,6}'), '');

    // Hapus ", [Provinsi]"
    if (province.isNotEmpty) {
      result = result.replaceAll(
          RegExp(',?\\s*${RegExp.escape(province)}'), '');
    }

    // Hapus ", [Kota/Kab]" — sering ada "Kota X" atau "Kabupaten X"
    if (city.isNotEmpty) {
      result = result.replaceAll(
          RegExp(',?\\s*${RegExp.escape(city)}'), '');
      // Coba juga tanpa prefix "Kota"/"Kabupaten"
      final bareCity = city
          .replaceFirst(RegExp(r'^(Kota|Kabupaten|Kab\.)\s*', caseSensitive: false), '');
      if (bareCity != city) {
        result = result.replaceAll(
            RegExp(',?\\s*${RegExp.escape(bareCity)}'), '');
      }
    }

    // Bersihkan sisa koma ganda / leading-trailing
    result = result
        .replaceAll(RegExp(r',\s*,+'), ',')
        .replaceAll(RegExp(r'^[,\s]+'), '')
        .replaceAll(RegExp(r'[,\s]+$'), '')
        .trim();

    return result;
  }
}
