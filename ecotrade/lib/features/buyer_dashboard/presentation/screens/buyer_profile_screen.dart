import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/user/domain/user_providers.dart';
import '../../../../features/seller_registration/domain/models/seller_application_model.dart';
import '../../../../features/seller_registration/domain/seller_application_providers.dart';
import '../../../../features/seller_registration/presentation/screens/seller_registration_screen.dart';
import '../../../courier_dashboard/domain/courier_application_providers.dart';
import '../../../courier_dashboard/domain/models/courier_application_model.dart';
import '../../../courier_dashboard/presentation/screens/courier_pendaftaran.dart';
import '../../../courier_dashboard/presentation/screens/courier_status_verif.dart';
import 'edit_profile_screen.dart';
import 'manage_address_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Profile Screen
// ─────────────────────────────────────────────────────────────────────────────
class BuyerProfileScreen extends ConsumerWidget {
  const BuyerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync  = ref.watch(currentUserDocProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme  = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: colorScheme.surfaceContainerLowest,
          elevation: 0,
          floating: true,
          snap: true,
          automaticallyImplyLeading: false,
          title: Text(
            'Profil Saya',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: userAsync.when(
            loading: () => const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error: $e'),
              ),
            ),
            data: (user) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 28),

                  // Avatar
                  _ProfileAvatar(
                    photoUrl:    user?.photoUrl,
                    displayName: user?.name ?? 'User',
                  ),

                  const SizedBox(height: 16),

                  // Name
                  Text(
                    user?.name ?? 'User',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Email
                  Text(
                    user?.email ?? '',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),

                  if (user?.phoneNumber != null) ...[  
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.45)),
                        const SizedBox(width: 4),
                        Text(
                          user!.phoneNumber!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Role badges
                  if (user != null) _RoleBadges(roles: user.roles, activeRole: user.activeRole),

                  const SizedBox(height: 32),

                  // Alamat summary
                  if (user != null && user.addresses.isNotEmpty) ...[  
                    _AddressSummaryCard(
                      count: user.addresses.length,
                      defaultAddr: user.addresses
                          .where((a) => a['isDefault'] == true)
                          .firstOrNull,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ManageAddressScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Menu card
                  _MenuCard(items: [
                    _MenuItem(
                      icon: Icons.edit_outlined,
                      iconBgColor: const Color(0xFFDDE8FF),
                      iconColor: const Color(0xFF4A7AFF),
                      label: 'Edit Profil',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const EditProfileScreen()),
                      ),
                      isFirst: true,
                    ),
                    _MenuItem(
                      icon: Icons.location_on_outlined,
                      iconBgColor: const Color(0xFFD4F5E2),
                      iconColor: const Color(0xFF27AE60),
                      label: 'Manage Addresses',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ManageAddressScreen()),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.history_rounded,
                      iconBgColor: const Color(0xFFD4F5E2),
                      iconColor: const Color(0xFF27AE60),
                      label: 'Purchase History',
                      onTap: () {},
                      isLast: true,
                    ),
                  ]),

                  const SizedBox(height: 20),

                  _ExpandImpactBanner(
                    appAsync: ref.watch(mySellerApplicationProvider),
                    courierAppAsync: ref.watch(myCourierApplicationProvider),
                  ),

                  const SizedBox(height: 20),

