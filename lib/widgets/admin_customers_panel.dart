import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// Admin view of every customer, with an edit action for each.
class AdminCustomersPanel extends StatefulWidget {
  const AdminCustomersPanel({super.key});

  @override
  State<AdminCustomersPanel> createState() => _AdminCustomersPanelState();
}

class _AdminCustomersPanelState extends State<AdminCustomersPanel> {
  List<Map<String, dynamic>>? _customers;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ApiService.getCustomers();
    if (!mounted) return;
    setState(() {
      _customers = list ?? const [];
      _loading = false;
    });
  }

  Future<void> _edit(Map<String, dynamic> customer) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AdminCustomerEditDialog(customer: customer),
    );
    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final customers = _customers ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'All customers',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (customers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No customers yet',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          )
        else
          ...customers.map(_buildRow),
      ],
    );
  }

  Widget _buildRow(Map<String, dynamic> c) {
    final name = (c['name'] as String?)?.trim();
    final contact = [c['phone'], c['email']]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' · ');
    final location = [c['district'], c['state'], c['country']]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(', ');
    final status = (c['approvalStatus'] as String?) ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (name == null || name.isEmpty) ? 'Unnamed customer' : name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (contact.isNotEmpty)
                  Text(
                    contact,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                if (location.isNotEmpty)
                  Text(
                    location,
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _edit(c),
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class AdminCustomerEditDialog extends StatefulWidget {
  final Map<String, dynamic> customer;

  const AdminCustomerEditDialog({super.key, required this.customer});

  @override
  State<AdminCustomerEditDialog> createState() =>
      _AdminCustomerEditDialogState();
}

class _AdminCustomerEditDialogState extends State<AdminCustomerEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _country;
  late final TextEditingController _state;
  late final TextEditingController _district;
  bool _saving = false;
  String? _error;

  String _str(String key) => (widget.customer[key] as String?) ?? '';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _str('name'));
    _email = TextEditingController(text: _str('email'));
    _country = TextEditingController(text: _str('country'));
    _state = TextEditingController(text: _str('state'));
    _district = TextEditingController(text: _str('district'));
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _country, _state, _district]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiService.updateCustomer(_str('id'), {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'country': _country.text.trim(),
        'state': _state.text.trim(),
        'district': _district.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit customer'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _country,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _state,
                decoration: const InputDecoration(labelText: 'State'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _district,
                decoration: const InputDecoration(labelText: 'District'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                enabled: false,
                initialValue: _str('phone'),
                decoration: const InputDecoration(
                  labelText: 'Mobile number (cannot be changed)',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.pureBlack,
            foregroundColor: AppTheme.pureWhite,
          ),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}
