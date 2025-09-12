import 'dart:async';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'dart:collection';
import '../entity/entity.dart';

class SftpConnectionInfo {
  final String host;
  final int port;
  final String user;
  final String? password;
  final SftpAuthType authType;
  final String? privateKeyPath;
  final String? passphrase;

  SftpConnectionInfo({
    required this.host,
    required this.port,
    required this.user,
    this.password,
    required this.authType,
    this.privateKeyPath,
    this.passphrase,
  });

  String get key => '$host:$port:$user:${authType.toString()}:${privateKeyPath ?? ""}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SftpConnectionInfo &&
          runtimeType == other.runtimeType &&
          host == other.host &&
          port == other.port &&
          user == other.user &&
          password == other.password &&
          authType == other.authType &&
          privateKeyPath == other.privateKeyPath &&
          passphrase == other.passphrase;

  @override
  int get hashCode => Object.hash(host, port, user, password, authType, privateKeyPath, passphrase);
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

  static const int _connectionsPerServer = 20;
  final Map<String, Queue<SftpConnectionEntry>> _connectionPools = {};
  final Set<String> _initializedServers = {};
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

  Future<void> _initializeConnectionPool(SftpConnectionInfo info) async {
    final key = info.key;
    if (_initializedServers.contains(key)) {
      return; // Already initialized
    }
    
    final pool = _connectionPools[key] ??= Queue<SftpConnectionEntry>();
    final List<SftpConnectionEntry> newConnections = [];
    
    try {
      // Create 20 connections in parallel
      final futures = <Future<SftpConnectionEntry>>[];
      for (int i = 0; i < _connectionsPerServer; i++) {
        futures.add(_createSingleConnection(info));
      }
      
      final connections = await Future.wait(futures);
      newConnections.addAll(connections);
      
      // All connections created successfully, add to pool
      for (final connection in newConnections) {
        pool.add(connection);
      }
      
      _initializedServers.add(key);
      
      // Start cleanup timer if not already active
      if (_cleanupTimer == null || !_cleanupTimer!.isActive) {
        _startCleanupTimer();
      }
    } catch (e) {
      // Clean up any partially created connections
      for (final connection in newConnections) {
        connection.dispose();
      }
      throw Exception('无法初始化SFTP连接池到服务器 ${info.host}:${info.port}: $e');
    }
  }

  Future<SftpConnectionEntry> _createSingleConnection(SftpConnectionInfo info) async {
    final socket = await SSHSocket.connect(info.host, info.port);
    
    SSHClient client;
    
    switch (info.authType) {
      case SftpAuthType.privateKey:
        client = await _createClientWithPrivateKey(socket, info);
        break;
      case SftpAuthType.both:
        client = await _createClientWithBothAuth(socket, info);
        break;
      case SftpAuthType.password:
      default:
        client = SSHClient(
          socket,
          username: info.user,
          onPasswordRequest: () => info.password ?? '',
        );
        break;
    }

    final sftp = await client.sftp();
    
    return SftpConnectionEntry(
      client: client,
      sftp: sftp,
      info: info,
    );
  }

  Future<SSHClient> _createClientWithPrivateKey(SSHSocket socket, SftpConnectionInfo info) async {
    if (info.privateKeyPath == null || info.privateKeyPath!.isEmpty) {
      throw Exception('Private key path is required for private key authentication');
    }
    
    final privateKeyFile = File(info.privateKeyPath!);
    if (!await privateKeyFile.exists()) {
      throw Exception('Private key file not found: ${info.privateKeyPath}');
    }
    
    final privateKeyContent = await privateKeyFile.readAsString();
    
    try {
      // Check if the private key is encrypted
      final isEncrypted = SSHKeyPair.isEncryptedPem(privateKeyContent);
      
      List<SSHKeyPair> keyPairs;
      if (isEncrypted && info.passphrase != null && info.passphrase!.isNotEmpty) {
        keyPairs = SSHKeyPair.fromPem(privateKeyContent, info.passphrase!);
      } else if (!isEncrypted) {
        keyPairs = SSHKeyPair.fromPem(privateKeyContent);
      } else {
        throw Exception('Private key is encrypted but no passphrase provided');
      }
      
      return SSHClient(
        socket,
        username: info.user,
        identities: keyPairs,
      );
    } catch (e) {
      throw Exception('Failed to load private key: $e');
    }
  }

  Future<SSHClient> _createClientWithBothAuth(SSHSocket socket, SftpConnectionInfo info) async {
    try {
      // Try private key authentication first
      return await _createClientWithPrivateKey(socket, info);
    } catch (e) {
      // If private key authentication fails, try password authentication
      if (info.password != null && info.password!.isNotEmpty) {
        return SSHClient(
          socket,
          username: info.user,
          onPasswordRequest: () => info.password!,
        );
      } else {
        throw Exception('Both private key and password authentication failed. Private key error: $e');
      }
    }
  }

  Future<SftpConnectionEntry> _getAvailableConnection(SftpConnectionInfo info) async {
    final key = info.key;
    
    // Initialize connection pool if not already done
    if (!_initializedServers.contains(key)) {
      await _initializeConnectionPool(info);
    }
    
    final pool = _connectionPools[key]!;
    
    // Find an available connection
    for (final connection in pool) {
      if (!connection.inUse && !connection.isExpired && !connection.isDisposed) {
        try {
          // Test if connection is still alive
          await connection.sftp.stat('/');
          connection.markInUse();
          return connection;
        } catch (e) {
          // Connection is dead, replace it
          pool.remove(connection);
          connection.dispose();
          
          // Create a new connection to maintain the pool size of 20
          try {
            final newConnection = await _createSingleConnection(info);
            pool.add(newConnection);
            newConnection.markInUse();
            return newConnection;
          } catch (createError) {
            throw Exception('无法重新创建SFTP连接到服务器 ${info.host}:${info.port}: $createError');
          }
        }
      }
    }
    
    // All connections are in use, wait and retry
    throw Exception('所有SFTP连接都在使用中，请稍后重试');
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

  @Deprecated('Use withConn instead')
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
    _initializedServers.remove(key);
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
    _initializedServers.clear();
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  int get activeConnectionCount => _connectionPools.values
      .fold<int>(0, (sum, pool) => sum + pool.length);

  int get connectionsPerServer => _connectionsPerServer;

  List<String> get activeConnectionKeys => _connectionPools.keys.toList();

  Map<String, int> get connectionCounts => _connectionPools.map(
      (key, pool) => MapEntry(key, pool.length));

  void dispose() {
    clearAllConnections();
  }
}