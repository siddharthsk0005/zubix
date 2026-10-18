// ignore_for_file: use_null_aware_elements
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import '../models/brand_model.dart';
import '../models/session_model.dart';
import '../models/voucher_model.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:4000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000'; // Android emulator to host machine mapping
    }
    return 'http://localhost:4000'; // iOS simulator or desktop
  }

  static Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
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

  static Future<VoucherModel?> claimSessionVoucher(String sessionId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/sessions/$sessionId/claim'),
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return VoucherModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  // ---------------- VOUCHERS (Supabase Wallet) ----------------
  static Future<List<VoucherModel>?> getVouchers() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/vouchers')).timeout(const Duration(seconds: 4));
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
}
