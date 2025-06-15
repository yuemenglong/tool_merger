import 'dart:io';
import 'package:get/get.dart';

class FileExplorerUtils {
  /// 在文件资源管理器中打开并选中指定路径的文件或目录
  /// [path] 文件或目录的完整路径
  static Future<void> openInExplorer(String? path) async {
    if (path == null || path.isEmpty) {
      Get.snackbar('错误', '项目路径无效', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final uri = Uri.file(path);
    // 检查路径是否存在
    final pathExists = await FileSystemEntity.type(path) != FileSystemEntityType.notFound;
    if (!pathExists) {
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
        final parentDir = File(path).parent.path;
        await Process.run('xdg-open', [parentDir]);
      }
    } catch (e) {
      Get.snackbar('操作失败', '无法在资源管理器中打开路径: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }
}