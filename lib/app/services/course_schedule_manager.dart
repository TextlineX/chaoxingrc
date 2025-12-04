// 课程表管理器 - 在线课程表管理
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 课程项模型
class CourseItem {
  final String id;
  final String name;
  final String teacher;
  final String classroom;
  final DateTime startTime;
  final DateTime endTime;
  final String dayOfWeek; // Monday, Tuesday, etc.
  final String weekRange; // 1-16周
  final String color;
  final String courseType; // 必修、选修、实验等
  final List<String> students;
  final Map<String, dynamic> metadata;

  CourseItem({
    required this.id,
    required this.name,
    required this.teacher,
    required this.classroom,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    this.weekRange = '1-16',
    this.color = '#2196F3',
    this.courseType = '必修',
    this.students = const [],
    this.metadata = const {},
  });

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    return CourseItem(
      id: json['id'] as String,
      name: json['name'] as String,
      teacher: json['teacher'] as String,
      classroom: json['classroom'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      dayOfWeek: json['dayOfWeek'] as String,
      weekRange: json['weekRange'] as String? ?? '1-16',
      color: json['color'] as String? ?? '#2196F3',
      courseType: json['courseType'] as String? ?? '必修',
      students: (json['students'] as List<dynamic>?)?.cast<String>() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teacher': teacher,
      'classroom': classroom,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'dayOfWeek': dayOfWeek,
      'weekRange': weekRange,
      'color': color,
      'courseType': courseType,
      'students': students,
      'metadata': metadata,
    };
  }

  CourseItem copyWith({
    String? id,
    String? name,
    String? teacher,
    String? classroom,
    DateTime? startTime,
    DateTime? endTime,
    String? dayOfWeek,
    String? weekRange,
    String? color,
    String? courseType,
    List<String>? students,
    Map<String, dynamic>? metadata,
  }) {
    return CourseItem(
      id: id ?? this.id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      classroom: classroom ?? this.classroom,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      weekRange: weekRange ?? this.weekRange,
      color: color ?? this.color,
      courseType: courseType ?? this.courseType,
      students: students ?? this.students,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 学期信息模型
class SemesterInfo {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int weekCount;
  final bool isCurrent;

  SemesterInfo({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.weekCount,
    this.isCurrent = false,
  });

  factory SemesterInfo.fromJson(Map<String, dynamic> json) {
    return SemesterInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      weekCount: json['weekCount'] as int,
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'weekCount': weekCount,
      'isCurrent': isCurrent,
    };
  }
}

/// 课程表管理器
class CourseScheduleManager {
  static final CourseScheduleManager _instance =
      CourseScheduleManager._internal();
  factory CourseScheduleManager() => _instance;
  CourseScheduleManager._internal();

  late SharedPreferences _prefs;
  final List<CourseItem> _courses = [];
  final List<SemesterInfo> _semesters = [];
  bool _isInitialized = false;

  // Getters
  List<CourseItem> get courses => List.unmodifiable(_courses);
  List<SemesterInfo> get semesters => List.unmodifiable(_semesters);
  bool get isInitialized => _isInitialized;

  /// 初始化课程表管理器
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadCourses();
      await _loadSemesters();
      await _initDefaultSemester();
      _isInitialized = true;
      debugPrint('CourseScheduleManager 初始化完成');
    } catch (e) {
      debugPrint('CourseScheduleManager 初始化失败: $e');
      rethrow;
    }
  }

  /// 加载课程列表
  Future<void> _loadCourses() async {
    try {
      final coursesJson = _prefs.getStringList('course_schedule') ?? [];
      _courses.clear();

      for (final jsonStr in coursesJson) {
        try {
          // 简化的JSON解析 - 实际项目中应使用dart:convert
          final Map<String, dynamic> json = jsonDecode(jsonStr);
          final course = CourseItem.fromJson(json);
          _courses.add(course);
        } catch (e) {
          debugPrint('解析课程项失败: $e');
        }
      }

      debugPrint('加载了 ${_courses.length} 个课程');
    } catch (e) {
      debugPrint('加载课程列表失败: $e');
    }
  }

  /// 保存课程列表
  Future<void> _saveCourses() async {
    try {
      final coursesJson = _courses.map((c) => c.toJson()).toList();
      final jsonStrings = coursesJson.map((json) => json.toString()).toList();
      await _prefs.setStringList('course_schedule', jsonStrings);
      debugPrint('保存了 ${_courses.length} 个课程');
    } catch (e) {
      debugPrint('保存课程列表失败: $e');
    }
  }

