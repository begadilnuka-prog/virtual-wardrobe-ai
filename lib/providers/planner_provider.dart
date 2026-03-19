import 'package:flutter/foundation.dart';

import '../core/app_utils.dart';
import '../models/daily_plan.dart';
import '../models/planned_outfit.dart';
import '../repositories/planner_repository.dart';
import 'auth_provider.dart';

class PlannerProvider extends ChangeNotifier {
  PlannerProvider({
    required AuthProvider authProvider,
    required PlannerRepository repository,
  })  : _authProvider = authProvider,
        _repository = repository;

  AuthProvider _authProvider;
  PlannerRepository _repository;

  final List<PlannedOutfit> _plans = [];
  final List<DailyPlan> _dailyPlans = [];
  bool isLoading = false;

  List<PlannedOutfit> get plans => List.unmodifiable(_plans);
  List<DailyPlan> get dailyPlans => List.unmodifiable(_dailyPlans);
  DailyPlan? get todayPlan => planForDate(DateTime.now());

  void updateDependencies(
      AuthProvider authProvider, PlannerRepository repository) {
    final previousUserId = _authProvider.currentUser?.id;
    _authProvider = authProvider;
    _repository = repository;
    if (previousUserId != _authProvider.currentUser?.id) {
      loadPlans();
    }
  }

  Future<void> loadPlans() async {
    final user = _authProvider.currentUser;
    if (user == null) {
      _plans.clear();
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();
    final result = await _repository.fetchPlans(user.id);
    final smartPlans = await _repository.fetchDailyPlans(user.id);
    _plans
      ..clear()
      ..addAll(result);
    _dailyPlans
      ..clear()
      ..addAll(smartPlans);
    isLoading = false;
    notifyListeners();
  }

  String? outfitIdForDay(int dayIndex) {
    return _plans
        .where((plan) => plan.dayIndex == dayIndex)
        .firstOrNull
        ?.outfitId;
  }

  DailyPlan? planForDate(DateTime date) {
    return _dailyPlans.where((plan) => isSameDate(plan.date, date)).firstOrNull;
  }

  Future<void> assignOutfit({
    required int dayIndex,
    required String outfitId,
  }) async {
    final user = _authProvider.currentUser;
    if (user == null) {
      return;
    }

    final next = [
      PlannedOutfit(
        userId: user.id,
        dayIndex: dayIndex,
        outfitId: outfitId,
        updatedAt: DateTime.now(),
      ),
      ..._plans.where((plan) => plan.dayIndex != dayIndex),
    ]..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));

    _plans
      ..clear()
      ..addAll(next);
    await _repository.savePlans(userId: user.id, plans: _plans);
    notifyListeners();
  }

  Future<void> removePlan(int dayIndex) async {
    final user = _authProvider.currentUser;
    if (user == null) {
      return;
    }

    _plans.removeWhere((plan) => plan.dayIndex == dayIndex);
    await _repository.savePlans(userId: user.id, plans: _plans);
    notifyListeners();
  }

  Future<void> saveDailyPlan(DailyPlan plan) async {
    final user = _authProvider.currentUser;
    if (user == null) {
      return;
    }

    final next = [
      plan.copyWith(updatedAt: DateTime.now()),
      ..._dailyPlans.where((entry) => !isSameDate(entry.date, plan.date)),
    ]..sort((a, b) => b.date.compareTo(a.date));

    _dailyPlans
      ..clear()
      ..addAll(next);
    await _repository.saveDailyPlans(userId: user.id, plans: _dailyPlans);
    notifyListeners();
  }

  Future<void> attachSavedOutfitToDate({
    required DateTime date,
    required String outfitId,
  }) async {
    final existing = planForDate(date);
    if (existing == null) {
      return;
    }
    await saveDailyPlan(existing.copyWith(savedOutfitId: outfitId));
  }
}
