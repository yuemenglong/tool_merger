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
      final directory = await getApplicationDocumentsDirectory();
      final file = LocalFile.create('${directory.path}/sftp_roots.json');
      
      if (await file.isFile()) {
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
      } else {
        _createSampleSftpRoots();
      }
    } catch (e) {
      Get.snackbar('错误', '加载 SFTP 根目录失败: $e');
      _createSampleSftpRoots();
    }
  }

  Future<void> saveSftpRoots() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      final jsonList = sftpRoots.map((root) => root.toJson()).toList();
      final content = json.encode(jsonList);
      final outputFile = File('${directory.path}/sftp_roots.json');
      await outputFile.writeAsString(content);
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