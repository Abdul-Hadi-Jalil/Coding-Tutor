class Course {
  final String id;
  final String title;
  final String language;
  final String description;
  final List<CourseDay> days;

  Course({
    required this.id,
    required this.title,
    required this.language,
    required this.description,
    required this.days,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      title: json['title'],
      language: json['language'],
      description: json['description'],
      days: (json['days'] as List).map((d) => CourseDay.fromJson(d)).toList(),
    );
  }

  // Added: Support for java_course.json schema
  factory Course.fromJavaJson(Map<String, dynamic> json) {
    final List<dynamic> daysJson = (json['days'] as List?) ?? [];
    final List<CourseDay> parsedDays = [];
    for (int i = 0; i < daysJson.length; i++) {
      final Map<String, dynamic> dayObj = Map<String, dynamic>.from(
        daysJson[i] as Map,
      );
      parsedDays.add(CourseDay.fromJavaJson(dayObj, i + 1));
    }
    return Course(
      id: 'java_course',
      title: 'Java for Beginners', // align with UI expectation
      language: 'Java',
      description: (json['course_title'] as String?) ?? 'Java course',
      days: parsedDays,
    );
  }

  // Added: Support for python_course.json schema
  factory Course.fromPythonJson(Map<String, dynamic> json) {
    final List<dynamic> daysJson = (json['days'] as List?) ?? [];
    final List<CourseDay> parsedDays = [];
    for (int i = 0; i < daysJson.length; i++) {
      final Map<String, dynamic> dayObj = Map<String, dynamic>.from(
        daysJson[i] as Map,
      );
      // Python course JSON shares the same schema as Java
      parsedDays.add(CourseDay.fromJavaJson(dayObj, i + 1));
    }
    return Course(
      id: 'python_course',
      title: 'Python for Beginners',
      language: 'Python',
      description: (json['course_title'] as String?) ?? 'Python course',
      days: parsedDays,
    );
  }
  // Add this to the Course class - put it after fromPythonJson
  factory Course.fromCppJson(Map<String, dynamic> json) {
    final List<dynamic> daysJson = (json['days'] as List?) ?? [];
    final List<CourseDay> parsedDays = [];
    for (int i = 0; i < daysJson.length; i++) {
      final Map<String, dynamic> dayObj = Map<String, dynamic>.from(
        daysJson[i] as Map,
      );
      // C++ course JSON shares the same schema as Java
      parsedDays.add(CourseDay.fromJavaJson(dayObj, i + 1));
    }
    return Course(
      id: 'cpp_course',
      title:
          'C++ for Beginners', // This matches what we used in CourseLevelSelectionScreen
      language: 'C++',
      description: (json['course_title'] as String?) ?? 'C++ course',
      days: parsedDays,
    );
  }
}

class CourseDay {
  final int day;
  final String title;
  // New granular fields mapped from java_course.json
  final String definition;
  final String explanation;
  final String codeExample;
  final String realWorldExample;
  final List<String> interactiveTasks;
  final List<QuizQuestion> quiz;

  // Legacy fields to keep backward-compat (not used by new UI)
  final String content;
  final String interactiveTask;

  CourseDay({
    required this.day,
    required this.title,
    required this.definition,
    required this.explanation,
    required this.codeExample,
    required this.realWorldExample,
    required this.interactiveTasks,
    required this.quiz,
    required this.content,
    required this.interactiveTask,
  });

  factory CourseDay.fromJson(Map<String, dynamic> json) {
    final List<dynamic> quizJson = (json['quiz'] as List?) ?? [];
    final List<QuizQuestion> parsedQuiz = quizJson
        .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList();

    final String legacyContent = (json['content'] as String?) ?? '';
    final String legacyTask = (json['interactive_task'] as String?) ?? '';

    return CourseDay(
      day: json['day'] ?? 0,
      title: (json['title'] as String?) ?? 'Day',
      // Map legacy to granular with sensible defaults
      definition: legacyContent,
      explanation: '',
      codeExample: '',
      realWorldExample: '',
      interactiveTasks: legacyTask.isNotEmpty ? [legacyTask] : [],
      quiz: parsedQuiz,
      content: legacyContent,
      interactiveTask: legacyTask,
    );
  }

  // Added: Map java_course.json day object
  factory CourseDay.fromJavaJson(Map<String, dynamic> json, int dayNumber) {
    final List<String> tasks = List<String>.from(
      (json['interactive_tasks'] as List?) ?? [],
    );

    final String definition = (json['definition'] as String?) ?? '';
    final String explanation = (json['explanation'] as String?) ?? '';
    final String codeExample = (json['code_example'] as String?) ?? '';
    final String realWorld = (json['real_world_example'] as String?) ?? '';

    final String combinedContent = [
      definition,
      explanation,
      codeExample,
    ].where((s) => s.isNotEmpty).join('\n\n');
    final String interactiveTaskString = tasks.isNotEmpty
        ? tasks.join('\n\n')
        : '';

    final List<dynamic> quizJson = (json['quiz'] as List?) ?? [];
    final List<QuizQuestion> parsedQuiz = quizJson
        .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList();

    return CourseDay(
      day: dayNumber,
      title: (json['title'] as String?) ?? 'Day $dayNumber',
      definition: definition,
      explanation: explanation,
      codeExample: codeExample,
      realWorldExample: realWorld,
      interactiveTasks: tasks,
      quiz: parsedQuiz,
      content: combinedContent,
      interactiveTask: interactiveTaskString,
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final String answer;
  final String? reasoning;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
    this.reasoning,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'],
      options: List<String>.from(json['options'] ?? const []),
      answer: json['answer'],
      reasoning: json['reasoning'] as String?,
    );
  }
}
