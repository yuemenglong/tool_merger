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
      final directory = await getApplicationSupportDirectory();
      final configDir = Directory('${directory.path}/config');
      if (!await configDir.exists()) {
        await configDir.create(recursive: true);
      }
      
      final file = LocalFile.create('${configDir.path}/sftp_roots.json');
      
      if (await file.isFile()) {
        await _loadConfigFromFile(file);
      } else {
        _createSampleSftpRoots();
      }
    } catch (e) {
      Get.snackbar('错误', '加载 SFTP 根目录失败: $e', duration: const Duration(seconds: 1));
      _createSampleSftpRoots();
    }
  }

  Future<void> _loadConfigFromFile(LocalFile file) async {
    final contentBytes = await file.read();
    final jsonString = String.fromCharCodes(contentBytes);
    final List<dynamic> jsonList = json.decode(jsonString);
    sftpRoots.value = jsonList.map((json) => SftpFileRoot.fromJson(json)).toList();
    
    // Remove duplicates based on the SftpFileRoot equality comparison
    final uniqueRoots = <SftpFileRoot>[];
    for (final root in sftpRoots) {
      if (!uniqueRoots.any((existing) => existing == root)) {
        uniqueRoots.add(root);
      }
    }
    sftpRoots.value = uniqueRoots;
    
    if (sftpRoots.isNotEmpty && selectedSftpRoot.value == null) {
      final enabledRoot = sftpRoots.firstWhere(
        (root) => root.enabled == true, 
        orElse: () => sftpRoots.first
      );
      selectedSftpRoot.value = enabledRoot;
    } else if (selectedSftpRoot.value != null) {
      // Ensure the selected root exists in the current list using identical reference check
      SftpFileRoot? matchingRoot;
      for (final root in sftpRoots) {
        if (root == selectedSftpRoot.value) {
          matchingRoot = root;
          break;
        }
      }
      
      // If no exact match found, try to find by same properties and use that reference
      if (matchingRoot == null && sftpRoots.isNotEmpty) {
        final current = selectedSftpRoot.value!;
        matchingRoot = sftpRoots.firstWhere(
          (root) => root.name == current.name && 
                   root.host == current.host && 
                   root.port == current.port &&
                   root.user == current.user &&
                   root.path == current.path,
          orElse: () => sftpRoots.first,
        );
      }
      
      selectedSftpRoot.value = matchingRoot;
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
      Get.snackbar('错误', '保存 SFTP 根目录失败: $e', duration: const Duration(seconds: 1));
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
    if (root == null) {
      selectedSftpRoot.value = null;
      return;
    }
    
    // Find the exact object reference in the list
    SftpFileRoot? exactMatch;
    for (final listRoot in sftpRoots) {
      if (identical(listRoot, root)) {
        exactMatch = listRoot;
        break;
      }
    }
    
    // If not found by reference, find by equality
    if (exactMatch == null) {
      exactMatch = sftpRoots.firstWhere(
        (r) => r == root,
        orElse: () => root,
      );
    }
    
    selectedSftpRoot.value = exactMatch;
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
    
    Get.snackbar('成功', 'SFTP 根目录 "$name" 创建成功', duration: const Duration(seconds: 1));
  }

  Future<void> deleteSftpRoot(SftpFileRoot root) async {
    sftpRoots.remove(root);
    
    if (selectedSftpRoot.value == root) {
      selectedSftpRoot.value = sftpRoots.isNotEmpty ? sftpRoots.first : null;
    }
    
    await saveSftpRoots();
    Get.snackbar('成功', 'SFTP 根目录已删除', duration: const Duration(seconds: 1));
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
    
    Get.snackbar('成功', 'SFTP 根目录 "$name" 更新成功', duration: const Duration(seconds: 1));
  }

  Future<void> toggleSftpRootEnabled(SftpFileRoot root) async {
    root.enabled = !(root.enabled ?? false);
    root.updateTime = DateTime.now();
    
    sftpRoots.refresh();
    await saveSftpRoots();
  }
}