  /// 加载学期信息
  Future<void> _loadSemesters() async {
    try {
      final semestersJson = _prefs.getStringList('semesters_info') ?? [];
      _semesters.clear();

      for (final jsonStr in semestersJson) {
        try {
          final Map<String, dynamic> json = jsonDecode(jsonStr);
          final semester = SemesterInfo.fromJson(json);
          _semesters.add(semester);
        } catch (e) {
          debugPrint('解析学期信息失败: $e');
        }
      }

      debugPrint('加载了 ${_semesters.length} 个学期');
    } catch (e) {
      debugPrint('加载学期信息失败: $e');
    }
  }

  /// 保存学期信息
  Future<void> _saveSemesters() async {
    try {
      final semestersJson = _semesters.map((s) => s.toJson()).toList();
      final jsonStrings = semestersJson.map((json) => json.toString()).toList();
      await _prefs.setStringList('semesters_info', jsonStrings);
      debugPrint('保存了 ${_semesters.length} 个学期');
    } catch (e) {
      debugPrint('保存学期信息失败: $e');
    }
  }

  /// 初始化默认学期
  Future<void> _initDefaultSemester() async {
    if (_semesters.isEmpty) {
      final now = DateTime.now();
      final currentYear = now.year;
      final isSpring = now.month >= 2 && now.month <= 7;

      final defaultSemester = SemesterInfo(
        id: 'current_semester',
        name: isSpring ? '$currentYear学年春季学期' : '$currentYear学年秋季学期',
        startDate: isSpring
            ? DateTime(currentYear, 2, 26)
            : DateTime(currentYear, 9, 1),
        endDate: isSpring
            ? DateTime(currentYear, 7, 15)
            : DateTime(currentYear + 1, 1, 20),
        weekCount: 16,
        isCurrent: true,
      );

      _semesters.add(defaultSemester);
      await _saveSemesters();
      debugPrint('初始化了默认学期: ${defaultSemester.name}');
    }
  }

  /// 添加课程
  Future<void> addCourse(CourseItem course) async {
    try {
      // 检查是否已存在相同ID的课程
      _courses.removeWhere((c) => c.id == course.id);
      _courses.add(course);
      await _saveCourses();
      debugPrint('添加课程: ${course.name}');
    } catch (e) {
      debugPrint('添加课程失败: $e');
      rethrow;
    }
  }

  /// 更新课程
  Future<void> updateCourse(String id, CourseItem updatedCourse) async {
    try {
      final index = _courses.indexWhere((c) => c.id == id);
      if (index >= 0) {
        _courses[index] = updatedCourse;
        await _saveCourses();
        debugPrint('更新课程: ${updatedCourse.name}');
      } else {
        throw Exception('课程不存在: $id');
      }
    } catch (e) {
      debugPrint('更新课程失败: $e');
      rethrow;
    }
  }

  /// 删除课程
  Future<void> deleteCourse(String id) async {
    try {
      _courses.removeWhere((c) => c.id == id);
      await _saveCourses();
      debugPrint('删除课程: $id');
    } catch (e) {
      debugPrint('删除课程失败: $e');
      rethrow;
    }
  }

  /// 获取某天的课程
  List<CourseItem> getCoursesByDay(String dayOfWeek) {
    return _courses.where((c) => c.dayOfWeek == dayOfWeek).toList();
  }

  /// 获取当前学期的课程
  List<CourseItem> getCurrentSemesterCourses() {
    // 这里可以根据学期信息筛选当前学期的课程
    return _courses; // 简化实现，返回所有课程
  }

  /// 获取当前时间的课程
  List<CourseItem> getCurrentCourses() {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return _courses.where((c) {
      if (c.dayOfWeek != dayName) return false;

      final courseStartTime =
          '${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}';
      final courseEndTime =
          '${c.endTime.hour.toString().padLeft(2, '0')}:${c.endTime.minute.toString().padLeft(2, '0')}';

      return currentTime.compareTo(courseStartTime) >= 0 &&
          currentTime.compareTo(courseEndTime) <= 0;
    }).toList();
  }

  /// 获取下一节课
  CourseItem? getNextCourse() {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 今天的后续课程
    final todayCourses = _courses.where((c) => c.dayOfWeek == dayName).toList();
    todayCourses.sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final course in todayCourses) {
      final courseStartTime =
          '${course.startTime.hour.toString().padLeft(2, '0')}:${course.startTime.minute.toString().padLeft(2, '0')}';
      if (currentTime.compareTo(courseStartTime) < 0) {
        return course;
      }
    }

    // 如果今天没有后续课程，找明天的第一节课
    final tomorrowDay = (now.weekday % 7) + 1;
    final tomorrowDayName = _getDayName(tomorrowDay);
    final tomorrowCourses = _courses
        .where((c) => c.dayOfWeek == tomorrowDayName)
        .toList();

