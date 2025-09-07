import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import '../entity/entity.dart';
import '../explorer/uni_file.dart';
import '../explorer/sftp_explorer.dart';
import 'project_data_controller.dart';
import 'project_item_controller.dart';
import 'project_extension_controller.dart';
import 'project_generation_controller.dart';
import 'sftp_controller.dart';

class ProjectController extends GetxController {
  final RxString filterText = ''.obs;
  final RxString outputPath = ''.obs;
  
  // 子控制器
  late final ProjectDataController _dataController;
  late final ProjectItemController _itemController;
  late final ProjectExtensionController _extensionController;
  late final ProjectGenerationController _generationController;
  late final SftpController _sftpController;

  // 初始化子控制器
  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
  }
  
  void _initializeControllers() {
    _dataController = Get.put(ProjectDataController(), tag: 'projectData');
    _itemController = Get.put(ProjectItemController(), tag: 'projectItem');
    _extensionController = Get.put(ProjectExtensionController(), tag: 'projectExtension');
    _generationController = Get.put(ProjectGenerationController(), tag: 'projectGeneration');
    _sftpController = Get.put(SftpController(), tag: 'sftp');
    
    // 监听选中项目变化，更新相关状态
    ever(_dataController.selectedProject, (project) {
      if (project != null) {
        outputPath.value = project.outputPath ?? '';
        _itemController.loadProjectItems();
      } else {
        outputPath.value = '';
      }
    });
  }

  // 过滤后的项目列表
  List<Project> get filteredProjects {
    List<Project> result;
    if (filterText.value.isEmpty) {
      result = _dataController.projects.toList();
    } else {
      result = _dataController.projects.where((project) => 
        project.name?.toLowerCase().contains(filterText.value.toLowerCase()) ?? false
      ).toList();
    }
    result.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    return result;
  }

  // 委托属性
  RxList<Project> get projects => _dataController.projects;
  Rx<Project?> get selectedProject => _dataController.selectedProject;
  RxList<ProjectItem> get currentItems => _itemController.currentItems;
  Rx<ProjectItem?> get selectedItem => _itemController.selectedItem;
  RxString get lastGenerateLog => _generationController.lastGenerateLog;
  RxBool get isGenerating => _generationController.isGenerating;
  Rx<GenerateStatus?> get lastGenerateStatus => _generationController.lastGenerateStatus;
  RxList<SftpFileRoot> get sftpRoots => _sftpController.sftpRoots;
  Rx<SftpFileRoot?> get selectedSftpRoot => _sftpController.selectedSftpRoot;

  // 委托方法 - 项目数据管理
  void selectProject(Project project) => _dataController.selectProject(project);
  Future<void> createProject(String name) => _dataController.createProject(name);
  Future<void> deleteProject(Project project) => _dataController.deleteProject(project);
  Future<void> moveProjectUp(Project project) => _dataController.moveProjectUp(project);
  Future<void> moveProjectDown(Project project) => _dataController.moveProjectDown(project);

  // 选择输出路径
  Future<void> selectOutputPath() async {
    if (selectedProject.value == null) return;
    
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    
    if (selectedDirectory != null) {
      await _dataController.updateProjectOutputPath(selectedDirectory);
      outputPath.value = selectedDirectory;
    }
  }

  // 委托方法 - 项目项管理
  Future<void> addDirectoriesToProject() => _itemController.addDirectoriesToProject();

  Future<void> addFilesToProject() => _itemController.addFilesToProject();

  void selectItem(ProjectItem item) => _itemController.selectItem(item);

  Future<void> toggleItemEnabled(ProjectItem item) => _itemController.toggleItemEnabled(item);

  Future<void> toggleItemExclude(ProjectItem item) => _itemController.toggleItemExclude(item);

  Future<void> deleteItem(ProjectItem item) => _itemController.deleteItem(item);

  Future<void> moveItemUp(ProjectItem item) => _itemController.moveItemUp(item);

  Future<void> moveItemDown(ProjectItem item) => _itemController.moveItemDown(item);

  void setFilterText(String text) {
    filterText.value = text;
  }

  int get enabledItemsCount => _itemController.enabledItemsCount;

  Future<void> handleDroppedFiles(List<XFile> files) => _itemController.handleDroppedFiles(files);

  Future<void> handleProjectDropAndCreate(List<XFile> files) async {
    if (files.isEmpty) return;

    final droppedFile = files.first;
    final filePath = droppedFile.path;
    final uniFile = LocalFile.create(filePath);
    
    if (!await uniFile.isDir()) {
      Get.snackbar('创建失败', '请拖拽一个文件夹以快速创建项目。');
      return;
    }

    final projectName = filePath.split(RegExp(r'[/\\]')).last;
    final isDuplicate = projects.any((p) => p.name == projectName);
    if (isDuplicate) {
      Get.snackbar('创建失败', '名为 "$projectName" 的项目已存在。');
      return;
    }

    // Create the project first
    await _dataController.createProject(projectName);
    
    // Add the folder as an item by creating a ProjectItem manually
    if (selectedProject.value != null) {
      final newItem = ProjectItem(
        name: projectName,
        path: filePath,
        enabled: true,
        sortOrder: 0,
        isExclude: false,
      );
      _itemController.currentItems.add(newItem);
      selectedProject.value!.items = [newItem];
      selectedProject.value!.updateTime = DateTime.now();
      await _dataController.saveProjects();
    }
    
    Get.snackbar('成功', '项目 "$projectName" 已通过拖拽快速创建。');
  }

  Future<void> addItemFromFileStatus(FileStatusInfo fileStatus) => _itemController.addItemFromFileStatus(fileStatus);

  // 委托方法 - 文件生成
  Future<void> generateProject([Project? targetProject]) => _generationController.generateProject(targetProject);


  // 委托方法 - SFTP 管理
  void selectSftpRoot(SftpFileRoot? root) => _sftpController.selectSftpRoot(root);
  Future<void> createSftpRoot(String name, String host, int port, String user, String password, String path) => 
      _sftpController.createSftpRoot(name, host, port, user, password, path);
  Future<void> deleteSftpRoot(SftpFileRoot root) => _sftpController.deleteSftpRoot(root);
  Future<void> updateSftpRoot(SftpFileRoot root, String name, String host, int port, String user, String password, String path) => 
      _sftpController.updateSftpRoot(root, name, host, port, user, password, path);
  Future<void> toggleSftpRootEnabled(SftpFileRoot root) => _sftpController.toggleSftpRootEnabled(root);

  // 委托方法 - 扩展管理
  void openExtensionSettings() => _extensionController.openExtensionSettings();
  Future<void> toggleExtension(TargetExtension ext) => _extensionController.toggleExtension(ext);
  Future<void> addExtension(String newExt) => _extensionController.addExtension(newExt);
  Future<void> deleteExtension(TargetExtension ext) => _extensionController.deleteExtension(ext);
  Future<void> resetExtensionsToDefault() => _extensionController.resetExtensionsToDefault();

  // SFTP文件处理方法
  Future<void> handleSftpProjectDropAndCreate(List<SftpFileInfo> sftpFiles) async {
    if (sftpFiles.isEmpty) return;

    final selectedSftpFile = sftpFiles.first;
    final uniFile = selectedSftpFile.file;
    
    if (!selectedSftpFile.isDirectory) {
      Get.snackbar('创建失败', '请选择一个文件夹以快速创建项目。');
      return;
    }

    final projectName = uniFile.getName();
    final isDuplicate = projects.any((p) => p.name == projectName);
    if (isDuplicate) {
      Get.snackbar('创建失败', '名为 "$projectName" 的项目已存在。');
      return;
    }

    // Create the project first
    await _dataController.createProject(projectName);
    
    // Add the SFTP folder as an item
    if (selectedProject.value != null && uniFile is SftpFile) {
      final newItem = ProjectItem(
        name: projectName,
        path: uniFile.getPath(),
        enabled: true,
        sortOrder: 0,
        isExclude: false,
        fileType: ProjectFileType.sftp,
        sftpHost: uniFile.host,
        sftpPort: uniFile.port,
        sftpUser: uniFile.user,
        sftpPassword: uniFile.password,
      );
      _itemController.currentItems.add(newItem);
      selectedProject.value!.items = [newItem];
      selectedProject.value!.updateTime = DateTime.now();
      await _dataController.saveProjects();
    }
    
    Get.snackbar('成功', '项目 "$projectName" 已通过SFTP文件快速创建。');
  }

  Future<void> handleSftpDroppedFiles(List<SftpFileInfo> sftpFiles) async {
    if (selectedProject.value == null) {
      Get.snackbar('提示', '请先选择一个项目');
      return;
    }

    if (sftpFiles.isEmpty) return;

    int addedCount = 0;

    for (var sftpFileInfo in sftpFiles) {
      final uniFile = sftpFileInfo.file;
      final filePath = uniFile.getPath();
      final fileName = uniFile.getName();

      final exists = _itemController.currentItems.any((item) => item.path == filePath);
      if (!exists && uniFile is SftpFile) {
        final newItem = ProjectItem(
          name: fileName,
          path: filePath,
          enabled: true,
          sortOrder: _itemController.currentItems.length + addedCount,
          isExclude: false,
          fileType: ProjectFileType.sftp,
          sftpHost: uniFile.host,
          sftpPort: uniFile.port,
          sftpUser: uniFile.user,
          sftpPassword: uniFile.password,
        );

        _itemController.currentItems.add(newItem);
        addedCount++;
      }
    }

    if (addedCount > 0) {
      selectedProject.value!.items = _itemController.currentItems.toList();
      selectedProject.value!.updateTime = DateTime.now();
      await _dataController.saveProjects();

      Get.snackbar('成功', '已添加 $addedCount 个SFTP项目 (文件/目录)', duration: const Duration(seconds: 4));
    } else {
      Get.snackbar('提示', '所选项目均已存在');
    }
  }
}