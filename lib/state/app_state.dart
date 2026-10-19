import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/brand_model.dart';
import '../models/brand_registration_model.dart';
import '../models/session_model.dart';
import '../models/session_request_model.dart';
import '../models/voucher_model.dart';
import '../services/api_service.dart';
import '../services/storage/storage_service.dart';

enum AppRole { consumer, admin, brand }

enum SessionParticipationStatus { idle, waiting, completed }

class AppState extends ChangeNotifier {
  AppRole _currentRole = AppRole.consumer;
  AppRole get currentRole => _currentRole;

  String? _currentUserId = 'usr_demo_01';
  String? get currentUserId => _currentUserId;

  void setCurrentUserId(String? id) {
    _currentUserId = id;
    initFromBackend();
  }

  bool _isLoadingBackend = false;
  bool get isLoadingBackend => _isLoadingBackend;

  AppState() {
    _loadFromStorage();
    initFromBackend();
  }

  Future<void> initFromBackend() async {
    _isLoadingBackend = true;
    notifyListeners();
    try {
      final remoteCategories = await ApiService.getCategories();
      if (remoteCategories != null && remoteCategories.isNotEmpty) {
        _categories.clear();
        _categories.addAll(remoteCategories);
      }

      final remoteBrands = await ApiService.getBrands(approvedOnly: false);
      if (remoteBrands != null && remoteBrands.isNotEmpty) {
        _brands.clear();
        _brands.addAll(remoteBrands);
      }

      final remoteSessions = await ApiService.getAllSessions();
      if (remoteSessions != null && remoteSessions.isNotEmpty) {
        _sessions.clear();
        _sessions.addAll(remoteSessions);
      }

      final remoteVouchers = await ApiService.getVouchers(userId: _currentUserId);
      if (remoteVouchers != null && remoteVouchers.isNotEmpty) {
        _myVouchers.clear();
        _myVouchers.addAll(remoteVouchers);
      }

      await fetchNearbyStores();
    } catch (_) {}
    _isLoadingBackend = false;
    notifyListeners();
  }

  // ----------------------------------------------------
  // NEARBY LOCAL STORES & LOCATION
  // ----------------------------------------------------
  String _selectedCity = 'Indiranagar, Bengaluru';
  String get selectedCity => _selectedCity;

  final List<BrandModel> _nearbyStores = [];
  List<BrandModel> get nearbyStores => _nearbyStores;

  bool _isLoadingNearby = false;
  bool get isLoadingNearby => _isLoadingNearby;

  void setSelectedCity(String city) {
    if (_selectedCity == city.trim()) return;
    _selectedCity = city.trim();
    fetchNearbyStores();
  }

  Future<void> fetchNearbyStores() async {
    _isLoadingNearby = true;
    notifyListeners();

    try {
      final cityName = _selectedCity.split(',').last.trim();
      final remoteNearby = await ApiService.getNearbyStores(city: cityName);
      if (remoteNearby != null && remoteNearby.isNotEmpty) {
        _nearbyStores.clear();
        _nearbyStores.addAll(remoteNearby);
      }
    } catch (_) {}

    _isLoadingNearby = false;
    notifyListeners();
  }

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

  Future<void> addCategory(String name, {String iconName = 'category'}) async {
    final tempId = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    final slug = name.toLowerCase().replaceAll(' ', '-').replaceAll('&', 'and');
    final localCat = CategoryModel(
      id: tempId,
      name: name,
      slug: slug,
      iconName: iconName,
      displayOrder: _categories.length + 1,
    );
    _categories.add(localCat);
    notifyListeners();

    try {
      final created = await ApiService.createCategory(name, iconName: iconName);
      if (created != null) {
        final idx = _categories.indexWhere((c) => c.id == tempId);
        if (idx != -1) {
          _categories[idx] = created;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> updateCategory(String id, String newName, {bool? isActive}) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index].name = newName;
      if (isActive != null) {
        _categories[index].isActive = isActive;
      }
      notifyListeners();

      try {
        await ApiService.updateCategory(id, name: newName, isActive: isActive);
      } catch (_) {}
    }
  }

  Future<void> removeCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    if (_selectedCategoryId == id && _categories.isNotEmpty) {
      _selectedCategoryId = _categories.first.id;
    }
    notifyListeners();

    try {
      await ApiService.deleteCategory(id);
    } catch (_) {}
  }

