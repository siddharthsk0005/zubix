import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

// Edits the signed-in customer's own details. The phone number is locked because it is the login identity.
Future<void> showCustomerProfileEditDialog(
  BuildContext context,
  UserModel user,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => CustomerProfileEditDialog(user: user),
  );
}

class CustomerProfileEditDialog extends ConsumerStatefulWidget {
  final UserModel user;

  const CustomerProfileEditDialog({super.key, required this.user});

  @override
  ConsumerState<CustomerProfileEditDialog> createState() =>
      _CustomerProfileEditDialogState();
}

class _CustomerProfileEditDialogState
    extends ConsumerState<CustomerProfileEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _country;
  late final TextEditingController _state;
  late final TextEditingController _district;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name ?? '');
    _email = TextEditingController(text: widget.user.email ?? '');
    _country = TextEditingController(text: widget.user.country ?? '');
    _state = TextEditingController(text: widget.user.state ?? '');
    _district = TextEditingController(text: widget.user.district ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _country.dispose();
    _state.dispose();
    _district.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .updateProfile(
            name: _name.text,
            email: _email.text,
            country: _country.text,
            userState: _state.text,
            district: _district.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      title: const Text('Edit profile'),
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
                initialValue: widget.user.phone ?? '',
                decoration: const InputDecoration(
                  labelText: 'Mobile number (cannot be changed)',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
