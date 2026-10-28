// ignore_for_file: use_null_aware_elements
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/brand_media_model.dart';
import '../models/category_model.dart';
import '../models/brand_model.dart';
import '../models/session_model.dart';
import '../models/voucher_model.dart';
import '../models/user_model.dart';
import '../models/brand_registration_model.dart';
import '../models/session_request_model.dart';
import 'storage/storage_service.dart';

class BrandAuthException implements Exception {
  final String message;
  const BrandAuthException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      if (kDebugMode) return 'http://localhost:4000';
      return Uri.base.origin;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000'; // Direct connectivity to local server on Android
    }
    return 'https://www.zubixapp.com';
  }

  static Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------- AUTH (Supabase User Accounts & OTP) ----------------
  static Future<Map<String, dynamic>?> sendOtp(String phone) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/auth/send-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone.trim()}),
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // Checks a code without creating a user. Returns true only if the backend accepted it.
  static Future<bool> checkOtp(String phone, String otp) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/auth/check-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone.trim(), 'otp': otp.trim()}),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> verifyOtp(
    String phone,
    String otp,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/auth/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone.trim(), 'otp': otp.trim()}),
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'success': true,
          'isNewUser': data['isNewUser'] == true,
          'isProfileComplete': data['isProfileComplete'] == true,
          'token': data['token'] as String?,
          'user': UserModel.fromJson(data['user'] as Map<String, dynamic>),
        };
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> socialLogin(
    String provider, {
    String? email,
    String? name,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/auth/social-login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'provider': provider,
              'email':
                  email?.trim() ??
                  'member.${provider.toLowerCase()}@zubix.example',
              'name': name?.trim() ?? 'Zubix Member',
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'success': true,
          'isNewUser': data['isNewUser'] == true,
          'isProfileComplete': data['isProfileComplete'] == true,
          'token': data['token'] as String?,
          'user': UserModel.fromJson(data['user'] as Map<String, dynamic>),
        };
      }
    } catch (_) {}
    return null;
  }

  // Saves the customer token issued at sign-in; used for self-service profile edits.
  static void setCustomerToken(String? token) {
    _customerToken = token;
    if (token == null) {
      LocalStorageService.remove(_customerTokenKey);
    } else {
      LocalStorageService.setString(_customerTokenKey, token);
    }
  }

  // Updates the signed-in customer's own profile. Phone is not editable here.
  static Future<UserModel?> updateCustomerProfile({
    required String name,
    required String? email,
    required String country,
    required String state,
    required String district,
  }) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/api/auth/profile'),
            headers: _customerHeaders,
            body: jsonEncode({
              'name': name.trim(),
              'email': email?.trim() ?? '',
              'country': country.trim(),
              'state': state.trim(),
              'district': district.trim(),
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
      final err = _errorFrom(res.body);
      throw Exception(err ?? 'Could not save your profile.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Could not save your profile. Check your connection.');
    }
  }

  // Returns the approval status for a customer ('draft' | 'pending' | 'approved' | 'rejected').
  static Future<String?> getApprovalStatus(String userId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/auth/approval-status/$userId'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['approvalStatus'] as String?;
      }
    } catch (_) {}
    return null;
  }

  static Future<UserModel?> completeProfile({
    required String userId,
    required String name,
    required String phone,
    required String country,
    required String state,
    required String district,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/auth/complete-profile'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'name': name.trim(),
              'phone': phone.trim(),
              'country': country.trim(),
              'state': state.trim(),
              'district': district.trim(),
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/auth/me?userId=$userId'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  static Future<UserModel?> register(
    String email, {
    String? name,
    String role = 'consumer',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              if (name != null) 'name': name,
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return UserModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<UserModel?> login(String email, {String? name}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, if (name != null) 'name': name}),
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return UserModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  // ---------------- SESSION PERSISTENCE ----------------
  // Admin and brand sessions survive a page refresh via local storage.
  static const _adminTokenKey = 'zubix_admin_token';
  static const _brandTokenKey = 'zubix_brand_token';
  static const _brandRegistrationKey = 'zubix_brand_registration';
  static const _customerTokenKey = 'zubix_customer_token';

  static String? _adminToken;
  static String? _brandToken;
  static String? _customerToken;
  static BrandRegistrationModel? _restoredBrandRegistration;

  static bool get isAdminSignedIn => _adminToken != null;
  static bool get isBrandSignedIn => _brandToken != null;
  static bool get isCustomerSignedIn => _customerToken != null;

  // Extracts the "error" message from a backend JSON error body.
  static String? _errorFrom(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['error'] is String) return data['error'] as String;
    } catch (_) {}
    return null;
  }

  // The signed-in brand's registration, restored after a refresh.
  static BrandRegistrationModel? get restoredBrandRegistration =>
      _restoredBrandRegistration;

  // Tokens are "payload.signature"; the payload carries the expiry (ms).
  static bool _isTokenFresh(String token) {
    try {
      final payload = token.split('.').first;
      final data =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(payload))),
              )
              as Map<String, dynamic>;
      final exp = data['exp'];
      return exp is num && exp > DateTime.now().millisecondsSinceEpoch;
    } catch (_) {
      return false;
    }
  }

  // Call once at startup, before the first screen builds.
  static void restoreSessions() {
    final customer = LocalStorageService.getString(_customerTokenKey);
    if (customer != null && _isTokenFresh(customer)) {
      _customerToken = customer;
    } else {
      LocalStorageService.remove(_customerTokenKey);
    }

    final admin = LocalStorageService.getString(_adminTokenKey);
    if (admin != null && _isTokenFresh(admin)) {
      _adminToken = admin;
    } else {
      LocalStorageService.remove(_adminTokenKey);
    }

    final brand = LocalStorageService.getString(_brandTokenKey);
    final regRaw = LocalStorageService.getString(_brandRegistrationKey);
    if (brand != null && regRaw != null && _isTokenFresh(brand)) {
      try {
        _restoredBrandRegistration = BrandRegistrationModel.fromJson(
          jsonDecode(regRaw) as Map<String, dynamic>,
        );
        _brandToken = brand;
      } catch (_) {
        _clearBrandStorage();
      }
    } else {
      _clearBrandStorage();
    }
  }

  static void _clearBrandStorage() {
    LocalStorageService.remove(_brandTokenKey);
    LocalStorageService.remove(_brandRegistrationKey);
    _brandToken = null;
    _restoredBrandRegistration = null;
  }

  static Map<String, String> get _adminHeaders => {
    'Content-Type': 'application/json',
    if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
  };

  static Map<String, String> get _brandHeaders => {
    'Content-Type': 'application/json',
    if (_brandToken != null) 'Authorization': 'Bearer $_brandToken',
  };

  static Map<String, String> get _customerHeaders => {
    'Content-Type': 'application/json',
    if (_customerToken != null) 'Authorization': 'Bearer $_customerToken',
  };

  // Used by brand writes that admins may also perform (updateBrand).
  static Map<String, String> get _brandOrAdminHeaders => {
    'Content-Type': 'application/json',
    if (_adminToken != null)
      'Authorization': 'Bearer $_adminToken'
    else if (_brandToken != null)
      'Authorization': 'Bearer $_brandToken',
  };

  // Returns true when the backend accepts the credentials for an admin account.
  static Future<bool> adminLogin(String email, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/admin/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return false;
      final token =
          (jsonDecode(res.body) as Map<String, dynamic>)['token'] as String?;
      if (token == null) return false;
      _adminToken = token;
      LocalStorageService.setString(_adminTokenKey, token);
      return true;
    } catch (_) {
      return false;
    }
  }

  static void adminSignOut() {
    _adminToken = null;
    LocalStorageService.remove(_adminTokenKey);
  }

  // Returns the brand registration on success, or throws the server message on failure.
  static Future<BrandRegistrationModel> brandLogin(
    String email,
    String password,
  ) async {
    final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('$baseUrl/api/brand/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      throw const BrandAuthException(
        'Could not reach the server. Please try again.',
      );
    }
    final body =
        jsonDecode(res.body.isEmpty ? '{}' : res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw BrandAuthException((body['error'] as String?) ?? 'Sign in failed.');
    }
    final token = body['token'] as String?;
    final registrationJson = body['registration'] as Map<String, dynamic>;
    final registration = BrandRegistrationModel.fromJson(registrationJson);
    _brandToken = token;
    _restoredBrandRegistration = registration;
    if (token != null) {
      LocalStorageService.setString(_brandTokenKey, token);
      LocalStorageService.setString(
        _brandRegistrationKey,
        jsonEncode(registrationJson),
      );
    }
    return registration;
  }

  static void brandSignOut() {
    _clearBrandStorage();
  }

  static Future<List<SessionRequestModel>?> getBrandSessionRequests() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/brand/session-requests'),
            headers: _brandHeaders,
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map(
              (item) =>
                  SessionRequestModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (_) {}
    return null;
  }

  // ---------------- CATEGORIES (Supabase CRUD) ----------------
  static Future<List<CategoryModel>?> getCategories({String? scope}) async {
    try {
      final query = scope == null ? '' : '?scope=$scope';
      final res = await http
          .get(Uri.parse('$baseUrl/api/categories$query'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<CategoryModel?> createCategory(
    String name, {
    String iconName = 'category',
    String scope = 'brand',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/categories'),
            headers: _adminHeaders,
            body: jsonEncode({'name': name, 'iconName': iconName, 'scope': scope}),
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 201) {
        return CategoryModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> updateCategory(
    String id, {
    String? name,
    bool? isActive,
    String? scope,
  }) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/api/categories/$id'),
            headers: _adminHeaders,
            body: jsonEncode({
              if (name case final n?) 'name': n,
              if (isActive case final a?) 'isActive': a,
              if (scope case final s?) 'scope': s,
            }),
          )
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteCategory(String id) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$baseUrl/api/categories/$id'),
            headers: _adminHeaders,
          )
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------- BRANDS (Supabase CRUD) ----------------
  static Future<List<BrandModel>?> getBrands({
    String? categoryId,
    bool approvedOnly = true,
  }) async {
    try {
      var url = '$baseUrl/api/brands?approvedOnly=$approvedOnly';
      if (categoryId != null) url += '&categoryId=$categoryId';
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map((item) => BrandModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<List<BrandModel>?> getNearbyStores({
    String? city,
    double? lat,
    double? lng,
    double radiusKm = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        if (lat != null) 'lat': lat.toString(),
        if (lng != null) 'lng': lng.toString(),
        'radiusKm': radiusKm.toString(),
      };
      final uri = Uri.parse(
        '$baseUrl/api/brands/nearby',
      ).replace(queryParameters: queryParams);
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map((item) => BrandModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<BrandModel?> createBrand({
    required String name,
    String tagline = '',
    String bio = '',
    String logoUrl = '',
    List<String> showcaseImages = const [],
    String websiteUrl = '',
    Map<String, String> socialLinks = const {},
    String contactEmail = '',
    String contactPhone = '',
    required String categoryId,
    String sessionCreatedBy = 'Admin Curators',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/brands'),
            headers: _adminHeaders,
            body: jsonEncode({
              'name': name,
              'tagline': tagline,
              'bio': bio,
              'logoUrl': logoUrl,
              'showcaseImages': showcaseImages,
              'websiteUrl': websiteUrl,
              'socialLinks': socialLinks,
              'contactEmail': contactEmail,
              'contactPhone': contactPhone,
              'categoryId': categoryId,
              'sessionCreatedBy': sessionCreatedBy,
            }),
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 201) {
        return BrandModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> updateBrand(String id, Map<String, dynamic> data) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/api/brands/$id'),
            headers: _brandOrAdminHeaders,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Brand logo: one image shown on the brand card and wherever the brand appears.
  static Future<String> uploadBrandLogo(
    String brandId, {
    required String mimeType,
    required Uint8List bytes,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/brands/$brandId/logo'),
            headers: _brandOrAdminHeaders,
            body: jsonEncode({
              'mimeType': mimeType,
              'dataBase64': base64Encode(bytes),
            }),
          )
          .timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as Map<String, dynamic>)['logoUrl'] as String? ?? '';
      }
      throw Exception(_errorFrom(res.body) ?? 'Could not upload the logo.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Could not reach the server.');
    }
  }

  static Future<void> removeBrandLogo(String brandId) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$baseUrl/api/brands/$brandId/logo'),
            headers: _brandOrAdminHeaders,
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return;
      throw Exception(_errorFrom(res.body) ?? 'Could not remove the logo.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Could not reach the server.');
    }
  }

  // Brand media: ordered images/videos shown to customers on the Brands page.
  static Future<List<BrandMediaItem>> getBrandMedia(String brandId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/brands/$brandId/media'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List<dynamic>)
            .map((e) => BrandMediaItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(_errorFrom(res.body) ?? 'Could not load brand media.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Could not reach the server.');
    }
  }

  static Future<BrandMediaItem> uploadBrandMedia(
    String brandId, {
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/brands/$brandId/media'),
            headers: _brandOrAdminHeaders,
            body: jsonEncode({
              'fileName': fileName,
              'mimeType': mimeType,
              'dataBase64': base64Encode(bytes),
            }),
          )
          .timeout(const Duration(seconds: 120));
      if (res.statusCode == 201) {
        return BrandMediaItem.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
      throw Exception(_errorFrom(res.body) ?? 'Upload failed.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Could not reach the server.');
    }
  }

  // [orderedIds] must contain every media id of the brand exactly once.
  static Future<List<BrandMediaItem>> reorderBrandMedia(
    String brandId,
    List<String> orderedIds,
  ) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/api/brands/$brandId/media/order'),
            headers: _brandOrAdminHeaders,
            body: jsonEncode({'ids': orderedIds}),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List<dynamic>)
            .map((e) => BrandMediaItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(_errorFrom(res.body) ?? 'Could not save the new order.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Could not reach the server.');
    }
  }

  static Future<void> deleteBrandMedia(String brandId, String mediaId) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$baseUrl/api/brands/$brandId/media/$mediaId'),
            headers: _brandOrAdminHeaders,
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return;
      throw Exception(_errorFrom(res.body) ?? 'Could not delete the file.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Could not reach the server.');
    }
  }

  // Saves the brand profile (portal registration + live listing). Returns the updated registration; throws with the backend message on failure.
  static Future<BrandRegistrationModel> updateBrandProfile(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/api/brands/$id/profile'),
            headers: _brandOrAdminHeaders,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final registrationJson = body['registration'] as Map<String, dynamic>;
        final saved = BrandRegistrationModel.fromJson(registrationJson);
        // Keep the signed-in brand's cached session in sync. Admins editing other brands skip this.
        if (_restoredBrandRegistration?.id == saved.id) {
          _restoredBrandRegistration = saved;
          LocalStorageService.setString(
            _brandRegistrationKey,
            jsonEncode(registrationJson),
          );
        }
        return saved;
      }
      throw Exception(_errorFrom(res.body) ?? 'Could not save the brand profile.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Could not save the brand profile. Check your connection.');
    }
  }

  // ---------------- CUSTOMERS (admin) ----------------
  static Future<List<Map<String, dynamic>>?> getCustomers() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/customers'), headers: _adminHeaders)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return null;
  }

  // Admin edit of a customer. Throws with the backend message on failure.
  static Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/api/customers/$id'),
            headers: _adminHeaders,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) return;
      throw Exception(_errorFrom(res.body) ?? 'Could not save the customer.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Could not save the customer. Check your connection.');
    }
  }

  static Future<bool> approveBrand(String id, bool isApproved) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/api/brands/$id/approve'),
            headers: _adminHeaders,
            body: jsonEncode({'isApproved': isApproved}),
          )
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------- BRAND REGISTRATIONS (public submit, admin review) ----------------
  static Future<BrandRegistrationModel?> submitBrandRegistration(
    BrandRegistrationModel reg,
    String password,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/brand-registrations'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({...reg.toJson(), 'password': password}),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 201 || res.statusCode == 200) {
        return BrandRegistrationModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<List<BrandRegistrationModel>?> getBrandRegistrations() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/brand-registrations'),
            headers: _adminHeaders,
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map(
              (item) =>
                  BrandRegistrationModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<BrandRegistrationModel?> reviewBrandRegistration(
    String id, {
    required String action,
    String? reason,
    String reviewedBy = 'Admin',
  }) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/api/brand-registrations/$id/review'),
            headers: _adminHeaders,
            body: jsonEncode({
              'action': action,
              'reason': reason,
              'reviewedBy': reviewedBy,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return BrandRegistrationModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  // ---------------- CUSTOMER APPROVALS (admin) ----------------
  static Future<List<Map<String, dynamic>>?> getCustomerApprovals() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/customer-approvals'),
            headers: _adminHeaders,
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> reviewCustomerApproval(
    String id, {
    required String action,
  }) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/api/customer-approvals/$id/review'),
            headers: _adminHeaders,
            body: jsonEncode({'action': action}),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  // ---------------- SESSION REQUESTS (brand submit, admin review) ----------------
  static Future<SessionRequestModel?> submitSessionRequest(
    SessionRequestModel req,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/session-requests'),
            headers: _brandHeaders,
            body: jsonEncode(req.toJson()),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 201 || res.statusCode == 200) {
        return SessionRequestModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<List<SessionRequestModel>?> getSessionRequests() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/session-requests'),
            headers: _adminHeaders,
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map(
              (item) =>
                  SessionRequestModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (_) {}
    return null;
  }

  // action: approve | reject | propose (propose also needs proposedDates)
  static Future<SessionRequestModel?> reviewSessionRequest(
    String id, {
    required String action,
    String? reason,
    List<DateTime>? proposedDates,
    String reviewedBy = 'Admin',
  }) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/api/session-requests/$id/review'),
            headers: _adminHeaders,
            body: jsonEncode({
              'action': action,
              'reason': reason,
              'reviewedBy': reviewedBy,
              if (proposedDates != null)
                'proposedDates': proposedDates
                    .map((d) => d.toUtc().toIso8601String())
                    .toList(),
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return SessionRequestModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  // Brand confirms one of the admin-proposed dates.
  static Future<SessionRequestModel?> confirmSessionRequest(
    String id,
    DateTime confirmedDate,
  ) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/api/session-requests/$id/confirm'),
            headers: _brandHeaders,
            body: jsonEncode({
              'confirmedDate': confirmedDate.toUtc().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return SessionRequestModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  // ---------------- SESSIONS (Supabase CRUD) ----------------
  static Future<List<SessionModel>?> getActiveSessions() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/sessions/active'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map((item) => SessionModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<List<SessionModel>?> getAllSessions() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/sessions'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map((item) => SessionModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<SessionModel?> createSession({
    required String brandId,
    required String sessionCreatedBy,
    required int waitingDurationSeconds,
    required String discountValue,
    required String couponCode,
    int totalVouchersPool = 100,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/sessions'),
            headers: _adminHeaders,
            body: jsonEncode({
              'brandId': brandId,
              'sessionCreatedBy': sessionCreatedBy,
              'waitingDurationSeconds': waitingDurationSeconds,
              'discountValue': discountValue,
              'couponCode': couponCode,
              'totalVouchersPool': totalVouchersPool,
            }),
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 201) {
        return SessionModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<VoucherModel?> claimSessionVoucher(
    String sessionId, {
    String? userId,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/sessions/$sessionId/claim'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({if (userId != null) 'userId': userId}),
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return VoucherModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  // ---------------- VOUCHERS (Supabase Wallet) ----------------
  static Future<List<VoucherModel>?> getVouchers({String? userId}) async {
    try {
      var url = '$baseUrl/api/vouchers';
      if (userId != null) {
        url += '?userId=$userId';
      }
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map((item) => VoucherModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> redeemVoucher(String voucherId) async {
    try {
      final res = await http
          .put(Uri.parse('$baseUrl/api/vouchers/$voucherId/redeem'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> verifyAndRedeemVoucher(
    String code,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/vouchers/verify-redeem'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code.trim()}),
          )
          .timeout(const Duration(seconds: 4));
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
