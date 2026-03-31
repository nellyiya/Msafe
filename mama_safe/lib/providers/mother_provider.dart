import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mother_model.dart';
import '../services/api_service.dart';

/// Mother Provider - Manages mothers data (CRUD operations)
class MotherProvider extends ChangeNotifier {
  List<MotherModel> _mothers = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<MotherModel> get mothers => _mothers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get mothers assigned to current CHW
  List<MotherModel> getMothersByChw(String chwId) {
    return _mothers.where((m) => m.assignedChwId == chwId).toList();
  }

  // Get all mothers
  List<MotherModel> get allMothers => _mothers;

  // Get total mothers count
  int get totalMothersCount => _mothers.length;

  // Get referrals count (mothers referred to hospital)
  int get referralsCount =>
      _mothers.where((m) => m.status == 'referred').length;

  // Get high risk mothers count
  int get highRiskCount => _mothers.where((m) => m.riskLevel == 'High').length;

  // Get mid risk mothers count
  int get midRiskCount => _mothers.where((m) => m.riskLevel == 'Mid' || m.riskLevel == 'Medium').length;

  // Get low risk mothers count
  int get lowRiskCount => _mothers.where((m) => m.riskLevel == 'Low').length;

  // Get scheduled appointments count
  int get scheduledAppointmentsCount => _mothers.where((m) => m.hasScheduledAppointment == true).length;

  // Get upcoming visits (mothers with nextVisitDate in the next 7 days)
  List<MotherModel> get upcomingVisits {
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));
    return _mothers.where((m) {
      if (m.nextVisitDate == null) return false;
      return m.nextVisitDate!.isAfter(now) &&
          m.nextVisitDate!.isBefore(sevenDaysLater) &&
          m.status != 'completed';
    }).toList();
  }

  // Get upcoming visits count
  int get upcomingVisitsCount => upcomingVisits.length;

  // Get high risk mothers
  List<MotherModel> get highRiskMothers =>
      _mothers.where((m) => m.riskLevel == 'High').toList();

  // Get recent mothers (last 5 added)
  List<MotherModel> get recentMothers {
    final sorted = List<MotherModel>.from(_mothers)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(5).toList();
  }

  MotherProvider() {
    // Don't load in constructor to avoid setState during build
    // Load will be triggered by screens when needed
  }

  // Load mothers from API
  Future<void> loadMothers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiService = ApiService();
      final mothersData = await apiService.getMothers();

      // Also load referrals to attach referral_id to each mother
      List<dynamic> referralsData = [];
      try {
        referralsData = await apiService.getCHWReferrals();
      } catch (_) {}

      // Build a map of mother_id -> latest referral_id
      final Map<String, int> motherReferralMap = {};
      for (final r in referralsData) {
        final mId = r['mother_id']?.toString();
        final rId = r['id'];
        if (mId != null && rId != null) {
          motherReferralMap[mId] = rId is int ? rId : int.tryParse(rId.toString()) ?? 0;
        }
      }

      _mothers = mothersData.map((m) {
        final mother = MotherModel.fromJson(m);
        final referralId = motherReferralMap[mother.id];
        if (referralId != null && referralId > 0) {
          return mother.copyWith(referralId: referralId);
        }
        return mother;
      }).toList();

      await _saveMothers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save mothers to storage
  Future<void> _saveMothers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mothersJson = json.encode(_mothers.map((m) => m.toJson()).toList());
      await prefs.setString('mothers', mothersJson);
    } catch (e) {
      _error = e.toString();
    }
  }

  // Add a new mother
  Future<bool> addMother(MotherModel mother) async {
    try {
      final apiService = ApiService();
      final data = {
        'name': mother.fullName,
        'phone': mother.phoneNumber,
        'district': mother.address.split(',')[0],
        'sector': mother.address.split(',').length > 1 ? mother.address.split(',')[1] : '',
        'village': mother.address.split(',').length > 2 ? mother.address.split(',')[2] : '',
        'pregnancy_start_date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'due_date': DateTime.now().add(const Duration(days: 240)).toIso8601String(),
      };
      final result = await apiService.createMother(data);
      await loadMothers();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get mother by ID
  MotherModel? getMotherById(String id) {
    try {
      return _mothers.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update mother
  Future<bool> updateMother(MotherModel mother) async {
    try {
      final index = _mothers.indexWhere((m) => m.id == mother.id);
      if (index != -1) {
        _mothers[index] = mother;
        await _saveMothers();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update mother risk level
  Future<bool> updateRiskLevel(
    String motherId,
    String riskLevel, {
    int? systolicBP,
    int? diastolicBP,
    double? bloodSugar,
    double? bodyTemp,
    int? heartRate,
  }) async {
    try {
      final index = _mothers.indexWhere((m) => m.id == motherId);
      if (index != -1) {
        _mothers[index] = _mothers[index].copyWith(
          riskLevel: riskLevel,
          systolicBP: systolicBP,
          diastolicBP: diastolicBP,
          bloodSugar: bloodSugar,
          bodyTemp: bodyTemp,
          heartRate: heartRate,
        );
        await _saveMothers();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Make referral (update status to referred)
  Future<bool> makeReferral(String motherId) async {
    try {
      final index = _mothers.indexWhere((m) => m.id == motherId);
      if (index != -1) {
        _mothers[index] = _mothers[index].copyWith(
          status: 'referred',
        );
        await _saveMothers();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Schedule next visit
  Future<bool> scheduleVisit(String motherId, DateTime visitDate) async {
    try {
      final index = _mothers.indexWhere((m) => m.id == motherId);
      if (index != -1) {
        _mothers[index] = _mothers[index].copyWith(
          nextVisitDate: visitDate,
        );
        await _saveMothers();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete mother
  Future<bool> deleteMother(String motherId) async {
    try {
      _mothers.removeWhere((m) => m.id == motherId);
      await _saveMothers();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
