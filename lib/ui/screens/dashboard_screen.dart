import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_assignment/models/claim_status.dart';

import '../../models/patient_claim.dart';
import '../../state/claim_store.dart';
import '../formatters/money.dart';
import '../widgets/empty_state.dart';
import 'claim_detail_screen.dart';
import 'claim_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const route = '/';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ClaimStore>();
    final claims = store.claims;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Claims Dashboard'),
        actions: [
          IconButton(
            tooltip: 'New claim',
            onPressed: () => Navigator.of(context).pushNamed(ClaimFormScreen.route),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: !store.ready
          ? const Center(child: CircularProgressIndicator())
          : claims.isEmpty
              ? EmptyState(
                  title: 'No claims yet',
                  subtitle: 'Create a patient claim to start tracking bills, advances, and settlements.',
                  actionLabel: 'Create claim',
                  onAction: () =>
                      Navigator.of(context).pushNamed(ClaimFormScreen.route),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: claims.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final claim = claims[index];
                    return _ClaimCard(
                      claim: claim,
                      onTap: () => Navigator.of(context).pushNamed(
                        ClaimDetailScreen.route,
                        arguments: claim.id,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(ClaimFormScreen.route),
        icon: const Icon(Icons.add),
        label: const Text('New claim'),
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.claim, required this.onTap});

  final PatientClaim claim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
          color: theme.colorScheme.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      claim.patientName,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusChip(label: claim.status.label),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Patient ID: ${claim.patientId}${claim.insurerName == null ? '' : ' • Insurer: ${claim.insurerName}'}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MoneyTile(label: 'Bills', value: formatMoney(claim.totalBills)),
                  const SizedBox(width: 10),
                  _MoneyTile(
                    label: 'Advance',
                    value: formatMoney(claim.advanceAmount),
                  ),
                  const SizedBox(width: 10),
                  _MoneyTile(
                    label: 'Settlement',
                    value: formatMoney(claim.settlementAmount),
                  ),
                  const SizedBox(width: 10),
                  _MoneyTile(
                    label: 'Pending',
                    value: formatMoney(claim.pendingAmount),
                    emphasis: claim.pendingAmount > 0,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoneyTile extends StatelessWidget {
  const _MoneyTile({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: emphasis ? theme.colorScheme.primary : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

