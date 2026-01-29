import 'bill.dart';
import 'claim_status.dart';

class PatientClaim {
  PatientClaim({
    required this.id,
    required this.patientName,
    required this.patientId,
    required this.createdAtMillis,
    required this.status,
    required this.bills,
    required this.advanceAmount,
    required this.settlementAmount,
    this.insurerName,
    this.notes,
  });

  final String id;
  final String patientName;
  final String patientId;
  final int createdAtMillis;
  final ClaimStatus status;
  final List<Bill> bills;
  final double advanceAmount;
  final double settlementAmount;
  final String? insurerName;
  final String? notes;

  double get totalBills =>
      bills.fold<double>(0, (sum, b) => sum + b.amount);

  double get pendingAmount {
    final pending = totalBills - advanceAmount - settlementAmount;
    // Keep a clean UI number (no negative pending).
    return pending < 0 ? 0 : pending;
  }

  bool get isSettled => pendingAmount <= 0.00001 && totalBills > 0;

  PatientClaim copyWith({
    String? id,
    String? patientName,
    String? patientId,
    int? createdAtMillis,
    ClaimStatus? status,
    List<Bill>? bills,
    double? advanceAmount,
    double? settlementAmount,
    String? insurerName,
    String? notes,
  }) {
    return PatientClaim(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      patientId: patientId ?? this.patientId,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      status: status ?? this.status,
      bills: bills ?? this.bills,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      settlementAmount: settlementAmount ?? this.settlementAmount,
      insurerName: insurerName ?? this.insurerName,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientName': patientName,
        'patientId': patientId,
        'createdAtMillis': createdAtMillis,
        'status': status.name,
        'bills': bills.map((b) => b.toJson()).toList(),
        'advanceAmount': advanceAmount,
        'settlementAmount': settlementAmount,
        'insurerName': insurerName,
        'notes': notes,
      };

  static PatientClaim fromJson(Map<String, dynamic> json) => PatientClaim(
        id: json['id'] as String,
        patientName: json['patientName'] as String,
        patientId: json['patientId'] as String,
        createdAtMillis: (json['createdAtMillis'] as num).toInt(),
        status: ClaimStatusUi.fromJson(json['status'] as String),
        bills: (json['bills'] as List<dynamic>)
            .map((e) => Bill.fromJson(e as Map<String, dynamic>))
            .toList(),
        advanceAmount: (json['advanceAmount'] as num).toDouble(),
        settlementAmount: (json['settlementAmount'] as num).toDouble(),
        insurerName: json['insurerName'] as String?,
        notes: json['notes'] as String?,
      );
}

