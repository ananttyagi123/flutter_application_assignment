import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../logic/claim_workflow.dart';
import '../../models/bill.dart';
import '../../models/claim_status.dart';
import '../../models/patient_claim.dart';
import '../../state/claim_store.dart';
import '../formatters/money.dart';
import '../widgets/empty_state.dart';

class ClaimDetailScreen extends StatelessWidget {
  const ClaimDetailScreen({super.key, required this.claimId});

  static const route = '/claim/detail';

  final String claimId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ClaimStore>();
    final claim = store.byId(claimId);

    if (claim == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Claim')),
        body: const EmptyState(
          title: 'Claim not found',
          subtitle: 'This claim may have been deleted.',
        ),
      );
    }

    return _ClaimDetailBody(claim: claim);
  }
}

class _ClaimDetailBody extends StatelessWidget {
  const _ClaimDetailBody({required this.claim});

  final PatientClaim claim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = context.read<ClaimStore>();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(claim.createdAtMillis);

    return Scaffold(
      appBar: AppBar(
        title: Text(claim.patientName),
        actions: [
          IconButton(
            tooltip: 'Delete claim',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete claim?'),
                  content: const Text('This will remove the claim permanently.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok != true) return;
              await store.deleteClaim(claim.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(claim: claim, createdAt: createdAt),
          const SizedBox(height: 12),
          Text('Amounts', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _TotalsCard(claim: claim),
          const SizedBox(height: 12),
          Text('Workflow', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _WorkflowCard(claim: claim),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('Bills', style: theme.textTheme.titleMedium),
              ),
              FilledButton.icon(
                onPressed: () => _BillEditorDialog.open(
                  context,
                  claimId: claim.id,
                  bill: store.newBillTemplate(),
                  isNew: true,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add bill'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          claim.bills.isEmpty
              ? const EmptyState(
                  title: 'No bills',
                  subtitle: 'Add bills to calculate totals and pending amount.',
                  icon: Icons.receipt_long,
                )
              : Column(
                  children: claim.bills
                      .map((b) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _BillTile(
                              claimId: claim.id,
                              bill: b,
                            ),
                          ))
                      .toList(),
                ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.claim, required this.createdAt});

  final PatientClaim claim;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dt = DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Patient ID: ${claim.patientId}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusChip(label: claim.status.label),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Created: $dt',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
            if (claim.insurerName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Insurer: ${claim.insurerName}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (claim.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                claim.notes!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.claim});

  final PatientClaim claim;

  @override
  Widget build(BuildContext context) {
    final store = context.read<ClaimStore>();

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _AmountRow(label: 'Total bills', value: formatMoney(claim.totalBills)),
            const Divider(height: 18),
            _EditableMoneyRow(
              label: 'Advance',
              value: claim.advanceAmount,
              onSave: (v) => store.setAdvance(claim.id, v),
            ),
            const SizedBox(height: 10),
            _EditableMoneyRow(
              label: 'Settlement',
              value: claim.settlementAmount,
              onSave: (v) => store.setSettlement(claim.id, v),
            ),
            const Divider(height: 18),
            _AmountRow(
              label: 'Pending',
              value: formatMoney(claim.pendingAmount),
              emphasize: claim.pendingAmount > 0,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({required this.claim});

  final PatientClaim claim;

  @override
  Widget build(BuildContext context) {
    final store = context.read<ClaimStore>();
    final options = ClaimStatus.values
        .where((s) => ClaimWorkflow.canTransition(claim.status, s))
        .toList();

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Current: ${claim.status.label}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            DropdownButton<ClaimStatus>(
              value: claim.status,
              items: options
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.label),
                    ),
                  )
                  .toList(),
              onChanged: (next) async {
                if (next == null) return;
                await store.setStatus(claim.id, next);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: emphasize ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

class _EditableMoneyRow extends StatelessWidget {
  const _EditableMoneyRow({
    required this.label,
    required this.value,
    required this.onSave,
  });

  final String label;
  final double value;
  final Future<void> Function(double) onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(formatMoney(value)),
        const SizedBox(width: 10),
        IconButton(
          tooltip: 'Edit $label',
          onPressed: () => _MoneyEditDialog.open(
            context,
            title: 'Edit $label',
            initial: value,
            onSave: onSave,
          ),
          icon: const Icon(Icons.edit),
        ),
      ],
    );
  }
}

class _BillTile extends StatelessWidget {
  const _BillTile({required this.claimId, required this.bill});

  final String claimId;
  final Bill bill;

  @override
  Widget build(BuildContext context) {
    final store = context.read<ClaimStore>();
    final theme = Theme.of(context);
    final dt = DateFormat('dd MMM yyyy')
        .format(DateTime.fromMillisecondsSinceEpoch(bill.dateMillis));

    return Card(
      elevation: 0,
      child: ListTile(
        title: Text(bill.title),
        subtitle: Text(dt + (bill.notes == null ? '' : ' • ${bill.notes}')),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatMoney(bill.amount),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit bill',
                  onPressed: () => _BillEditorDialog.open(
                    context,
                    claimId: claimId,
                    bill: bill,
                    isNew: false,
                  ),
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  tooltip: 'Delete bill',
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete bill?'),
                        content: const Text('This will remove the bill from the claim.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    await store.deleteBill(claimId, bill.id);
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
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

class _MoneyEditDialog extends StatefulWidget {
  const _MoneyEditDialog({
    required this.title,
    required this.initial,
    required this.onSave,
  });

  final String title;
  final double initial;
  final Future<void> Function(double) onSave;

  static Future<void> open(
    BuildContext context, {
    required String title,
    required double initial,
    required Future<void> Function(double) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (_) => _MoneyEditDialog(title: title, initial: initial, onSave: onSave),
    );
  }

  @override
  State<_MoneyEditDialog> createState() => _MoneyEditDialogState();
}

class _MoneyEditDialogState extends State<_MoneyEditDialog> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.initial.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final parsed = double.tryParse(_ctrl.text.trim().replaceAll(',', '')) ?? 0;
    setState(() => _saving = true);
    try {
      await widget.onSave(parsed);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Amount',
          prefixText: '₹ ',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}

class _BillEditorDialog extends StatefulWidget {
  const _BillEditorDialog({
    required this.claimId,
    required this.bill,
    required this.isNew,
  });

  final String claimId;
  final Bill bill;
  final bool isNew;

  static Future<void> open(
    BuildContext context, {
    required String claimId,
    required Bill bill,
    required bool isNew,
  }) {
    return showDialog(
      context: context,
      builder: (_) => _BillEditorDialog(claimId: claimId, bill: bill, isNew: isNew),
    );
  }

  @override
  State<_BillEditorDialog> createState() => _BillEditorDialogState();
}

class _BillEditorDialogState extends State<_BillEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.bill.title);
    _amountCtrl = TextEditingController(text: widget.bill.amount.toStringAsFixed(2));
    _notesCtrl = TextEditingController(text: widget.bill.notes ?? '');
    _date = DateTime.fromMillisecondsSinceEpoch(widget.bill.dateMillis);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final store = context.read<ClaimStore>();
    setState(() => _saving = true);
    try {
      final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', '')) ?? 0;
      final bill = widget.bill.copyWith(
        title: _titleCtrl.text.trim(),
        amount: amount < 0 ? 0 : amount,
        dateMillis: _date.millisecondsSinceEpoch,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await store.upsertBill(widget.claimId, bill);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = DateFormat('dd MMM yyyy').format(_date);
    return AlertDialog(
      title: Text(widget.isNew ? 'Add bill' : 'Edit bill'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Bill title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter bill title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim().replaceAll(',', ''));
                  if (value == null) return 'Enter a valid amount';
                  if (value < 0) return 'Amount cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Date: $dt')),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Pick'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}

