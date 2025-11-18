import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? provider; // 'google' or 'apple'
  final int totalPoints; // gamification element
  final int lessonsCompleted;
  final List<String> enrolledCourses;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool onboardingCompleted;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.provider,
    this.totalPoints = 0,
    this.lessonsCompleted = 0,
    this.enrolledCourses = const [],
    required this.createdAt,
    required this.lastLogin,
    this.onboardingCompleted = false,
  });

  // 🔹 Convert model to JSON (for Firebase or local storage)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'provider': provider,
      'totalPoints': totalPoints,
      'lessonsCompleted': lessonsCompleted,
      'enrolledCourses': enrolledCourses,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'onboardingCompleted': onboardingCompleted,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? provider,
    int? totalPoints,
    int? lessonsCompleted,
    List<String>? enrolledCourses,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? onboardingCompleted,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      provider: provider ?? this.provider,
      totalPoints: totalPoints ?? this.totalPoints,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  // 🔹 Create UserModel from Firestore Document (robust Timestamp/String parsing)
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return UserModel(
      uid: data['uid'] ?? doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      provider: data['provider'],
      totalPoints: data['totalPoints'] ?? 0,
      lessonsCompleted: data['lessonsCompleted'] ?? 0,
      enrolledCourses: List<String>.from(data['enrolledCourses'] ?? []),
      createdAt: parseDate(data['createdAt']),
      lastLogin: parseDate(data['lastLogin']),
      onboardingCompleted: data['onboardingCompleted'] ?? false,
    );
  }
}
