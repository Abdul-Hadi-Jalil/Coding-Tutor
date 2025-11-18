import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save or update user profile
  Future<void> saveUserProfile(UserModel user) async {
    debugPrint('[FirestoreService] saveUserProfile(uid=${user.uid}) → begin');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toJson(), SetOptions(merge: true));
    debugPrint('[FirestoreService] saveUserProfile(uid=${user.uid}) → success');
  }

  /// Fetch user profile
  Future<UserModel?> getUserProfile(String uid) async {
    debugPrint('[FirestoreService] getUserProfile(uid=$uid) → fetching');
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      // Helpful debug to trace missing documents
      debugPrint('[FirestoreService] getUserProfile(uid=$uid) → NOT FOUND');
      return null;
    }
    final user = UserModel.fromDocument(doc);
    debugPrint('[FirestoreService] getUserProfile(uid=$uid) → FOUND onboardingCompleted=${user.onboardingCompleted} createdAt=${user.createdAt} lastLogin=${user.lastLogin}');
    return user;
  }

  /// Update progress or other fields
  Future<void> updateUserProgress(String uid, Map<String, dynamic> data) async {
    debugPrint('[FirestoreService] updateUserProgress(uid=$uid) → data=$data');
    await _firestore.collection('users').doc(uid).update(data);
    debugPrint('[FirestoreService] updateUserProgress(uid=$uid) → success');
  }

  Future<void> updateUserProfile(UserModel user) async {
    debugPrint('[FirestoreService] updateUserProfile(uid=${user.uid})');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .update(user.toJson());
    debugPrint('[FirestoreService] updateUserProfile(uid=${user.uid}) → success');
  }

  /// 🔹 Get course progress for a given course title
  Future<Map<String, dynamic>?> getCourseProgress(String uid, String courseTitle) async {
    debugPrint('[FirestoreService] getCourseProgress(uid=$uid, courseTitle=$courseTitle)');
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return {'completedDays': <int>[], 'currentDay': 0};

    final rawProgress = data['courseProgress'];
    if (rawProgress is! Map) {
      return {'completedDays': <int>[], 'currentDay': 0};
    }

    final progress = Map<String, dynamic>.from(rawProgress);
    final rawCourse = progress[courseTitle];
    if (rawCourse is! Map) {
      return {'completedDays': <int>[], 'currentDay': 0};
    }

    final course = Map<String, dynamic>.from(rawCourse);

    // Normalize completedDays list entries to int
    final List<dynamic> rawList = (course['completedDays'] as List?) ?? const [];
    final completedDays = rawList
        .map((e) {
          if (e is int) return e;
          if (e is num) return e.toInt();
          return int.tryParse(e.toString()) ?? 0;
        })
        .where((e) => e > 0)
        .toList();

    // Normalize currentDay
    final dynamic cd = course['currentDay'];
    final currentDay = cd is int
        ? cd
        : cd is num
            ? cd.toInt()
            : int.tryParse(cd?.toString() ?? '') ?? 0;

    return {
      'completedDays': completedDays.cast<int>(),
      'currentDay': currentDay,
    };
  }

  /// 🔹 Get ALL course progress entries for a user (normalized)
  Future<Map<String, Map<String, dynamic>>> getAllCourseProgress(String uid) async {
    debugPrint('[FirestoreService] getAllCourseProgress(uid=$uid)');
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return {};

    final data = doc.data();
    if (data == null) return {};

    final rawProgress = data['courseProgress'];
    if (rawProgress is! Map) return {};

    final progress = Map<String, dynamic>.from(rawProgress);
    final Map<String, Map<String, dynamic>> normalized = {};

    for (final entry in progress.entries) {
      final String title = entry.key;
      final dynamic rawCourse = entry.value;
      if (rawCourse is! Map) {
        normalized[title] = {
          'completedDays': <int>[],
          'currentDay': 0,
        };
        continue;
      }
      final Map<String, dynamic> course = Map<String, dynamic>.from(rawCourse);

      // Normalize completedDays list entries to int
      final List<dynamic> rawList = (course['completedDays'] as List?) ?? const [];
      final List<int> completedDays = rawList
          .map((e) {
            if (e is int) return e;
            if (e is num) return e.toInt();
            return int.tryParse(e.toString()) ?? 0;
          })
          .where((e) => e > 0)
          .toList();

      // Normalize currentDay
      final dynamic cd = course['currentDay'];
      final int currentDay = cd is int
          ? cd
          : cd is num
              ? cd.toInt()
              : int.tryParse(cd?.toString() ?? '') ?? 0;

      normalized[title] = {
        'completedDays': completedDays,
        'currentDay': currentDay,
      };
    }

    debugPrint('[FirestoreService] getAllCourseProgress(uid=$uid) → ${normalized.length} courses');
    return normalized;
  }

  /// 🔹 Mark a day complete (adds to array and updates currentDay)
  Future<void> markDayComplete(String uid, String courseTitle, int day) async {
    debugPrint('[FirestoreService] markDayComplete(uid=$uid, courseTitle=$courseTitle, day=$day)');
    await _firestore.collection('users').doc(uid).set({
      'courseProgress': {
        courseTitle: {
          'completedDays': FieldValue.arrayUnion([day]),
          'currentDay': day,
          'lastUpdated': FieldValue.serverTimestamp(),
        }
      }
    }, SetOptions(merge: true));
    debugPrint('[FirestoreService] markDayComplete(uid=$uid) → success');
  }
}
