import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../entity/entity.dart';
import '../controllers/project_controller.dart';
import 'uni_file.dart';

class SftpFileInfo {
  final UniFile file;
  final bool isDirectory;
  final int size;
  final DateTime? modifiedTime;
  final String name;
  final String path;

  SftpFileInfo({
    required this.file,
    required this.isDirectory,
    required this.size,
    required this.name,
    required this.path,
    this.modifiedTime,
  });
}

class SftpExplorerController extends GetxController {
  final RxList<SftpFileInfo> _files = <SftpFileInfo>[].obs;
  final RxString _currentPath = ''.obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxList<String> _pathHistory = <String>[].obs;
  final Rx<SftpFileRoot?> _currentRoot = Rx<SftpFileRoot?>(null);
  final RxList<SftpFileInfo> _selectedFiles = <SftpFileInfo>[].obs;
  final RxString _sortColumn = 'name'.obs;
  final RxBool _sortAscending = true.obs;
  final RxString _searchQuery = ''.obs;

  List<SftpFileInfo> get files => _searchQuery.isEmpty 
    ? _files 
    : _files.where((file) => file.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  
  String get currentPath => _currentPath.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  List<String> get pathHistory => _pathHistory;
  SftpFileRoot? get currentRoot => _currentRoot.value;
  List<SftpFileInfo> get selectedFiles => _selectedFiles;
  String get sortColumn => _sortColumn.value;
  bool get sortAscending => _sortAscending.value;
  String get searchQuery => _searchQuery.value;

  bool get canGoBack => _pathHistory.isNotEmpty;
  
  String get displayPath {
    if (_currentRoot.value == null) return '';
    final rootName = _currentRoot.value!.name ?? 'SFTP';
    return _currentPath.isEmpty ? rootName : '$rootName$_currentPath';
  }

  List<String> get breadcrumbs {
    if (_currentPath.isEmpty) return [];
    return _currentPath.value.split('/').where((part) => part.isNotEmpty).toList();
  }

  Future<void> connectToSftp(SftpFileRoot root) async {
    if (_currentRoot.value == root && _currentPath.value == root.path) {
      return;
    }

    _currentRoot.value = root;
    _pathHistory.clear();
    await navigateToPath(root.path ?? '/');
  }

  Future<void> navigateToPath(String path) async {
    if (_isLoading.value) return;
    
    _error.value = '';
    _isLoading.value = true;
    _selectedFiles.clear();

    try {
      final root = _currentRoot.value;
      if (root == null) {
        throw Exception('未连接到SFTP服务器');
      }

      final sftpFile = SftpFile.create(
        root.host!,
        root.port!,
        root.user!,
        root.password!,
        path,
      );

      final fileList = await sftpFile.list();
      final fileInfoList = <SftpFileInfo>[];

      for (final file in fileList) {
        final isDir = await file.isDir();
        final size = isDir ? 0 : await file.getSize();
        DateTime? modifiedTime;
        
        if (file is SftpFile) {
          modifiedTime = file.getModifiedTime();
        }
        
        fileInfoList.add(SftpFileInfo(
          file: file,
          isDirectory: isDir,
          size: size,
          name: file.getName(),
          path: file.getPath(),
          modifiedTime: modifiedTime,
        ));
      }

      _files.value = fileInfoList;
      _currentPath.value = path;
      _sortFiles();
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('错误', '无法加载目录: $e', backgroundColor: Colors.red.withOpacity(0.7), duration: const Duration(seconds: 1));
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> enterDirectory(SftpFileInfo fileInfo) async {
    if (!fileInfo.isDirectory) return;

    _pathHistory.add(_currentPath.value);
    await navigateToPath(fileInfo.path);
  }

  Future<void> goBack() async {
    if (!canGoBack) return;

    final previousPath = _pathHistory.removeLast();
    await navigateToPath(previousPath);
  }

  Future<void> goUp() async {
    if (_currentPath.isEmpty || _currentPath.value == '/') return;

    final pathParts = _currentPath.value.split('/');
    pathParts.removeLast();
    final parentPath = pathParts.isEmpty ? '/' : pathParts.join('/');
    
    _pathHistory.add(_currentPath.value);
    await navigateToPath(parentPath);
  }

  @override
  Future<void> refresh() async {
    await navigateToPath(_currentPath.value);
  }

  void selectFile(SftpFileInfo fileInfo) {
    if (_selectedFiles.contains(fileInfo)) {
      _selectedFiles.remove(fileInfo);
    } else {
      _selectedFiles.add(fileInfo);
    }
  }

  void selectAllFiles() {
    _selectedFiles.clear();
    _selectedFiles.addAll(_files);
  }

  void clearSelection() {
    _selectedFiles.clear();
  }

  void setSortColumn(String column) {
    if (_sortColumn.value == column) {
      _sortAscending.value = !_sortAscending.value;
    } else {
      _sortColumn.value = column;
      _sortAscending.value = true;
    }
    _sortFiles();
  }

  void _sortFiles() {
    final sortedFiles = List<SftpFileInfo>.from(_files);
    
    switch (_sortColumn.value) {
      case 'name':
        sortedFiles.sort((a, b) => _sortAscending.value 
          ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
          : b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'size':
        sortedFiles.sort((a, b) => _sortAscending.value 
          ? a.size.compareTo(b.size)
          : b.size.compareTo(a.size));
        break;
      case 'type':
        sortedFiles.sort((a, b) {
          final aType = a.isDirectory ? '文件夹' : '文件';
          final bType = b.isDirectory ? '文件夹' : '文件';
          return _sortAscending.value 
            ? aType.compareTo(bType)
            : bType.compareTo(aType);
        });
        break;
    }

    sortedFiles.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return 0;
    });

    _files.value = sortedFiles;
  }

  void setSearchQuery(String query) {
    _searchQuery.value = query;
  }

  void navigateToBreadcrumb(int index) {
    final pathParts = breadcrumbs;
    if (index >= pathParts.length) return;

    final targetPath = '/${pathParts.sublist(0, index + 1).join('/')}';
    _pathHistory.add(_currentPath.value);
    navigateToPath(targetPath);
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class SftpExplorer extends StatelessWidget {
  final SftpExplorerController controller;

  const SftpExplorer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(context),
        _buildBreadcrumb(context),
        Expanded(
          child: _buildFileList(context),
        ),
        _buildStatusBar(context),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Obx(() => IconButton(
            onPressed: controller.canGoBack ? controller.goBack : null,
            icon: const Icon(Icons.arrow_back),
            tooltip: '后退',
          )),
          IconButton(
            onPressed: controller.goUp,
            icon: const Icon(Icons.arrow_upward),
            tooltip: '上级目录',
          ),
          IconButton(
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: '搜索文件...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: controller.setSearchQuery,
            ),
          ),
          const SizedBox(width: 16),
          // 项目操作按钮
          Obx(() => ElevatedButton.icon(
            onPressed: controller.selectedFiles.isNotEmpty 
                ? () => _handleCreateProject(context)
                : null,
            icon: const Icon(Icons.create_new_folder, size: 16),
            label: const Text('Create Project'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          )),
          const SizedBox(width: 8),
          Obx(() => ElevatedButton.icon(
            onPressed: controller.selectedFiles.isNotEmpty 
                ? () => _handleAddToCurrentProject(context)
                : null,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add to Current'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context) {
    return Obx(() {
      final breadcrumbs = controller.breadcrumbs;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => controller.navigateToPath(controller.currentRoot?.path ?? '/'),
              child: Text(
                controller.currentRoot?.name ?? 'SFTP',
                style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            ...breadcrumbs.asMap().entries.map((entry) {
              final index = entry.key;
              final part = entry.value;
              return Row(
                children: [
                  const Text(' > '),
                  GestureDetector(
                    onTap: () => controller.navigateToBreadcrumb(index),
                    child: Text(
                      part,
                      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildFileList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.error.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(controller.error),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.refresh,
                child: const Text('重试'),
              ),
            ],
          ),
        );
      }

      return _buildDataTable(context);
    });
  }

  Widget _buildDataTable(BuildContext context) {
    return Obx(() {
      final files = controller.files;
      
      return SingleChildScrollView(
        child: DataTable(
          sortColumnIndex: _getSortColumnIndex(),
          sortAscending: controller.sortAscending,
          showCheckboxColumn: true,
          columns: [
            DataColumn(
              label: const Text('名称'),
              onSort: (columnIndex, ascending) => controller.setSortColumn('name'),
            ),
            DataColumn(
              label: const Text('类型'),
              onSort: (columnIndex, ascending) => controller.setSortColumn('type'),
            ),
            DataColumn(
              label: const Text('大小'),
              onSort: (columnIndex, ascending) => controller.setSortColumn('size'),
              numeric: true,
            ),
            const DataColumn(label: Text('修改时间')),
          ],
          rows: files.map((file) => DataRow(
            selected: controller.selectedFiles.contains(file),
            onSelectChanged: (selected) {
              if (selected ?? false) {
                controller.selectFile(file);
              } else {
                controller.selectedFiles.remove(file);
              }
            },
            cells: [
              DataCell(
                Row(
                  children: [
                    Icon(
                      file.isDirectory ? Icons.folder : Icons.insert_drive_file,
                      color: file.isDirectory ? Colors.amber : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(file.name),
                  ],
                ),
                onTap: () {
                  if (file.isDirectory) {
                    controller.enterDirectory(file);
                  }
                },
              ),
              DataCell(Text(file.isDirectory ? '文件夹' : '文件')),
              DataCell(Text(file.isDirectory ? '' : controller.formatFileSize(file.size))),
              DataCell(Text(file.modifiedTime?.toString().substring(0, 19) ?? '')),
            ],
          )).toList(),
        ),
      );
    });
  }

  int _getSortColumnIndex() {
    switch (controller.sortColumn) {
      case 'name': return 0;
      case 'type': return 1;
      case 'size': return 2;
      default: return 0;
    }
  }

  Widget _buildStatusBar(BuildContext context) {
    return Obx(() {
      final totalFiles = controller.files.length;
      final selectedFiles = controller.selectedFiles.length;
      final directories = controller.files.where((f) => f.isDirectory).length;
      final files = totalFiles - directories;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Text('$directories 个文件夹, $files 个文件'),
            if (selectedFiles > 0) ...[
              const SizedBox(width: 16),
              Text('已选择 $selectedFiles 项'),
            ],
            const Spacer(),
            Text('路径: ${controller.displayPath}'),
          ],
        ),
      );
    });
  }

  void _handleCreateProject(BuildContext context) {
    if (controller.selectedFiles.isEmpty) return;
    
    // 获取ProjectController实例
    try {
      final projectController = Get.find<ProjectController>();
      // 调用SFTP项目创建方法
      projectController.handleSftpProjectDropAndCreate(controller.selectedFiles);
    } catch (e) {
      Get.snackbar('错误', '无法获取项目控制器: $e', duration: const Duration(seconds: 1));
    }
  }

  void _handleAddToCurrentProject(BuildContext context) {
    if (controller.selectedFiles.isEmpty) return;
    
    // 获取ProjectController实例
    try {
      final projectController = Get.find<ProjectController>();
      // 调用SFTP文件添加方法
      projectController.handleSftpDroppedFiles(controller.selectedFiles);
    } catch (e) {
      Get.snackbar('错误', '无法获取项目控制器: $e', duration: const Duration(seconds: 1));
    }
  }
}