                  _LogoutButton(
                    onTap: () async =>
                        ref.read(authRepositoryProvider).signOut(),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role Badges
// ─────────────────────────────────────────────────────────────────────────────
class _RoleBadges extends StatelessWidget {
  const _RoleBadges({required this.roles, required this.activeRole});
  final List<String> roles;
  final String activeRole;

  Color _colorFor(String role) {
    switch (role) {
      case 'seller': return const Color(0xFF27AE60);
      case 'kurir':  return const Color(0xFFE67E22);
      case 'admin':  return const Color(0xFF8E44AD);
      default:       return const Color(0xFF4A7AFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: roles.map((role) {
        final isActive = role == activeRole;
        final color = _colorFor(role);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: isActive
                ? null
                : Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive)
                Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                ),
              Text(
                role.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : color,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Address Summary Card (ditampilkan di profil jika ada alamat)
// ─────────────────────────────────────────────────────────────────────────────
class _AddressSummaryCard extends StatelessWidget {
  const _AddressSummaryCard({
    required this.count,
    required this.defaultAddr,
    required this.onTap,
  });
  final int count;
  final Map<String, dynamic>? defaultAddr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final detail = defaultAddr?['detail'] as String? ?? '';
    final city   = defaultAddr?['city']   as String? ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.04),
              blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on_outlined,
                  color: Color(0xFF27AE60), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count Alamat Tersimpan',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: cs.onSurface),
                  ),
                  if (detail.isNotEmpty)
                    Text(
                      [detail, if (city.isNotEmpty) city].join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.35), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar with gradient border + verified badge
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar(
      {required this.photoUrl, required this.displayName});

  final String? photoUrl;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(

      width: 120,
      height: 120,
      child: Stack(
        children: [
          // Gradient border
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF27AE60), Color(0xFF1565C0)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: photoUrl != null
                    ? Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _AvatarFallback(displayName: displayName),
                      )
                    : _AvatarFallback(displayName: displayName),
              ),
            ),
          ),

          // Verified badge
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF27AE60),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.verified_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.displayName});
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu card
// ─────────────────────────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(18) : Radius.zero,
            bottom: isLast ? const Radius.circular(18) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon box
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                // Label
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                // Chevron
                Icon(Icons.chevron_right_rounded,
                    color: colorScheme.onSurface.withOpacity(0.35),
                    size: 22),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            indent: 72,
            endIndent: 16,
            color: colorScheme.outline.withOpacity(0.12),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expand Your Impact Banner — reaktif berdasarkan status aplikasi seller
// ─────────────────────────────────────────────────────────────────────────────
class _ExpandImpactBanner extends ConsumerWidget {
  const _ExpandImpactBanner({
    required this.appAsync,
    required this.courierAppAsync,
  });
  final AsyncValue<SellerApplicationModel?> appAsync;
  final AsyncValue<CourierApplicationModel?> courierAppAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = appAsync.value;
    final courierApp = courierAppAsync.value;
    final isSeller  = app?.isApproved == true;
    final isCourier = courierApp?.isApproved == true;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF1A7FD4)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Expand Your Impact',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            'Bergabunglah sebagai seller atau kurir terverifikasi untuk mulai berdagang di ekosistem EcoTrade.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),

          const SizedBox(height: 16),

          // ── SELLER BUTTON — berubah sesuai status ──
          if (isSeller)
            // Approved → Pindah ke Dashboard Seller
            _SellerDoneButton(
              onTap: () {
                // TODO: switch activeRole to 'seller' lalu navigate
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur switch dashboard dalam pengembangan'),
                  ),
                );
              },
            )
          else if (app?.isPending == true)
            // Pending → tombol disabled
            const _PendingButton()
          else if (app?.isRejected == true)
            // Rejected → bisa daftar ulang
            _RejectedButton(
              reason: app!.rejectionReason ?? '',
              onTap: () {
                // Blokir jika sudah menjadi Courier aktif
                if (isCourier) {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Tidak Dapat Mendaftar',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      content: const Text(
                        'Akun Anda sudah terdaftar sebagai Kurir aktif. '
                        'Satu akun tidak dapat menjadi Kurir dan Seller secara bersamaan.',
                        style: TextStyle(height: 1.5),
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Mengerti'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SellerRegistrationScreen()));
              },
            )
          else
            // Null / belum apply → tombol register
            _BannerOutlineButton(
              label: 'REGISTER AS SELLER',
              onTap: () {
                // Blokir jika sudah menjadi Courier aktif
                if (isCourier) {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Tidak Dapat Mendaftar',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      content: const Text(
                        'Akun Anda sudah terdaftar sebagai Kurir aktif. '
                        'Satu akun tidak dapat menjadi Kurir dan Seller secara bersamaan.',
                        style: TextStyle(height: 1.5),
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Mengerti'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SellerRegistrationScreen()));
              },
            ),

          const SizedBox(height: 10),

          // ── COURIER BUTTON — berubah sesuai status ──
          if (isCourier)
            // Approved → Pindah ke Dashboard Kurir
            _CourierDoneButton(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CourierStatusVerifScreen(),
                ),
              ),
            )
          else if (courierApp?.isPending == true)
            // Pending → tombol disabled
            const _CourierPendingButton()
          else if (courierApp?.isRejected == true)
            // Rejected → lihat status & alasan penolakan
            _CourierRejectedButton(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CourierStatusVerifScreen(),
                ),
              ),
            )
          else
            // Null / belum apply → tombol register
            _BannerOutlineButton(
              label: 'REGISTER AS COURIER',
              onTap: () {
                // Blokir jika sudah menjadi Seller aktif
                if (isSeller) {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Tidak Dapat Mendaftar',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      content: const Text(
                        'Akun Anda sudah terdaftar sebagai Seller aktif. '
                        'Satu akun tidak dapat menjadi Kurir dan Seller secara bersamaan.',
                        style: TextStyle(height: 1.5),
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Mengerti'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CourierPendaftaranScreen(),
                ));
              },
            ),

          const SizedBox(height: 14),

          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white54, size: 14),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Pendaftaran perlu persetujuan admin sebelum aktif',
                  style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Status Buttons ────────────────────────────────────────────────────────────

class _SellerDoneButton extends StatelessWidget {
  const _SellerDoneButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.storefront_rounded, size: 18),
        label: const Text(
          'PINDAH KE DASHBOARD SELLER',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF27AE60),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
    );
  }
}

class _PendingButton extends StatelessWidget {
  const _PendingButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.6)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.orange),
          ),
          SizedBox(width: 10),
          Text(
            'MENUNGGU PERSETUJUAN ADMIN',
            style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class _RejectedButton extends StatelessWidget {
  const _RejectedButton({required this.reason, required this.onTap});
  final String reason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reason.isNotEmpty) ...[  
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cancel_outlined,
                    color: Colors.redAccent, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ditolak: $reason',
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text(
              'DAFTAR ULANG SEBAGAI SELLER',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerOutlineButton extends StatelessWidget {
  const _BannerOutlineButton(
      {required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white54, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Courier-specific Status Buttons
// ─────────────────────────────────────────────────────────────────────────────

class _CourierDoneButton extends StatelessWidget {
  const _CourierDoneButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.local_shipping_rounded, size: 18),
        label: const Text(
          'PINDAH KE DASHBOARD KURIR',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
    );
  }
}

class _CourierPendingButton extends StatelessWidget {
  const _CourierPendingButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.6)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
          ),
          SizedBox(width: 10),
          Text(
            'KURIR: MENUNGGU PERSETUJUAN',
            style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class _CourierRejectedButton extends StatelessWidget {
  const _CourierRejectedButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text(
          'DAFTAR ULANG SEBAGAI KURIR',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout Button
// ─────────────────────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.logout_rounded, color: colorScheme.error, size: 20),
        label: Text(
          'Logout',
          style: TextStyle(
            color: colorScheme.error,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
              color: colorScheme.error.withOpacity(0.35), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
