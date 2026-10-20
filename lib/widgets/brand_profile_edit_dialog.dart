import 'package:flutter/material.dart';
import '../models/brand_registration_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// Edits a brand's profile. Used by the brand portal and by admins. Pops with the saved BrandRegistrationModel.
Future<BrandRegistrationModel?> showBrandProfileEditDialog(
  BuildContext context,
  BrandRegistrationModel brand,
) {
  return showDialog<BrandRegistrationModel>(
    context: context,
    builder: (_) => BrandProfileEditDialog(brand: brand),
  );
}

class BrandProfileEditDialog extends StatefulWidget {
  final BrandRegistrationModel brand;

  const BrandProfileEditDialog({super.key, required this.brand});

  @override
  State<BrandProfileEditDialog> createState() => _BrandProfileEditDialogState();
}

class _BrandProfileEditDialogState extends State<BrandProfileEditDialog> {
  late final TextEditingController _brandName;
  late final TextEditingController _ownerName;
  late final TextEditingController _contactEmail;
  late final TextEditingController _contactPhone;
  late final TextEditingController _website;
  late final TextEditingController _instagram;
  late final TextEditingController _description;
  late final TextEditingController _city;
  late final TextEditingController _area;
  late final TextEditingController _address;
  late final TextEditingController _hours;
  late String _brandType;
  String? _categoryId;
  List<CategoryModel> _categories = const [];
  bool _loadingCategories = true;
  bool _saving = false;
  String? _error;

  bool get _isStore => _brandType == 'local_store';

  @override
  void initState() {
    super.initState();
    final b = widget.brand;
    _brandName = TextEditingController(text: b.brandName);
    _ownerName = TextEditingController(text: b.ownerName);
    _contactEmail = TextEditingController(text: b.ownerEmail);
    _contactPhone = TextEditingController(text: b.ownerPhone);
    _website = TextEditingController(text: b.websiteUrl ?? '');
    _instagram = TextEditingController(text: b.instagramUrl ?? '');
    _description = TextEditingController(text: b.description ?? '');
    _city = TextEditingController(text: b.city ?? '');
    _area = TextEditingController(text: b.area ?? '');
    _address = TextEditingController(text: b.address ?? '');
    _hours = TextEditingController(text: b.operatingHours ?? '');
    _brandType = b.brandType;
    _categoryId = b.categoryId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await ApiService.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories ?? const [];
      _loadingCategories = false;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _brandName,
      _ownerName,
      _contactEmail,
      _contactPhone,
      _website,
      _instagram,
      _description,
      _city,
      _area,
      _address,
      _hours,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate() {
    if (_brandName.text.trim().isEmpty) return 'Brand name is required.';
    if (_ownerName.text.trim().isEmpty) return 'Owner name is required.';
    final email = _contactEmail.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid contact email.';
    }
    if (_contactPhone.text.trim().isEmpty) return 'Contact phone is required.';
    if (_categoryId == null) return 'Select a category.';
    if (_isStore && (_city.text.trim().isEmpty || _address.text.trim().isEmpty)) {
      return 'City and address are required for a physical store.';
    }
    return null;
  }

  Future<void> _save() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await ApiService.updateBrandProfile(widget.brand.id, {
        'brandName': _brandName.text.trim(),
        'ownerName': _ownerName.text.trim(),
        'contactEmail': _contactEmail.text.trim(),
        'contactPhone': _contactPhone.text.trim(),
        'brandType': _brandType,
        'categoryId': _categoryId,
        'websiteUrl': _website.text.trim(),
        'instagramUrl': _instagram.text.trim(),
        'description': _description.text.trim(),
        'city': _isStore ? _city.text.trim() : '',
        'area': _isStore ? _area.text.trim() : '',
        'address': _isStore ? _address.text.trim() : '',
        'operatingHours': _isStore ? _hours.text.trim() : '',
      });
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget _field(TextEditingController c, String label, {String? helper, int maxLines = 1, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, helperText: helper),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit brand profile'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_brandName, 'Brand name'),
              _field(_ownerName, 'Owner name'),
              _field(
                _contactEmail,
                'Contact email',
                helper: 'This is also the brand login email.',
                type: TextInputType.emailAddress,
              ),
              _field(_contactPhone, 'Contact phone', type: TextInputType.phone),
              DropdownButtonFormField<String>(
                initialValue: _categories.any((c) => c.id == _categoryId)
                    ? _categoryId
                    : null,
                decoration: InputDecoration(
                  labelText: 'Category',
                  helperText: _loadingCategories ? 'Loading categories…' : null,
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _brandType,
                decoration: const InputDecoration(labelText: 'Brand type'),
                items: const [
                  DropdownMenuItem(value: 'online_d2c', child: Text('D2C / Online brand')),
                  DropdownMenuItem(value: 'local_store', child: Text('Local physical store')),
                ],
                onChanged: (v) => setState(() => _brandType = v ?? _brandType),
              ),
              const SizedBox(height: 12),
              _field(_website, 'Website (optional)', type: TextInputType.url),
              _field(_instagram, 'Instagram URL (optional)', type: TextInputType.url),
              _field(_description, 'About / bio', maxLines: 3),
              if (_isStore) ...[
                _field(_city, 'City'),
                _field(_area, 'Area (optional)'),
                _field(_address, 'Address'),
                _field(_hours, 'Operating hours (e.g. 10:00 AM - 9:30 PM)'),
              ],
              if (_error != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
