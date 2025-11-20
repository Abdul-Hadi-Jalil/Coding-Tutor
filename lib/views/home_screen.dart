import 'package:coding_tutor/ads/ads_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'course_level_selection.dart';
import 'navbar_screen.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Preload ads after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final adProvider = context.read<AdProvider>();
        adProvider.preloadAd(AdType.homeAd1, adSize: TemplateType.small);
        adProvider.preloadAd(AdType.homeAd2, adSize: TemplateType.small);
        debugPrint('[HomeScreen] ✅ Ads preload requested');
      } catch (e) {
        debugPrint('[HomeScreen] ⚠️ Ad preload error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Discover {}",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontFamily: "custom",
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        context.read<ThemeProvider>().toggle();
                      },
                      icon: Icon(
                        theme.brightness == Brightness.dark
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: theme.colorScheme.onSurface.withOpacity(0.9),
                        size: 26,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 🔹 Featured Course Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: "Basics of Python with ",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontFamily: "custom",
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(
                              text: "Data Structures",
                              style: TextStyle(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "This is the course to pick if you are just getting into coding.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontFamily: "custom",
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // an ad above available courses
                _buildNativeAd(context, AdType.homeAd1),
                SizedBox(height: 10),

                // 🔹 Available Courses - Use _CourseTile
                _SectionHeader(
                  title: "Available Courses",
                  onSeeAll: () {
                    navBarKey.currentState?.setIndex(2);
                  },
                ),
                const SizedBox(height: 12),

                FutureBuilder<List<Course>>(
                  future: CourseService.loadCourses(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final courses = snapshot.data ?? const <Course>[];
                    final Course empty = Course(
                      id: '',
                      title: '',
                      language: '',
                      description: '',
                      days: const [],
                    );
                    final javaCourse = courses.firstWhere(
                      (c) => c.language.toLowerCase() == 'java',
                      orElse: () => empty,
                    );
                    final pythonCourse = courses.firstWhere(
                      (c) => c.language.toLowerCase() == 'python',
                      orElse: () => empty,
                    );
                    final cppCourse = courses.firstWhere(
                      (c) => c.language.toLowerCase() == 'c++',
                      orElse: () => empty,
                    );

                    final javaLessons = javaCourse.days.length;
                    final pythonLessons = pythonCourse.days.length;
                    final cppLessons = cppCourse.days.length;

                    return Column(
                      children: [
                        _CourseTile(
                          title: "Fun With Java",
                          lessons: javaLessons,
                          price: "\$2,350",
                          icon: Icons.coffee_rounded,
                          ontap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CourseLevelSelectionScreen(
                                      courseTitle: 'Fun With Java',
                                    ),
                              ),
                            );
                          },
                        ),
                        _CourseTile(
                          title: "Understanding Python",
                          lessons: pythonLessons,
                          price: "\$1,350",
                          icon: Icons.javascript_rounded,
                          ontap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CourseLevelSelectionScreen(
                                      courseTitle: 'Understanding Python',
                                    ),
                              ),
                            );
                          },
                        ),
                        _CourseTile(
                          title: "Development with C++",
                          lessons: cppLessons,
                          price: "\$1,850",
                          icon: Icons.code_rounded,
                          ontap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CourseLevelSelectionScreen(
                                      courseTitle: 'Development with C++',
                                    ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 30),

                // 🔹 Trending Courses - Use _TrendingCourseCard (horizontal scroll)
                _SectionHeader(
                  title: "trending courses",
                  onSeeAll: () {
                    navBarKey.currentState?.setIndex(2);
                  },
                ),
                const SizedBox(height: 12),

                FutureBuilder<List<Course>>(
                  future: CourseService.loadCourses(),
                  builder: (context, snapshot) {
                    final courses = snapshot.data ?? const <Course>[];
                    final Course empty = Course(
                      id: '',
                      title: '',
                      language: '',
                      description: '',
                      days: const [],
                    );
                    final javaCourse = courses.firstWhere(
                      (c) => c.language.toLowerCase() == 'java',
                      orElse: () => empty,
                    );
                    final pythonCourse = courses.firstWhere(
                      (c) => c.language.toLowerCase() == 'python',
                      orElse: () => empty,
                    );
                    final cppCourse = courses.firstWhere(
                      (c) => c.language.toLowerCase() == 'c++',
                      orElse: () => empty,
                    );

                    final javaLessons = javaCourse.days.length;
                    final pythonLessons = pythonCourse.days.length;
                    final cppLessons = cppCourse.days.length;

                    return SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          const SizedBox(width: 8),
                          _TrendingCourseCard(
                            title: "Fun With Java",
                            applicants: javaLessons,
                            image: 'assets/images/course1.jpg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CourseLevelSelectionScreen(
                                        courseTitle: 'Fun With Java',
                                      ),
                                ),
                              );
                            },
                          ),
                          _TrendingCourseCard(
                            title: "Understanding Python",
                            applicants: pythonLessons,
                            image: 'assets/images/course2.jpg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CourseLevelSelectionScreen(
                                        courseTitle: 'Understanding Python',
                                      ),
                                ),
                              );
                            },
                          ),
                          _TrendingCourseCard(
                            title: "Development with C++",
                            applicants: cppLessons,
                            image: 'assets/images/course3.jpeg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CourseLevelSelectionScreen(
                                        courseTitle: 'Development with C++',
                                      ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 8),
                // an ad below the trending courses
                _buildNativeAd(context, AdType.homeAd2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNativeAd(BuildContext context, AdType adType) {
    final adProvider = context.watch<AdProvider>();
    final isAdLoaded = adType == AdType.homeAd1
        ? adProvider.isHomeAd1
        : adProvider.isHomeAd2;
    final nativeAd = adType == AdType.homeAd1
        ? adProvider.homeAd1
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontFamily: "custom",
            fontSize: 16,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            "See all >",
            style: TextStyle(
              color: theme.colorScheme.secondary,
              fontFamily: "custom",
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _CourseTile extends StatelessWidget {
  final String title;
  final int lessons;
  final String price;
  final IconData icon;
  final VoidCallback? ontap;

  const _CourseTile({
    required this.title,
    required this.lessons,
    required this.price,
    required this.icon,
    this.ontap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: ontap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.secondary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontFamily: "custom",
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$lessons lessons",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontFamily: "custom",
                      fontSize: 13,
                    ),
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

class _TrendingCourseCard extends StatelessWidget {
  final String title;
  final int applicants;
  final String image;
  final VoidCallback? onTap;

  const _TrendingCourseCard({
    required this.title,
    required this.applicants,
    required this.image,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image on the left
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  image,
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(width: 12),

              // Text content on the right
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontFamily: "custom",
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "$applicants lessons",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontFamily: "custom",
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
