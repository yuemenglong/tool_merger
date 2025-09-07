import 'dart:io';
import 'package:get/get.dart';
import '../explorer/uni_file.dart';
import '../entity/entity.dart';
import '../explorer/sftp_explorer_page.dart';
import '../controllers/project_controller.dart';

class FileExplorerUtils {
  /// 在文件资源管理器中打开并选中指定路径的文件或目录
  /// [path] 文件或目录的完整路径
  /// [projectItem] 项目项对象，用于SFTP类型的路径处理
  static Future<void> openInExplorer(String? path, {ProjectItem? projectItem}) async {
    if (path == null || path.isEmpty) {
      Get.snackbar('错误', '项目路径无效', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // 如果是SFTP类型的项目，使用SFTP浏览器打开
    if (projectItem != null && projectItem.fileType == ProjectFileType.sftp) {
      await _openSftpPath(projectItem);
      return;
    }

    // 检查本地路径是否存在
    final uniFile = LocalFile.create(path);
    final isFile = await uniFile.isFile();
    final isDir = await uniFile.isDir();
    if (!isFile && !isDir) {
      Get.snackbar('错误', '路径不存在: $path', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      if (Platform.isWindows) {
        // 在 Windows 上，使用 'explorer.exe /select,' 命令可以最高效地实现"打开并选中"
        await Process.run('explorer.exe', ['/select,', path]);
      } else if (Platform.isMacOS) {
        // 在 macOS 上，使用 'open -R'
        await Process.run('open', ['-R', path]);
      } else if (Platform.isLinux) {
        // 在 Linux 上，可能需要根据不同的文件管理器调整，这里使用一个通用尝试
        final parentDir = uniFile.getParent()?.getPath() ?? path;
        await Process.run('xdg-open', [parentDir]);
      }
    } catch (e) {
      Get.snackbar('操作失败', '无法在资源管理器中打开路径: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// 处理SFTP类型的路径打开
  static Future<void> _openSftpPath(ProjectItem projectItem) async {
    if (projectItem.sftpHost == null || 
        projectItem.sftpUser == null || 
        projectItem.path == null) {
      Get.snackbar('错误', 'SFTP连接信息不完整', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      // 尝试找到现有的匹配SftpFileRoot
      SftpFileRoot? existingSftpRoot;
      try {
        final controller = Get.find<ProjectController>();
        existingSftpRoot = controller.sftpRoots.firstWhereOrNull((root) =>
          root.host == projectItem.sftpHost &&
          root.port == (projectItem.sftpPort ?? 22) &&
          root.user == projectItem.sftpUser &&
          root.enabled == true
        );
      } catch (e) {
        // 如果找不到 ProjectController，继续使用临时对象
      }

      SftpFileRoot sftpRoot;
      if (existingSftpRoot != null) {
        // 使用现有的SftpFileRoot，但更新路径
        sftpRoot = SftpFileRoot(
          name: existingSftpRoot.name,
          host: existingSftpRoot.host,
          port: existingSftpRoot.port,
          user: existingSftpRoot.user,
          password: existingSftpRoot.password,
          path: projectItem.path, // 使用项目项的路径
          enabled: existingSftpRoot.enabled,
          createTime: existingSftpRoot.createTime,
          updateTime: existingSftpRoot.updateTime,
        );
      } else {
        // 创建临时的SftpFileRoot对象用于连接
        sftpRoot = SftpFileRoot(
          name: projectItem.name ?? 'SFTP连接',
          host: projectItem.sftpHost,
          port: projectItem.sftpPort ?? 22,
          user: projectItem.sftpUser,
          password: projectItem.sftpPassword ?? '',
          path: projectItem.path,
          enabled: true,
        );
      }

      // 导航到SFTP浏览器页面
      await Get.to(() => const SftpExplorerPage(), arguments: sftpRoot);
    } catch (e) {
      Get.snackbar('操作失败', '无法打开SFTP路径: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }
}