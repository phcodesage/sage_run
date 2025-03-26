import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';

class ActivityService {
  static const String _storageKey = 'activities';
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  Future<List<Activity>> getActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final String? activitiesJson = prefs.getString(_storageKey);
    
    if (activitiesJson == null) return [];
    
    final List<dynamic> activitiesList = json.decode(activitiesJson);
    return activitiesList.map((json) => Activity.fromJson(json)).toList();
  }

  Future<void> saveActivity(Activity activity) async {
    final prefs = await SharedPreferences.getInstance();
    final activities = await getActivities();
    activities.add(activity);
    
    final activitiesJson = json.encode(activities.map((a) => a.toJson()).toList());
    await prefs.setString(_storageKey, activitiesJson);
  }

  Future<void> deleteActivity(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final activities = await getActivities();
    activities.removeWhere((activity) => activity.id == id);
    
    final activitiesJson = json.encode(activities.map((a) => a.toJson()).toList());
    await prefs.setString(_storageKey, activitiesJson);
  }
} 