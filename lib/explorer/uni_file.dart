import 'dart:io';
import 'dart:typed_data';

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
    if (!await _file.exists()) return false;
    final stat = await _file.stat();
    return stat.type == FileSystemEntityType.directory;
  }

  @override
  Future<bool> isFile() async {
    if (!await _file.exists()) return false;
    final stat = await _file.stat();
    return stat.type == FileSystemEntityType.file;
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
    /*TODO*/
  }
}

class SftpFile extends UniFile {
  final String _host;
  final int _port;
  final String _user;
  final String _password;
  final String _path;

  SftpFile._({
    required String host,
    required int port,
    required String user,
    required String password,
    required String path,
  })  : _host = host,
        _port = port,
        _user = user,
        _password = password,
        _path = path;

  static SftpFile create(String host, int port, String user, String password, String path) {
    return SftpFile._(
      host: host,
      port: port,
      user: user,
      password: password,
      path: path,
    );
  }

  @override
  Future<Uint8List> read() async {
    // TODO: 需要添加SSH库依赖 (如 ssh2 或 dartssh2) 来实现SFTP文件读取
    // 示例实现:
    // final client = SSHClient();
    // await client.connect(host: _host, port: _port, username: _user, password: _password);
    // final sftp = await client.sftp();
    // final data = await sftp.readFile(_path);
    // await client.disconnect();
    // return data;
    throw UnimplementedError('SFTP read requires SSH library dependency');
  }

  @override
  Future<List<UniFile>> list() async {
    // TODO: 实现SFTP目录列表
    // final client = SSHClient();
    // await client.connect(host: _host, port: _port, username: _user, password: _password);
    // final sftp = await client.sftp();
    // final files = await sftp.listDirectory(_path);
    // await client.disconnect();
    // return files.map((f) => SftpFile.create(_host, _port, _user, _password, f.path)).toList();
    throw UnimplementedError('SFTP list requires SSH library dependency');
  }

  @override
  Future<bool> isDir() async {
    // TODO: 实现SFTP目录检查
    throw UnimplementedError('SFTP isDir requires SSH library dependency');
  }

  @override
  Future<bool> isFile() async {
    // TODO: 实现SFTP文件检查
    throw UnimplementedError('SFTP isFile requires SSH library dependency');
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
    // TODO: 实现SFTP文件大小获取
    throw UnimplementedError('SFTP getSize requires SSH library dependency');
  }

  @override
  UniFile? getParent() {
    final parts = _path.split('/');
    if (parts.length <= 1) return null;
    final parentPath = parts.sublist(0, parts.length - 1).join('/');
    return SftpFile.create(_host, _port, _user, _password, parentPath.isEmpty ? '/' : parentPath);
  }
}