  // ----------------------------------------------------
  // BRANDS & PARTNERS
  // ----------------------------------------------------
  final List<BrandModel> _brands = [];

  List<BrandModel> get brands => _brands;
  List<BrandModel> get approvedBrands => _brands.where((b) => b.isApproved).toList();

  List<BrandModel> getBrandsForCategory(String catId) {
    return _brands.where((b) => b.categoryId == catId && b.isApproved).toList();
  }

  Future<void> addBrand(BrandModel brand) async {
    _brands.add(brand);
    notifyListeners();

    try {
      final created = await ApiService.createBrand(
        name: brand.name,
        tagline: brand.tagline,
        bio: brand.bio,
        logoUrl: brand.logoUrl,
        showcaseImages: brand.showcaseImages,
        websiteUrl: brand.websiteUrl,
        socialLinks: brand.socialLinks,
        contactEmail: brand.contactEmail,
        contactPhone: brand.contactPhone,
        categoryId: brand.categoryId,
        sessionCreatedBy: brand.sessionCreatedBy,
      );
      if (created != null) {
        final idx = _brands.indexWhere((b) => b.id == brand.id);
        if (idx != -1) {
          _brands[idx] = created;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> updateBrand(BrandModel brand) async {
    final idx = _brands.indexWhere((b) => b.id == brand.id);
    if (idx != -1) {
      _brands[idx] = brand;
    }

    final nIdx = _nearbyStores.indexWhere((b) => b.id == brand.id);
    if (nIdx != -1) {
      _nearbyStores[nIdx] = brand;
    } else if (brand.isPhysicalStore) {
      _nearbyStores.add(brand);
    }
    notifyListeners();

    try {
      await ApiService.updateBrand(brand.id, {
        'name': brand.name,
        'tagline': brand.tagline,
        'bio': brand.bio,
        'logoUrl': brand.logoUrl,
        'showcaseImages': brand.showcaseImages,
        'websiteUrl': brand.websiteUrl,
        'socialLinks': brand.socialLinks,
        'contactEmail': brand.contactEmail,
        'contactPhone': brand.contactPhone,
        'categoryId': brand.categoryId,
        'isPhysicalStore': brand.isPhysicalStore,
        'storeType': brand.storeType,
        'city': brand.city,
        'area': brand.area,
        'address': brand.address,
        'googleMapsUrl': brand.googleMapsUrl,
        'timings': brand.timings,
        'latitude': brand.latitude,
        'longitude': brand.longitude,
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>> verifyAndRedeemCounterVoucher(String code) async {
    final cleanCode = code.trim().toUpperCase();

    // 1. Check local in-memory wallet
    final localIdx = _myVouchers.indexWhere((v) => v.code.toUpperCase() == cleanCode);
    if (localIdx != -1) {
      if (_myVouchers[localIdx].isRedeemed) {
        return {
          'success': false,
          'alreadyRedeemed': true,
          'message': 'This voucher was already redeemed previously!',
          'voucher': _myVouchers[localIdx],
        };
      }
      _myVouchers[localIdx].isRedeemed = true;
      notifyListeners();
    }

    // 2. Call remote Supabase database verification
    try {
      final remoteRes = await ApiService.verifyAndRedeemVoucher(cleanCode);
      if (remoteRes != null) {
        return remoteRes;
      }
    } catch (_) {}

    if (localIdx != -1) {
      return {
        'success': true,
        'alreadyRedeemed': false,
        'message': 'Voucher verified & redeemed successfully at store counter!',
        'voucher': _myVouchers[localIdx],
      };
    }

    return {
      'success': false,
      'alreadyRedeemed': false,
      'message': 'Invalid voucher code. Not found in system.',
    };
  }

  Future<void> approveBrand(String brandId, bool approve) async {
    final idx = _brands.indexWhere((b) => b.id == brandId);
    if (idx != -1) {
      _brands[idx].isApproved = approve;
      notifyListeners();

      try {
        await ApiService.approveBrand(brandId, approve);
      } catch (_) {}
    }
  }

  // ----------------------------------------------------
  // SESSIONS ("Generative Sessions")
  // ----------------------------------------------------
  final List<SessionModel> _sessions = [];

  List<SessionModel> get sessions => _sessions;

  SessionModel? getActiveSessionForBrand(String brandId) {
    try {
      return _sessions.firstWhere((s) => s.brandId == brandId && s.status == 'active');
    } catch (_) {
      return null;
    }
  }

  Future<void> addSession(SessionModel session) async {
    _sessions.add(session);
    notifyListeners();

    try {
      final created = await ApiService.createSession(
        brandId: session.brandId,
        sessionCreatedBy: session.sessionCreatedBy,
        waitingDurationSeconds: session.waitingDurationSeconds,
        discountValue: session.discountValue,
        couponCode: session.couponCode,
        totalVouchersPool: session.totalVouchersPool,
      );
      if (created != null) {
        final idx = _sessions.indexWhere((s) => s.id == session.id);
        if (idx != -1) {
          _sessions[idx] = created;
          notifyListeners();
        }
      }
    } catch (_) {}
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

  Future<void> _completeSessionAndUnlockVoucher() async {
    if (_activeParticipatingSession == null || _activeParticipatingBrand == null) return;

    final session = _activeParticipatingSession!;
    final brand = _activeParticipatingBrand!;

    session.claimedVouchersCount++;

    // Try backend Supabase voucher claim first
    VoucherModel? serverVoucher;
    try {
      serverVoucher = await ApiService.claimSessionVoucher(
        session.id,
        userId: _currentUserId,
      );
    } catch (_) {}

    final finalVoucher = serverVoucher ?? VoucherModel(
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

    _myVouchers.insert(0, finalVoucher);
    _latestUnlockedVoucher = finalVoucher;
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
  final List<VoucherModel> _myVouchers = [];

  List<VoucherModel> get myVouchers => _myVouchers;

  Future<void> markVoucherRedeemed(String voucherId) async {
    final idx = _myVouchers.indexWhere((v) => v.id == voucherId);
    if (idx != -1) {
      _myVouchers[idx].isRedeemed = true;
      notifyListeners();

      try {
        await ApiService.redeemVoucher(voucherId);
      } catch (_) {}
    }
  }

  // ----------------------------------------------------
  // BRAND REGISTRATIONS (Onboarding Applications & Active Brand)
  // ----------------------------------------------------
  String? _currentBrandRegistrationId;
  String? get currentBrandRegistrationId => _currentBrandRegistrationId;

  set currentBrandRegistrationId(String? id) {
    _currentBrandRegistrationId = id;
    _saveToStorage();
    notifyListeners();
  }

  BrandRegistrationModel? get currentBrandRegistration {
    if (_currentBrandRegistrationId != null) {
      final found = _brandRegistrations.where((r) => r.id == _currentBrandRegistrationId);
      if (found.isNotEmpty) return found.first;
    }
    return _brandRegistrations.isNotEmpty ? _brandRegistrations.first : null;
  }

  final List<BrandRegistrationModel> _brandRegistrations = [];

  List<BrandRegistrationModel> get brandRegistrations => _brandRegistrations;

  List<BrandRegistrationModel> get pendingRegistrations =>
      _brandRegistrations.where((r) => r.status == 'pending').toList();

  bool loginBrand(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    for (final reg in _brandRegistrations) {
      if (reg.ownerEmail.trim().toLowerCase() == cleanEmail) {
        if (password.isEmpty || reg.password == password.trim()) {
          _currentBrandRegistrationId = reg.id;
          _saveToStorage();
          notifyListeners();
          return true;
        }
      }
    }
    return false;
  }

  void submitBrandRegistration(BrandRegistrationModel reg) {
    // Check if brand already applied (reapply clears old rejected entry)
    _brandRegistrations.removeWhere(
        (r) => r.ownerPhone == reg.ownerPhone && r.status == 'rejected');
    _brandRegistrations.removeWhere((r) => r.id == reg.id);
    _brandRegistrations.insert(0, reg);
    _currentBrandRegistrationId = reg.id;
    _saveToStorage();
    notifyListeners();
  }

  void approveBrandRegistration(String regId, {String reviewedBy = 'Zubix Admin'}) {
    final idx = _brandRegistrations.indexWhere((r) => r.id == regId);
    if (idx == -1) return;
    _brandRegistrations[idx] = _brandRegistrations[idx].copyWith(
      status: 'approved',
      reviewedAt: DateTime.now(),
      reviewedBy: reviewedBy,
    );
    final reg = _brandRegistrations[idx];

    // INJECT REAL BRAND MODEL INTO THE ECOSYSTEM
    final newBrand = BrandModel(
      id: reg.id,
      name: reg.brandName,
      tagline: reg.brandType == 'online_d2c' ? 'Curated D2C Brand' : 'Boutique Atelier',
      bio: reg.description != null && reg.description!.isNotEmpty
          ? reg.description!
          : '${reg.brandName} exclusive collections on Zubix.',
      logoUrl: 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=400&q=80',
      showcaseImages: [
        'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=800&q=80',
      ],
      websiteUrl: reg.websiteUrl ?? '',
      socialLinks: {'instagram': reg.instagramUrl ?? ''},
      contactEmail: reg.ownerEmail,
      contactPhone: reg.ownerPhone,
      categoryId: reg.categoryId,
      isApproved: true,
      isPhysicalStore: reg.brandType == 'local_store',
      storeType: reg.brandType,
      city: reg.city ?? 'Bengaluru',
      area: reg.area ?? 'Indiranagar',
      address: reg.address,
      timings: reg.operatingHours ?? '10:00 AM - 9:00 PM',
      distanceKm: 1.2,
    );

    if (reg.brandType == 'local_store') {
      _nearbyStores.removeWhere((b) => b.id == reg.id);
      _nearbyStores.insert(0, newBrand);
    } else {
      _brands.removeWhere((b) => b.id == reg.id);
      _brands.insert(0, newBrand);
    }

    _saveToStorage();
    notifyListeners();
  }

  void rejectBrandRegistration(String regId, String reason,
      {String reviewedBy = 'Zubix Admin'}) {
    final idx = _brandRegistrations.indexWhere((r) => r.id == regId);
    if (idx == -1) return;
    _brandRegistrations[idx] = _brandRegistrations[idx].copyWith(
      status: 'rejected',
      rejectionReason: reason,
      reviewedAt: DateTime.now(),
      reviewedBy: reviewedBy,
    );
    _saveToStorage();
    notifyListeners();
  }

  // ----------------------------------------------------
  // SESSION REQUESTS (Brand-Initiated Session Scheduling)
  // ----------------------------------------------------
  final List<SessionRequestModel> _sessionRequests = [];

  List<SessionRequestModel> get sessionRequests => _sessionRequests;

  List<SessionRequestModel> get pendingSessionRequests =>
      _sessionRequests.where((r) => r.status == 'pending_approval').toList();

  void submitSessionRequest(SessionRequestModel req) {
    _sessionRequests.removeWhere((s) => s.id == req.id);
    _sessionRequests.insert(0, req);
    _saveToStorage();
    notifyListeners();
  }

  void approveSessionRequest(String reqId, {String reviewedBy = 'Zubix Admin'}) {
    final idx = _sessionRequests.indexWhere((r) => r.id == reqId);
    if (idx == -1) return;
    final req = _sessionRequests[idx];
    _sessionRequests[idx] = req.copyWith(
      status: 'approved',
      reviewedAt: DateTime.now(),
      reviewedBy: reviewedBy,
    );

    // Ensure the BrandModel exists in either _brands or _nearbyStores
    if (!_brands.any((b) => b.id == req.brandId) && !_nearbyStores.any((b) => b.id == req.brandId)) {
      final regMatch = _brandRegistrations.where((r) => r.id == req.brandId);
      final reg = regMatch.isNotEmpty
          ? regMatch.first
          : BrandRegistrationModel(
              id: req.brandId,
              brandName: req.brandName,
              ownerName: 'Brand Owner',
              ownerPhone: '',
              ownerEmail: '',
              password: '',
              brandType: req.brandType,
              categoryId: 'cat_fashion',
            );
      final brand = BrandModel(
        id: reg.id,
        name: reg.brandName,
        tagline: reg.brandType == 'online_d2c' ? 'Curated D2C Brand' : 'Boutique Atelier',
        bio: reg.description ?? '${reg.brandName} exclusive collections on Zubix.',
        logoUrl: 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=400&q=80',
        showcaseImages: [
          'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=800&q=80',
        ],
        websiteUrl: reg.websiteUrl ?? '',
        socialLinks: {},
        contactEmail: reg.ownerEmail,
        contactPhone: reg.ownerPhone,
        categoryId: reg.categoryId,
        isApproved: true,
        isPhysicalStore: reg.brandType == 'local_store',
        storeType: reg.brandType,
        city: reg.city ?? 'Bengaluru',
        area: reg.area,
        address: reg.address,
      );
      if (reg.brandType == 'local_store') {
        _nearbyStores.insert(0, brand);
      } else {
        _brands.insert(0, brand);
      }
    }

    final topDiscount = req.couponTiers.isNotEmpty ? req.couponTiers.first.discountPct : 20;
    final couponLabel = '$topDiscount% OFF';
    final cleanPrefix = req.brandName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final codePrefix = cleanPrefix.length >= 4
        ? cleanPrefix.substring(0, 4)
        : (cleanPrefix.isEmpty ? 'BRAND' : cleanPrefix);

    // Auto-create and immediately ACTIVATE the live session for the app
    final newSession = SessionModel(
      id: 'session_sr_$reqId',
      title: '${req.brandName} Generative Session',
      brandId: req.brandId,
      sessionCreatedBy: req.brandName,
      waitingDurationSeconds: 15,
      discountValue: couponLabel,
      couponCode: 'ZUBIX-$codePrefix-$topDiscount',
      status: 'active', // ACTIVE so it immediately appears in Live Active Sessions!
      totalVouchersPool: req.totalSlots,
    );

    _sessions.removeWhere((s) => s.id == newSession.id);
    _sessions.insert(0, newSession);
    _saveToStorage();
    notifyListeners();
  }

  void rejectSessionRequest(String reqId, String reason,
      {String reviewedBy = 'Zubix Admin'}) {
    final idx = _sessionRequests.indexWhere((r) => r.id == reqId);
    if (idx == -1) return;
    _sessionRequests[idx] = _sessionRequests[idx].copyWith(
      status: 'rejected',
      rejectionReason: reason,
      reviewedAt: DateTime.now(),
      reviewedBy: reviewedBy,
    );
    _saveToStorage();
    notifyListeners();
  }

  void proposeAlternateDates(String reqId, List<DateTime> dates,
      {String reviewedBy = 'Zubix Admin'}) {
    final idx = _sessionRequests.indexWhere((r) => r.id == reqId);
    if (idx == -1) return;
    _sessionRequests[idx] = _sessionRequests[idx].copyWith(
      status: 'dates_proposed',
      proposedDates: dates,
      reviewedAt: DateTime.now(),
      reviewedBy: reviewedBy,
    );
    _saveToStorage();
    notifyListeners();
  }

  void brandConfirmSessionDate(String reqId, DateTime confirmedDate) {
    final idx = _sessionRequests.indexWhere((r) => r.id == reqId);
    if (idx == -1) return;
    _sessionRequests[idx] = _sessionRequests[idx].copyWith(
      status: 'brand_confirmed',
      confirmedDate: confirmedDate,
    );
    _saveToStorage();
    notifyListeners();
  }

  // ----------------------------------------------------
  // LOCAL STORAGE PERSISTENCE (Sync across reloads & tabs)
  // ----------------------------------------------------
  void _saveToStorage() {
    try {
      // 1. Brand Registrations
      final regJson = jsonEncode(_brandRegistrations.map((r) => r.toJson()).toList());
      LocalStorageService.setString('zubix_brand_registrations', regJson);

      // 2. Session Requests
      final reqJson = jsonEncode(_sessionRequests.map((s) => s.toJson()).toList());
      LocalStorageService.setString('zubix_session_requests', reqJson);

      // 3. Active Brand ID
      if (_currentBrandRegistrationId != null) {
        LocalStorageService.setString('zubix_active_brand_id', _currentBrandRegistrationId!);
      }

      // 4. Custom approved D2C Brands
      final customBrands = _brands.where((b) => b.id.startsWith('reg_')).map((b) => b.toJson()).toList();
      LocalStorageService.setString('zubix_custom_brands', jsonEncode(customBrands));

      // 5. Custom approved Nearby Boutiques
      final customNearby = _nearbyStores.where((b) => b.id.startsWith('reg_')).map((b) => b.toJson()).toList();
      LocalStorageService.setString('zubix_custom_nearby', jsonEncode(customNearby));

      // 6. Custom approved Sessions
      final customSessions = _sessions.where((s) => s.id.startsWith('session_sr_')).map((s) => s.toJson()).toList();
      LocalStorageService.setString('zubix_custom_sessions', jsonEncode(customSessions));
    } catch (e) {
      debugPrint('Error saving to local storage: $e');
    }
  }

  void _loadFromStorage() {
    try {
      // 1. Brand Registrations (Filter out legacy demo items)
      final regRaw = LocalStorageService.getString('zubix_brand_registrations');
      if (regRaw != null && regRaw.isNotEmpty) {
        final list = (jsonDecode(regRaw) as List<dynamic>)
            .map((item) => BrandRegistrationModel.fromJson(item as Map<String, dynamic>))
            .where((r) => !r.id.contains('demo'))
            .toList();
        _brandRegistrations.clear();
        _brandRegistrations.addAll(list);
      }

      // 2. Active Brand ID
      final activeId = LocalStorageService.getString('zubix_active_brand_id');
      if (activeId != null && activeId.isNotEmpty && !activeId.contains('demo') && _brandRegistrations.any((r) => r.id == activeId)) {
        _currentBrandRegistrationId = activeId;
      } else if (_brandRegistrations.isNotEmpty) {
        _currentBrandRegistrationId = _brandRegistrations.first.id;
      } else {
        _currentBrandRegistrationId = null;
      }

      // 3. Session Requests (Filter out legacy demo items)
      final reqRaw = LocalStorageService.getString('zubix_session_requests');
      if (reqRaw != null && reqRaw.isNotEmpty) {
        final list = (jsonDecode(reqRaw) as List<dynamic>)
            .map((item) => SessionRequestModel.fromJson(item as Map<String, dynamic>))
            .where((s) => !s.id.contains('demo') && !s.brandId.contains('demo'))
            .toList();
        _sessionRequests.clear();
        _sessionRequests.addAll(list);
      }

      // 4. Custom D2C Brands (Filter out legacy mock brands)
      final cbRaw = LocalStorageService.getString('zubix_custom_brands');
      if (cbRaw != null && cbRaw.isNotEmpty) {
        final list = (jsonDecode(cbRaw) as List<dynamic>)
            .map((item) => BrandModel.fromJson(item as Map<String, dynamic>))
            .where((b) => !b.id.contains('demo') && !b.id.startsWith('brand_'))
            .toList();
        for (final b in list) {
          _brands.removeWhere((existing) => existing.id == b.id);
          _brands.insert(0, b);
        }
      }

      // 5. Custom Nearby Stores (Filter out legacy mock local stores)
      final cnRaw = LocalStorageService.getString('zubix_custom_nearby');
      if (cnRaw != null && cnRaw.isNotEmpty) {
        final list = (jsonDecode(cnRaw) as List<dynamic>)
            .map((item) => BrandModel.fromJson(item as Map<String, dynamic>))
            .where((b) => !b.id.contains('demo') && !b.id.startsWith('local_'))
            .toList();
        for (final b in list) {
          _nearbyStores.removeWhere((existing) => existing.id == b.id);
          _nearbyStores.insert(0, b);
        }
      }

      // 6. Custom Sessions (Filter out legacy mock sessions)
      final csRaw = LocalStorageService.getString('zubix_custom_sessions');
      if (csRaw != null && csRaw.isNotEmpty) {
        final list = (jsonDecode(csRaw) as List<dynamic>)
            .map((item) => SessionModel.fromJson(item as Map<String, dynamic>))
            .where((s) => !s.id.contains('demo') && !s.id.startsWith('session_aurora') && !s.id.startsWith('session_botanica') && !s.id.startsWith('session_kanso'))
            .toList();
        for (final s in list) {
          _sessions.removeWhere((existing) => existing.id == s.id);
          _sessions.insert(0, s);
        }
      }

      // Re-save sanitized state to storage
      _saveToStorage();
    } catch (e) {
      debugPrint('Error loading from local storage: $e');
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
