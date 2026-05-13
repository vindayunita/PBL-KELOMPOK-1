import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/auth_providers.dart';
import '../../data/courier_application_repository.dart';
import '../../domain/models/courier_application_model.dart';
import 'courier_profil.dart';
import 'courier_riwayat.dart';
import 'courier_tugas.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model (placeholder — swap with real Firestore model later)
// ─────────────────────────────────────────────────────────────────────────────
class _DeliveryTask {
  const _DeliveryTask({
    required this.orderId,
    required this.sellerLocation,
    required this.buyerLocation,
  });
  final String orderId;
  final String sellerLocation;
  final String buyerLocation;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class CourierDashboardScreen extends ConsumerStatefulWidget {
  const CourierDashboardScreen({
    super.key,
    required this.courierId,
    required this.courierName,
  });

  final String courierId;
  final String courierName;

  @override
  ConsumerState<CourierDashboardScreen> createState() =>
      _CourierDashboardScreenState();
}

class _CourierDashboardScreenState
    extends ConsumerState<CourierDashboardScreen> {
  int _selectedIndex = 0;

  // Empty list — akan diganti data Firestore nantinya
  final List<_DeliveryTask> _availableTasks = [];

  @override
  Widget build(BuildContext context) {
    final user      = ref.watch(currentUserProvider);
    final uid       = user?.uid ?? '';
    final appAsync  = uid.isNotEmpty
        ? ref.watch(courierApplicationByUidProvider(uid))
        : const AsyncData<CourierApplicationModel?>(null);
    final isActive  = appAsync.asData?.value?.isActive ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(
            courierName: widget.courierName,
            tasks: _availableTasks,
            isActive: isActive,
          ),
          // Gate: tampilkan layar terkunci jika kurir tidak aktif
          isActive
              ? const CourierTugasScreen()
              : _LockedTugasScreen(
                  onGoToProfile: () =>
                      setState(() => _selectedIndex = 3),
                ),
          const CourierRiwayatScreen(),
          const CourierProfilScreen(),
        ],
      ),
      bottomNavigationBar: _CourierBottomNav(
        selectedIndex: _selectedIndex,
        isActive: isActive,
        onTap: (i) {
          if (i == 1 && !isActive) {
            // Tetap navigate ke tab Tugas, tapi tampil layar terkunci
          }
          setState(() => _selectedIndex = i);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Tab
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.courierName,
    required this.tasks,
    required this.isActive,
  });

  final String courierName;
  final List<_DeliveryTask> tasks;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final firstName = courierName.split(' ').first;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: colorScheme.surfaceContainerLowest,
            floating: true,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.sync_rounded,
                      color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'EcoTrade',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_outlined,
                    color: colorScheme.onSurface),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // ── Hero Banner ──────────────────────────────────────────
                  _HeroBanner(
                    courierName: firstName,
                    taskCount: tasks.length,
                    isActive: isActive,
                  ),

                  const SizedBox(height: 16),

                  // ── Status Banner ─────────────────────────────────────────
                  if (!isActive)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Colors.orange, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Status kamu tidak aktif. Aktifkan di tab Profil untuk mulai menerima tugas.',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                color: Colors.orange.shade800,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // ── Section header ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tugas Pengantaran\nTersedia',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          height: 1.25,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Lihat\nSemua',
                          textAlign: TextAlign.right,
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Task List / Empty State ───────────────────────────────────────
          if (tasks.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: _EmptyTaskState(),
              ),
            )
          else
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = tasks[index];
                    return _TaskCard(
                      task: task,
                      onAccept: () {
                        // TODO: implementasi terima tugas
                      },
                      onReject: () {
                        // TODO: implementasi tolak tugas
                      },
                    );
                  },
                  childCount: tasks.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Banner
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.courierName,
    required this.taskCount,
    required this.isActive,
  });

  final String courierName;
  final int taskCount;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withBlue(
              (colorScheme.primary.blue + 60).clamp(0, 255),
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF10B981)
                        : Colors.white.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  isActive ? 'AKTIF' : 'TIDAK AKTIF',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Halo, $courierName',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            taskCount == 0
                ? 'Belum ada tugas pengantaran\nbaru di sekitarmu.'
                : 'Ada $taskCount tugas pengantaran baru di\nsekitarmu.',
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Locked Tugas Screen (when courier is inactive)
// ─────────────────────────────────────────────────────────────────────────────
class _LockedTugasScreen extends StatelessWidget {
  const _LockedTugasScreen({required this.onGoToProfile});
  final VoidCallback onGoToProfile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 38,
                  color: cs.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Status Tidak Aktif',
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Aktifkan status kurir kamu di halaman Profil untuk mulai menerima dan mengambil tugas pengantaran.',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onGoToProfile,
                icon: const Icon(Icons.person_outline_rounded, size: 18),
                label: const Text(
                  'Ke Halaman Profil',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty Task State (same pattern as admin's _EmptyActivityState)
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyTaskState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              size: 32,
              color: colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak Ada Tugas',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Belum ada tugas pengantaran\nyang tersedia untukmu saat ini.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task Card
// ─────────────────────────────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onAccept,
    required this.onReject,
  });

  final _DeliveryTask task;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID label + value
          Text(
            'ORDER ID',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.45),
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '#${task.orderId}',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 16),

          // Route info
          _RouteRow(
            icon: Icons.store_outlined,
            iconColor: colorScheme.secondary,
            label: 'JEMPUT (SELLER)',
            location: task.sellerLocation,
          ),

          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Container(
              width: 1.5,
              height: 16,
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),

          _RouteRow(
            icon: Icons.location_on_outlined,
            iconColor: colorScheme.primary,
            label: 'TUJUAN (BUYER)',
            location: task.buyerLocation,
          ),

          const SizedBox(height: 18),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(
                        color: colorScheme.outlineVariant, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'TOLAK',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'TERIMA',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Route Row (pickup / destination)
// ─────────────────────────────────────────────────────────────────────────────
class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.location,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String location;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.45),
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              location,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Bottom Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────
class _CourierBottomNav extends StatelessWidget {
  const _CourierBottomNav({
    required this.selectedIndex,
    required this.isActive,
    required this.onTap,
  });

  final int selectedIndex;
  final bool isActive;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationBar(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primaryContainer,
      selectedIndex: selectedIndex,
      onDestinationSelected: onTap,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.local_shipping_outlined),
              if (!isActive)
                Positioned(
                  top: -2,
                  right: -4,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: colorScheme.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          selectedIcon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.local_shipping_rounded),
              if (!isActive)
                Positioned(
                  top: -2,
                  right: -4,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: colorScheme.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          label: 'Tugas',
        ),
        const NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history_rounded),
          label: 'Riwayat',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profil',
        ),
      ],
    );
  }
}
