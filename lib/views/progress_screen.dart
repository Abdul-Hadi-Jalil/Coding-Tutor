import 'package:flutter/material.dart';
import '../core/App_theme.dart';
import '../controllers/course_controller.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';
import 'course_topics_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final CourseController _controller = CourseController();
  bool _loading = true;
  List<Course> _courses = [];
  final Map<String, Map<String, dynamic>> _progressByCourse = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Load all available courses (e.g., Java and Python)
    final courses = await CourseService.loadCourses();
    // Collect progress for each course
    for (final course in courses) {
      final progress = await _controller.getProgress(course.title);
      _progressByCourse[course.title] = progress;
    }
    setState(() {
      _courses = courses;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Your Progress',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'custom',
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: ListView.builder(
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  final progress = _progressByCourse[course.title] ?? const {
                    'completedDays': <int>[],
                    'currentDay': 0,
                  };
                  final completedDays = List<int>.from(progress['completedDays'] ?? []);
                  final currentDay = (progress['currentDay'] ?? 0) as int;
                  final totalDays = course.days.length;
                  final percentage = totalDays > 0
                      ? (completedDays.length / totalDays).clamp(0.0, 1.0)
                      : 0.0;

                  return _ProgressCard(
                    title: course.title,
                    subtitle: '${completedDays.length}/$totalDays topics completed',
                    percentage: percentage,
                    accentColor: colorScheme.primary,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: theme.scaffoldBackgroundColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (_) {
                          return _ProgressDetailSheet(
                            course: course,
                            completedDays: completedDays,
                            currentDay: currentDay,
                            percentage: percentage,
                            accentColor: colorScheme.primary,
                          );
                        },
                      );
                    },
                    currentDay: currentDay,
                  );
                },
              ),
            ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double percentage;
  final Color accentColor;
  final VoidCallback onTap;
  final int currentDay;

  const _ProgressCard({
    required this.title,
    required this.subtitle,
    required this.percentage,
    required this.accentColor,
    required this.onTap,
    required this.currentDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  accentColor.withValues(alpha: 0.12),
                  accentColor.withValues(alpha: 0.05),
                ]
              : [
                  accentColor.withValues(alpha: 0.08),
                  accentColor.withValues(alpha: 0.03),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: accentColor.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.insights_rounded, color: accentColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'custom',
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontFamily: 'custom',
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 8,
                          backgroundColor: colorScheme.surface.withValues(alpha: 0.6),
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_rounded, size: 16, color: AppColors.secondary),
                      const SizedBox(width: 6),
                      Text(
                        'Day $currentDay',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'custom',
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
    );
  }
}

class _ProgressDetailSheet extends StatelessWidget {
  final Course course;
  final List<int> completedDays;
  final int currentDay;
  final double percentage;
  final Color accentColor;

  const _ProgressDetailSheet({
    required this.course,
    required this.completedDays,
    required this.currentDay,
    required this.percentage,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalDays = course.days.length;
    final completedCount = completedDays.length;
    final remaining = (totalDays - completedCount).clamp(0, totalDays);

    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      course.title,
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
              Text(
                'Progress Overview',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontFamily: 'custom',
                ),
              ),
      
              const SizedBox(height: 20),
      
              // Donut Progress
              Row(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(140, 140),
                          painter: _DonutProgressPainter(
                            percentage: percentage,
                            color: accentColor,
                            backgroundColor: colorScheme.surface.withValues(alpha: 0.3),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(percentage * 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'custom',
                              ),
                            ),
                            Text(
                              'Complete',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                                fontFamily: 'custom',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
      
                  const SizedBox(width: 16),
      
                  // Stats
                  Expanded(
                    child: Column(
                      children: [
                        _StatTile(
                          label: 'Completed',
                          value: '$completedCount/$totalDays',
                          color: accentColor,
                        ),
                        const SizedBox(height: 10),
                        _StatTile(
                          label: 'Remaining',
                          value: '$remaining',
                          color: AppColors.secondary,
                        ),
                        const SizedBox(height: 10),
                        _StatTile(
                          label: 'Current Day',
                          value: '$currentDay',
                          color: colorScheme.tertiaryContainer,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      
              const SizedBox(height: 24),
      
              // Segmented progress by topic/day
              Text(
                'Topics Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'custom',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final day in course.days)
                    _DayChip(
                      dayNumber: day.day,
                      label: 'Day ${day.day}',
                      isCompleted: completedDays.contains(day.day),
                      accentColor: accentColor,
                      onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (_) => CourseTopicsScreen(courseTitle: course.title),
                        //   ),
                        // );
                      },
                    ),
                ],
              ),
      
              const SizedBox(height: 24),
      
              // Action: View Topics
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseTopicsScreen(courseTitle: course.title),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt_rounded),
                  label: const Text('View Topics'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [color.withValues(alpha: 0.18), color.withValues(alpha: 0.07)]
              : [color.withValues(alpha: 0.12), color.withValues(alpha: 0.05)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontFamily: 'custom',
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontFamily: 'custom',
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final int dayNumber;
  final String label;
  final bool isCompleted;
  final Color accentColor;
  final VoidCallback onTap;

  const _DayChip({
    required this.dayNumber,
    required this.label,
    required this.isCompleted,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color base = isCompleted ? AppColors.secondary : accentColor;
    final Color fg = isCompleted ? Colors.white : base;
    final Color bg = isCompleted
        ? base.withOpacity(0.8)
        : base.withOpacity(0.12);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive width based on screen size
        final double chipWidth = constraints.maxWidth * 0.23; // 25% of parent width
        final double minWidth = 70;
        final double maxWidth = 110;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: chipWidth.clamp(minWidth, maxWidth), // keeps it responsive yet bounded
            height: 40, // fixed height for consistent design
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: base.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.circle,
                  size: 16,
                  color: fg,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isCompleted ? Colors.white : colorScheme.onSurface,
                      fontFamily: 'custom',
                      fontSize: 12,
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


class _DonutProgressPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;

  _DonutProgressPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    const stroke = 12.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    // Background circle
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    final sweep = 2 * 3.1415926535 * percentage;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -3.1415926535 / 2; // start at top
    canvas.drawArc(rect, startAngle, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}