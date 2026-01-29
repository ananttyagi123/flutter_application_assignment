import '../models/claim_status.dart';
import '../models/patient_claim.dart';

class ClaimWorkflow {
  static bool canTransition(ClaimStatus from, ClaimStatus to) {
    if (from == to) return true;
    return switch (from) {
      ClaimStatus.draft => to == ClaimStatus.submitted,
      ClaimStatus.submitted =>
        to == ClaimStatus.approved || to == ClaimStatus.rejected,
      ClaimStatus.approved => to == ClaimStatus.partiallySettled,
      ClaimStatus.partiallySettled => to == ClaimStatus.approved,
      ClaimStatus.rejected => to == ClaimStatus.draft,
    };
  }

  /// Derive a sensible status based on financials after a change.
  /// Keeps status within the allowed workflow.
  static ClaimStatus normalizeAfterFinancialChange(PatientClaim claim) {
    // If claim is rejected, don't auto-flip it.
    if (claim.status == ClaimStatus.rejected) return claim.status;

    // If not submitted yet, keep Draft.
    if (claim.status == ClaimStatus.draft) return claim.status;

    // If submitted but user is still editing financials, keep Submitted.
    if (claim.status == ClaimStatus.submitted) return claim.status;

    // Approved <-> Partially settled depending on pending.
    if (claim.pendingAmount > 0.00001) {
      return ClaimStatus.partiallySettled;
    }
    return ClaimStatus.approved;
  }
}

