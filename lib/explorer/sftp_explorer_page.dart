import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sftp_controller.dart';
import '../entity/entity.dart';
import 'sftp_explorer.dart';

class SftpExplorerPage extends StatefulWidget {
  const SftpExplorerPage({super.key});

  @override
  State<SftpExplorerPage> createState() => _SftpExplorerPageState();
}

class _SftpExplorerPageState extends State<SftpExplorerPage> {
  late final SftpController sftpController;
  late final SftpExplorerController explorerController;

  @override
  void initState() {
    super.initState();
    // 尝试从不同的tag中获取SftpController
    try {
      sftpController = Get.find<SftpController>(tag: 'sftp');
    } catch (e) {
      // 如果没有找到带tag的，尝试不带tag的
      try {
        sftpController = Get.find<SftpController>();
      } catch (e2) {
        // 如果都没找到，创建一个新的
        sftpController = Get.put(SftpController());
      }
    }
    explorerController = SftpExplorerController();
    
    // 检查是否有传入的SftpFileRoot参数
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is SftpFileRoot) {
        _connectToSftp(arguments);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SFTP 文件浏览器'),
        backgroundColor: Colors.blue.shade100,
        actions: [
          _buildConnectionSelector(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildConnectionStatus(),
          Expanded(
            child: Obx(() {
              final currentRoot = sftpController.selectedSftpRoot.value;
              if (currentRoot == null) {
                return _buildNoConnectionView();
              }
              return SftpExplorer(controller: explorerController);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionSelector() {
    return Obx(() {
      final sftpRoots = sftpController.sftpRoots;
      final selectedRoot = sftpController.selectedSftpRoot.value;

      return PopupMenuButton<SftpFileRoot?>(
        icon: const Icon(Icons.dns),
        tooltip: '选择SFTP连接',
        onSelected: _connectToSftp,
        itemBuilder: (context) => [
          ...sftpRoots.map((root) => PopupMenuItem(
            value: root,
            child: Row(
              children: [
                Icon(
                  root.enabled == true ? Icons.check_circle : Icons.cancel,
                  color: root.enabled == true ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        root.name ?? '未命名',
                        style: TextStyle(
                          fontWeight: selectedRoot == root ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Text(
                        '${root.user}@${root.host}:${root.port}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
          if (sftpRoots.isNotEmpty) const PopupMenuDivider(),
          const PopupMenuItem(
            value: null,
            child: Row(
              children: [
                Icon(Icons.close, size: 16),
                SizedBox(width: 8),
                Text('断开连接'),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildConnectionStatus() {
    return Obx(() {
      final currentRoot = sftpController.selectedSftpRoot.value;
      final isLoading = explorerController.isLoading;
      
      if (currentRoot == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
        ),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 16,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '已连接到: ${currentRoot.name} (${currentRoot.user}@${currentRoot.host}:${currentRoot.port})',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            TextButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.close, size: 16),
              label: const Text('断开'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildNoConnectionView() {
    return Obx(() {
      final sftpRoots = sftpController.sftpRoots;
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              '未连接到SFTP服务器',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '请选择一个SFTP连接开始浏览文件',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (sftpRoots.isNotEmpty) ...[
              const Text('可用连接:'),
              const SizedBox(height: 16),
              ...sftpRoots.map((root) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    root.enabled == true ? Icons.dns : Icons.dns_outlined,
                    color: root.enabled == true ? Colors.blue : Colors.grey,
                  ),
                  title: Text(root.name ?? '未命名'),
                  subtitle: Text('${root.user}@${root.host}:${root.port}'),
                  trailing: root.enabled == true 
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
                    : const Icon(Icons.cancel, color: Colors.red, size: 16),
                  onTap: root.enabled == true ? () => _connectToSftp(root) : null,
                  enabled: root.enabled == true,
                ),
              )),
            ] else ...[
              const Text('暂无可用的SFTP连接'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showAddConnectionDialog,
                icon: const Icon(Icons.add),
                label: const Text('添加SFTP连接'),
              ),
            ],
          ],
        ),
      );
    });
  }

  Future<void> _connectToSftp(SftpFileRoot? root) async {
    if (root == null) {
      _disconnect();
      return;
    }

    if (root.enabled != true) {
      Get.snackbar('错误', '连接已禁用，请先启用此连接');
      return;
    }

    sftpController.selectSftpRoot(root);
    
    try {
      await explorerController.connectToSftp(root);
      Get.snackbar('成功', '已连接到 ${root.name}');
    } catch (e) {
      Get.snackbar('连接失败', e.toString(), backgroundColor: Colors.red.withOpacity(0.7));
    }
  }

  void _disconnect() {
    sftpController.selectSftpRoot(null);
    Get.snackbar('已断开', '已断开SFTP连接');
  }

  void _showAddConnectionDialog() {
    final nameController = TextEditingController();
    final hostController = TextEditingController();
    final portController = TextEditingController(text: '22');
    final userController = TextEditingController();
    final passwordController = TextEditingController();
    final pathController = TextEditingController(text: '/');

    Get.dialog(
      AlertDialog(
        title: const Text('添加SFTP连接'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '连接名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: hostController,
                      decoration: const InputDecoration(
                        labelText: '主机地址',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: portController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '端口',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: userController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pathController,
                decoration: const InputDecoration(
                  labelText: '初始路径',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final host = hostController.text.trim();
              final port = int.tryParse(portController.text) ?? 22;
              final user = userController.text.trim();
              final password = passwordController.text;
              final path = pathController.text.trim();

              if (name.isEmpty || host.isEmpty || user.isEmpty) {
                Get.snackbar('错误', '请填写所有必要信息');
                return;
              }

              sftpController.createSftpRoot(name, host, port, user, password, path);
              Get.back();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}