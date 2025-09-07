import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../entity/entity.dart';
import '../explorer/uni_file.dart';

class SftpController extends GetxController {
  final RxList<SftpFileRoot> sftpRoots = <SftpFileRoot>[].obs;
  final Rx<SftpFileRoot?> selectedSftpRoot = Rx<SftpFileRoot?>(null);

  @override
  void onInit() {
    super.onInit();
    loadSftpRoots();
  }

  Future<void> loadSftpRoots() async {
    try {
      // 使用应用支持目录而非文档目录
      final directory = await getApplicationSupportDirectory();
      
      // 创建配置子目录
      final configDir = Directory('${directory.path}/config');
      if (!await configDir.exists()) {
        await configDir.create(recursive: true);
      }
      
      final newFile = LocalFile.create('${configDir.path}/sftp_roots.json');
      
      // 打印配置文件路径信息
      print('=== SFTP 配置文件路径信息 ===');
      print('应用支持目录: ${directory.path}');
      print('配置目录: ${configDir.path}');
      print('SFTP配置文件: ${newFile.getPath()}');
      print('配置目录是否存在: ${await configDir.exists()}');
      print('配置文件是否存在: ${await newFile.isFile()}');
      print('==============================');
      
      // 检查新位置是否存在配置文件
      if (await newFile.isFile()) {
        print('从新位置加载配置文件');
        await _loadConfigFromFile(newFile);
      } else {
        print('新位置无配置文件，尝试迁移');
        // 尝试从旧位置迁移配置文件
        await _migrateConfigFromOldLocation(newFile);
      }
    } catch (e) {
      print('加载 SFTP 根目录时出错: $e');
      Get.snackbar('错误', '加载 SFTP 根目录失败: $e');
      _createSampleSftpRoots();
    }
  }

  Future<void> _loadConfigFromFile(LocalFile file) async {
    final contentBytes = await file.read();
    final jsonString = String.fromCharCodes(contentBytes);
    final List<dynamic> jsonList = json.decode(jsonString);
    sftpRoots.value = jsonList.map((json) => SftpFileRoot.fromJson(json)).toList();
    
    if (sftpRoots.isNotEmpty && selectedSftpRoot.value == null) {
      final enabledRoot = sftpRoots.firstWhere(
        (root) => root.enabled == true, 
        orElse: () => sftpRoots.first
      );
      selectedSftpRoot.value = enabledRoot;
    }
  }

  Future<void> _migrateConfigFromOldLocation(LocalFile newFile) async {
    try {
      // 检查旧位置的配置文件
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final oldFile = LocalFile.create('${documentsDirectory.path}/sftp_roots.json');
      
      print('检查旧配置文件: ${oldFile.getPath()}');
      print('旧配置文件是否存在: ${await oldFile.isFile()}');
      
      if (await oldFile.isFile()) {
        print('发现旧配置文件，开始迁移...');
        
        // 从旧位置加载配置
        await _loadConfigFromFile(oldFile);
        print('已从旧位置加载配置');
        
        // 保存到新位置
        await _saveConfigToFile(newFile);
        print('已保存到新位置');
        
        // 删除旧文件
        final oldFilePath = oldFile.getPath();
        await File(oldFilePath).delete();
        print('已删除旧配置文件');
        
        Get.snackbar('迁移成功', '配置文件已迁移到应用专用目录');
        print('配置文件迁移完成');
      } else {
        print('未找到旧配置文件，创建默认配置');
        // 没有旧配置文件，创建示例配置
        _createSampleSftpRoots();
      }
    } catch (e) {
      print('迁移配置文件时出错: $e');
      // 迁移过程中出错，使用示例配置
      _createSampleSftpRoots();
    }
  }

  Future<void> _saveConfigToFile(LocalFile file) async {
    final jsonList = sftpRoots.map((root) => root.toJson()).toList();
    final content = json.encode(jsonList);
    final filePath = file.getPath();
    await File(filePath).writeAsString(content);
  }

  Future<void> saveSftpRoots() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final configDir = Directory('${directory.path}/config');
      if (!await configDir.exists()) {
        await configDir.create(recursive: true);
      }
      
      final file = LocalFile.create('${configDir.path}/sftp_roots.json');
      await _saveConfigToFile(file);
    } catch (e) {
      Get.snackbar('错误', '保存 SFTP 根目录失败: $e');
    }
  }

  void _createSampleSftpRoots() {
    sftpRoots.value = [
      SftpFileRoot(
        name: '开发服务器',
        host: '192.168.1.100',
        port: 22,
        user: 'developer',
        password: '',
        path: '/home/developer/projects',
        enabled: true,
        createTime: DateTime.now().subtract(const Duration(days: 7)),
        updateTime: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      SftpFileRoot(
        name: '测试服务器',
        host: '192.168.1.101',
        port: 22,
        user: 'tester',
        password: '',
        path: '/opt/test',
        enabled: false,
        createTime: DateTime.now().subtract(const Duration(days: 3)),
        updateTime: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    
    selectedSftpRoot.value = sftpRoots.first;
  }

  void selectSftpRoot(SftpFileRoot? root) {
    selectedSftpRoot.value = root;
  }

  Future<void> createSftpRoot(String name, String host, int port, String user, String password, String path) async {
    final newRoot = SftpFileRoot(
      name: name,
      host: host,
      port: port,
      user: user,
      password: password,
      path: path,
      enabled: true,
      createTime: DateTime.now(),
      updateTime: DateTime.now(),
    );

    sftpRoots.add(newRoot);
    await saveSftpRoots();
    
    selectedSftpRoot.value = newRoot;
    
    Get.snackbar('成功', 'SFTP 根目录 "$name" 创建成功');
  }

  Future<void> deleteSftpRoot(SftpFileRoot root) async {
    sftpRoots.remove(root);
    
    if (selectedSftpRoot.value == root) {
      selectedSftpRoot.value = sftpRoots.isNotEmpty ? sftpRoots.first : null;
    }
    
    await saveSftpRoots();
    Get.snackbar('成功', 'SFTP 根目录已删除');
  }

  Future<void> updateSftpRoot(SftpFileRoot root, String name, String host, int port, String user, String password, String path) async {
    root.name = name;
    root.host = host;
    root.port = port;
    root.user = user;
    root.password = password;
    root.path = path;
    root.updateTime = DateTime.now();
    
    sftpRoots.refresh();
    await saveSftpRoots();
    
    Get.snackbar('成功', 'SFTP 根目录 "$name" 更新成功');
  }

  Future<void> toggleSftpRootEnabled(SftpFileRoot root) async {
    root.enabled = !(root.enabled ?? false);
    root.updateTime = DateTime.now();
    
    sftpRoots.refresh();
    await saveSftpRoots();
  }
}