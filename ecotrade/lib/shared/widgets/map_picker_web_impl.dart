// Web-only implementation of the map view.
// Uses HtmlElementView + Google Maps JS API + JS Geocoder via dart:js interop.
// This file is ONLY compiled when targeting web (dart.library.html).

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

import '../services/geocoding_service.dart';

/// Implementasi view peta untuk platform Web menggunakan HtmlElementView
/// dan Google Maps JavaScript API via JS interop.
class WebMapView extends StatefulWidget {
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
  State<WebMapView> createState() => _WebMapViewState();
}

class _WebMapViewState extends State<WebMapView> {
  late final String _viewId;
  Timer? _coordPollTimer;
  Timer? _geocodePollTimer;
  double _lastLat = 0;
  double _lastLng = 0;
  bool _mapInitialized = false;
  int _initAttempts = 0;

  @override
  void initState() {
    super.initState();
    _viewId = 'ecotrade-map-${math.Random().nextInt(1000000)}';
    _lastLat = widget.lat;
    _lastLng = widget.lng;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final div = html.DivElement()
          ..id = _viewId
          ..style.width = '100%'
          ..style.height = '100%';

        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          _tryInitMap();
        });

        return div;
      },
    );
  }

  void _tryInitMap() {
    if (!mounted || _mapInitialized || _initAttempts > 12) return;
    _initAttempts++;
    try {
      js.context.callMethod('initEcoTradeMap', [
        _viewId,
        widget.lat,
        widget.lng,
      ]);
      _mapInitialized = true;
      _startCoordPolling();
      _startGeocodePolling();
    } catch (_) {
      Future.delayed(const Duration(milliseconds: 500), _tryInitMap);
    }
  }

  // Poll koordinat setiap 500ms
  void _startCoordPolling() {
    _coordPollTimer?.cancel();
    _coordPollTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted || !_mapInitialized) return;
      try {
        final coordsJson =
            js.context.callMethod('getMapCoordinates', [_viewId]) as String?;
        if (coordsJson == null || coordsJson.isEmpty) return;

        final latMatch = RegExp(r'"lat"\s*:\s*([\-\d.]+)').firstMatch(coordsJson);
        final lngMatch = RegExp(r'"lng"\s*:\s*([\-\d.]+)').firstMatch(coordsJson);
        final lat = double.tryParse(latMatch?.group(1) ?? '');
        final lng = double.tryParse(lngMatch?.group(1) ?? '');

        if (lat != null && lng != null) {
          if ((lat - _lastLat).abs() > 0.000005 ||
              (lng - _lastLng).abs() > 0.000005) {
            _lastLat = lat;
            _lastLng = lng;
            widget.onLocationChanged(lat, lng);
          }
        }
      } catch (_) {}
    });
  }

  // Poll hasil geocoding dari JS Geocoder
  void _startGeocodePolling() {
    _geocodePollTimer?.cancel();
    _geocodePollTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted || widget.onGeocodeResult == null) return;
      try {
        // Cek apakah geocoding sedang berjalan
        final isLoading = js.context.callMethod('isGeocoding', []) as bool? ?? false;
        if (isLoading) return; // Masih loading

        final resultJson = js.context.callMethod('getLastGeocode', []) as String?;
        if (resultJson == null || resultJson.isEmpty) return;

        // Parse dan kirim ke Dart, lalu reset agar tidak terkirim ulang
        final parsed = _parseGeocodeResult(resultJson);
        if (parsed != null) {
          // Reset JS cache agar tidak dipanggil ulang
          js.context['_lastGeocode'] = null;
          widget.onGeocodeResult!(parsed);
        }
      } catch (_) {}
    });
  }

  MapPickResult? _parseGeocodeResult(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final formatted = data['formatted_address'] as String? ?? '';
      final components = data['address_components'] as List<dynamic>? ?? [];

      String streetNumber = '';
      String route        = '';
      String neighborhood = '';
      String sublocality  = '';
      String adminLv4     = '';
      String adminLv3     = '';
      String city         = '';
      String province     = '';
      String country      = '';
      String postalCode   = '';

      for (final comp in components) {
        final types    = List<String>.from(comp['types'] as List? ?? []);
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
          if (city.isEmpty || types.contains('administrative_area_level_2')) {
            city = longName;
          }
        }
        if (types.contains('administrative_area_level_1')) province  = longName;
        if (types.contains('country'))                     country   = longName;
        if (types.contains('postal_code'))                 postalCode = longName;
      }

      // Bangun detail alamat
      final parts = <String>[];
      if (route.isNotEmpty) {
        parts.add(streetNumber.isNotEmpty ? '$route No. $streetNumber' : route);
      }
      final kelurahan = sublocality.isNotEmpty
          ? sublocality
          : (adminLv4.isNotEmpty ? adminLv4 : neighborhood);
      if (kelurahan.isNotEmpty) parts.add(kelurahan);
      if (adminLv3.isNotEmpty) parts.add('Kec. $adminLv3');

      String detail = parts.join(', ');

      // Fallback: strip kota/prov/negara dari formatted_address
      if (detail.isEmpty && formatted.isNotEmpty) {
        detail = _stripFormatted(formatted, city: city, province: province, country: country);
      }
      if (detail.isEmpty && formatted.isNotEmpty) {
        final segs = formatted.split(',');
        detail = segs.take(segs.length < 3 ? segs.length : 3).join(',').trim();
      }

      return MapPickResult(
        lat: _lastLat,
        lng: _lastLng,
        detail: detail,
        city: city,
        postalCode: postalCode,
      );
    } catch (_) {
      return null;
    }
  }

  String _stripFormatted(String formatted,
      {required String city, required String province, required String country}) {
    String result = formatted;
    if (country.isNotEmpty) {
      result = result.replaceAll(RegExp(',?\\s*${RegExp.escape(country)}\$'), '');
    }
    result = result.replaceAll(RegExp(r'\s*\d{4,6}'), '');
    if (province.isNotEmpty) {
      result = result.replaceAll(RegExp(',?\\s*${RegExp.escape(province)}'), '');
    }
    if (city.isNotEmpty) {
      result = result.replaceAll(RegExp(',?\\s*${RegExp.escape(city)}'), '');
      final bareCity = city.replaceFirst(
          RegExp(r'^(Kota|Kabupaten|Kab\.)\s*', caseSensitive: false), '');
      if (bareCity != city) {
        result = result.replaceAll(RegExp(',?\\s*${RegExp.escape(bareCity)}'), '');
      }
    }
    return result
        .replaceAll(RegExp(r',\s*,+'), ',')
        .replaceAll(RegExp(r'^[,\s]+'), '')
        .replaceAll(RegExp(r'[,\s]+$'), '')
        .trim();
  }

  @override
  void dispose() {
    _coordPollTimer?.cancel();
    _geocodePollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
