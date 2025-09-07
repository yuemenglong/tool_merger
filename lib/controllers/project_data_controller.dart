import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../entity/entity.dart';
import '../services/xml_merger.dart';
import '../explorer/uni_file.dart';

class ProjectDataController extends GetxController {
  final RxList<Project> projects = <Project>[].obs;
  final Rx<Project?> selectedProject = Rx<Project?>(null);

  List<Project> get filteredProjects {
    return projects.toList()..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
  }

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  Future<void> loadProjects() async {
    try {
      // 使用应用支持目录而非文档目录
      final directory = await getApplicationSupportDirectory();
      
      // 创建配置子目录
      final configDir = Directory('${directory.path}/config');
      if (!await configDir.exists()) {
        await configDir.create(recursive: true);
      }
      
      final newFile = LocalFile.create('${configDir.path}/projects.json');
      
      // 打印配置文件路径信息
      print('=== 项目配置文件路径信息 ===');
      print('应用支持目录: ${directory.path}');
      print('配置目录: ${configDir.path}');
      print('项目配置文件: ${newFile.getPath()}');
      print('配置目录是否存在: ${await configDir.exists()}');
      print('配置文件是否存在: ${await newFile.isFile()}');
      print('==============================');
      
      // 检查新位置是否存在配置文件
      if (await newFile.isFile()) {
        print('从新位置加载项目配置文件');
        await _loadProjectsFromFile(newFile);
      } else {
        print('新位置无项目配置文件，尝试迁移');
        // 尝试从旧位置迁移配置文件
        await _migrateProjectsFromOldLocation(newFile);
      }
    } catch (e) {
      print('加载项目配置时出错: $e');
      Get.snackbar('错误', '加载项目失败: $e');
      _createSampleData();
    }
  }

  Future<void> _loadProjectsFromFile(LocalFile file) async {
    final contentBytes = await file.read();
    final jsonString = String.fromCharCodes(contentBytes);
    final List<dynamic> jsonList = json.decode(jsonString);
    projects.value = jsonList.map((json) => Project.fromJson(json)).toList();

    bool needsSave = false;
    for (var project in projects) {
      if (project.targetExt == null || project.targetExt!.isEmpty) {
        _populateDefaultExtensions(project);
        needsSave = true;
      }
    }
    if (needsSave) {
      await saveProjects();
    }
  }

  Future<void> _migrateProjectsFromOldLocation(LocalFile newFile) async {
    try {
      // 检查旧位置的配置文件
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final oldFile = LocalFile.create('${documentsDirectory.path}/projects.json');
      
      print('检查旧项目配置文件: ${oldFile.getPath()}');
      print('旧项目配置文件是否存在: ${await oldFile.isFile()}');
      
      if (await oldFile.isFile()) {
        print('发现旧项目配置文件，开始迁移...');
        
        // 从旧位置加载配置
        await _loadProjectsFromFile(oldFile);
        print('已从旧位置加载项目配置');
        
        // 保存到新位置
        await _saveProjectsToFile(newFile);
        print('已保存项目配置到新位置');
        
        // 删除旧文件
        final oldFilePath = oldFile.getPath();
        await File(oldFilePath).delete();
        print('已删除旧项目配置文件');
        
        Get.snackbar('迁移成功', '项目配置文件已迁移到应用专用目录');
        print('项目配置文件迁移完成');
      } else {
        print('未找到旧项目配置文件，创建默认配置');
        // 没有旧配置文件，创建示例配置
        _createSampleData();
      }
    } catch (e) {
      print('迁移项目配置文件时出错: $e');
      // 迁移过程中出错，使用示例配置
      _createSampleData();
    }
  }

  Future<void> _saveProjectsToFile(LocalFile file) async {
    final jsonList = projects.map((project) => project.toJson()).toList();
    final content = json.encode(jsonList);
    final filePath = file.getPath();
    await File(filePath).writeAsString(content);
  }

  Future<void> saveProjects() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final configDir = Directory('${directory.path}/config');
      if (!await configDir.exists()) {
        await configDir.create(recursive: true);
      }
      
      final file = LocalFile.create('${configDir.path}/projects.json');
      await _saveProjectsToFile(file);
    } catch (e) {
      Get.snackbar('错误', '保存项目失败: $e');
    }
  }

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

  void selectProject(Project project) {
    selectedProject.value = project;
  }

  void _populateDefaultExtensions(Project project) {
    project.targetExt = XmlMerger.targetExt
        .map((ext) => TargetExtension(ext: ext, enabled: true))
        .toList();
    project.targetExt?.sort((a, b) => a.ext.compareTo(b.ext));
  }

  Future<void> createProject(String name) async {
    final newProject = Project(
      name: name,
      outputPath: '',
      sortOrder: projects.length,
      createTime: DateTime.now(),
      updateTime: DateTime.now(),
      items: [],
    );

    _populateDefaultExtensions(newProject);

    projects.add(newProject);
    await saveProjects();
    selectProject(newProject);

    Get.snackbar('成功', '项目 "$name" 创建成功');
  }

  Future<void> deleteProject(Project project) async {
    projects.remove(project);
    
    for (int i = 0; i < projects.length; i++) {
      projects[i].sortOrder = i;
    }
    
    if (selectedProject.value == project) {
      selectedProject.value = null;
    }
    
    await saveProjects();
    Get.snackbar('成功', '项目已删除');
  }

  Future<void> moveProjectUp(Project project) async {
    final index = projects.indexOf(project);
    if (index > 0) {
      projects.removeAt(index);
      projects.insert(index - 1, project);
      
      for (int i = 0; i < projects.length; i++) {
        projects[i].sortOrder = i;
      }
      
      await saveProjects();
    }
  }

  Future<void> moveProjectDown(Project project) async {
    final index = projects.indexOf(project);
    if (index < projects.length - 1) {
      projects.removeAt(index);
      projects.insert(index + 1, project);
      
      for (int i = 0; i < projects.length; i++) {
        projects[i].sortOrder = i;
      }
      
      await saveProjects();
    }
  }

  Future<void> updateProjectOutputPath(String outputPath) async {
    if (selectedProject.value != null) {
      selectedProject.value!.outputPath = outputPath;
      selectedProject.value!.updateTime = DateTime.now();
      await saveProjects();
    }
  }
}