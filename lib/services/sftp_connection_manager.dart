import 'dart:async';
import 'package:dartssh2/dartssh2.dart';

class SftpConnectionInfo {
  final String host;
  final int port;
  final String user;
  final String password;

  SftpConnectionInfo({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
  });

  String get key => '$host:$port:$user';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SftpConnectionInfo &&
          runtimeType == other.runtimeType &&
          host == other.host &&
          port == other.port &&
          user == other.user &&
          password == other.password;

  @override
  int get hashCode => host.hashCode ^ port.hashCode ^ user.hashCode ^ password.hashCode;
}

class SftpConnectionEntry {
  final SSHClient client;
  final SftpClient sftp;
  final SftpConnectionInfo info;
  DateTime lastUsed;
  bool _disposed = false;

  SftpConnectionEntry({
    required this.client,
    required this.sftp,
    required this.info,
  }) : lastUsed = DateTime.now();

  void updateLastUsed() {
    if (!_disposed) {
      lastUsed = DateTime.now();
    }
  }

  bool get isExpired {
    final now = DateTime.now();
    return now.difference(lastUsed).inMinutes > 30; // 30分钟超时
  }

  bool get isDisposed => _disposed;

  void dispose() {
    if (!_disposed) {
      _disposed = true;
      try {
        client.close();
      } catch (e) {
        // 忽略关闭错误
      }
    }
  }
}

class SftpConnectionManager {
  static final SftpConnectionManager _instance = SftpConnectionManager._internal();
  factory SftpConnectionManager() => _instance;
  SftpConnectionManager._internal();

  final Map<String, SftpConnectionEntry> _connections = {};
  Timer? _cleanupTimer;

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpiredConnections();
    });
  }

  void _cleanupExpiredConnections() {
    final expiredKeys = <String>[];
    
    for (final entry in _connections.entries) {
      if (entry.value.isExpired || entry.value.isDisposed) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      final connection = _connections.remove(key);
      connection?.dispose();
    }
  }

  Future<SftpClient> getConnection(SftpConnectionInfo info) async {
    final key = info.key;
    
    // 检查是否有可用连接
    final existing = _connections[key];
    if (existing != null && !existing.isExpired && !existing.isDisposed) {
      try {
        // 测试连接是否还活着
        await existing.sftp.stat('/');
        existing.updateLastUsed();
        return existing.sftp;
      } catch (e) {
        // 连接已断开，移除并重新创建
        _connections.remove(key);
        existing.dispose();
      }
    }

    // 创建新连接
    try {
      final client = SSHClient(
        await SSHSocket.connect(info.host, info.port),
        username: info.user,
        onPasswordRequest: () => info.password,
      );

      final sftp = await client.sftp();
      
      final connection = SftpConnectionEntry(
        client: client,
        sftp: sftp,
        info: info,
      );

      _connections[key] = connection;
      
      // 启动清理定时器（如果还没启动）
      if (_cleanupTimer == null || !_cleanupTimer!.isActive) {
        _startCleanupTimer();
      }

      return sftp;
    } catch (e) {
      throw Exception('无法连接到SFTP服务器 ${info.host}:${info.port}: $e');
    }
  }

  void removeConnection(String key) {
    final connection = _connections.remove(key);
    connection?.dispose();
  }

  void removeConnectionByInfo(SftpConnectionInfo info) {
    removeConnection(info.key);
  }

  void clearAllConnections() {
    for (final connection in _connections.values) {
      connection.dispose();
    }
    _connections.clear();
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  int get activeConnectionCount => _connections.length;

  List<String> get activeConnectionKeys => _connections.keys.toList();

  void dispose() {
    clearAllConnections();
  }
}