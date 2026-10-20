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

  String? _currentUserId;
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
    if (_activeBrandRegistration != null) {
      loadBrandSessionRequests().then((_) => notifyListeners());
    }
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

      final remoteVouchers = await ApiService.getVouchers(
        userId: _currentUserId,
      );
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
  final List<CategoryModel> _categories = [];

  List<CategoryModel> get categories =>
      _categories.where((c) => c.isActive).toList();
  List<CategoryModel> get allCategories => _categories;

  String _selectedCategoryId = '';
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

  Future<void> updateCategory(
    String id,
    String newName, {
    bool? isActive,
  }) async {
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
  List<BrandModel> get approvedBrands =>
      _brands.where((b) => b.isApproved).toList();

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

  Future<Map<String, dynamic>> verifyAndRedeemCounterVoucher(
    String code,
  ) async {
    final cleanCode = code.trim().toUpperCase();

    // 1. Check local in-memory wallet
    final localIdx = _myVouchers.indexWhere(
      (v) => v.code.toUpperCase() == cleanCode,
    );
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

  Future<bool> approveBrand(String brandId, bool approve) async {
    final idx = _brands.indexWhere((b) => b.id == brandId);
    if (idx == -1) return false;
    final previous = _brands[idx].isApproved;
    _brands[idx].isApproved = approve;
    notifyListeners();

    final ok = await ApiService.approveBrand(brandId, approve);
    if (!ok) {
      _brands[idx].isApproved = previous;
      notifyListeners();
    }
    return ok;
  }

  // ----------------------------------------------------
  // SESSIONS ("Generative Sessions")
  // ----------------------------------------------------
  final List<SessionModel> _sessions = [];

  List<SessionModel> get sessions => _sessions;

  SessionModel? getActiveSessionForBrand(String brandId) {
    try {
      return _sessions.firstWhere(
        (s) => s.brandId == brandId && s.status == 'active',
      );
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

  SessionParticipationStatus _participationStatus =
      SessionParticipationStatus.idle;
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
    if (_activeParticipatingSession == null ||
        _activeParticipatingBrand == null)
      return;

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

    final finalVoucher =
        serverVoucher ??
        VoucherModel(
          id: 'vouch_${DateTime.now().millisecondsSinceEpoch}',
          code: session.couponCode,
          brandName: brand.name,
          brandLogoUrl: brand.logoUrl,
          brandWebsite: brand.websiteUrl,
          discountValue: session.discountValue,
          categoryName: categories
              .firstWhere(
                (c) => c.id == brand.categoryId,
                orElse: () =>
                    CategoryModel(id: '', name: 'General', slug: 'general'),
              )
              .name,
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
  // Signed-in brand's registration. Restored from local storage after a refresh.
  BrandRegistrationModel? _activeBrandRegistration =
      ApiService.restoredBrandRegistration;
  BrandRegistrationModel? get currentBrandRegistration =>
      _activeBrandRegistration;

  final List<BrandRegistrationModel> _brandRegistrations = [];

  List<BrandRegistrationModel> get brandRegistrations => _brandRegistrations;

  List<BrandRegistrationModel> get pendingRegistrations =>
      _brandRegistrations.where((r) => r.status == 'pending').toList();

  // Customer sign-ups awaiting admin approval (raw backend rows).
  final List<Map<String, dynamic>> _customerApprovals = [];

  List<Map<String, dynamic>> get customerApprovals => _customerApprovals;

  int get pendingCustomerApprovals => _customerApprovals.length;

  // Returns null on success, or the message to show the user.
  Future<String?> loginBrand(String email, String password) async {
    try {
      _activeBrandRegistration = await ApiService.brandLogin(email, password);
    } on BrandAuthException catch (e) {
      return e.message;
    }
    await loadBrandSessionRequests();
    notifyListeners();
    return null;
  }

  void signOutBrand() {
    ApiService.brandSignOut();
    _activeBrandRegistration = null;
    _sessionRequests.clear();
    notifyListeners();
  }

  // Swaps in a registration saved from the brand profile editor.
  void replaceBrandRegistration(BrandRegistrationModel reg) {
    if (_activeBrandRegistration?.id == reg.id) {
      _activeBrandRegistration = reg;
    }
    final index = _brandRegistrations.indexWhere((r) => r.id == reg.id);
    if (index != -1) _brandRegistrations[index] = reg;
    notifyListeners();
  }

  // Loads only this brand's requests (the server rejects admin-wide lists for brand tokens).
  Future<void> loadBrandSessionRequests() async {
    final reqs = await ApiService.getBrandSessionRequests();
    if (reqs != null) {
      _sessionRequests
        ..clear()
        ..addAll(reqs);
    }
    notifyListeners();
  }

  // The password is sent to the backend (hashed there) and is never kept on this device.
  Future<bool> submitBrandRegistration(
    BrandRegistrationModel reg,
    String password,
  ) async {
    final saved = await ApiService.submitBrandRegistration(reg, password);
    return saved != null;
  }

  // Replaces the admin queue with the backend's list (server is the source of truth).
  Future<void> loadAdminQueues() async {
    final regs = await ApiService.getBrandRegistrations();
    if (regs != null) {
      _brandRegistrations
        ..clear()
        ..addAll(regs);
    }
    final reqs = await ApiService.getSessionRequests();
    if (reqs != null) {
      _sessionRequests
        ..clear()
        ..addAll(reqs);
    }
    final customers = await ApiService.getCustomerApprovals();
    if (customers != null) {
      _customerApprovals
        ..clear()
        ..addAll(customers);
    }
    _saveToStorage();
    notifyListeners();
  }

  // After any admin action, refresh the admin queues and the public brand/session data.
  Future<void> _refreshAfterReview() async {
    await loadAdminQueues();
    await initFromBackend();
  }

  Future<bool> approveBrandRegistration(
    String regId, {
    String reviewedBy = 'Admin',
  }) async {
    final updated = await ApiService.reviewBrandRegistration(
      regId,
      action: 'approve',
      reviewedBy: reviewedBy,
    );
    if (updated == null) return false;
    await _refreshAfterReview();
    return true;
  }

  Future<bool> rejectBrandRegistration(
    String regId,
    String reason, {
    String reviewedBy = 'Admin',
  }) async {
    final updated = await ApiService.reviewBrandRegistration(
      regId,
      action: 'reject',
      reason: reason,
      reviewedBy: reviewedBy,
    );
    if (updated == null) return false;
    await _refreshAfterReview();
    return true;
  }

  Future<bool> reviewCustomerApproval(
    String userId, {
    required bool approve,
  }) async {
    final ok = await ApiService.reviewCustomerApproval(
      userId,
      action: approve ? 'approve' : 'reject',
    );
    if (!ok) return false;
    await loadAdminQueues();
    return true;
  }

  // ----------------------------------------------------
  // SESSION REQUESTS (Brand-Initiated Session Scheduling)
  // ----------------------------------------------------
  final List<SessionRequestModel> _sessionRequests = [];

  List<SessionRequestModel> get sessionRequests => _sessionRequests;

  List<SessionRequestModel> get pendingSessionRequests =>
      _sessionRequests.where((r) => r.status == 'pending_approval').toList();

  // Returns true when the server saved the request.
  Future<bool> submitSessionRequest(SessionRequestModel req) async {
    final saved = await ApiService.submitSessionRequest(req);
    if (saved == null) return false;
    _sessionRequests.removeWhere((s) => s.id == req.id);
    _sessionRequests.insert(0, saved);
    notifyListeners();
    return true;
  }

  // Server creates the live session and coupon when approved.
  Future<bool> approveSessionRequest(
    String reqId, {
    String reviewedBy = 'Admin',
  }) async {
    final updated = await ApiService.reviewSessionRequest(
      reqId,
      action: 'approve',
      reviewedBy: reviewedBy,
    );
    if (updated == null) return false;
    await _refreshAfterReview();
    return true;
  }

  Future<bool> rejectSessionRequest(
    String reqId,
    String reason, {
    String reviewedBy = 'Admin',
  }) async {
    final updated = await ApiService.reviewSessionRequest(
      reqId,
      action: 'reject',
      reason: reason,
      reviewedBy: reviewedBy,
    );
    if (updated == null) return false;
    await loadAdminQueues();
    return true;
  }

  Future<bool> proposeAlternateDates(
    String reqId,
    List<DateTime> dates, {
    String reviewedBy = 'Admin',
  }) async {
    final updated = await ApiService.reviewSessionRequest(
      reqId,
      action: 'propose',
      proposedDates: dates,
      reviewedBy: reviewedBy,
    );
    if (updated == null) return false;
    await loadAdminQueues();
    return true;
  }

  Future<bool> brandConfirmSessionDate(
    String reqId,
    DateTime confirmedDate,
  ) async {
    final updated = await ApiService.confirmSessionRequest(
      reqId,
      confirmedDate,
    );
    if (updated == null) return false;
    final idx = _sessionRequests.indexWhere((r) => r.id == reqId);
    if (idx != -1) _sessionRequests[idx] = updated;
    _saveToStorage();
    notifyListeners();
    return true;
  }

  // ----------------------------------------------------
  // LOCAL STORAGE PERSISTENCE (Sync across reloads & tabs)
  // ----------------------------------------------------
  void _saveToStorage() {
    try {
      // 1. Custom approved D2C Brands
      final customBrands = _brands
          .where((b) => b.id.startsWith('reg_'))
          .map((b) => b.toJson())
          .toList();
      LocalStorageService.setString(
        'zubix_custom_brands',
        jsonEncode(customBrands),
      );

      // 2. Custom approved Nearby Boutiques
      final customNearby = _nearbyStores
          .where((b) => b.id.startsWith('reg_'))
          .map((b) => b.toJson())
          .toList();
      LocalStorageService.setString(
        'zubix_custom_nearby',
        jsonEncode(customNearby),
      );

      // 3. Custom approved Sessions
      final customSessions = _sessions
          .where((s) => s.id.startsWith('session_sr_'))
          .map((s) => s.toJson())
          .toList();
      LocalStorageService.setString(
        'zubix_custom_sessions',
        jsonEncode(customSessions),
      );
    } catch (e) {
      debugPrint('Error saving to local storage: $e');
    }
  }

  void _loadFromStorage() {
    try {
      // Registrations, the active brand and requests live on the server now.
      // Remove device copies left by earlier builds so they cannot be used to sign in.
      LocalStorageService.remove('zubix_brand_registrations');
      LocalStorageService.remove('zubix_active_brand_id');
      LocalStorageService.remove('zubix_session_requests');

      final cbRaw = LocalStorageService.getString('zubix_custom_brands');
      if (cbRaw != null && cbRaw.isNotEmpty) {
        final list = (jsonDecode(cbRaw) as List<dynamic>)
            .map((item) => BrandModel.fromJson(item as Map<String, dynamic>))
            .toList();
        for (final b in list) {
          _brands.removeWhere((existing) => existing.id == b.id);
          _brands.insert(0, b);
        }
      }

      final cnRaw = LocalStorageService.getString('zubix_custom_nearby');
      if (cnRaw != null && cnRaw.isNotEmpty) {
        final list = (jsonDecode(cnRaw) as List<dynamic>)
            .map((item) => BrandModel.fromJson(item as Map<String, dynamic>))
            .toList();
        for (final b in list) {
          _nearbyStores.removeWhere((existing) => existing.id == b.id);
          _nearbyStores.insert(0, b);
        }
      }

      final csRaw = LocalStorageService.getString('zubix_custom_sessions');
      if (csRaw != null && csRaw.isNotEmpty) {
        final list = (jsonDecode(csRaw) as List<dynamic>)
            .map((item) => SessionModel.fromJson(item as Map<String, dynamic>))
            .toList();
        for (final s in list) {
          _sessions.removeWhere((existing) => existing.id == s.id);
          _sessions.insert(0, s);
        }
      }

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
