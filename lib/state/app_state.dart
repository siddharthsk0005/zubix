import 'dart:async';
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/brand_model.dart';
import '../models/session_model.dart';
import '../models/voucher_model.dart';

enum AppRole { consumer, admin, brand }

enum SessionParticipationStatus { idle, waiting, completed }

class AppState extends ChangeNotifier {
  AppRole _currentRole = AppRole.consumer;
  AppRole get currentRole => _currentRole;

  void setRole(AppRole role) {
    _currentRole = role;
    notifyListeners();
  }

  // ----------------------------------------------------
  // CATEGORIES (Fully Flexible & Dynamic)
  // ----------------------------------------------------
  final List<CategoryModel> _categories = [
    CategoryModel(
      id: 'cat_fashion',
      name: 'Fashion and Lifestyle',
      slug: 'fashion-lifestyle',
      iconName: 'checkroom',
      displayOrder: 1,
    ),
    CategoryModel(
      id: 'cat_beauty',
      name: 'Beauty and Body Care',
      slug: 'beauty-body-care',
      iconName: 'spa',
      displayOrder: 2,
    ),
    CategoryModel(
      id: 'cat_home',
      name: 'Home Essentials',
      slug: 'home-essentials',
      iconName: 'home',
      displayOrder: 3,
    ),
    CategoryModel(
      id: 'cat_cosmetics',
      name: 'Cosmetics',
      slug: 'cosmetics',
      iconName: 'brush',
      displayOrder: 4,
    ),
    CategoryModel(
      id: 'cat_electronics',
      name: 'Electronics and Devices',
      slug: 'electronics-devices',
      iconName: 'devices',
      displayOrder: 5,
    ),
  ];

  List<CategoryModel> get categories => _categories.where((c) => c.isActive).toList();
  List<CategoryModel> get allCategories => _categories;

  String _selectedCategoryId = 'cat_fashion';
  String get selectedCategoryId => _selectedCategoryId;

