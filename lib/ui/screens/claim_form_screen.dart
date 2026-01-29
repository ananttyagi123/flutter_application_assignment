import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/claim_store.dart';
import 'claim_detail_screen.dart';

class ClaimFormScreen extends StatefulWidget {
  const ClaimFormScreen({super.key});

  static const route = '/claim/new';

  @override
  State<ClaimFormScreen> createState() => _ClaimFormScreenState();
}

class _ClaimFormScreenState extends State<ClaimFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameCtrl = TextEditingController();
  final _patientIdCtrl = TextEditingController();
  final _insurerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _patientIdCtrl.dispose();
    _insurerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final store = context.read<ClaimStore>();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final id = await store.createClaim(
        patientName: _patientNameCtrl.text,
        patientId: _patientIdCtrl.text,
        insurerName: _insurerCtrl.text,
        notes: _notesCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context)
        ..pop()
        ..pushNamed(ClaimDetailScreen.route, arguments: id);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create patient claim')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Patient details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _patientNameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Patient name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter patient name';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _patientIdCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Patient ID',
                  hintText: 'e.g., P-1003',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter patient ID';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _insurerCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Insurer name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                textInputAction: TextInputAction.newline,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Create claim'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

