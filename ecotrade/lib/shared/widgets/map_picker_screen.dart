import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/geocoding_service.dart';

// Conditional import: web menggunakan HtmlElementView, mobile menggunakan stub kosong
import 'map_picker_stub.dart'
    if (dart.library.html) 'map_picker_web_impl.dart' as web_impl;

/// Screen fullscreen untuk memilih lokasi di Google Maps.
///
/// Mengembalikan [MapPickResult] jika user mengkonfirmasi lokasi.
/// Mengembalikan null jika user membatalkan.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  final double? initialLat;
  final double? initialLng;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // Default: Surabaya (atau lokasi sebelumnya jika ada)
  static const double _defaultLat = -7.2575;
  static const double _defaultLng = 112.7521;

  late double _lat;
  late double _lng;

  MapPickResult? _geocodeResult;
  bool _isLoadingGeocode = false;
  bool _isLoadingGps = false;

  // Controller untuk mobile (native)
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLat ?? _defaultLat;
    _lng = widget.initialLng ?? _defaultLng;
    _markers = {
      Marker(
        markerId: const MarkerId('selected'),
        position: LatLng(_lat, _lng),
        draggable: true,
        onDragEnd: _onMarkerDragEnd,
      ),
    };
    // Lakukan geocoding awal
    _reverseGeocode(_lat, _lng);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onMarkerDragEnd(LatLng pos) {
    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: pos,
          draggable: true,
          onDragEnd: _onMarkerDragEnd,
        ),
      };
    });
    _debounceGeocode(pos.latitude, pos.longitude);
  }

  void _onMapTap(LatLng pos) {
    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: pos,
          draggable: true,
          onDragEnd: _onMarkerDragEnd,
        ),
      };
    });
    _debounceGeocode(pos.latitude, pos.longitude);
  }

  void _debounceGeocode(double lat, double lng) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      _reverseGeocode(lat, lng);
    });
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() => _isLoadingGeocode = true);
    final result = await GeocodingService.reverseGeocode(lat, lng);
    if (mounted) {
      setState(() {
        _geocodeResult = result;
        _isLoadingGeocode = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Layanan lokasi tidak aktif. Aktifkan GPS terlebih dahulu.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Izin lokasi ditolak.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Izin lokasi ditolak permanen. Aktifkan di pengaturan.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _markers = {
          Marker(
            markerId: const MarkerId('selected'),
            position: LatLng(_lat, _lng),
            draggable: true,
            onDragEnd: _onMarkerDragEnd,
          ),
        };
      });

      final ctrl = await _mapController.future;
      ctrl.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(_lat, _lng), zoom: 17),
        ),
      );
      _reverseGeocode(_lat, _lng);
    } catch (e) {
      _showSnack('Gagal mendapatkan lokasi: $e');
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  bool _isConfirming = false;

  Future<void> _confirm() async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);

    // Tunggu geocoding selesai (maks 6 detik)
    if (_isLoadingGeocode) {
      int waited = 0;
      while (_isLoadingGeocode && waited < 60) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited++;
      }
    }

    if (!mounted) return;

    if (_geocodeResult != null) {
      Navigator.of(context).pop(_geocodeResult);
    } else {
      Navigator.of(context).pop(
        MapPickResult(lat: _lat, lng: _lng, detail: '', city: '', postalCode: ''),
      );
    }
    if (mounted) setState(() => _isConfirming = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // ── Peta ─────────────────────────────────────────────────────────────
          if (kIsWeb)
            web_impl.WebMapView(
              lat: _lat,
              lng: _lng,
              onLocationChanged: (lat, lng) {
                setState(() {
                  _lat = lat;
                  _lng = lng;
                  // Reset hasil lama saat lokasi berubah
                  _geocodeResult = null;
                  _isLoadingGeocode = true;
                });
              },
              // Gunakan JS Geocoder untuk web — tidak ada CORS / API restriction
              onGeocodeResult: (result) {
                if (mounted) {
                  setState(() {
                    _geocodeResult = result;
                    _isLoadingGeocode = false;
                  });
                }
              },
            )
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_lat, _lng),
                zoom: 16,
              ),
              markers: _markers,
              onMapCreated: (ctrl) => _mapController.complete(ctrl),
              onTap: _onMapTap,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
            ),

          // ── AppBar transparan ─────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _GlassButton(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          '📍 Pilih Lokasi Alamat',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tombol GPS — aktif di mobile DAN web
                    _GlassButton(
                      onTap: _useCurrentLocation,
                      tooltip: 'Gunakan lokasi saat ini',
                      child: _isLoadingGps
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(
                              Icons.my_location_rounded,
                              size: 20,
                              color: cs.primary,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Crosshair tengah (hanya web — mobile pakai marker) ────────────
          if (kIsWeb)
            const Center(
              child: Icon(Icons.location_pin, size: 48, color: Color(0xFFE53935)),
            ),

          // ── Card preview & tombol konfirmasi (bawah) ─────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomConfirmCard(
              geocodeResult: _geocodeResult,
              isLoading: _isLoadingGeocode,
              isConfirming: _isConfirming,
              onConfirm: _confirm,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget helper: Tombol kaca (AppBar)
// ─────────────────────────────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.onTap,
    required this.child,
    this.tooltip,
  });

  final VoidCallback? onTap;
  final Widget child;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Card preview alamat + tombol konfirmasi
// ─────────────────────────────────────────────────────────────────────────────
class _BottomConfirmCard extends StatelessWidget {
  const _BottomConfirmCard({
    required this.geocodeResult,
    required this.isLoading,
    required this.isConfirming,
    required this.onConfirm,
  });

  final MapPickResult? geocodeResult;
  final bool isLoading;
  final bool isConfirming;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Instruksi
          Text(
            'Tap atau geser marker untuk memilih lokasi',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),

          // Preview alamat
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
            ),
            child: isLoading
                ? Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Mencari alamat...',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontSize: 13),
                      ),
                    ],
                  )
                : geocodeResult != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  size: 16, color: cs.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Lokasi Dipilih',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: cs.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (geocodeResult!.detail.isNotEmpty)
                            Text(
                              geocodeResult!.detail,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          if (geocodeResult!.city.isNotEmpty ||
                              geocodeResult!.postalCode.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (geocodeResult!.city.isNotEmpty)
                                  geocodeResult!.city,
                                if (geocodeResult!.postalCode.isNotEmpty)
                                  geocodeResult!.postalCode,
                              ].join(', '),
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '${geocodeResult!.lat.toStringAsFixed(5)}, ${geocodeResult!.lng.toStringAsFixed(5)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.4),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Pilih titik lokasi pada peta',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.4),
                            fontSize: 13),
                      ),
          ),

          const SizedBox(height: 16),

          // Tombol konfirmasi
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (isLoading || isConfirming) ? null : onConfirm,
              icon: (isLoading || isConfirming)
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: Text(
                isLoading
                    ? 'Mencari alamat...'
                    : isConfirming
                        ? 'Memproses...'
                        : 'Gunakan Lokasi Ini',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                backgroundColor: (isLoading || isConfirming)
                    ? const Color(0xFF27AE60).withValues(alpha: 0.6)
                    : const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    const Color(0xFF27AE60).withValues(alpha: 0.6),
                disabledForegroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
