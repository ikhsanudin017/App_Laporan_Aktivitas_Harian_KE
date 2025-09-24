import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/app_user.dart';
import '../models/report.dart';

class ApiService {
  ApiService({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment('API_BASE_URL',
                defaultValue:
                    'https://web-laporan-aktivitas-harian-ke.vercel.app');

  final String baseUrl;

  Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final resolvedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$resolvedPath');
    if (query == null || query.isEmpty) {
      return uri;
    }
    return uri.replace(
      queryParameters:
          query.map((key, value) => MapEntry(key, value?.toString() ?? '')),
    );
  }

  Future<SessionData> loginAdmin(
      {required String email, required String password}) async {
    final response = await http.post(
      _buildUri('/api/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = _decodeResponse(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final userJson =
          Map<String, dynamic>.from(data['user'] as Map? ?? const {});
      final token = data['token'] as String? ?? '';
      if (token.isEmpty) {
        throw const ApiException('Token tidak ditemukan pada respons.');
      }
      return SessionData(user: AppUser.fromJson(userJson), token: token);
    }

    throw ApiException(data['message']?.toString() ?? 'Login admin gagal');
  }

  Future<Map<String, dynamic>> fetchReportDataForDate({
    required String token,
    required String date,
  }) async {
    final response = await http.get(
      _buildUri('/api/reports', {'date': date}),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = _decodeResponse(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data['reportData'] as Map? ?? const {});
    }

    throw ApiException(
        data['message']?.toString() ?? 'Gagal memuat data laporan');
  }

  Future<List<Report>> fetchReportHistory({required String token}) async {
    final response = await http.get(
      _buildUri('/api/reports/history'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = _decodeResponse(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final reports = data['reports'] as List? ?? const [];
      return reports
          .map(
              (item) => Report.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    throw ApiException(
        data['error']?.toString() ?? 'Gagal memuat riwayat laporan');
  }

  Future<List<Report>> fetchAdminReports({
    required String token,
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, String>{};
    if (startDate != null && startDate.isNotEmpty) {
      query['startDate'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      query['endDate'] = endDate;
    }

    final response = await http.get(
      _buildUri('/api/admin/reports', query.isEmpty ? null : query),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = _decodeResponse(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final reports = data['reports'] as List? ?? const [];
      return reports
          .map(
              (item) => Report.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    throw ApiException(
        data['message']?.toString() ?? 'Gagal memuat laporan admin');
  }

  Future<Report> createReport({
    required String token,
    required String date,
    required Map<String, dynamic> reportData,
  }) async {
    final response = await http.post(
      _buildUri('/api/reports'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'date': date, 'reportData': reportData}),
    );

    final data = _decodeResponse(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final reportJson =
          Map<String, dynamic>.from(data['report'] as Map? ?? const {});
      return Report.fromJson(reportJson);
    }

    throw ApiException(
        data['message']?.toString() ?? 'Gagal menyimpan laporan');
  }

  Future<Report> updateReport({
    required String token,
    required String reportId,
    required Map<String, dynamic> reportData,
    String? date,
  }) async {
    final response = await http.put(
      _buildUri('/api/reports/$reportId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'reportData': reportData,
        if (date != null) 'date': date,
      }),
    );

    final data = _decodeResponse(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final reportJson =
          Map<String, dynamic>.from(data['report'] as Map? ?? const {});
      return Report.fromJson(reportJson);
    }

    throw ApiException(
        data['message']?.toString() ?? 'Gagal memperbarui laporan');
  }

  Future<void> deleteReport(
      {required String token, required String reportId}) async {
    final response = await http.delete(
      _buildUri('/api/reports/$reportId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = _decodeResponse(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw ApiException(
        data['message']?.toString() ?? 'Gagal menghapus laporan');
  }

  Future<void> resetAllReports({required String token}) async {
    final response = await http.delete(
      _buildUri('/api/admin/reset-all'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = _decodeResponse(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw ApiException(
        data['error']?.toString() ?? 'Gagal menghapus data aktivitas');
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return const {};
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => 'ApiException: $message';
}
