import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../providers/theme_provider.dart';
import 'auth_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _computedLessons = 0;
  int _computedPoints = 0;
  int _activeCourses = 0;
  bool _loadingStats = true;
  String? _lastUid;
  Map<String, int> _lessonsByCourse = {};
  Map<String, int> _pointsByCourse = {};
  List<String> _activeCourseTitles = [];

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return '';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _loadComputedStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadComputedStats();
  }

  Future<void> _loadComputedStats() async {
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      setState(() {
        _activeCourses = 0;
        _computedLessons = 0;
        _computedPoints = 0;
        _loadingStats = false;
      });
      return;
    }

    if (_lastUid == firebaseUser.uid && !_loadingStats) {
      return;
    }
    _lastUid = firebaseUser.uid;

    final fs = FirestoreService();
    try {
      final all = await fs.getAllCourseProgress(firebaseUser.uid);
      int lessons = 0;
      final Map<String, int> byCourseLessons = {};
      final Map<String, int> byCoursePoints = {};

      for (final map in all.values) {
        final completedDays = List<int>.from(map['completedDays'] ?? const []);
        final count = completedDays.length;
        lessons += count;
      }

      for (final entry in all.entries) {
        final title = entry.key;
        final completedDays = List<int>.from(entry.value['completedDays'] ?? const []);
        final count = completedDays.length;
        byCourseLessons[title] = count;
        byCoursePoints[title] = count * 5;
      }

      setState(() {
        _activeCourses = all.length;
        _computedLessons = lessons;
        _computedPoints = lessons * 5;
        _activeCourseTitles = all.keys.toList();
        _lessonsByCourse = byCourseLessons;
        _pointsByCourse = byCoursePoints;
        _loadingStats = false;
      });
    } catch (e) {
      setState(() {
        _activeCourses = 0;
        _computedLessons = 0;
        _computedPoints = 0;
        _activeCourseTitles = [];
        _lessonsByCourse = {};
        _pointsByCourse = {};
        _loadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'custom',
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
      ),
      body: user == null
          ? const _LoadingState()
          : _ProfileContent(
        user: user,
        loadingStats: _loadingStats,
        computedPoints: _computedPoints,
        computedLessons: _computedLessons,
        activeCourses: _activeCourses,
        lessonsByCourse: _lessonsByCourse,
        pointsByCourse: _pointsByCourse,
        activeCourseTitles: _activeCourseTitles,
        onSignOut: () => _handleSignOut(context),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthProvider>().signOut();
      if (!mounted) return;
      // Navigate to the AuthWrapper and clear the navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Sign out failed: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _ProfileContent extends StatelessWidget {
  final dynamic user;
  final bool loadingStats;
  final int computedPoints;
  final int computedLessons;
  final int activeCourses;
  final Map<String, int> lessonsByCourse;
  final Map<String, int> pointsByCourse;
  final List<String> activeCourseTitles;
  final VoidCallback onSignOut;

  const _ProfileContent({
    required this.user,
    required this.loadingStats,
    required this.computedPoints,
    required this.computedLessons,
    required this.activeCourses,
    required this.lessonsByCourse,
    required this.pointsByCourse,
    required this.activeCourseTitles,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header
          _ProfileHeader(user: user),

          const SizedBox(height: 32),

          // Stats Overview
          _StatsOverview(
            loadingStats: loadingStats,
            computedPoints: computedPoints,
            computedLessons: computedLessons,
            activeCourses: activeCourses,
            lessonsByCourse: lessonsByCourse,
            pointsByCourse: pointsByCourse,
            activeCourseTitles: activeCourseTitles,
          ),

          const SizedBox(height: 32),

          // Actions Section
          _ActionsSection(
            onSignOut: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic user;

  const _ProfileHeader({required this.user});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return '';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayName = user.name.isNotEmpty ? user.name : (user.email.isNotEmpty ? user.email.split('@').first : 'Learner');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.15),
            colorScheme.secondary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withOpacity(0.2),
                  colorScheme.secondary.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _initials(displayName),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'custom',
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'custom',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontFamily: 'custom',
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.provider ?? 'email',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'custom',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsOverview extends StatelessWidget {
  final bool loadingStats;
  final int computedPoints;
  final int computedLessons;
  final int activeCourses;
  final Map<String, int> lessonsByCourse;
  final Map<String, int> pointsByCourse;
  final List<String> activeCourseTitles;

  const _StatsOverview({
    required this.loadingStats,
    required this.computedPoints,
    required this.computedLessons,
    required this.activeCourses,
    required this.lessonsByCourse,
    required this.pointsByCourse,
    required this.activeCourseTitles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning Statistics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'custom',
          ),
        ),
        const SizedBox(height: 16),

        // Stats Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
          children: [
            _StatCard(
              value: loadingStats ? '...' : computedPoints.toString(),
              label: 'Points',
              icon: Icons.emoji_events_rounded,
              color: Colors.amber,
              onTap: loadingStats ? null : () => _showPointsBreakdown(context),
            ),
            _StatCard(
              value: loadingStats ? '...' : computedLessons.toString(),
              label: 'Lessons',
              icon: Icons.menu_book_rounded,
              color: Colors.green,
              onTap: loadingStats ? null : () => _showLessonsBreakdown(context),
            ),
            _StatCard(
              value: loadingStats ? '...' : activeCourses.toString(),
              label: 'Courses',
              icon: Icons.library_books_rounded,
              color: Colors.blue,
              onTap: loadingStats ? null : () => _showCoursesBreakdown(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showPointsBreakdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _BreakdownSheet(
        title: 'Points Breakdown',
        subtitle: '5 points per completed lesson',
        items: pointsByCourse,
        isPoints: true,
      ),
    );
  }

  void _showLessonsBreakdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _BreakdownSheet(
        title: 'Lessons Breakdown',
        subtitle: 'Completed lessons by course',
        items: lessonsByCourse,
        isPoints: false,
      ),
    );
  }

  void _showCoursesBreakdown(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Active Courses',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'custom',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Courses you are currently following',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontFamily: 'custom',
                ),
              ),
              const SizedBox(height: 20),
              if (activeCourseTitles.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.library_books_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No active courses yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontFamily: 'custom',
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...activeCourseTitles
                    .map((course) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_circle_filled_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          course,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'custom',
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
                    .toList(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'custom',
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontFamily: 'custom',
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      );
    }

    return card;
  }
}

class _BreakdownSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final Map<String, int> items;
  final bool isPoints;

  const _BreakdownSheet({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.isPoints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sortedItems = items.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'custom',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontFamily: 'custom',
              ),
            ),
            const SizedBox(height: 20),
            if (sortedItems.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      isPoints ? Icons.emoji_events_outlined : Icons.menu_book_outlined,
                      size: 48,
                      color: colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPoints ? 'No points yet' : 'No lessons completed yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: 'custom',
                      ),
                    ),
                  ],
                ),
              )
            else
              ...sortedItems.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'custom',
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${entry.value} ${isPoints ? 'pts' : 'lessons'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'custom',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  final VoidCallback onSignOut;

  const _ActionsSection({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'custom',
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              _ActionTile(
                icon: Icons.person_rounded,
                label: 'Edit Profile',
                color: colorScheme.primary,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (ctx) => const _EditProfileSheet(),
                  );
                },
              ),
              const Divider(height: 1),
              _ActionTile(
                icon: Icons.settings_rounded,
                label: 'Settings',
                color: colorScheme.secondary,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (ctx) => const _SettingsSheet(),
                  );
                },
              ),
              const Divider(height: 1),
              _ActionTile(
                icon: Icons.help_rounded,
                label: 'Help & Support',
                color: Colors.orange,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (ctx) => const _HelpSupportSheet(),
                  );
                },
              ),
              const Divider(height: 1),
              _ActionTile(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                color: colorScheme.error,
                onTap: onSignOut,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HelpSupportSheet extends StatelessWidget {
  const _HelpSupportSheet();

  static final Uri _faqUrl = Uri.parse('https://vectorlabzlimited.com/terms-of-use/');
  static final Uri _privacyUrl = Uri.parse('https://vectorlabzlimited.com/privacy-policy/');
  static final Uri _bugUrl = Uri.parse('https://vectorlabzlimited.com/terms-of-use/');
  static final Uri _supportEmail = Uri.parse('https://vectorlabzlimited.com/privacy-policy/');

  Future<void> _openUri(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        messenger.showSnackBar(const SnackBar(content: Text('Unable to open link')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to open: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Help & Support',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'custom',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.question_mark_rounded),
                    title: const Text('FAQs'),
                    subtitle: const Text('Common questions and answers'),
                    onTap: () => _openUri(context, _faqUrl),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.email_rounded),
                    title: const Text('Contact Support'),
                    subtitle: const Text('Email our support team'),
                    onTap: () => _openUri(context, _supportEmail),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bug_report_rounded),
                    title: const Text('Report a Bug'),
                    subtitle: const Text('Tell us about an issue'),
                    onTap: () => _openUri(context, _bugUrl),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_rounded),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('Read how we handle data'),
                    onTap: () => _openUri(context, _privacyUrl),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.userModel;
    _nameController.text = user?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    final user = auth.userModel;
    if (user == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Not signed in')));
      return;
    }

    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = user.copyWith(name: newName);
      await FirestoreService().updateUserProfile(updated);
      auth.userModel = updated;
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit Profile',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'custom',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.email ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontFamily: 'custom',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.mode == ThemeMode.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Settings',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'custom',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: isDark,
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Toggle application theme'),
                    onChanged: (_) => context.read<ThemeProvider>().toggle(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'custom',
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading your profile...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontFamily: 'custom',
            ),
          ),
        ],
      ),
    );
  }
}