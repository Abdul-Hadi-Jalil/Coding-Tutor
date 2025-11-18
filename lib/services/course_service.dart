import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/course_model.dart';

class CourseService {
  static Future<List<Course>> loadCourses() async {
    final List<Course> courses = [];
    // Load Java course
    try {
      final dataJava = await rootBundle.loadString('assets/java_course.json');
      final Map<String, dynamic> jsonJava = jsonDecode(dataJava);
      courses.add(Course.fromJavaJson(jsonJava));
    } catch (_) {}

    // Load Python course
    try {
      final dataPython = await rootBundle.loadString(
        'assets/python_course.json',
      );
      final Map<String, dynamic> jsonPython = jsonDecode(dataPython);
      courses.add(Course.fromPythonJson(jsonPython));
    } catch (_) {}

    // Load C++ course
    try {
      final dataCpp = await rootBundle.loadString('assets/cpp_course.json');
      final Map<String, dynamic> jsonCpp = jsonDecode(dataCpp);
      courses.add(Course.fromCppJson(jsonCpp));
    } catch (_) {}

    return courses;
  }

  static Future<Course> getCourseByTitle(String title) async {
    final courses = await loadCourses();

    // Try to match by title with more flexible matching
    final course = courses.firstWhere((c) {
      final courseTitle = c.title.toLowerCase();
      final searchTitle = title.toLowerCase();

      // Handle different title formats
      if (searchTitle.contains('c++') && courseTitle.contains('c++'))
        return true;
      if (searchTitle.contains('java') && courseTitle.contains('java'))
        return true;
      if (searchTitle.contains('python') && courseTitle.contains('python'))
        return true;

      // Exact match fallback
      return courseTitle == searchTitle;
    }, orElse: () => courses.first);

    return course;
  }
}
