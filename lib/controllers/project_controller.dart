import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import '../entity/entity.dart';
import '../services/xml_merger.dart';
import '../utils/windows_clipboard.dart';

class ProjectController extends GetxController {
  // 响应式变量
  final RxList<Project> projects = <Project>[].obs;
  final Rx<Project?> selectedProject = Rx<Project?>(null);
  final RxList<ProjectItem> currentItems = <ProjectItem>[].obs;
  final Rx<ProjectItem?> selectedItem = Rx<ProjectItem?>(null);
  final RxString filterText = ''.obs;
  final RxString outputPath = ''.obs;
  final RxString lastGenerateLog = ''.obs;
  final RxBool isGenerating = false.obs;
  final Rx<GenerateStatus?> lastGenerateStatus = Rx<GenerateStatus?>(null);

  // 过滤后的项目列表
  List<Project> get filteredProjects {
    List<Project> result;
    if (filterText.value.isEmpty) {
      result = projects.toList();
    } else {
      result = projects.where((project) => 
        project.name?.toLowerCase().contains(filterText.value.toLowerCase()) ?? false
      ).toList();
    }
    // 按sortOrder排序
    result.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    return result;
  }

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  // 加载项目数据
  Future<void> loadProjects() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/projects.json');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        projects.value = jsonList.map((json) => Project.fromJson(json)).toList();
      } else {
        // 如果文件不存在，创建示例数据
        _createSampleData();
      }
    } catch (e) {
      Get.snackbar('错误', '加载项目失败: $e');
      _createSampleData();
    }
  }

  // 保存项目数据
  Future<void> saveProjects() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/projects.json');
      
      final jsonList = projects.map((project) => project.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      Get.snackbar('错误', '保存项目失败: $e');
    }
  }

  // 创建示例数据
  void _createSampleData() {
    projects.value = [
      Project(
        name: '示例项目1',
        outputPath: '/path/to/output1',
        sortOrder: 0,
        createTime: DateTime.now().subtract(const Duration(days: 2)),
        updateTime: DateTime.now().subtract(const Duration(hours: 1)),
        items: [
          ProjectItem(
            name: 'file1.txt',
            path: '/path/to/file1.txt',
            enabled: true,
            sortOrder: 0,
            isExclude: false,
          ),
          ProjectItem(
            name: 'file2.cpp',
            path: '/path/to/file2.cpp',
            enabled: false,
            sortOrder: 1,
            isExclude: false,
          ),
        ],
      ),
      Project(
        name: '示例项目2',
        outputPath: '/path/to/output2',
        sortOrder: 1,
        createTime: DateTime.now().subtract(const Duration(days: 1)),
        updateTime: DateTime.now().subtract(const Duration(minutes: 30)),
        items: [
          ProjectItem(
            name: 'document.md',
            path: '/path/to/document.md',
            enabled: true,
            sortOrder: 0,
            isExclude: false,
          ),
        ],
      ),
    ];
  }

  // 选择项目
  void selectProject(Project project) {
    selectedProject.value = project;
    final items = project.items ?? [];
    // 按sortOrder排序
    items.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    currentItems.value = items;
    selectedItem.value = null;
    outputPath.value = project.outputPath ?? '';
  }

  // 创建项目
  Future<void> createProject(String name) async {
    final newProject = Project(
      name: name,
      outputPath: '',
      sortOrder: projects.length,
      createTime: DateTime.now(),
      updateTime: DateTime.now(),
      items: [],
    );
    
    projects.add(newProject);
    await saveProjects();
    selectProject(newProject);
    
    Get.snackbar('成功', '项目 "$name" 创建成功');
  }

  // 删除项目
  Future<void> deleteProject(Project project) async {
    projects.remove(project);
    
    // 重新排序
    for (int i = 0; i < projects.length; i++) {
      projects[i].sortOrder = i;
    }
    
    if (selectedProject.value == project) {
      selectedProject.value = null;
      currentItems.clear();
      selectedItem.value = null;
      outputPath.value = '';
    }
    
    await saveProjects();
    Get.snackbar('成功', '项目已删除');
  }

  // 向上移动项目
  Future<void> moveProjectUp(Project project) async {
    final index = projects.indexOf(project);
    if (index > 0) {
      projects.removeAt(index);
      projects.insert(index - 1, project);
      
      // 重新排序
      for (int i = 0; i < projects.length; i++) {
        projects[i].sortOrder = i;
      }
      
      await saveProjects();
    }
  }

  // 向下移动项目
  Future<void> moveProjectDown(Project project) async {
    final index = projects.indexOf(project);
    if (index < projects.length - 1) {
      projects.removeAt(index);
      projects.insert(index + 1, project);
      
      // 重新排序
      for (int i = 0; i < projects.length; i++) {
        projects[i].sortOrder = i;
      }
      
      await saveProjects();
    }
  }

  // 选择输出路径
  Future<void> selectOutputPath() async {
    if (selectedProject.value == null) return;
    
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    
    if (selectedDirectory != null) {
      selectedProject.value!.outputPath = selectedDirectory;
      outputPath.value = selectedDirectory;
      selectedProject.value!.updateTime = DateTime.now();
      await saveProjects();
    }
  }

  // 添加目录到项目
  Future<void> addDirectoriesToProject() async {
    if (selectedProject.value == null) return;
    
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    
    if (selectedDirectory != null) {
      final dirName = selectedDirectory.split(RegExp(r'[/\\]')).last;
      
      // 检查是否已存在
      final exists = currentItems.any((item) => item.path == selectedDirectory);
      if (!exists) {
        final newItem = ProjectItem(
          name: dirName,
          path: selectedDirectory,
          enabled: true,
          sortOrder: currentItems.length,
        );
        
        currentItems.add(newItem);
        selectedProject.value!.items = currentItems.toList();
        selectedProject.value!.updateTime = DateTime.now();
        
        await saveProjects();
        
        // 检查目录类型并给出建议
        String message = '已添加目录: $dirName';
        if (XmlMerger.shouldIgnorePath(selectedDirectory)) {
          message += '\n提示: 此目录路径可能应该被忽略';
        }
        
        Get.snackbar('成功', message, duration: const Duration(seconds: 3));
      } else {
        Get.snackbar('提示', '所选目录已存在于项目中');
      }
    }
  }

  // 添加文件到项目
  Future<void> addFilesToProject() async {
    if (selectedProject.value == null) return;
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    
    if (result != null) {
      int addedCount = 0;
      
      for (var file in result.files) {
        if (file.path != null) {
          final fileName = file.name;
          final filePath = file.path!;
          
          // 检查是否已存在
          final exists = currentItems.any((item) => item.path == filePath);
          if (!exists) {
                      final newItem = ProjectItem(
            name: fileName,
            path: filePath,
            enabled: true,
            sortOrder: currentItems.length,
            isExclude: false,
          );
            
            currentItems.add(newItem);
            selectedProject.value!.items = currentItems.toList();
            selectedProject.value!.updateTime = DateTime.now();
            addedCount++;
          }
        }
      }
      
      await saveProjects();
      
      if (addedCount > 0) {
        Get.snackbar('成功', '已添加 $addedCount 个文件', duration: const Duration(seconds: 3));
      } else {
        Get.snackbar('提示', '所选文件已存在于项目中');
      }
    }
  }

  // 选择项目项
  void selectItem(ProjectItem item) {
    selectedItem.value = item;
  }

  // 切换项目项启用状态
  Future<void> toggleItemEnabled(ProjectItem item) async {
    item.enabled = !(item.enabled ?? false);
    selectedProject.value!.updateTime = DateTime.now();
    
    // 手动触发UI更新
    currentItems.refresh();
    
    await saveProjects();
  }

  // 切换项目项排除状态
  Future<void> toggleItemExclude(ProjectItem item) async {
    item.isExclude = !(item.isExclude ?? false);
    selectedProject.value!.updateTime = DateTime.now();
    
    // 手动触发UI更新
    currentItems.refresh();
    
    await saveProjects();
  }

  // 删除项目项
  Future<void> deleteItem(ProjectItem item) async {
    currentItems.remove(item);
    selectedProject.value!.items = currentItems.toList();
    
    // 重新排序
    for (int i = 0; i < currentItems.length; i++) {
      currentItems[i].sortOrder = i;
    }
    
    if (selectedItem.value == item) {
      selectedItem.value = null;
    }
    
    selectedProject.value!.updateTime = DateTime.now();
    await saveProjects();
    Get.snackbar('成功', '文件已删除');
  }

  // 向上移动项目项
  Future<void> moveItemUp(ProjectItem item) async {
    final index = currentItems.indexOf(item);
    if (index > 0) {
      currentItems.removeAt(index);
      currentItems.insert(index - 1, item);
      
      // 重新排序
      for (int i = 0; i < currentItems.length; i++) {
        currentItems[i].sortOrder = i;
      }
      
      selectedProject.value!.items = currentItems.toList();
      selectedProject.value!.updateTime = DateTime.now();
      await saveProjects();
    }
  }

  // 向下移动项目项
  Future<void> moveItemDown(ProjectItem item) async {
    final index = currentItems.indexOf(item);
    if (index < currentItems.length - 1) {
      currentItems.removeAt(index);
      currentItems.insert(index + 1, item);
      
      // 重新排序
      for (int i = 0; i < currentItems.length; i++) {
        currentItems[i].sortOrder = i;
      }
      
      selectedProject.value!.items = currentItems.toList();
      selectedProject.value!.updateTime = DateTime.now();
      await saveProjects();
    }
  }

  // 设置过滤文本
  void setFilterText(String text) {
    filterText.value = text;
  }

  // 获取启用的项目项数量
  int get enabledItemsCount {
    return currentItems.where((item) => item.enabled == true).length;
  }

  // 处理拖拽文件/目录
  Future<void> handleDroppedFiles(List<XFile> files) async {
    if (selectedProject.value == null) {
      Get.snackbar('提示', '请先选择一个项目');
      return;
    }
    
    int addedCount = 0;
    int ignoredCount = 0;
    
    for (var file in files) {
      final fileName = file.name;
      final filePath = file.path;
      
      // 检查是否为目录
      final entity = FileSystemEntity.typeSync(filePath);
      if (entity == FileSystemEntityType.directory) {
        // 处理目录
        final exists = currentItems.any((item) => item.path == filePath);
        if (!exists) {
          final newItem = ProjectItem(
            name: fileName,
            path: filePath,
            enabled: true,
            sortOrder: currentItems.length,
            isExclude: false,
          );
          
          currentItems.add(newItem);
          selectedProject.value!.items = currentItems.toList();
          selectedProject.value!.updateTime = DateTime.now();
          addedCount++;
          
          // 检查目录类型并统计
          if (XmlMerger.shouldIgnorePath(filePath)) {
            ignoredCount++;
          }
        }
      } else {
        // 对于单个文件，提示用户应该拖拽目录
        Get.snackbar('提示', '请拖拽目录而不是单个文件\n当前工具处理的是目录结构');
        return;
      }
    }
    
    await saveProjects();
    
    // 构建提示消息
    String message = '已添加 $addedCount 个目录';
    if (ignoredCount > 0) {
      message += '\n其中 $ignoredCount 个目录路径可能应该被忽略';
    }
    
    if (addedCount > 0) {
      Get.snackbar('成功', message, duration: const Duration(seconds: 3));
    } else {
      Get.snackbar('提示', '所选目录已存在于项目中');
    }
  }

  // 新增：处理拖拽文件夹到项目列表以快速创建项目
  Future<void> handleProjectDropAndCreate(List<XFile> files) async {
    // 1. 输入验证
    if (files.isEmpty) {
      return; // 没有拖入任何内容
    }

    // 此功能只处理拖入的第一个项目，并确保它是一个文件夹
    final droppedFile = files.first;
    final filePath = droppedFile.path;

    final entityType = FileSystemEntity.typeSync(filePath);
    if (entityType != FileSystemEntityType.directory) {
      Get.snackbar('创建失败', '请拖拽一个文件夹以快速创建项目。');
      return;
    }

    // 2. 提取文件夹名作为项目名，并检查是否重复
    final projectName = filePath.split(RegExp(r'[/\\]')).last; // Fixed RegExp
    final isDuplicate = projects.any((p) => p.name == projectName);
    if (isDuplicate) {
      Get.snackbar('创建失败', '名为 "$projectName" 的项目已存在。');
      return;
    }

    // 3. 确定新项目的输出路径
    // 规则：使用当前第一个项目的输出路径；若项目列表为空，则为空字符串。
    final String defaultOutputPath = projects.isNotEmpty ? (projects.first.outputPath ?? '') : '';

    // 4. 创建新的 ProjectItem
    final newItem = ProjectItem(
      name: projectName,
      path: filePath,
      enabled: true,
      sortOrder: 0, // 因为是唯一的item，所以排序为0
      isExclude: false,
    );

    // 5. 创建新的 Project
    final newProject = Project(
      name: projectName,
      outputPath: defaultOutputPath,
      sortOrder: projects.length, // 添加到列表末尾
      createTime: DateTime.now(),
      updateTime: DateTime.now(),
      items: [newItem], // 将文件夹作为唯一的item
    );

    // 6. 添加到列表、保存并提供用户反馈
    projects.add(newProject);
    await saveProjects();
    
    // (可选，但建议) 自动选中新创建的项目，提升用户体验
    selectProject(newProject);

    Get.snackbar('成功', '项目 "$projectName" 已通过拖拽快速创建。');
  }

  // 生成项目合并文件
  Future<void> generateProject([Project? targetProject]) async {
    // 检查是否正在生成
    if (isGenerating.value) {
      return;
    }

    final project = targetProject ?? selectedProject.value;
    if (project == null) {
      Get.snackbar('错误', '请先选择一个项目');
      return;
    }
    if (project.outputPath == null || project.outputPath!.isEmpty) {
      Get.snackbar('错误', '请先设置输出路径');
      return;
    }

    final projectItems = project.items ?? [];
    final enabledItems = projectItems.where((item) => item.enabled == true).toList();
    if (enabledItems.isEmpty) {
      Get.snackbar('错误', '没有启用的文件');
      return;
    }

    // 设置生成状态
    isGenerating.value = true;

    final logBuffer = StringBuffer();
    final startTime = DateTime.now();
    
    try {
      logBuffer.writeln('=== Tool Merger Generate Log ===');
      logBuffer.writeln('开始时间: ${startTime.toString()}');
      logBuffer.writeln('项目名称: ${project.name}');
      logBuffer.writeln('输出路径: ${project.outputPath}');
      logBuffer.writeln('');
      
      // 显示启用的项目项详情
      logBuffer.writeln('=== 项目项列表 ===');
      logBuffer.writeln('总项目项数: ${projectItems.length}');
      logBuffer.writeln('启用项目项数: ${enabledItems.length}');
      logBuffer.writeln('');
      
      for (int i = 0; i < projectItems.length; i++) {
        final item = projectItems[i];
        final status = (item.enabled ?? false) ? '[启用]' : '[禁用]';
        logBuffer.writeln('${i + 1}. $status ${item.name} -> ${item.path}');
      }
      logBuffer.writeln('');
      
      // 创建输出文件路径
      logBuffer.writeln('=== 输出文件准备 ===');
      final outputDir = Directory(project.outputPath!);
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
        logBuffer.writeln('创建输出目录: ${project.outputPath}');
      } else {
        logBuffer.writeln('输出目录已存在: ${project.outputPath}');
      }

      final outputFile = File('${project.outputPath}/${project.name}.xml');
      logBuffer.writeln('输出文件路径: ${outputFile.path}');
      logBuffer.writeln('');
      
      // 使用 XmlMerger 生成 XML 内容
      logBuffer.writeln('=== XML 生成过程 ===');
      logBuffer.writeln('开始调用 XmlMerger.mergeXml()...');
      
      // 记录每个启用项目项的处理过程
      int processedCount = 0;
      int totalFiles = 0;
      int totalDirs = 0;
      
      for (final item in enabledItems) {
        processedCount++;
        logBuffer.writeln('[$processedCount/${enabledItems.length}] 处理项目项: ${item.name}');
        logBuffer.writeln('  路径: ${item.path}');
        
        // 检查是文件还是目录
        final entity = FileSystemEntity.typeSync(item.path ?? '');
        if (entity == FileSystemEntityType.file) {
          logBuffer.writeln('  类型: 文件');
          totalFiles++;
        } else if (entity == FileSystemEntityType.directory) {
          logBuffer.writeln('  类型: 目录');
          totalDirs++;
          
          // 如果是目录，扫描其中的文件
          try {
            final dir = Directory(item.path!);
            final files = await dir.list(recursive: true).where((entity) => entity is File).toList();
            logBuffer.writeln('  扫描到文件数: ${files.length}');
            
            // 显示前几个文件作为示例
            final sampleFiles = files.take(3).toList();
            for (final file in sampleFiles) {
              logBuffer.writeln('    - ${file.path}');
            }
            if (files.length > 3) {
              logBuffer.writeln('    ... 还有 ${files.length - 3} 个文件');
            }
          } catch (e) {
            logBuffer.writeln('  扫描目录时出错: $e');
          }
        } else {
          logBuffer.writeln('  类型: 未知或不存在');
        }
        logBuffer.writeln('');
      }
      
      logBuffer.writeln('项目项处理完成:');
      logBuffer.writeln('  - 文件数: $totalFiles');
      logBuffer.writeln('  - 目录数: $totalDirs');
      logBuffer.writeln('');
      
      final mergeResult = await XmlMerger.mergeXml(project, logCallback: (message) {
        logBuffer.writeln(message);
      });
      final xmlContent = mergeResult.xmlContent;
      logBuffer.writeln('');
      logBuffer.writeln('XML 内容生成完成');
      logBuffer.writeln('  - 内容大小: ${(xmlContent.length / 1024).toStringAsFixed(1)} KB');
      logBuffer.writeln('  - 字符数: ${xmlContent.length}');
      logBuffer.writeln('  - 行数: ${xmlContent.split('\n').length}');
      logBuffer.writeln('');
      
      // 写入文件
      logBuffer.writeln('=== 文件写入 ===');
      await outputFile.writeAsString(xmlContent, encoding: utf8);
      logBuffer.writeln('文件写入完成: ${outputFile.path}');
      
      // 验证写入的文件
      bool clipboardSuccess = false;
      final writtenFile = File(outputFile.path);
      if (await writtenFile.exists()) {
        final fileSize = await writtenFile.length();
        logBuffer.writeln('文件验证成功:');
        logBuffer.writeln('  - 文件大小: ${(fileSize / 1024).toStringAsFixed(1)} KB');
        logBuffer.writeln('  - 文件路径: ${writtenFile.path}');
        
        // 将文件复制到剪切板 (仅 Windows)
        logBuffer.writeln('');
        logBuffer.writeln('=== 剪切板操作 ===');
        if (Platform.isWindows) {
          logBuffer.writeln('尝试将文件复制到剪切板...');
          clipboardSuccess = await WindowsClipboard.copyFileToClipboard(outputFile.path);
          if (clipboardSuccess) {
            logBuffer.writeln('文件已复制到剪切板，可以使用 Ctrl+V 粘贴');
          } else {
            logBuffer.writeln('警告: 文件复制到剪切板失败');
          }
        } else {
          logBuffer.writeln('跳过剪切板操作 (仅支持 Windows)');
        }
      } else {
        logBuffer.writeln('警告: 文件写入后验证失败');
      }
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      logBuffer.writeln('');
      logBuffer.writeln('=== 生成完成 ===');
      logBuffer.writeln('结束时间: ${endTime.toString()}');
      logBuffer.writeln('总耗时: ${duration.inMilliseconds} ms (${(duration.inMilliseconds / 1000).toStringAsFixed(2)} 秒)');
      logBuffer.writeln('生成状态: 成功');
      logBuffer.writeln('处理统计:');
      logBuffer.writeln('  - 启用项目项: ${enabledItems.length}');
      logBuffer.writeln('  - 文件项: $totalFiles');
      logBuffer.writeln('  - 目录项: $totalDirs');
      logBuffer.writeln('  - 输出文件: ${outputFile.path}');
      
      // 收集文件状态信息
      logBuffer.writeln('');
      logBuffer.writeln('=== 收集文件状态信息 ===');
      final fileStatuses = await _collectFileStatuses(mergeResult.mergedFilePaths, logBuffer);
      logBuffer.writeln('收集到 ${fileStatuses.length} 个文件的状态信息');
      
      // 保存生成状态信息
      lastGenerateStatus.value = GenerateStatus(
        generateTime: DateTime.now(),
        projectName: project.name,
        fileStatuses: fileStatuses,
      );
      
      // 保存日志到全局变量
      lastGenerateLog.value = logBuffer.toString();
      
      // 更新项目时间并保存
      project.updateTime = DateTime.now();
      await saveProjects();
      
      // 构建成功消息
      String successMessage = '文件生成成功!\n路径: ${outputFile.path}\n大小: ${(xmlContent.length / 1024).toStringAsFixed(1)} KB';
      
      // 如果剪切板操作成功，添加提示
      if (clipboardSuccess) {
        successMessage += '\n\n文件已复制到剪切板，可使用 Ctrl+V 粘贴';
      }
      
            Get.snackbar(
        '成功', 
        successMessage,
        duration: const Duration(seconds: 5),
      );
    } catch (e, stackTrace) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      logBuffer.writeln('');
      logBuffer.writeln('=== 生成失败 ===');
      logBuffer.writeln('结束时间: ${endTime.toString()}');
      logBuffer.writeln('总耗时: ${duration.inMilliseconds} ms (${(duration.inMilliseconds / 1000).toStringAsFixed(2)} 秒)');
      logBuffer.writeln('生成状态: 失败');
      logBuffer.writeln('');
      logBuffer.writeln('错误详情:');
      logBuffer.writeln('  错误类型: ${e.runtimeType}');
      logBuffer.writeln('  错误信息: $e');
      logBuffer.writeln('');
      logBuffer.writeln('堆栈跟踪:');
      logBuffer.writeln(stackTrace.toString());
      logBuffer.writeln('');
      logBuffer.writeln('调试信息:');
      logBuffer.writeln('  - 项目名称: ${project.name}');
      logBuffer.writeln('  - 输出路径: ${project.outputPath}');
      logBuffer.writeln('  - 启用项目项数: ${enabledItems.length}');
      
      // 保存错误日志到全局变量
      lastGenerateLog.value = logBuffer.toString();
      project.updateTime = DateTime.now();
      await saveProjects();
      
      Get.snackbar('错误', '生成文件失败: $e');
    } finally {
      // 重置生成状态
      isGenerating.value = false;
    }
  }

  // 收集文件状态信息
  Future<List<FileStatusInfo>> _collectFileStatuses(List<String> mergedFilePaths, StringBuffer logBuffer) async {
    final List<FileStatusInfo> fileStatuses = [];
    
    for (final filePath in mergedFilePaths) {
      if (filePath.isEmpty) continue;
      
      try {
        final fileStatus = await _getFileStatus(filePath);
        if (fileStatus != null) {
          fileStatuses.add(fileStatus);
          logBuffer.writeln('  文件: ${fileStatus.fullPath} (${fileStatus.fileSize} bytes, ${fileStatus.lineCount} lines)');
        }
      } catch (e) {
        logBuffer.writeln('  错误: 无法处理 $filePath - $e');
      }
    }
    
    return fileStatuses;
  }

  // 获取单个文件的状态信息
  Future<FileStatusInfo?> _getFileStatus(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      
      final stat = await file.stat();
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      // 获取文件扩展名
      String? extension;
      final lastDotIndex = filePath.lastIndexOf('.');
      if (lastDotIndex != -1 && lastDotIndex < filePath.length - 1) {
        extension = filePath.substring(lastDotIndex + 1);
      }
      
      return FileStatusInfo(
        fullPath: filePath,
        extension: extension,
        lineCount: lines.length,
        fileSize: stat.size,
        processTime: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }
}