import 'dart:io';
import '../explorer/uni_file.dart';

class PathUtils {
  /// 计算文件路径列表的公共父目录
  static String? findCommonParentPath(List<String> paths) {
    if (paths.isEmpty) return null;
    if (paths.length == 1) {
      final file = LocalFile.create(paths.first);
      final parent = file.getParent();
      return parent?.getPath();
    }

    // 将所有路径分割成组件
    final pathComponents = paths.map((path) {
      return path.replaceAll('\\', '/').split('/').where((c) => c.isNotEmpty).toList();
    }).toList();

    if (pathComponents.isEmpty) return null;

    // 找到最短路径的长度
    final minLength = pathComponents.map((components) => components.length).reduce((a, b) => a < b ? a : b);
    
    // 找到公共前缀
    final commonComponents = <String>[];
    for (int i = 0; i < minLength; i++) {
      final component = pathComponents.first[i];
      bool isCommon = true;
      
      for (final components in pathComponents) {
        if (components[i] != component) {
          isCommon = false;
          break;
        }
      }
      
      if (isCommon) {
        commonComponents.add(component);
      } else {
        break;
      }
    }

    if (commonComponents.isEmpty) return null;
    
    // 重新构建路径
    if (Platform.isWindows && commonComponents.isNotEmpty) {
      // Windows路径处理
      return commonComponents.join('\\');
    } else {
      return '/' + commonComponents.join('/');
    }
  }

  /// 获取相对于公共父目录的显示路径
  static String getDisplayPath(String fullPath, String? commonParent) {
    if (commonParent == null || commonParent.isEmpty) {
      // 如果没有公共父目录，返回文件名
      return fullPath.split(Platform.isWindows ? '\\' : '/').last;
    }

    // 标准化路径分隔符
    final normalizedFullPath = fullPath.replaceAll('\\', '/');
    final normalizedCommonParent = commonParent.replaceAll('\\', '/');

    if (normalizedFullPath.startsWith(normalizedCommonParent)) {
      String relativePath = normalizedFullPath.substring(normalizedCommonParent.length);
      if (relativePath.startsWith('/')) {
        relativePath = relativePath.substring(1);
      }
      return relativePath.isEmpty ? fullPath.split(Platform.isWindows ? '\\' : '/').last : relativePath;
    }

    // 如果不是子路径，返回文件名
    return fullPath.split(Platform.isWindows ? '\\' : '/').last;
  }
} 