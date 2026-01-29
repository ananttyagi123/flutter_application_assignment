enum ClaimStatus {
  draft,
  submitted,
  approved,
  rejected,
  partiallySettled,
}

extension ClaimStatusUi on ClaimStatus {
  String get label => switch (this) {
        ClaimStatus.draft => 'Draft',
        ClaimStatus.submitted => 'Submitted',
        ClaimStatus.approved => 'Approved',
        ClaimStatus.rejected => 'Rejected',
        ClaimStatus.partiallySettled => 'Partially Settled',
      };

  static ClaimStatus fromJson(String value) => ClaimStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => ClaimStatus.draft,
      );
}
