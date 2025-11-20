import 'package:coding_tutor/responsive/responsive.dart';
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
        final completedDays = List<int>.from(
          entry.value['completedDays'] ?? const [],
        );
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
            fontSize: context.responsive.fontSize(22),
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
    Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: context.responsive.padding(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                _ProfileHeader(user: user),

                SizedBox(height: context.responsive.spacing(AppSpacing.xxl)),

                _StatsOverview(
                  loadingStats: loadingStats,
                  computedPoints: computedPoints,
                  computedLessons: computedLessons,
                  activeCourses: activeCourses,
                  lessonsByCourse: lessonsByCourse,
                  pointsByCourse: pointsByCourse,
                  activeCourseTitles: activeCourseTitles,
                ),

                SizedBox(height: context.responsive.spacing(AppSpacing.xxl)),
                _ActionsSection(onSignOut: onSignOut),
              ],
            ),
          ),
        );
      },
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
    final displayName = user.name.isNotEmpty
        ? user.name
        : (user.email.isNotEmpty ? user.email.split('@').first : 'Learner');

    // ------------------------ ADDED FOR RESPONSIVENESS ------------------------
    final screenWidth = MediaQuery.of(
      context,
    ).size.width; // dynamic screen width
    final scaling = screenWidth / 400; // base scale factor
    // --------------------------------------------------------------------------

    return LayoutBuilder(
      builder: (context, constraints) {
        final avatarSize = 80 * scaling.clamp(0.7, 1.4); // responsive avatar
        final padding = 24 * scaling.clamp(0.6, 1.2); // responsive padding
        final spacing = 20 * scaling.clamp(0.6, 1.2); // responsive spacing
        // ----------------------------------------------------------------------

        return Container(
          padding: EdgeInsets.all(padding), // changed to dynamic padding
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
            border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: avatarSize, // dynamic
                height: avatarSize, // dynamic
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
                    width: 2 * scaling.clamp(0.7, 1.3), // dynamic border width
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials(displayName),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize:
                          (theme.textTheme.headlineSmall!.fontSize ?? 24) *
                          scaling.clamp(0.8, 1.3), // responsive font
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'custom',
                    ),
                  ),
                ),
              ),

              SizedBox(width: spacing), // dynamic spacing
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize:
                            (theme.textTheme.titleLarge!.fontSize ?? 20) *
                            scaling.clamp(0.85, 1.3), // responsive font
                        fontWeight: FontWeight.bold,
                        fontFamily: 'custom',
                      ),
                    ),
                    SizedBox(height: 6 * scaling), // dynamic spacing
                    Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize:
                            (theme.textTheme.bodyMedium!.fontSize ?? 14) *
                            scaling.clamp(0.85, 1.3), // responsive font
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontFamily: 'custom',
                      ),
                    ),
                    SizedBox(height: 10 * scaling), // dynamic spacing

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12 * scaling.clamp(0.7, 1.2),
                        vertical: 6 * scaling.clamp(0.7, 1.2),
                      ), // dynamic padding
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          12 * scaling.clamp(0.7, 1.2),
                        ), // dynamic radius
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.2),
                          width: scaling.clamp(0.7, 1.2), // dynamic border
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 14 * scaling.clamp(0.8, 1.3), // responsive
                            color: colorScheme.primary,
                          ),
                          SizedBox(width: 6 * scaling),
                          Text(
                            user.provider ?? 'email',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize:
                                  (theme.textTheme.labelSmall!.fontSize ?? 12) *
                                  scaling.clamp(0.85, 1.3),
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
      },
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
    final width = MediaQuery.of(context).size.width; // 📌 ADDED: screen width
    final scale = (width / 400).clamp(0.75, 1.4); // 📌 ADDED: responsive scale

    return LayoutBuilder(
      // 📌 ADDED LayoutBuilder
      builder: (context, constraints) {
        final gridCount = width < 500
            ? 2
            : width < 900
            ? 3
            : 4; // 📌 Dynamic grid count

        final gridAspect = width < 500
            ? 1.1
            : 0.9; // 📌 Responsive aspect ratio

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learning Statistics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize:
                    (theme.textTheme.titleLarge?.fontSize ?? 22) *
                    scale, // 📌 Dynamic font
                fontFamily: 'custom',
              ),
            ),

            SizedBox(height: 16 * scale), // 📌 Responsive spacing

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: gridCount, // 📌 Responsive grid
              crossAxisSpacing: 12 * scale, // 📌 Responsive spacing
              mainAxisSpacing: 12 * scale, // 📌 Responsive spacing
              childAspectRatio: gridAspect, // 📌 Responsive card shape
              children: [
                _StatCard(
                  value: loadingStats ? '...' : computedPoints.toString(),
                  label: 'Points',
                  icon: Icons.emoji_events_rounded,
                  color: Colors.amber,
                  onTap: loadingStats
                      ? null
                      : () => _showPointsBreakdown(context),
                ),
                _StatCard(
                  value: loadingStats ? '...' : computedLessons.toString(),
                  label: 'Lessons',
                  icon: Icons.menu_book_rounded,
                  color: Colors.green,
                  onTap: loadingStats
                      ? null
                      : () => _showLessonsBreakdown(context),
                ),
                _StatCard(
                  value: loadingStats ? '...' : activeCourses.toString(),
                  label: 'Courses',
                  icon: Icons.library_books_rounded,
                  color: Colors.blue,
                  onTap: loadingStats
                      ? null
                      : () => _showCoursesBreakdown(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ⬇ breakdown sheets remain unchanged (UI scales automatically from Theme + device width)
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
    final width = MediaQuery.of(
      context,
    ).size.width; // 📌 for scaling bottom sheet
    final scale = (width / 400).clamp(0.7, 1.4); // 📌 added

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24 * scale), // 📌 responsive padding
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
                        fontSize:
                            (theme.textTheme.titleLarge?.fontSize ?? 22) *
                            scale, // 📌 responsive font
                        fontFamily: 'custom',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 22 * scale, // 📌 responsive icon
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              SizedBox(height: 8 * scale),
              Text(
                'Courses you are currently following',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize:
                      (theme.textTheme.bodyMedium?.fontSize ?? 14) * scale,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontFamily: 'custom',
                ),
              ),
              SizedBox(height: 20 * scale),

              if (activeCourseTitles.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.library_books_outlined,
                        size: 48 * scale, // 📌 responsive icon
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      SizedBox(height: 12 * scale),
                      Text(
                        'No active courses yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize:
                              (theme.textTheme.bodyMedium?.fontSize ?? 14) *
                              scale,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontFamily: 'custom',
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...activeCourseTitles.map(
                  (course) => Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 8 * scale,
                    ), // 📌 responsive
                    child: Row(
                      children: [
                        Icon(
                          Icons.play_circle_filled_rounded,
                          size: 16 * scale, // 📌 responsive icon
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 12 * scale),
                        Expanded(
                          child: Text(
                            course,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize:
                                  (theme.textTheme.bodyMedium?.fontSize ?? 14) *
                                  scale,
                              fontFamily: 'custom',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 20 * scale),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Close',
                    style: TextStyle(fontSize: 16 * scale), // 📌 responsive
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

    // ---------------------- ADDED FOR RESPONSIVENESS ----------------------
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 400).clamp(0.75, 1.4); // dynamic scaling
    // ----------------------------------------------------------------------

    Widget card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16 * scale), // responsive radius
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10 * scale, // responsive shadow blur
            offset: Offset(0, 4 * scale), // responsive shadow offset
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1 * scale, // responsive border size
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * scale), // responsive padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40 * scale, // responsive size
              height: 30 * scale, // responsive size
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20 * scale, // responsive icon size
              ),
            ),
            SizedBox(height: 12 * scale), // responsive spacing
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize:
                    (theme.textTheme.headlineSmall?.fontSize ?? 22) *
                    scale, // responsive font
                fontWeight: FontWeight.bold,
                fontFamily: 'custom',
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 4 * scale), // responsive spacing
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: (theme.textTheme.labelMedium?.fontSize ?? 14) * scale,
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
          borderRadius: BorderRadius.circular(16 * scale), // responsive radius
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // 🔥 Scaling factors for phone ↔ tablet
        final isTablet = width > 600;
        final scale = isTablet ? 1.35 : 1.0;

        // dynamic paddings
        final horizontalPadding = 16 * scale;
        final verticalPadding = 16 * scale;

        // text + icon scale
        final titleSize = (theme.textTheme.titleLarge?.fontSize ?? 22) * scale;
        final subtitleSize =
            (theme.textTheme.bodyMedium?.fontSize ?? 14) * scale;

        final iconSize = 48 * scale;
        final cardPadding = 16 * scale;
        final chipPaddingV = 6 * scale;
        final chipPaddingH = 12 * scale;

        final sortedItems = items.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'custom',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 24 * scale),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                SizedBox(height: 4 * scale),

                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: subtitleSize,
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontFamily: 'custom',
                  ),
                ),

                SizedBox(height: 20 * scale),

                /// EMPTY STATE
                if (sortedItems.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          isPoints
                              ? Icons.emoji_events_outlined
                              : Icons.menu_book_outlined,
                          size: iconSize,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                        SizedBox(height: 12 * scale),
                        Text(
                          isPoints
                              ? 'No points yet'
                              : 'No lessons completed yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: subtitleSize,
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontFamily: 'custom',
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...sortedItems.map(
                    (entry) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 8 * scale),
                      child: Container(
                        padding: EdgeInsets.all(cardPadding),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12 * scale),
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
                                  fontSize: subtitleSize,
                                  fontFamily: 'custom',
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: chipPaddingH,
                                vertical: chipPaddingV,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8 * scale),
                              ),
                              child: Text(
                                '${entry.value} ${isPoints ? 'pts' : 'lessons'}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: subtitleSize,
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'custom',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: 20 * scale),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: TextStyle(fontSize: subtitleSize),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HelpSupportSheet extends StatelessWidget {
  const _HelpSupportSheet();

  static final Uri _faqUrl = Uri.parse(
    'https://vectorlabzlimited.com/terms-of-use/',
  );
  static final Uri _privacyUrl = Uri.parse(
    'https://vectorlabzlimited.com/privacy-policy/',
  );
  static final Uri _bugUrl = Uri.parse(
    'https://vectorlabzlimited.com/terms-of-use/',
  );
  static final Uri _supportEmail = Uri.parse(
    'https://vectorlabzlimited.com/privacy-policy/',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = width > 600 ? 1.35 : 1.0;

        final horizontalPadding = 16 * scale;
        final verticalPadding = 16 * scale;
        final titleSize = (theme.textTheme.titleLarge?.fontSize ?? 22) * scale;
        final subtitleSize =
            (theme.textTheme.bodyMedium?.fontSize ?? 14) * scale;
        final iconSize = 24 * scale;
        final borderRadius = 12 * scale;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Help & Support',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'custom',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 24 * scale),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                SizedBox(height: 8 * scale),

                // Card Container
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildTile(
                        context,
                        icon: Icons.question_mark_rounded,
                        title: 'FAQs',
                        subtitle: 'Common questions and answers',
                        uri: _faqUrl,
                        scale: scale,
                        titleSize: subtitleSize,
                        subtitleSize: subtitleSize * 0.9,
                        iconSize: iconSize,
                      ),
                      Divider(height: 1),
                      _buildTile(
                        context,
                        icon: Icons.email_rounded,
                        title: 'Contact Support',
                        subtitle: 'Email our support team',
                        uri: _supportEmail,
                        scale: scale,
                        titleSize: subtitleSize,
                        subtitleSize: subtitleSize * 0.9,
                        iconSize: iconSize,
                      ),
                      Divider(height: 1),
                      _buildTile(
                        context,
                        icon: Icons.bug_report_rounded,
                        title: 'Report a Bug',
                        subtitle: 'Tell us about an issue',
                        uri: _bugUrl,
                        scale: scale,
                        titleSize: subtitleSize,
                        subtitleSize: subtitleSize * 0.9,
                        iconSize: iconSize,
                      ),
                      Divider(height: 1),
                      _buildTile(
                        context,
                        icon: Icons.privacy_tip_rounded,
                        title: 'Privacy Policy',
                        subtitle: 'Read how we handle data',
                        uri: _privacyUrl,
                        scale: scale,
                        titleSize: subtitleSize,
                        subtitleSize: subtitleSize * 0.9,
                        iconSize: iconSize,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Uri uri,
    required double scale,
    required double titleSize,
    required double subtitleSize,
    required double iconSize,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, size: iconSize),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: titleSize,
          fontFamily: 'custom',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: subtitleSize,
          fontFamily: 'custom',
        ),
      ),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!ok) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Unable to open link')),
            );
          }
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('Failed to open: $e')));
        }
      },
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
      messenger.showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = width > 600 ? 1.35 : 1.0; // scale for tablet vs phone

        final horizontalPadding = 24 * scale;
        final verticalPadding = 24 * scale;
        final spacingSmall = 12 * scale;
        final spacingLarge = 20 * scale;
        final titleSize = (theme.textTheme.titleLarge?.fontSize ?? 22) * scale;
        final bodySize = (theme.textTheme.bodyMedium?.fontSize ?? 14) * scale;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              top: verticalPadding,
              bottom:
                  MediaQuery.of(context).viewInsets.bottom + verticalPadding,
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
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'custom',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 24 * scale),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: spacingSmall),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                  style: TextStyle(fontSize: bodySize),
                ),
                SizedBox(height: spacingSmall),
                Text(
                  user?.email ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: bodySize,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontFamily: 'custom',
                  ),
                ),
                SizedBox(height: spacingLarge),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? SizedBox(
                            height: 20 * scale,
                            width: 20 * scale,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Save Changes',
                            style: TextStyle(fontSize: bodySize),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = width > 600 ? 1.35 : 1.0; // phone vs tablet

        final paddingAll = 24 * scale;
        final spacing = 8 * scale;
        final titleSize = (theme.textTheme.titleLarge?.fontSize ?? 22) * scale;
        final subtitleSize =
            (theme.textTheme.bodyMedium?.fontSize ?? 14) * scale;
        final iconSize = 24 * scale;
        final borderRadius = 12 * scale;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(paddingAll),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Settings',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'custom',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: iconSize),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                // Card Container
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: isDark,
                        title: Text(
                          'Dark Mode',
                          style: TextStyle(
                            fontSize: subtitleSize,
                            fontFamily: 'custom',
                          ),
                        ),
                        subtitle: Text(
                          'Toggle application theme',
                          style: TextStyle(
                            fontSize: subtitleSize * 0.9,
                            fontFamily: 'custom',
                          ),
                        ),
                        onChanged: (_) =>
                            context.read<ThemeProvider>().toggle(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = width > 600 ? 1.5 : 1.0; // tablet vs phone

        final indicatorSize = 60 * scale;
        final spacing = 20 * scale;
        final textSize = (theme.textTheme.bodyLarge?.fontSize ?? 16) * scale;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: indicatorSize,
                height: indicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: 3 * scale,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(height: spacing),
              Text(
                'Loading your profile...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: textSize,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontFamily: 'custom',
                ),
              ),
            ],
          ),
        );
      },
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

    final width = MediaQuery.of(context).size.width;
    final scale = (width / 400).clamp(0.75, 1.4); // responsive scale

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize:
                (theme.textTheme.titleLarge?.fontSize ?? 22) * scale, // scaled
            fontWeight: FontWeight.bold,
            fontFamily: 'custom',
          ),
        ),
        SizedBox(height: 16 * scale), // scaled spacing
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16 * scale), // scaled radius
            border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _ActionTile(
                icon: Icons.person_rounded,
                label: 'Edit Profile',
                color: colorScheme.primary,
                scale: scale, // pass scale
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24 * scale), // scaled radius
                      ),
                    ),
                    builder: (ctx) => const _EditProfileSheet(),
                  );
                },
              ),
              Divider(height: 1),
              _ActionTile(
                icon: Icons.settings_rounded,
                label: 'Settings',
                color: colorScheme.secondary,
                scale: scale,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24 * scale),
                      ),
                    ),
                    builder: (ctx) => const _SettingsSheet(),
                  );
                },
              ),
              Divider(height: 1),
              _ActionTile(
                icon: Icons.help_rounded,
                label: 'Help & Support',
                color: Colors.orange,
                scale: scale,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24 * scale),
                      ),
                    ),
                    builder: (ctx) => const _HelpSupportSheet(),
                  );
                },
              ),
              Divider(height: 1),
              _ActionTile(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                color: colorScheme.error,
                scale: scale,
                onTap: onSignOut,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double scale;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.scale = 1.0, // default scale
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final padding = 16 * scale;
    final iconContainerSize = 40 * scale;
    final iconSize = 20 * scale;
    final spacing = 16 * scale;
    final arrowSize = 16 * scale;
    final borderRadius = 16 * scale;
    final textSize = (theme.textTheme.bodyMedium?.fontSize ?? 14) * scale;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: EdgeInsets.all(padding),
          child: Row(
            children: [
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: textSize,
                    fontFamily: 'custom',
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: arrowSize,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
