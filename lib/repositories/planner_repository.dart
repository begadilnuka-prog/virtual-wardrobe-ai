import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_plan.dart';
import '../models/planned_outfit.dart';

class PlannerRepository {
  Future<List<PlannedOutfit>> fetchPlans(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('planner_$userId');
    if (raw == null) {
      return [];
    }

    final data =
        List<Map<String, dynamic>>.from(jsonDecode(raw) as List<dynamic>);
    return data.map(PlannedOutfit.fromMap).toList()
      ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
  }

  Future<void> savePlans({
    required String userId,
    required List<PlannedOutfit> plans,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'planner_$userId',
      jsonEncode(plans.map((entry) => entry.toMap()).toList()),
    );
  }

  Future<List<DailyPlan>> fetchDailyPlans(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('daily_plans_$userId');
    if (raw == null) {
      return [];
    }

    final data =
        List<Map<String, dynamic>>.from(jsonDecode(raw) as List<dynamic>);
    return data.map(DailyPlan.fromMap).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveDailyPlans({
    required String userId,
    required List<DailyPlan> plans,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'daily_plans_$userId',
      jsonEncode(plans.map((entry) => entry.toMap()).toList()),
    );
  }
}
