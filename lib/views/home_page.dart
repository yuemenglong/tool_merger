import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/project_controller.dart';
import '../config.dart';
import '../entity/entity.dart';
import '../explorer/sftp_explorer_page.dart';
import 'project_section_view.dart';
import 'item_section_view.dart';

class ToolMergerHomePage extends StatelessWidget {
  const ToolMergerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectController controller = Get.put(ProjectController());

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: ProjectSectionView(controller: controller),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: ItemSectionView(controller: controller),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, controller),
    );
  }

  SftpFileRoot? _findMatchingRoot(ProjectController controller) {
    final selected = controller.selectedSftpRoot.value;
    if (selected == null) return null;
    
    // Check if the selected root exists by reference in the list
    for (final root in controller.sftpRoots) {
      if (identical(root, selected)) {
        return root;
      }
    }
    
    // Check if any root matches by equality
    for (final root in controller.sftpRoots) {
      if (root == selected) {
        return root;
      }
    }
    
    // No match found, return null to show hint
    return null;
  }

  AppBar _buildAppBar(BuildContext context) {
    final ProjectController controller = Get.find<ProjectController>();
    
    return AppBar(
      title: const Text(
        'Tool Merger',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        // SFTP Root 下拉框
        Flexible(
          child: Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SftpFileRoot?>(
                value: _findMatchingRoot(controller),
                hint: const Text('选择SFTP根目录', style: TextStyle(fontSize: 12)),
                items: [
                  const DropdownMenuItem<SftpFileRoot?>(
                    value: null,
                    child: Text('无', style: TextStyle(fontSize: 12)),
                  ),
                  ...controller.sftpRoots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final root = entry.value;
                    return DropdownMenuItem<SftpFileRoot?>(
                      value: root,
                      key: ValueKey('sftp_root_$index'),
                      child: Text(
                        root.name ?? '未命名',
                        style: TextStyle(
                          fontSize: 12,
                          color: root.enabled == true ? Colors.black : Colors.grey,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  controller.selectSftpRoot(value);
                },
                style: const TextStyle(fontSize: 12),
                isDense: true,
              ),
            ),
          )),
        ),
        const SizedBox(width: 8),
        // 添加按钮
        IconButton(
          onPressed: () => _showSftpRootDialog(context, controller),
          icon: const Icon(Icons.add, size: 18),
          tooltip: '添加SFTP根目录',
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: const EdgeInsets.all(4),
        ),
        // 编辑按钮
        Obx(() => IconButton(
          onPressed: controller.selectedSftpRoot.value != null 
              ? () => _showSftpRootDialog(context, controller, controller.selectedSftpRoot.value) 
              : null,
          icon: const Icon(Icons.edit, size: 18),
          tooltip: '编辑SFTP根目录',
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: const EdgeInsets.all(4),
        )),
        // 删除按钮
        Obx(() => IconButton(
          onPressed: controller.selectedSftpRoot.value != null 
              ? () => _showDeleteSftpRootDialog(context, controller) 
              : null,
          icon: const Icon(Icons.delete, size: 18),
          tooltip: '删除SFTP根目录',
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: const EdgeInsets.all(4),
        )),
        // 浏览按钮
        Obx(() => IconButton(
          onPressed: controller.selectedSftpRoot.value != null && controller.selectedSftpRoot.value!.enabled == true
              ? () => _openSftpExplorer(context, controller.selectedSftpRoot.value!) 
              : null,
          icon: const Icon(Icons.folder_open, size: 18),
          tooltip: '浏览SFTP文件',
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: const EdgeInsets.all(4),
        )),
      ],
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      elevation: 0,
      toolbarHeight: 48,
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, ProjectController controller) {
    return Obx(() {
      return controller.selectedProject.value != null
          ? Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '当前: ${controller.selectedProject.value?.name}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: AppConfig.statusFontSize,
                    ),
                  ),
                  const Spacer(),
                  if (controller.currentItems.isNotEmpty) ...[
                    Icon(
                      Icons.folder,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${controller.currentItems.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: AppConfig.buttonFontSize,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: AppConfig.enabledCountColor.shade600,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${controller.enabledItemsCount}',
                      style: TextStyle(
                        color: AppConfig.enabledCountColor.shade600,
                        fontSize: AppConfig.buttonFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            )
          : const SizedBox.shrink();
    });
  }

  // 显示 SFTP Root 添加/编辑对话框
  void _showSftpRootDialog(BuildContext context, ProjectController controller, [SftpFileRoot? editRoot]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _SftpRootDialog(
          editRoot: editRoot,
          onSave: (data) async {
            if (editRoot != null) {
              await controller.updateSftpRoot(
                editRoot,
                data['name']!,
                data['host']!,
                int.parse(data['port']!),
                data['user']!,
                data['password']!,
                data['path']!,
                authType: data['authType'] as SftpAuthType?,
                privateKeyPath: data['privateKeyPath'],
                passphrase: data['passphrase'],
              );
            } else {
              await controller.createSftpRoot(
                data['name']!,
                data['host']!,
                int.parse(data['port']!),
                data['user']!,
                data['password']!,
                data['path']!,
                authType: data['authType'] as SftpAuthType?,
                privateKeyPath: data['privateKeyPath'],
                passphrase: data['passphrase'],
              );
            }
          },
        );
      },
    );
  }

  // 显示删除 SFTP Root 确认对话框
  void _showDeleteSftpRootDialog(BuildContext context, ProjectController controller) {
    final root = controller.selectedSftpRoot.value;
    if (root == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除 SFTP 根目录 "${root.name}" 吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                await controller.deleteSftpRoot(root);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('删除', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // 打开SFTP Explorer
  void _openSftpExplorer(BuildContext context, SftpFileRoot sftpRoot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SftpExplorerPage(),
        settings: RouteSettings(arguments: sftpRoot),
      ),
    );
  }
}