    if (tomorrowCourses.isNotEmpty) {
      tomorrowCourses.sort((a, b) => a.startTime.compareTo(b.startTime));
      return tomorrowCourses.first;
    }

    return null;
  }

  /// 搜索课程
  List<CourseItem> searchCourses(String query) {
    if (query.isEmpty) return _courses;

    final lowerQuery = query.toLowerCase();
    return _courses
        .where(
          (c) =>
              c.name.toLowerCase().contains(lowerQuery) ||
              c.teacher.toLowerCase().contains(lowerQuery) ||
              c.classroom.toLowerCase().contains(lowerQuery) ||
              c.courseType.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  /// 添加学期
  Future<void> addSemester(SemesterInfo semester) async {
    try {
      _semesters.removeWhere((s) => s.id == semester.id);
      _semesters.add(semester);
      await _saveSemesters();
      debugPrint('添加学期: ${semester.name}');
    } catch (e) {
      debugPrint('添加学期失败: $e');
      rethrow;
    }
  }

  /// 设置当前学期
  Future<void> setCurrentSemester(String semesterId) async {
    try {
      final updatedSemesters = _semesters
          .map(
            (s) => SemesterInfo(
              id: s.id,
              name: s.name,
              startDate: s.startDate,
              endDate: s.endDate,
              weekCount: s.weekCount,
              isCurrent: s.id == semesterId,
            ),
          )
          .toList();
      _semesters.clear();
      _semesters.addAll(updatedSemesters);
      await _saveSemesters();
      debugPrint('设置当前学期: $semesterId (功能暂时禁用)');
    } catch (e) {
      debugPrint('设置当前学期失败: $e');
      rethrow;
    }
  }

  /// 获取当前学期
  SemesterInfo? getCurrentSemester() {
    try {
      return _semesters.firstWhere((s) => s.isCurrent);
    } catch (e) {
      return null;
    }
  }

  /// 获取周课程表
  Map<String, List<CourseItem>> getWeekSchedule() {
    final weekSchedule = <String, List<CourseItem>>{};
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    for (final day in days) {
      final dayCourses = getCoursesByDay(day);
      dayCourses.sort((a, b) => a.startTime.compareTo(b.startTime));
      weekSchedule[day] = dayCourses;
    }

    return weekSchedule;
  }

  /// 导入课程表
  Future<void> importCourses(List<CourseItem> courses) async {
    try {
      _courses.clear();
      _courses.addAll(courses);
      await _saveCourses();
      debugPrint('导入了 ${courses.length} 个课程');
    } catch (e) {
      debugPrint('导入课程表失败: $e');
      rethrow;
    }
  }

  /// 导出课程表
  List<CourseItem> exportCourses() {
    return List.from(_courses);
  }

  /// 获取课程统计信息
  Map<String, dynamic> getCourseStatistics() {
    final courseTypeCount = <String, int>{};
    final teacherCourseCount = <String, int>{};
    final classroomCount = <String, int>{};

    for (final course in _courses) {
      courseTypeCount[course.courseType] =
          (courseTypeCount[course.courseType] ?? 0) + 1;
      teacherCourseCount[course.teacher] =
          (teacherCourseCount[course.teacher] ?? 0) + 1;
      classroomCount[course.classroom] =
          (classroomCount[course.classroom] ?? 0) + 1;
    }

    return {
      'totalCourses': _courses.length,
      'totalSemesters': _semesters.length,
      'coursesByType': courseTypeCount,
      'coursesByTeacher': teacherCourseCount,
      'coursesByClassroom': classroomCount,
      'coursesByDay': {
        'Monday': getCoursesByDay('Monday').length,
        'Tuesday': getCoursesByDay('Tuesday').length,
        'Wednesday': getCoursesByDay('Wednesday').length,
        'Thursday': getCoursesByDay('Thursday').length,
        'Friday': getCoursesByDay('Friday').length,
        'Saturday': getCoursesByDay('Saturday').length,
        'Sunday': getCoursesByDay('Sunday').length,
      },
    };
  }

  /// 获取星期几的英文名称
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  /// 清空所有课程
  Future<void> clearAllCourses() async {
    try {
      _courses.clear();
      await _saveCourses();
      debugPrint('清空了所有课程');
    } catch (e) {
      debugPrint('清空课程失败: $e');
      rethrow;
    }
  }

  /// 重置所有数据
  Future<void> resetAllData() async {
    try {
      await _prefs.remove('course_schedule');
      await _prefs.remove('semesters_info');
      _courses.clear();
      _semesters.clear();
      await _initDefaultSemester();
      debugPrint('重置了所有课程表数据');
    } catch (e) {
      debugPrint('重置数据失败: $e');
      rethrow;
    }
  }
}