  void selectCategory(String id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  void addCategory(String name, {String iconName = 'category'}) {
    final newId = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    final slug = name.toLowerCase().replaceAll(' ', '-').replaceAll('&', 'and');
    _categories.add(CategoryModel(
      id: newId,
      name: name,
      slug: slug,
      iconName: iconName,
      displayOrder: _categories.length + 1,
    ));
    notifyListeners();
  }

  void updateCategory(String id, String newName, {bool? isActive}) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index].name = newName;
      if (isActive != null) {
        _categories[index].isActive = isActive;
      }
      notifyListeners();
    }
  }

  void removeCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    if (_selectedCategoryId == id && _categories.isNotEmpty) {
      _selectedCategoryId = _categories.first.id;
    }
    notifyListeners();
  }

  // ----------------------------------------------------
  // BRANDS & PARTNERS
  // ----------------------------------------------------
  final List<BrandModel> _brands = [
    BrandModel(
      id: 'brand_aurora',
      name: 'AURORA Minimal',
      tagline: 'Timeless Monochromatic Streetwear & Silhouettes',
      bio: 'Aurora blends high-density Japanese cotton with architectural silhouettes. Designed for effortless modern wardrobes.',
      logoUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=200&auto=format&fit=crop&q=80',
      showcaseImages: [
        'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=900&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1445205170230-053b83016050?w=900&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=900&auto=format&fit=crop&q=80',
      ],
      websiteUrl: 'https://auroraminimal.example.com',
      socialLinks: {
        'Instagram': 'https://instagram.com/aurora.minimal',
        'X': 'https://x.com/auroraminimal',
        'LinkedIn': 'https://linkedin.com/company/aurora-apparel',
      },
      contactEmail: 'partner@auroraminimal.com',
      contactPhone: '+1 (555) 392-8810',
      categoryId: 'cat_fashion',
      sessionCreatedBy: 'Aman Verma (Lead Curator)',
      isApproved: true,
    ),
    BrandModel(
      id: 'brand_botanica',
      name: 'Botanica Botanics',
      tagline: 'Cold-Pressed Botanical Body & Skin Elixirs',
      bio: 'Zero-chemical, wild-harvested botanicals crafted for skin barrier restoration and natural glow.',
      logoUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=200&auto=format&fit=crop&q=80',
      showcaseImages: [
        'https://images.unsplash.com/photo-1608248597359-566085a85590?w=900&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=900&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=900&auto=format&fit=crop&q=80',
      ],
      websiteUrl: 'https://botanicabotanics.example.com',
      socialLinks: {
        'Instagram': 'https://instagram.com/botanica.official',
        'LinkedIn': 'https://linkedin.com/company/botanica-skincare',
      },
      contactEmail: 'press@botanica.com',
      contactPhone: '+1 (555) 782-9901',
      categoryId: 'cat_beauty',
      sessionCreatedBy: 'Siddharth Kumawat (Admin)',
      isApproved: true,
    ),
    BrandModel(
      id: 'brand_nordic',
      name: 'Nordic Space',
      tagline: 'Artisanal Ceramic & Wood Home Accents',
      bio: 'Functional interior objects celebrating raw organic textures and Scandinavian minimalism.',
      logoUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=200&auto=format&fit=crop&q=80',
      showcaseImages: [
        'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=900&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?w=900&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=900&auto=format&fit=crop&q=80',
      ],
      websiteUrl: 'https://nordicspace.example.com',
      socialLinks: {
        'Instagram': 'https://instagram.com/nordicspace',
        'X': 'https://x.com/nordic_space',
      },
      contactEmail: 'concierge@nordicspace.com',
      contactPhone: '+1 (555) 234-7712',
      categoryId: 'cat_home',
      sessionCreatedBy: 'Zubix Partner Guild',
      isApproved: true,
    ),
    BrandModel(
      id: 'brand_lumiere',
      name: 'LUMIÈRE Atelier',
      tagline: 'High-Pigment Vegan Mineral Cosmetics',
      bio: 'Clean performance makeup engineered for ultra-fine blendability and 18-hour weightless wear.',
      logoUrl: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=200&auto=format&fit=crop&q=80',
      showcaseImages: [
        'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=900&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=900&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?w=900&auto=format&fit=crop&q=80',
      ],
      websiteUrl: 'https://lumiereatelier.example.com',
      socialLinks: {
        'Instagram': 'https://instagram.com/lumiereatelier',
        'X': 'https://x.com/lumiere_cosmetics',
      },
      contactEmail: 'connect@lumiereatelier.com',
      contactPhone: '+1 (555) 912-3450',
      categoryId: 'cat_cosmetics',
      sessionCreatedBy: 'Admin Control Center',
      isApproved: true,
    ),
    BrandModel(
      id: 'brand_kanso',
      name: 'KANSO Audio & Tech',
      tagline: 'Precision Acoustic Hi-Fi & Wireless Earwear',
      bio: 'Bespoke precision audio with beryllium drivers and CNC anodized aluminum craftsmanship.',
      logoUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=200&auto=format&fit=crop&q=80',
      showcaseImages: [
        'https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=900&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=900&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=900&auto=format&fit=crop&q=80',
      ],
      websiteUrl: 'https://kansoaudio.example.com',
      socialLinks: {
        'Instagram': 'https://instagram.com/kansoaudio',
        'X': 'https://x.com/kanso_tech',
        'LinkedIn': 'https://linkedin.com/company/kanso-audio',
      },
      contactEmail: 'hello@kansoaudio.com',
      contactPhone: '+1 (555) 674-8890',
      categoryId: 'cat_electronics',
      sessionCreatedBy: 'Zubix Editorial Board',
      isApproved: true,
    ),
  ];

  List<BrandModel> get brands => _brands;
  List<BrandModel> get approvedBrands => _brands.where((b) => b.isApproved).toList();

  List<BrandModel> getBrandsForCategory(String catId) {
    return _brands.where((b) => b.categoryId == catId && b.isApproved).toList();
  }

  void addBrand(BrandModel brand) {
    _brands.add(brand);
    notifyListeners();
  }

  void approveBrand(String brandId, bool approve) {
    final idx = _brands.indexWhere((b) => b.id == brandId);
    if (idx != -1) {
      _brands[idx].isApproved = approve;
      notifyListeners();
    }
  }

  // ----------------------------------------------------
  // SESSIONS ("Generative Sessions")
  // ----------------------------------------------------
  final List<SessionModel> _sessions = [
    SessionModel(
      id: 'session_aurora_01',
      brandId: 'brand_aurora',
      sessionCreatedBy: 'Aman Verma (Admin)',
      waitingDurationSeconds: 15, // 15 seconds for effortless testing
      discountValue: '35% FLAT OFF',
      couponCode: 'ZUBIX-AURORA-35',
      status: 'active',
      totalVouchersPool: 250,
      claimedVouchersCount: 84,
    ),
    SessionModel(
      id: 'session_botanica_01',
      brandId: 'brand_botanica',
      sessionCreatedBy: 'Siddharth Kumawat',
      waitingDurationSeconds: 20,
      discountValue: '25% OFF + Free Elixir',
      couponCode: 'ZUBIX-BOTANICA-25',
      status: 'active',
      totalVouchersPool: 150,
      claimedVouchersCount: 42,
    ),
    SessionModel(
      id: 'session_kanso_01',
      brandId: 'brand_kanso',
      sessionCreatedBy: 'Zubix Editorial Board',
      waitingDurationSeconds: 25,
      discountValue: '\$50 INSTANT VOUCHER',
      couponCode: 'ZUBIX-KANSO-50',
      status: 'active',
      totalVouchersPool: 100,
      claimedVouchersCount: 61,
    ),
  ];

  List<SessionModel> get sessions => _sessions;

  SessionModel? getActiveSessionForBrand(String brandId) {
    try {
      return _sessions.firstWhere((s) => s.brandId == brandId && s.status == 'active');
    } catch (_) {
      return null;
    }
  }

  void addSession(SessionModel session) {
    _sessions.add(session);
    notifyListeners();
  }

  void updateSession(SessionModel session) {
    final idx = _sessions.indexWhere((s) => s.id == session.id);
    if (idx != -1) {
      _sessions[idx] = session;
      notifyListeners();
    }
  }

  // ----------------------------------------------------
  // GENERATIVE SESSION PARTICIPATION & WAITING ENGINE
  // ----------------------------------------------------
  SessionModel? _activeParticipatingSession;
  SessionModel? get activeParticipatingSession => _activeParticipatingSession;

  BrandModel? _activeParticipatingBrand;
  BrandModel? get activeParticipatingBrand => _activeParticipatingBrand;

  SessionParticipationStatus _participationStatus = SessionParticipationStatus.idle;
  SessionParticipationStatus get participationStatus => _participationStatus;

  int _remainingSeconds = 0;
  int get remainingSeconds => _remainingSeconds;

  int _totalWaitingSeconds = 0;
  int get totalWaitingSeconds => _totalWaitingSeconds;

  double get waitingProgress {
    if (_totalWaitingSeconds == 0) return 0.0;
    return 1.0 - (_remainingSeconds / _totalWaitingSeconds);
  }

  Timer? _countdownTimer;
  VoucherModel? _latestUnlockedVoucher;
  VoucherModel? get latestUnlockedVoucher => _latestUnlockedVoucher;

  void joinSession(SessionModel session, BrandModel brand) {
    _countdownTimer?.cancel();
    _activeParticipatingSession = session;
    _activeParticipatingBrand = brand;
    _totalWaitingSeconds = session.waitingDurationSeconds;
    _remainingSeconds = session.waitingDurationSeconds;
    _participationStatus = SessionParticipationStatus.waiting;
    _latestUnlockedVoucher = null;
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _remainingSeconds = 0;
        timer.cancel();
        _completeSessionAndUnlockVoucher();
      }
    });
  }

  void cancelParticipation() {
    _countdownTimer?.cancel();
    _participationStatus = SessionParticipationStatus.idle;
    _activeParticipatingSession = null;
    _activeParticipatingBrand = null;
    _remainingSeconds = 0;
    _totalWaitingSeconds = 0;
    notifyListeners();
  }

  void _completeSessionAndUnlockVoucher() {
    if (_activeParticipatingSession == null || _activeParticipatingBrand == null) return;

    final session = _activeParticipatingSession!;
    final brand = _activeParticipatingBrand!;

    session.claimedVouchersCount++;

    final newVoucher = VoucherModel(
      id: 'vouch_${DateTime.now().millisecondsSinceEpoch}',
      code: session.couponCode,
      brandName: brand.name,
      brandLogoUrl: brand.logoUrl,
      brandWebsite: brand.websiteUrl,
      discountValue: session.discountValue,
      categoryName: categories.firstWhere((c) => c.id == brand.categoryId, orElse: () => categories.first).name,
      claimedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 14)),
      terms: 'Valid on official store checkout. Single-use per account.',
    );

    _myVouchers.insert(0, newVoucher);
    _latestUnlockedVoucher = newVoucher;
    _participationStatus = SessionParticipationStatus.completed;
    notifyListeners();
  }

  void dismissCompletedSession() {
    _participationStatus = SessionParticipationStatus.idle;
    _activeParticipatingSession = null;
    _activeParticipatingBrand = null;
    notifyListeners();
  }

  // ----------------------------------------------------
  // MY VOUCHERS (Wallet Storage)
  // ----------------------------------------------------
  final List<VoucherModel> _myVouchers = [
    VoucherModel(
      id: 'vouch_seed_01',
      code: 'ZUBIX-AURORA-WELCOME',
      brandName: 'AURORA Minimal',
      brandLogoUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=200&auto=format&fit=crop&q=80',
      brandWebsite: 'https://auroraminimal.example.com',
      discountValue: '20% OFF',
      categoryName: 'Fashion and Lifestyle',
      claimedAt: DateTime.now().subtract(const Duration(days: 1)),
      expiresAt: DateTime.now().add(const Duration(days: 10)),
      terms: 'Minimum cart value \$80. Free shipping included.',
    ),
  ];

  List<VoucherModel> get myVouchers => _myVouchers;

  void markVoucherRedeemed(String voucherId) {
    final idx = _myVouchers.indexWhere((v) => v.id == voucherId);
    if (idx != -1) {
      _myVouchers[idx].isRedeemed = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