class _SftpRootDialog extends StatefulWidget {
  final SftpFileRoot? editRoot;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const _SftpRootDialog({
    this.editRoot,
    required this.onSave,
  });

  @override
  State<_SftpRootDialog> createState() => _SftpRootDialogState();
}

class _SftpRootDialogState extends State<_SftpRootDialog> {
  late final TextEditingController nameController;
  late final TextEditingController hostController;
  late final TextEditingController portController;
  late final TextEditingController userController;
  late final TextEditingController passwordController;
  late final TextEditingController pathController;
  late final TextEditingController privateKeyPathController;
  late final TextEditingController passphraseController;
  
  late SftpAuthType selectedAuthType;

  @override
  void initState() {
    super.initState();
    final editRoot = widget.editRoot;
    nameController = TextEditingController(text: editRoot?.name ?? '');
    hostController = TextEditingController(text: editRoot?.host ?? '');
    portController = TextEditingController(text: (editRoot?.port ?? 22).toString());
    userController = TextEditingController(text: editRoot?.user ?? '');
    passwordController = TextEditingController(text: editRoot?.password ?? '');
    pathController = TextEditingController(text: editRoot?.path ?? '');
    privateKeyPathController = TextEditingController(text: editRoot?.privateKeyPath ?? '');
    passphraseController = TextEditingController(text: editRoot?.passphrase ?? '');
    selectedAuthType = editRoot?.authType ?? SftpAuthType.password;
  }

