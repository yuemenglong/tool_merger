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
      final directory = await getApplicationDocumentsDirectory();
      final file = LocalFile.create('${directory.path}/projects.json');
      
      if (await file.isFile()) {
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
      } else {
        _createSampleData();
      }
    } catch (e) {
      Get.snackbar('错误', '加载项目失败: $e');
      _createSampleData();
    }
  }

  Future<void> saveProjects() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      final jsonList = projects.map((project) => project.toJson()).toList();
      final content = json.encode(jsonList);
      final outputFile = File('${directory.path}/projects.json');
      await outputFile.writeAsString(content);
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