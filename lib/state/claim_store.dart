import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../logic/claim_workflow.dart';
import '../models/bill.dart';
import '../models/claim_status.dart';
import '../models/patient_claim.dart';

class ClaimStore extends ChangeNotifier {
  static const _prefsKey = 'claims_v1';
  final _uuid = const Uuid();

  bool _ready = false;
  bool get ready => _ready;

  final List<PatientClaim> _claims = [];
  List<PatientClaim> get claims => List.unmodifiable(_claims);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      _claims
        ..clear()
        ..addAll(_seedClaims());
      await _persist();
    } else {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _claims
        ..clear()
        ..addAll(
          decoded.map((e) => PatientClaim.fromJson(e as Map<String, dynamic>)),
        );
    }
    _ready = true;
    notifyListeners();
  }

  PatientClaim? byId(String id) {
    for (final c in _claims) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<String> createClaim({
    required String patientName,
    required String patientId,
    String? insurerName,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final claim = PatientClaim(
      id: id,
      patientName: patientName.trim(),
      patientId: patientId.trim(),
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      status: ClaimStatus.draft,
      bills: const [],
      advanceAmount: 0,
      settlementAmount: 0,
      insurerName: insurerName?.trim().isEmpty ?? true ? null : insurerName!.trim(),
      notes: notes?.trim().isEmpty ?? true ? null : notes!.trim(),
    );
    _claims.insert(0, claim);
    await _persist();
    notifyListeners();
    return id;
  }

  Future<void> updateClaimMeta(
    String claimId, {
    required String patientName,
    required String patientId,
    String? insurerName,
    String? notes,
  }) async {
    final idx = _claims.indexWhere((c) => c.id == claimId);
    if (idx == -1) return;
    _claims[idx] = _claims[idx].copyWith(
      patientName: patientName.trim(),
      patientId: patientId.trim(),
      insurerName: insurerName?.trim().isEmpty ?? true ? null : insurerName!.trim(),
      notes: notes?.trim().isEmpty ?? true ? null : notes!.trim(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> deleteClaim(String claimId) async {
    _claims.removeWhere((c) => c.id == claimId);
    await _persist();
    notifyListeners();
  }

  Future<void> setStatus(String claimId, ClaimStatus next) async {
    final idx = _claims.indexWhere((c) => c.id == claimId);
    if (idx == -1) return;
    final current = _claims[idx];
    if (!ClaimWorkflow.canTransition(current.status, next)) return;
    _claims[idx] = current.copyWith(status: next);
    await _persist();
    notifyListeners();
  }

  Future<void> upsertBill(String claimId, Bill bill) async {
    final idx = _claims.indexWhere((c) => c.id == claimId);
    if (idx == -1) return;
    final claim = _claims[idx];
    final bills = [...claim.bills];
    final billIdx = bills.indexWhere((b) => b.id == bill.id);
    if (billIdx == -1) {
      bills.insert(0, bill);
    } else {
      bills[billIdx] = bill;
    }
    var updated = claim.copyWith(bills: bills);
    updated = updated.copyWith(
      status: ClaimWorkflow.normalizeAfterFinancialChange(updated),
    );
    _claims[idx] = updated;
    await _persist();
    notifyListeners();
  }

  Future<void> deleteBill(String claimId, String billId) async {
    final idx = _claims.indexWhere((c) => c.id == claimId);
    if (idx == -1) return;
    final claim = _claims[idx];
    final bills = claim.bills.where((b) => b.id != billId).toList();
    var updated = claim.copyWith(bills: bills);
    updated = updated.copyWith(
      status: ClaimWorkflow.normalizeAfterFinancialChange(updated),
    );
    _claims[idx] = updated;
    await _persist();
    notifyListeners();
  }

  Future<void> setAdvance(String claimId, double advanceAmount) async {
    final idx = _claims.indexWhere((c) => c.id == claimId);
    if (idx == -1) return;
    final claim = _claims[idx];
    var updated = claim.copyWith(advanceAmount: _clampMoney(advanceAmount));
    updated = updated.copyWith(
      status: ClaimWorkflow.normalizeAfterFinancialChange(updated),
    );
    _claims[idx] = updated;
    await _persist();
    notifyListeners();
  }

  Future<void> setSettlement(String claimId, double settlementAmount) async {
    final idx = _claims.indexWhere((c) => c.id == claimId);
    if (idx == -1) return;
    final claim = _claims[idx];
    var updated = claim.copyWith(settlementAmount: _clampMoney(settlementAmount));
    updated = updated.copyWith(
      status: ClaimWorkflow.normalizeAfterFinancialChange(updated),
    );
    _claims[idx] = updated;
    await _persist();
    notifyListeners();
  }

  Bill newBillTemplate() => Bill(
        id: _uuid.v4(),
        title: '',
        amount: 0,
        dateMillis: DateTime.now().millisecondsSinceEpoch,
      );

  double _clampMoney(double value) => value.isNaN || value.isInfinite
      ? 0
      : value < 0
          ? 0
          : double.parse(value.toStringAsFixed(2));

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_claims.map((c) => c.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }

  List<PatientClaim> _seedClaims() {
    final now = DateTime.now();
    final c1 = PatientClaim(
      id: _uuid.v4(),
      patientName: 'Aarav Sharma',
      patientId: 'P-1001',
      createdAtMillis: now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
      status: ClaimStatus.submitted,
      bills: [
        Bill(
          id: _uuid.v4(),
          title: 'Emergency consultation',
          amount: 1200,
          dateMillis: now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
        ),
        Bill(
          id: _uuid.v4(),
          title: 'Lab tests',
          amount: 850,
          dateMillis: now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
        ),
      ],
      advanceAmount: 500,
      settlementAmount: 0,
      insurerName: 'CareShield',
      notes: 'Admitted for observation.',
    );

    final c2 = PatientClaim(
      id: _uuid.v4(),
      patientName: 'Meera Iyer',
      patientId: 'P-1002',
      createdAtMillis: now.subtract(const Duration(days: 5)).millisecondsSinceEpoch,
      status: ClaimStatus.approved,
      bills: [
        Bill(
          id: _uuid.v4(),
          title: 'Surgery package',
          amount: 25000,
          dateMillis: now.subtract(const Duration(days: 5)).millisecondsSinceEpoch,
        ),
      ],
      advanceAmount: 5000,
      settlementAmount: 20000,
      insurerName: 'MediSure',
      notes: 'Cashless approval received.',
    );

    // Normalize seed statuses based on financials (for realism).
    final n1 = c1.copyWith(status: ClaimWorkflow.normalizeAfterFinancialChange(c1));
    final n2 = c2.copyWith(status: ClaimWorkflow.normalizeAfterFinancialChange(c2));
    return [n1, n2];
  }
}