  @override
  void dispose() {
    nameController.dispose();
    hostController.dispose();
    portController.dispose();
    userController.dispose();
    passwordController.dispose();
    pathController.dispose();
    privateKeyPathController.dispose();
    passphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.editRoot != null ? '编辑 SFTP 根目录' : '添加 SFTP 根目录'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic connection info
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '名称 *',
                  hintText: '输入显示名称',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hostController,
                decoration: const InputDecoration(
                  labelText: '主机地址 *',
                  hintText: '例如: 192.168.1.100',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: portController,
                decoration: const InputDecoration(
                  labelText: '端口',
                  hintText: '默认: 22',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: userController,
                decoration: const InputDecoration(
                  labelText: '用户名 *',
                  hintText: '输入用户名',
                ),
              ),
              const SizedBox(height: 16),
              
              // Authentication type selection
              const Text(
                '认证方式',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<SftpAuthType>(
                value: selectedAuthType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                    value: SftpAuthType.password,
                    child: Text('密码认证'),
                  ),
                  DropdownMenuItem(
                    value: SftpAuthType.privateKey,
                    child: Text('SSH密钥认证'),
                  ),
                  DropdownMenuItem(
                    value: SftpAuthType.both,
                    child: Text('混合认证（优先密钥）'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedAuthType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Password field (shown for password and both auth)
              if (selectedAuthType == SftpAuthType.password || 
                  selectedAuthType == SftpAuthType.both) ...[
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: selectedAuthType == SftpAuthType.both ? '密码 (可选)' : '密码 *',
                    hintText: '输入密码',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
              ],
              
              // Private key fields (shown for privateKey and both auth)
              if (selectedAuthType == SftpAuthType.privateKey || 
                  selectedAuthType == SftpAuthType.both) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: privateKeyPathController,
                        decoration: const InputDecoration(
                          labelText: '私钥文件路径 *',
                          hintText: '例如: /home/user/.ssh/id_ed25519',
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _pickPrivateKeyFile,
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: const Text('选择'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passphraseController,
                  decoration: const InputDecoration(
                    labelText: 'Passphrase (可选)',
                    hintText: '如果私钥已加密，请输入密码短语',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
              ],
              
              TextField(
                controller: pathController,
                decoration: const InputDecoration(
                  labelText: '根路径',
                  hintText: '例如: /home/user/projects',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: Text(widget.editRoot != null ? '更新' : '添加'),
        ),
      ],
    );
  }

  Future<void> _pickPrivateKeyFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      dialogTitle: '选择SSH私钥文件',
      initialDirectory: null,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        privateKeyPathController.text = result.files.single.path!;
      });
    }
  }

  Future<void> _handleSave() async {
    final name = nameController.text.trim();
    final host = hostController.text.trim();
    final portText = portController.text.trim();
    final user = userController.text.trim();
    final password = passwordController.text;
    final path = pathController.text.trim();
    final privateKeyPath = privateKeyPathController.text.trim();
    final passphrase = passphraseController.text.trim();

    // Validation
    if (name.isEmpty || host.isEmpty || user.isEmpty) {
      Get.snackbar('错误', '请填写必要的字段（名称、主机地址、用户名）', 
          duration: const Duration(seconds: 2));
      return;
    }

    // Validate auth-specific fields
    if (selectedAuthType == SftpAuthType.password && password.isEmpty) {
      Get.snackbar('错误', '密码认证模式下必须提供密码', 
          duration: const Duration(seconds: 2));
      return;
    }

    if (selectedAuthType == SftpAuthType.privateKey && privateKeyPath.isEmpty) {
      Get.snackbar('错误', 'SSH密钥认证模式下必须选择私钥文件', 
          duration: const Duration(seconds: 2));
      return;
    }

    if (selectedAuthType == SftpAuthType.both && 
        password.isEmpty && privateKeyPath.isEmpty) {
      Get.snackbar('错误', '混合认证模式下至少需要提供密码或私钥文件', 
          duration: const Duration(seconds: 2));
      return;
    }

    int port;
    try {
      port = int.parse(portText.isEmpty ? '22' : portText);
    } catch (e) {
      Get.snackbar('错误', '端口必须是有效的数字', 
          duration: const Duration(seconds: 2));
      return;
    }

    try {
      await widget.onSave({
        'name': name,
        'host': host,
        'port': port.toString(),
        'user': user,
        'password': password,
        'path': path,
        'authType': selectedAuthType,
        'privateKeyPath': privateKeyPath.isEmpty ? null : privateKeyPath,
        'passphrase': passphrase.isEmpty ? null : passphrase,
      });
      Navigator.of(context).pop();
    } catch (e) {
      Get.snackbar('错误', '保存失败: $e', 
          duration: const Duration(seconds: 2));
    }
  }
}