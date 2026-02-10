import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/vip_model.dart';
import 'package:flutter_hbb/utils/http_service.dart' as http;

class VipApi {
  static Future<String> get _apiServer async => await bind.mainGetApiServer();

  static Map<String, String> get _headers {
    final token = bind.mainGetLocalOption(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<ServerNode>> getServers() async {
    try {
      final url = await _apiServer;
      if (url.isEmpty) return [];

      final response = await http.get(
        Uri.parse('$url/api/vip/servers'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(decode_http_response(response));
        if (body is List) {
          return ServerNode.fromJsonList(body);
        } else if (body is Map && body['list'] != null) {
          return ServerNode.fromJsonList(body['list']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('getServers error: $e');
      return [];
    }
  }

  static Future<VipInfo?> getVipInfo() async {
    try {
      final url = await _apiServer;
      if (url.isEmpty) return null;

      final response = await http.get(
        Uri.parse('$url/api/user/info'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(decode_http_response(response));
        if (body is Map && body['error'] == null) {
          return VipInfo.fromJson(body);
        }
      }
      return null;
    } catch (e) {
      debugPrint('getVipInfo error: $e');
      return null;
    }
  }

  static Future<RedeemResult> redeem(String code) async {
    try {
      final url = await _apiServer;
      if (url.isEmpty) {
        return RedeemResult(success: false, message: 'API服务器未配置');
      }

      final response = await http.post(
        Uri.parse('$url/api/vip/redeem'),
        headers: _headers,
        body: jsonEncode({'code': code.trim()}),
      );

      final body = jsonDecode(decode_http_response(response));
      
      if (response.statusCode == 200 && body['error'] == null) {
        return RedeemResult(
          success: true,
          message: '激活成功',
          addedDays: body['valid_days'] ?? body['added_days'],
        );
      } else {
        return RedeemResult(
          success: false,
          message: body['error'] ?? body['message'] ?? '激活失败',
        );
      }
    } catch (e) {
      debugPrint('redeem error: $e');
      return RedeemResult(success: false, message: '网络错误: $e');
    }
  }

  static Future<bool> register({
    required String username,
    required String password,
    String? email,
    String? activationCode,
  }) async {
    try {
      final url = await _apiServer;
      if (url.isEmpty) return false;

      final body = <String, dynamic>{
        'username': username,
        'password': password,
      };
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }
      if (activationCode != null && activationCode.isNotEmpty) {
        body['activation_code'] = activationCode;
      }

      final response = await http.post(
        Uri.parse('$url/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final respBody = jsonDecode(decode_http_response(response));
        return respBody['error'] == null;
      }
      return false;
    } catch (e) {
      debugPrint('register error: $e');
      return false;
    }
  }
}
