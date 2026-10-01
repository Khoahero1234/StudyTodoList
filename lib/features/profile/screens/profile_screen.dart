// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundDark,
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.white30,
                        child: Text(
                          (user?.username ?? 'U')[0].toUpperCase(),
                          style: AppTextStyles.headlineLarge
                              .copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user?.username ?? 'User',
                        style: AppTextStyles.titleLarge
                            .copyWith(color: Colors.white),
                      ),
                      Text(
                        user?.email ?? '',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _ProfileStat(
                        value: '${user?.currentStreak ?? 0}',
                        label: 'Day Streak',
                        icon: Icons.local_fire_department_rounded,
                        color: const Color(0xFFFF6B35),
                      ),
                    ),
                    Expanded(
                      child: _ProfileStat(
                        value: '${user?.tokenBalance ?? 0}',
                        label: 'Tokens',
                        icon: Icons.monetization_on_rounded,
                        color: AppColors.gold,
                      ),
                    ),
                    Expanded(
                      child: _ProfileStat(
                        value: user?.isPremium == true ? '⭐' : 'Free',
                        label: 'Plan',
                        icon: Icons.workspace_premium_rounded,
                        color: AppColors.priorityUrgent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Premium upgrade card
                if (user?.isPremium != true) ...[
                  _PremiumCard(onTap: () => context.push(AppRoutes.premium)),
                  const SizedBox(height: 20),
                ],

                // Menu items
                _MenuSection(
                  title: 'Account',
                  items: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Edit Profile',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.lock_outline_rounded,
                      label: 'Change Password',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _MenuSection(
                  title: 'Features',
                  items: [
                    _MenuItem(
                      icon: Icons.pets_rounded,
                      label: 'Virtual Pet',
                      onTap: () => context.push(AppRoutes.pet),
                    ),
                    _MenuItem(
                      icon: Icons.backpack_rounded,
                      label: 'Inventory',
                      onTap: () => context.push(AppRoutes.inventory),
                    ),
                    _MenuItem(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Wallet & Tokens',
                      onTap: () => context.push(AppRoutes.wallet),
                    ),
                    _MenuItem(
                      icon: Icons.school_rounded,
                      label: 'Study Rooms',
                      onTap: () => context.push(AppRoutes.studyRooms),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _MenuSection(
                  title: 'Support',
                  items: [
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & FAQ',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Logout
                AppButton(
                  label: 'Sign Out',
                  variant: AppButtonVariant.danger,
                  prefixIcon: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 18),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surfaceDark,
                        title: Text('Sign Out',
                            style: AppTextStyles.titleMedium),
                        content: Text(
                          'Are you sure you want to sign out?',
                          style: AppTextStyles.bodyMedium,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await ref.read(authProvider.notifier).logout();
                    }
                  },
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _ProfileStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.titleMedium,
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.premiumGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Premium ⭐',
                    style: AppTextStyles.titleSmall
                        .copyWith(color: Colors.white),
                  ),
                  Text(
                    'Unlock AI features, study rooms, and more',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            children: items
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        e.value,
                        if (e.key < items.length - 1)
                          const Divider(
                            color: AppColors.borderDark,
                            height: 1,
                            indent: 52,
                          ),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing:
          trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
