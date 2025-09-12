import 'dart:io';
import 'dart:typed_data';
import '../services/sftp_connection_manager.dart';
import '../entity/entity.dart';

abstract class UniFile {
  /*定义常见的文件操作(只读)，如
  * read 获取全部内容
  * list
  * isDir
  * isFile
  * getPath
  * getName
  * getSize
  * getParent
  * */

  Future<Uint8List> read();

  Future<List<UniFile>> list();

  Future<bool> isDir();

  Future<bool> isFile();

  String getPath();

  String getName();

  Future<int> getSize();

  UniFile? getParent();
}

class LocalFile extends UniFile {
  final String _path;
  final bool? _isDirectory;
  final int? _size;
  final DateTime? _modifiedTime;

  LocalFile._({
    required String path,
    bool? isDirectory,
    int? size,
    DateTime? modifiedTime,
  })  : _path = path,
        _isDirectory = isDirectory,
        _size = size,
        _modifiedTime = modifiedTime;

  LocalFile(String path) : this._(path: path);

  LocalFile.fromFile(File file) : this._(path: file.path);

  @override
  Future<Uint8List> read() async {
    final file = File(_path);
    return await file.readAsBytes();
  }

  @override
  Future<List<UniFile>> list() async {
    final directory = Directory(_path);
    if (!directory.existsSync()) {
      return [];
    }
    final stat = directory.statSync();
    if (stat.type != FileSystemEntityType.directory) {
      return [];
    }
    final entities = await directory.list().toList();
    
    // 缓存每个实体的信息
    final results = <LocalFile>[];
    for (final entity in entities) {
      final entityStat = await entity.stat();
      results.add(LocalFile.createWithCache(
        entity.path,
        isDirectory: entityStat.type == FileSystemEntityType.directory,
        size: entityStat.size,
        modifiedTime: entityStat.modified,
      ));
    }
    return results;
  }

  @override
  Future<bool> isDir() async {
    if (_isDirectory != null) {
      return _isDirectory;
    }
    
    final directory = Directory(_path);
    return await directory.exists();
  }

  @override
  Future<bool> isFile() async {
    if (_isDirectory != null) {
      return !_isDirectory;
    }
    
    final file = File(_path);
    return await file.exists();
  }

  @override
  String getPath() {
    return _path;
  }

  @override
  String getName() {
    return _path.split(Platform.pathSeparator).last;
  }

  @override
  Future<int> getSize() async {
    if (_size != null) {
      return _size;
    }
    
    final file = File(_path);
    if (!await file.exists()) return 0;
    final stat = await file.stat();
    return stat.size;
  }

  @override
  UniFile? getParent() {
    final file = File(_path);
    final parent = file.parent;
    return parent.path != _path ? LocalFile(parent.path) : null;
  }

  static LocalFile create(String path) {
    return LocalFile(path);
  }

  static LocalFile createWithCache(
    String path, {
    bool? isDirectory,
    int? size,
    DateTime? modifiedTime,
  }) {
    return LocalFile._(
      path: path,
      isDirectory: isDirectory,
      size: size,
      modifiedTime: modifiedTime,
    );
  }

  DateTime? getModifiedTime() {
    return _modifiedTime;
  }
}

class SftpFile extends UniFile {
  final String _host;
  final int _port;
  final String _user;
  final String _password;
  final String _path;
  final bool? _isDirectory;
  final int? _size;
  final DateTime? _modifiedTime;

  SftpFile._({
    required String host,
    required int port,
    required String user,
    required String password,
    required String path,
    bool? isDirectory,
    int? size,
    DateTime? modifiedTime,
  })  : _host = host,
        _port = port,
        _user = user,
        _password = password,
        _path = path,
        _isDirectory = isDirectory,
        _size = size,
        _modifiedTime = modifiedTime;

  static SftpFile create(String host, int port, String user, String password, String path) {
    return SftpFile._(
      host: host,
      port: port,
      user: user,
      password: password,
      path: path,
    );
  }

