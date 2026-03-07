class ServerNode {
  int id;
  String name;
  String region;
  String idServer;
  String relayServer;
  String apiServer;
  String key;
  bool isOnline;
  bool isDefault;
  int priority;
  String description;
  bool supportsWebSocket;

  ServerNode({
    required this.id,
    required this.name,
    this.region = '',
    required this.idServer,
    required this.relayServer,
    this.apiServer = '',
    this.key = '',
    this.isOnline = true,
    this.isDefault = false,
    this.priority = 0,
    this.description = '',
    this.supportsWebSocket = false,
  });

  String get statusText => isOnline ? '不限速' : '离线';

  factory ServerNode.fromJson(Map<String, dynamic> json) {
    return ServerNode(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      region: json['region'] ?? '',
      idServer: json['id_server'] ?? '',
      relayServer: json['relay_server'] ?? '',
      apiServer: json['api_server'] ?? '',
      key: json['key'] ?? '',
      isOnline: json['is_online'] ?? true,
      isDefault: json['is_default'] ?? false,
      priority: json['priority'] ?? 0,
      description: json['description'] ?? '',
      supportsWebSocket: json['supports_websocket'] == true ||
          json['supports_ws'] == true ||
          json['allow_websocket'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'id_server': idServer,
      'relay_server': relayServer,
      'api_server': apiServer,
      'key': key,
      'is_online': isOnline,
      'is_default': isDefault,
      'priority': priority,
      'description': description,
      'supports_websocket': supportsWebSocket,
    };
  }

  static List<ServerNode> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => ServerNode.fromJson(json)).toList();
  }
}

class VipInfo {
  String username;
  int validDays;
  DateTime? firstLoginAt;
  int deviceLimit;

  VipInfo({
    this.username = '',
    this.validDays = 0,
    this.firstLoginAt,
    this.deviceLimit = 0,
  });

  DateTime? get expireAt {
    if (firstLoginAt == null || validDays <= 0) return null;
    return firstLoginAt!.add(Duration(days: validDays));
  }

  bool get isExpired {
    final expire = expireAt;
    if (expire == null) return false;
    return expire.isBefore(DateTime.now());
  }

  bool get isLifetime => validDays == -1;

  int get remainingDays {
    if (isLifetime) return -1;
    final expire = expireAt;
    if (expire == null) return 0;
    final diff = expire.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  String get expireDateStr {
    if (isLifetime) return '永久';
    final expire = expireAt;
    if (expire == null) return '未知';
    return '${expire.year}-${expire.month.toString().padLeft(2, '0')}-${expire.day.toString().padLeft(2, '0')}';
  }

  factory VipInfo.fromJson(Map<String, dynamic> json) {
    DateTime? firstLoginAt;
    if (json['first_login_at'] != null &&
        json['first_login_at'].toString().isNotEmpty) {
      try {
        firstLoginAt = DateTime.parse(json['first_login_at'].toString());
      } catch (_) {}
    }
    return VipInfo(
      username: json['name'] ?? json['username'] ?? '',
      validDays: json['valid_days'] ?? 0,
      firstLoginAt: firstLoginAt,
      deviceLimit: json['device_limit'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'valid_days': validDays,
      'first_login_at': firstLoginAt?.toIso8601String(),
      'device_limit': deviceLimit,
    };
  }
}

class RedeemResult {
  bool success;
  String message;
  int? addedDays;

  RedeemResult({
    required this.success,
    this.message = '',
    this.addedDays,
  });

  factory RedeemResult.fromJson(Map<String, dynamic> json) {
    return RedeemResult(
      success: json['success'] ?? false,
      message: json['message'] ?? json['error'] ?? '',
      addedDays: json['added_days'] ?? json['valid_days'],
    );
  }
}

class ActionResult {
  bool success;
  String message;

  ActionResult({
    required this.success,
    this.message = '',
  });

  factory ActionResult.fromJson(Map<String, dynamic> json) {
    return ActionResult(
      success: json['success'] == true && json['error'] == null,
      message: json['message'] ?? json['error'] ?? '',
    );
  }
}
