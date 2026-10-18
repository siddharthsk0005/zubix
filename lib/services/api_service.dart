// ignore_for_file: use_null_aware_elements
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import '../models/brand_model.dart';
import '../models/session_model.dart';
import '../models/voucher_model.dart';
import '../models/user_model.dart';

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
      final res = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------- AUTH (Supabase User Accounts & OTP) ----------------
  static Future<Map<String, dynamic>?> sendOtp(String phone) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone.trim()}),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> verifyOtp(String phone, String otp) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone.trim(),
          'otp': otp.trim(),
        }),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'success': true,
          'isNewUser': data['isNewUser'] == true,
          'isProfileComplete': data['isProfileComplete'] == true,
          'user': UserModel.fromJson(data['user'] as Map<String, dynamic>),
        };
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> socialLogin(String provider, {String? email, String? name}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/social-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'email': email?.trim() ?? 'member.${provider.toLowerCase()}@zubix.example',
          'name': name?.trim() ?? 'Zubix Member',
        }),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'success': true,
          'isNewUser': data['isNewUser'] == true,
          'isProfileComplete': data['isProfileComplete'] == true,
          'user': UserModel.fromJson(data['user'] as Map<String, dynamic>),
        };
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
      final res = await http.post(
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
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/auth/me?userId=$userId'),
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  static Future<UserModel?> register(String email, {String? name, String role = 'consumer'}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          if (name != null) 'name': name,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return UserModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<UserModel?> login(String email, {String? name}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          if (name != null) 'name': name,
        }),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return UserModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  // ---------------- CATEGORIES (Supabase CRUD) ----------------
  static Future<List<CategoryModel>?> getCategories() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/categories')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((item) => CategoryModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<CategoryModel?> createCategory(String name, {String iconName = 'category'}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/categories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'iconName': iconName}),
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 201) {
        return CategoryModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> updateCategory(String id, {String? name, bool? isActive}) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/categories/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (name case final n?) 'name': n,
          if (isActive case final a?) 'isActive': a,
        }),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteCategory(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/api/categories/$id')).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------- BRANDS (Supabase CRUD) ----------------
  static Future<List<BrandModel>?> getBrands({String? categoryId, bool approvedOnly = true}) async {
    try {
      var url = '$baseUrl/api/brands?approvedOnly=$approvedOnly';
      if (categoryId != null) url += '&categoryId=$categoryId';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((item) => BrandModel.fromJson(item as Map<String, dynamic>)).toList();
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
      final uri = Uri.parse('$baseUrl/api/brands/nearby').replace(queryParameters: queryParams);
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((item) => BrandModel.fromJson(item as Map<String, dynamic>)).toList();
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
      final res = await http.post(
        Uri.parse('$baseUrl/api/brands'),
        headers: {'Content-Type': 'application/json'},
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
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 201) {
        return BrandModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> updateBrand(String id, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/brands/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> approveBrand(String id, bool isApproved) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/brands/$id/approve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isApproved': isApproved}),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------- SESSIONS (Supabase CRUD) ----------------
  static Future<List<SessionModel>?> getActiveSessions() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/sessions/active')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((item) => SessionModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<List<SessionModel>?> getAllSessions() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/sessions')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((item) => SessionModel.fromJson(item as Map<String, dynamic>)).toList();
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
      final res = await http.post(
        Uri.parse('$baseUrl/api/sessions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'brandId': brandId,
          'sessionCreatedBy': sessionCreatedBy,
          'waitingDurationSeconds': waitingDurationSeconds,
          'discountValue': discountValue,
          'couponCode': couponCode,
          'totalVouchersPool': totalVouchersPool,
        }),
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 201) {
        return SessionModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<VoucherModel?> claimSessionVoucher(String sessionId, {String? userId}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/sessions/$sessionId/claim'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (userId != null) 'userId': userId,
        }),
      ).timeout(const Duration(seconds: 4));
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
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((item) => VoucherModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> redeemVoucher(String voucherId) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/api/vouchers/$voucherId/redeem')).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> verifyAndRedeemVoucher(String code) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/vouchers/verify-redeem'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code.trim()}),
      ).timeout(const Duration(seconds: 4));
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
