import 'package:coding_tutor/ads/ads_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../core/App_theme.dart';
import 'course_detail_screen.dart';
import 'course_topics_screen.dart';

class CourseLevelSelectionScreen extends StatefulWidget {
  final String courseTitle;
  const CourseLevelSelectionScreen({super.key, required this.courseTitle});

  @override
  State<CourseLevelSelectionScreen> createState() =>
      _CourseLevelSelectionScreenState();
}

class _CourseLevelSelectionScreenState
    extends State<CourseLevelSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Preload ads after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final adProvider = context.read<AdProvider>();
        adProvider.preloadAd(
          AdType.discoverPlantAd,
          adSize: TemplateType.small,
        );
        debugPrint('[HomeScreen] ✅ Ads preload requested');
      } catch (e) {
        debugPrint('[HomeScreen] ⚠️ Ad preload error: $e');
      }
    });
  }

  String _beginnerTitleFor(String title) {
    if (title.toLowerCase().contains('java')) {
      return 'Java for Beginners';
    } else if (title.toLowerCase().contains('python')) {
      return 'Python for Beginners';
    } else if (title.toLowerCase().contains('c++') ||
        title.toLowerCase().contains('cpp')) {
      return 'C++ for Beginners'; // Add this line
    }
    return 'Java for Beginners';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Widget levelTile({
      required String label,
      required String subtitle,
      required IconData icon,
      required Color color,
      required bool isLocked,
      required VoidCallback onTap,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [color.withOpacity(0.15), color.withOpacity(0.05)]
                : [color.withOpacity(0.1), color.withOpacity(0.03)],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDark ? 0.2 : 0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: color.withOpacity(0.1),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              label,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                fontFamily: 'custom',
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!isLocked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.secondary.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'FREE',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    fontFamily: 'custom',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                            height: 1.4,
                            fontFamily: 'custom',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isLocked ? Icons.lock : Icons.play_arrow,
                                    size: 14,
                                    color: color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isLocked ? 'COMING SOON' : 'START LEARNING',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      fontFamily: 'custom',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color.withOpacity(0.7),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withOpacity(isDark ? 0.15 : 0.1),
                    colorScheme.secondary.withOpacity(isDark ? 0.08 : 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: colorScheme.onSurface,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose Your Level',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      fontFamily: 'custom',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.courseTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'custom',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select your experience level. Beginner level is completely free to start your learning journey!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      height: 1.5,
                      fontFamily: 'custom',
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Levels List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Beginner Level
                      levelTile(
                        label: 'Beginner',
                        subtitle:
                            'Perfect for starters. Learn fundamentals, basic syntax, and build your first programs.',
                        icon: Icons.rocket_launch_outlined,
                        color: AppColors.primary,
                        isLocked: false,
                        onTap: () {
                          final beginnerTitle = _beginnerTitleFor(
                            widget.courseTitle,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseTopicsScreen(
                                courseTitle: beginnerTitle,
                              ),
                            ),
                          );
                        },
                      ),

                      // ad to show
                      _buildNativeAd(context, AdType.discoverPlantAd),

                      // Intermediate Level
                      levelTile(
                        label: 'Intermediate',
                        subtitle:
                            'Dive deeper into concepts, design patterns, and build more complex applications.',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.secondary,
                        isLocked: true,
                        onTap: () {
                          _showPremiumDialog(
                            context,
                            'Intermediate',
                            AppColors.secondary,
                          );
                        },
                      ),

                      // Advanced Level
                      levelTile(
                        label: 'Advanced',
                        subtitle:
                            'Master advanced topics, work on real-world projects, and become an expert.',
                        icon: Icons.star_outline_rounded,
                        color: AppColors.primary.withOpacity(0.8),
                        isLocked: true,
                        onTap: () {
                          _showPremiumDialog(
                            context,
                            'Advanced',
                            AppColors.primary.withOpacity(0.8),
                          );
                        },
                      ),

                      // Info Card
                      Container(
                        margin: const EdgeInsets.only(top: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'More levels coming soon! Stay tuned for updates.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.8),
                                  fontFamily: 'custom',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumDialog(BuildContext context, String level, Color color) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 2),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: color,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '$level Level',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'custom',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Premium Content',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                  fontFamily: 'custom',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'The $level level is part of our premium offering. Unlock advanced content, projects, and expert guidance.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'custom',
                  height: 1.5,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'Maybe Later',
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(fontFamily: 'custom'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$level level purchase coming soon!',
                              style: const TextStyle(fontFamily: 'custom'),
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Get Premium',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontFamily: 'custom',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNativeAd(BuildContext context, AdType adType) {
    final adProvider = context.watch<AdProvider>();
    final isAdLoaded = adType == AdType.discoverPlantAd
        ? adProvider.isYVideoPageAd1
        : adProvider.isHomeAd2;
    final nativeAd = adType == AdType.discoverPlantAd
        ? adProvider.discoverPlantAd
        : adProvider.homeAd2;

    if (!isAdLoaded || nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AdWidget(ad: nativeAd),
      ),
    );
  }
}
