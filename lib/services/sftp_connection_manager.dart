import 'dart:async';
import 'package:dartssh2/dartssh2.dart';
import 'dart:collection';

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
  bool _inUse = false;

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
  
  bool get inUse => _inUse;
  
  void markInUse() {
    _inUse = true;
    updateLastUsed();
  }
  
  void markAvailable() {
    _inUse = false;
    updateLastUsed();
  }

  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _inUse = false;
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

  static const int _maxConnections = 20;
  final Map<String, Queue<SftpConnectionEntry>> _connectionPools = {};
  Timer? _cleanupTimer;

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpiredConnections();
    });
  }

  void _cleanupExpiredConnections() {
    for (final poolEntry in _connectionPools.entries) {
      final pool = poolEntry.value;
      final expiredConnections = <SftpConnectionEntry>[];
      
      for (final connection in pool) {
        if (connection.isExpired || connection.isDisposed) {
          expiredConnections.add(connection);
        }
      }
      
      for (final expired in expiredConnections) {
        pool.remove(expired);
        expired.dispose();
      }
    }
    
    // 移除空的连接池
    _connectionPools.removeWhere((key, pool) => pool.isEmpty);
  }

  Future<SftpConnectionEntry> _getAvailableConnection(SftpConnectionInfo info) async {
    final key = info.key;
    final pool = _connectionPools[key] ??= Queue<SftpConnectionEntry>();
    
    // 寻找可用的连接
    for (final connection in pool) {
      if (!connection.inUse && !connection.isExpired && !connection.isDisposed) {
        try {
          // 测试连接是否还活着
          await connection.sftp.stat('/');
          connection.markInUse();
          return connection;
        } catch (e) {
          // 连接已断开，移除
          pool.remove(connection);
          connection.dispose();
          break;
        }
      }
    }
    
    // 检查是否超过连接数限制
    final totalConnections = _connectionPools.values
        .fold<int>(0, (sum, pool) => sum + pool.length);
    
    if (totalConnections >= _maxConnections) {
      // 尝试清理过期连接
      _cleanupExpiredConnections();
      
      final newTotalConnections = _connectionPools.values
          .fold<int>(0, (sum, pool) => sum + pool.length);
      
      if (newTotalConnections >= _maxConnections) {
        // 找到最老的可用连接并移除
        SftpConnectionEntry? oldestConnection;
        String? oldestPoolKey;
        
        for (final poolEntry in _connectionPools.entries) {
          for (final connection in poolEntry.value) {
            if (!connection.inUse && 
                (oldestConnection == null || 
                 connection.lastUsed.isBefore(oldestConnection.lastUsed))) {
              oldestConnection = connection;
              oldestPoolKey = poolEntry.key;
            }
          }
        }
        
        if (oldestConnection != null && oldestPoolKey != null) {
          _connectionPools[oldestPoolKey]!.remove(oldestConnection);
          oldestConnection.dispose();
        }
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
      
      connection.markInUse();
      pool.add(connection);
      
      // 启动清理定时器（如果还没启动）
      if (_cleanupTimer == null || !_cleanupTimer!.isActive) {
        _startCleanupTimer();
      }

      return connection;
    } catch (e) {
      throw Exception('无法连接到SFTP服务器 ${info.host}:${info.port}: $e');
    }
  }

  void _releaseConnection(SftpConnectionEntry connection) {
    if (!connection.isDisposed) {
      connection.markAvailable();
    }
  }

  Future<T> withConn<T>(
    SftpConnectionInfo connInfo, 
    Future<T> Function(SftpClient sftp) callback
  ) async {
    SftpConnectionEntry? connection;
    try {
      connection = await _getAvailableConnection(connInfo);
      return await callback(connection.sftp);
    } finally {
      if (connection != null) {
        _releaseConnection(connection);
      }
    }
  }

  @deprecated
  Future<SftpClient> getConnection(SftpConnectionInfo info) async {
    final connection = await _getAvailableConnection(info);
    return connection.sftp;
  }

  void removeConnection(String key) {
    final pool = _connectionPools.remove(key);
    if (pool != null) {
      for (final connection in pool) {
        connection.dispose();
      }
    }
  }

  void removeConnectionByInfo(SftpConnectionInfo info) {
    removeConnection(info.key);
  }

  void clearAllConnections() {
    for (final pool in _connectionPools.values) {
      for (final connection in pool) {
        connection.dispose();
      }
    }
    _connectionPools.clear();
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  int get activeConnectionCount => _connectionPools.values
      .fold<int>(0, (sum, pool) => sum + pool.length);

  int get maxConnections => _maxConnections;

  List<String> get activeConnectionKeys => _connectionPools.keys.toList();

  Map<String, int> get connectionCounts => _connectionPools.map(
      (key, pool) => MapEntry(key, pool.length));

  void dispose() {
    clearAllConnections();
  }
}