  static SftpFile createWithCache(
    String host,
    int port,
    String user,
    String password,
    String path, {
    bool? isDirectory,
    int? size,
    DateTime? modifiedTime,
  }) {
    return SftpFile._(
      host: host,
      port: port,
      user: user,
      password: password,
      path: path,
      isDirectory: isDirectory,
      size: size,
      modifiedTime: modifiedTime,
    );
  }

  @override
  Future<Uint8List> read() async {
    final connectionInfo = SftpConnectionInfo(
      host: _host,
      port: _port,
      user: _user,
      password: _password,
      authType: SftpAuthType.password,
    );

    return await SftpConnectionManager().withConn(connectionInfo, (sftp) async {
      final file = await sftp.open(_path);
      try {
        final data = await file.readBytes();
        return Uint8List.fromList(data);
      } finally {
        await file.close();
      }
    });
  }

  @override
  Future<List<UniFile>> list() async {
    final connectionInfo = SftpConnectionInfo(
      host: _host,
      port: _port,
      user: _user,
      password: _password,
      authType: SftpAuthType.password,
    );

    return await SftpConnectionManager().withConn(connectionInfo, (sftp) async {
      final files = await sftp.listdir(_path);
      return files
          .where((item) => item.filename != '.' && item.filename != '..')
          .map((item) {
        final itemPath = _path.endsWith('/') ? '$_path${item.filename}' : '$_path/${item.filename}';

        return SftpFile.createWithCache(
          _host,
          _port,
          _user,
          _password,
          itemPath,
          isDirectory: item.attr.isDirectory,
          size: item.attr.size,
          modifiedTime: item.attr.modifyTime != null ? DateTime.fromMillisecondsSinceEpoch(item.attr.modifyTime! * 1000) : null,
        );
      }).toList();
    });
  }

  @override
  Future<bool> isDir() async {
    if (_isDirectory != null) {
      return _isDirectory;
    }

    try {
      final connectionInfo = SftpConnectionInfo(
        host: _host,
        port: _port,
        user: _user,
        password: _password,
        authType: SftpAuthType.password,
      );

      return await SftpConnectionManager().withConn(connectionInfo, (sftp) async {
        final stat = await sftp.stat(_path);
        return stat.isDirectory;
      });
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isFile() async {
    if (_isDirectory != null) {
      return !_isDirectory;
    }

    try {
      final connectionInfo = SftpConnectionInfo(
        host: _host,
        port: _port,
        user: _user,
        password: _password,
        authType: SftpAuthType.password,
      );

      return await SftpConnectionManager().withConn(connectionInfo, (sftp) async {
        final stat = await sftp.stat(_path);
        return stat.isFile;
      });
    } catch (e) {
      return false;
    }
  }

  @override
  String getPath() {
    return _path;
  }

  @override
  String getName() {
    return _path.split('/').last;
  }

  @override
  Future<int> getSize() async {
    if (_size != null) {
      return _size;
    }

    try {
      final connectionInfo = SftpConnectionInfo(
        host: _host,
        port: _port,
        user: _user,
        password: _password,
        authType: SftpAuthType.password,
      );

      return await SftpConnectionManager().withConn(connectionInfo, (sftp) async {
        final stat = await sftp.stat(_path);
        return stat.size ?? 0;
      });
    } catch (e) {
      return 0;
    }
  }

  @override
  UniFile? getParent() {
    final parts = _path.split('/');
    if (parts.length <= 1) return null;
    final parentPath = parts.sublist(0, parts.length - 1).join('/');
    return SftpFile.create(_host, _port, _user, _password, parentPath.isEmpty ? '/' : parentPath);
  }

  DateTime? getModifiedTime() {
    return _modifiedTime;
  }

  // Getter methods for SFTP connection info
  String get host => _host;

  int get port => _port;

  String get user => _user;

  String get password => _password;
}
