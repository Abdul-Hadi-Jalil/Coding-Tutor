import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';
import '../services/firestore_service.dart';

/// Controller for course loading and progress operations
class CourseController {
  final FirestoreService _fs = FirestoreService();

  Future<Course> loadCourseByTitle(String title) async {
    return CourseService.getCourseByTitle(title);
  }

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>> getProgress(String courseTitle) async {
    final user = currentUser;
    if (user == null) return {'completedDays': <int>[], 'currentDay': 0};
    final data = await _fs.getCourseProgress(user.uid, courseTitle);
    return data ?? {'completedDays': <int>[], 'currentDay': 0};
  }

  Future<void> markDayComplete(String courseTitle, int day) async {
    final user = currentUser;
    if (user == null) return;
    await _fs.markDayComplete(user.uid, courseTitle, day);
  }

  /// Compute next day index (0-based) from progress and course days length
  int computeStartingIndex({required Set<int> completedDays, required int totalDays}) {
    if (totalDays <= 0) return 0;
    if (completedDays.isEmpty) return 0;
    final maxCompleted = completedDays.reduce((a, b) => a > b ? a : b);
    final nextDayNumber = (maxCompleted + 1).clamp(1, totalDays);
    return nextDayNumber - 1;
  }
}