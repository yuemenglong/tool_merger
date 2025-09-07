import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';

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
  final File _file;

  LocalFile(String path) : _file = File(path);

  LocalFile.fromFile(File file) : _file = file;

  @override
  Future<Uint8List> read() async {
    return await _file.readAsBytes();
  }

  @override
  Future<List<UniFile>> list() async {
    if (await _file.exists() && await _file.stat().then((stat) => stat.type == FileSystemEntityType.directory)) {
      final directory = Directory(_file.path);
      final entities = await directory.list().toList();
      return entities.map((entity) => LocalFile(entity.path)).toList();
    }
    return [];
  }

  @override
  Future<bool> isDir() async {
    final directory = Directory(_file.path);
    return await directory.exists();
  }

  @override
  Future<bool> isFile() async {
    return await _file.exists();
  }

  @override
  String getPath() {
    return _file.path;
  }

  @override
  String getName() {
    return _file.path.split(Platform.pathSeparator).last;
  }

  @override
  Future<int> getSize() async {
    if (!await _file.exists()) return 0;
    final stat = await _file.stat();
    return stat.size;
  }

  @override
  UniFile? getParent() {
    final parent = _file.parent;
    return parent.path != _file.path ? LocalFile.fromFile(File(parent.path)) : null;
  }

  static LocalFile create(String path) {
    return LocalFile(path);
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
    final client = SSHClient(
      await SSHSocket.connect(_host, _port),
      username: _user,
      onPasswordRequest: () => _password,
    );
    
    try {
      final sftp = await client.sftp();
      final file = await sftp.open(_path);
      final data = await file.readBytes();
      await file.close();
      return Uint8List.fromList(data);
    } finally {
      client.close();
    }
  }

  @override
  Future<List<UniFile>> list() async {
    final client = SSHClient(
      await SSHSocket.connect(_host, _port),
      username: _user,
      onPasswordRequest: () => _password,
    );
    
    try {
      final sftp = await client.sftp();
      final files = await sftp.listdir(_path);
      return files.map((item) {
        final itemPath = _path.endsWith('/') ? '$_path${item.filename}' : '$_path/${item.filename}';
        
        return SftpFile.createWithCache(
          _host, 
          _port, 
          _user, 
          _password, 
          itemPath,
          isDirectory: item.attr.isDirectory,
          size: item.attr.size,
          modifiedTime: item.attr.modifyTime != null 
            ? DateTime.fromMillisecondsSinceEpoch(item.attr.modifyTime! * 1000) 
            : null,
        );
      }).toList();
    } finally {
      client.close();
    }
  }

  @override
  Future<bool> isDir() async {
    if (_isDirectory != null) {
      return _isDirectory!;
    }
    
    final client = SSHClient(
      await SSHSocket.connect(_host, _port),
      username: _user,
      onPasswordRequest: () => _password,
    );
    
    try {
      final sftp = await client.sftp();
      final stat = await sftp.stat(_path);
      return stat.isDirectory;
    } catch (e) {
      return false;
    } finally {
      client.close();
    }
  }

  @override
  Future<bool> isFile() async {
    if (_isDirectory != null) {
      return !_isDirectory!;
    }
    
    final client = SSHClient(
      await SSHSocket.connect(_host, _port),
      username: _user,
      onPasswordRequest: () => _password,
    );
    
    try {
      final sftp = await client.sftp();
      final stat = await sftp.stat(_path);
      return stat.isFile;
    } catch (e) {
      return false;
    } finally {
      client.close();
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
      return _size!;
    }
    
    final client = SSHClient(
      await SSHSocket.connect(_host, _port),
      username: _user,
      onPasswordRequest: () => _password,
    );
    
    try {
      final sftp = await client.sftp();
      final stat = await sftp.stat(_path);
      return stat.size ?? 0;
    } catch (e) {
      return 0;
    } finally {
      client.close();
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
