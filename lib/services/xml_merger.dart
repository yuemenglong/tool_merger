import 'dart:convert';
import 'dart:io';
import '../entity/entity.dart';

class XmlMerger {
  // 代码文件扩展名（与 C++ 版本保持一致）
  static const Set<String> _codeExtensions = {
    '.c', '.cpp', '.h', '.hpp', '.cc', '.cxx', '.hxx', '.java',
    '.py', '.js', '.ts', '.go', '.dart', '.kt', '.kts', '.cs',
    '.gradle', '.properties', '.yml', '.yaml', '.mdc', '.rs'
  };

  // 特殊文件模式（与 C++ 版本保持一致）
  static const List<String> _specialFilePatterns = [
    'cmakelists.txt',
    'readme.md',
    'readme.txt'
  ];

  // 忽略的路径模式（与 C++ 版本保持一致）
  static const List<String> _ignorePatterns = [
    'venv',
    'node_modules',
    '__pycache__',
    'build',
    'dist',
    'bin',
    'obj',
    'target',
    'cmake-build-debug',
    'cmake-build-release',
    'json.hpp'
  ];

  // 反忽略模式（与 C++ 版本保持一致）
  static const List<String> _antiIgnorePatterns = [
    '.cursor'
  ];
  /// 检查文件是否为代码文件（通过扩展名）
  static bool isCodeFile(String filePath) {
    final extension = _getFileExtension(filePath).toLowerCase();
    return _codeExtensions.contains(extension);
  }

  /// 检查文件是否为特殊文件（如 README, CMakeLists 等）
  static bool isSpecialFile(String fileName) {
    final lowerName = fileName.toLowerCase();
    return _specialFilePatterns.any((pattern) => lowerName == pattern);
  }

  /// 检查路径是否应该被忽略
  static bool shouldIgnorePath(String filePath) {
    final pathParts = filePath.split(RegExp(r'[/\\]'));
    
    for (final part in pathParts) {
      if (part.isEmpty || part == '.' || part == '..') continue;
      
      // 检查反忽略模式（优先级更高）
      for (final antiPattern in _antiIgnorePatterns) {
        if (part == antiPattern) {
          return false; // 不忽略
        }
      }
      
      // 检查忽略模式
      for (final pattern in _ignorePatterns) {
        if (part == pattern) {
          return true; // 忽略
        }
      }
      
      // 忽略以点开头的文件/目录（除了反忽略列表中的）
      if (part.startsWith('.') && !_antiIgnorePatterns.contains(part)) {
        return true;
      }
    }
    
    return false;
  }

  /// 检查文件是否应该被包含（代码文件或特殊文件，且不在忽略列表中）
  static bool shouldIncludeFile(String filePath) {
    if (shouldIgnorePath(filePath)) {
      return false;
    }
    
    final fileName = _getFileName(filePath);
    final extension = _getFileExtension(filePath);
    
    return isCodeFile(filePath) || isSpecialFile(fileName);
  }

  /// 获取文件扩展名
  static String _getFileExtension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot == -1 || lastDot == filePath.length - 1) {
      return '';
    }
    return filePath.substring(lastDot);
  }

  /// 获取文件名（不含路径）
  static String _getFileName(String filePath) {
    final lastSlash = filePath.lastIndexOf(RegExp(r'[/\\]'));
    if (lastSlash == -1) {
      return filePath;
    }
    return filePath.substring(lastSlash + 1);
  }

  /// 将项目合并为 XML 字符串
  /// 
  /// [project] 要合并的项目，其中 items 应该是目录路径列表
  /// [logCallback] 可选的日志回调函数，用于接收处理过程中的日志信息
  /// 返回包含XML内容和合并文件列表的MergeResult对象
  static Future<MergeResult> mergeXml(Project project, {Function(String)? logCallback}) async {
    if (project.items == null || project.items!.isEmpty) {
      throw Exception('项目中没有目录');
    }

    final enabledItems = project.items!.where((item) => item.enabled == true).toList();
    if (enabledItems.isEmpty) {
      throw Exception('没有启用的目录');
    }

    return await _generateXmlContent(project, enabledItems, logCallback);
  }

  /// 生成 XML 内容（处理目录列表）
  static Future<MergeResult> _generateXmlContent(Project project, List<ProjectItem> enabledItems, Function(String)? logCallback) async {
    final buffer = StringBuffer();
    
    // XML 头部
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<project name="${_escapeXmlAttribute(project.name ?? '')}" output_path="${_escapeXmlAttribute(project.outputPath ?? '')}">');
    
    // 使用对象来包装统计变量，以便在递归中正确传递引用
    final stats = _MergeStats();
    
    // 跟踪实际合并的文件路径
    final mergedFilePaths = <String>[];
    
    // 创建排除路径集合
    final excludePaths = <String>{};
    // 只从“已启用”的项中构建排除列表
    for (final item in enabledItems) {
      if (item.isExclude == true && item.path != null) {
        excludePaths.add(item.path!);
      }
    }
    
    // 创建日志函数
    void log(String message) {
      print(message);
      logCallback?.call(message);
    }
    
    // 处理每个启用的项目项（可能是目录或文件）
    for (final item in enabledItems) {
      try {
        final itemPath = item.path ?? '';
        
        // 检查是否被排除
        if (item.isExclude == true) {
          log('跳过排除项: ${item.name} (${itemPath})');
          stats.skippedFilesIgnored++;
          continue;
        }
        
        final itemFile = File(itemPath);
        final itemDirectory = Directory(itemPath);
        
        // 检查是文件还是目录
        if (await itemFile.exists()) {
          // 处理单个文件（无视过滤规则，必然引入）
          log('处理文件: ${item.name} (${itemPath})');
          
          String content;
          try {
            // 尝试以 UTF-8 读取
            content = await itemFile.readAsString(encoding: utf8);
          } catch (e) {
            // 如果 UTF-8 失败，尝试系统默认编码
            final bytes = await itemFile.readAsBytes();
            content = String.fromCharCodes(bytes);
          }

          // 检查文件是否为空
          if (content.isEmpty && await itemFile.length() > 0) {
            log('警告: 文件 \'${item.name}\' 读取内容为空或失败，跳过XML写入。');
            stats.skippedFilesIgnored++;
            continue;
          }

          buffer.writeln('  <file name="${_escapeXmlAttribute(item.name ?? '')}" path="${_escapeXmlAttribute(itemPath)}">');
          buffer.writeln('    <![CDATA[');

          // 处理内容
          if (content.isNotEmpty) {
            // 移除可能的 BOM
            if (content.startsWith('\uFEFF')) {
              content = content.substring(1);
            }

            // 转义 CDATA 内容
            content = _escapeCDataContent(content);

            // 按行处理内容，添加适当的缩进
            final lines = content.split('\n');
            for (int i = 0; i < lines.length; i++) {
              final line = lines[i];
              // 移除行尾的回车符
              final cleanLine = line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
              
              if (i == 0) {
                buffer.writeln(); // 在第一行前添加换行
              }
              buffer.write('      $cleanLine');
              if (i < lines.length - 1) {
                buffer.writeln();
              }
            }
            buffer.writeln(); // 在内容后添加换行
            buffer.write('    ');
          }

          buffer.writeln(']]>');
          buffer.writeln('  </file>');
          stats.mergedFiles++;
          mergedFilePaths.add(itemPath);
        } else if (await itemDirectory.exists()) {
          // 处理目录
          log('检查目录: ${item.name} (${itemPath})');
          
          // 检查目录是否只包含空文件夹
          final isOnlyEmptyFolders = await _isDirectoryOnlyEmptyFolders(itemDirectory, excludePaths);
          if (isOnlyEmptyFolders) {
            log('跳过空目录: ${item.name} (只包含空文件夹)');
            stats.skippedDirs++;
            continue;
          }
          
          log('处理目录: ${item.name} (${itemPath})');
          
          // 为每个根目录创建一个 <dir> 元素
          buffer.writeln('  <dir name="${_escapeXmlAttribute(item.name ?? '')}">');
          
          // 递归处理目录内容
          await _processDirectoryRecursive(
            itemDirectory,
            buffer,
            2, // 缩进级别 2（在 project > dir 内）
            stats,
            log,
            excludePaths,
            mergedFilePaths,
          );
          
          buffer.writeln('  </dir>');
        } else {
          log('警告: 路径不存在: ${itemPath}');
          stats.skippedFilesIgnored++;
        }
      } catch (e) {
        log('错误: 处理项目项失败 ${item.path}: $e');
        stats.skippedFilesIgnored++;
      }
    }
    
    buffer.writeln('</project>');
    
    log('生成完成: 合并文件 ${stats.mergedFiles} 个，跳过文件(非代码) ${stats.skippedFilesNonCode} 个，跳过文件(忽略) ${stats.skippedFilesIgnored} 个，跳过目录 ${stats.skippedDirs} 个');
    
    return MergeResult(
      xmlContent: buffer.toString(),
      mergedFilePaths: mergedFilePaths,
    );
  }

  /// XML 属性转义
  static String _escapeXmlAttribute(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// 检查内容是否包含 CDATA 结束标记，如果包含则需要特殊处理
  static String _escapeCDataContent(String content) {
    // 如果内容包含 ]]>，需要将其分割成多个 CDATA 段
    if (content.contains(']]>')) {
      final parts = content.split(']]>');
      final buffer = StringBuffer();
      for (int i = 0; i < parts.length; i++) {
        if (i > 0) {
          buffer.write(']]]]><![CDATA[>');
        }
        buffer.write(parts[i]);
      }
      return buffer.toString();
    }
    return content;
  }

  /// 检查目录是否只包含空文件夹（递归检查）
  static Future<bool> _isDirectoryOnlyEmptyFolders(
    Directory dir,
    Set<String> excludePaths,
  ) async {
    try {
      await for (final entity in dir.list()) {
        final entityPath = entity.path;

        // 跳过排除的路径
        if (excludePaths.contains(entityPath)) {
          continue;
        }

        // 跳过应该被忽略的路径
        if (shouldIgnorePath(entityPath)) {
          continue;
        }

        if (entity is File) {
          // 如果找到任何文件，检查是否为代码文件或特殊文件
          final fileName = _getFileName(entity.path);
          if (isCodeFile(entity.path) || isSpecialFile(fileName)) {
            return false; // 找到了有效文件，不是空文件夹
          }
        } else if (entity is Directory) {
          // 递归检查子目录
          final hasValidContent = await _isDirectoryOnlyEmptyFolders(entity, excludePaths);
          if (!hasValidContent) {
            return false; // 子目录包含有效内容
          }
        }
      }
      return true; // 只包含空文件夹或没有内容
    } catch (e) {
      // 如果检查失败，保守地认为目录不为空
      return false;
    }
  }

  /// 递归处理目录（与 C++ 版本的 processDirectoryRecursive 对应）
  static Future<void> _processDirectoryRecursive(
    Directory currentDir,
    StringBuffer buffer,
    int indentLevel,
    _MergeStats stats,
    Function(String) log,
    Set<String> excludePaths,
    List<String> mergedFilePaths,
  ) async {
    final List<Directory> subdirs = [];
    final List<File> files = [];

    try {
      // 遍历目录中的所有条目
      await for (final entity in currentDir.list()) {
        final entityPath = entity.path;

        // 检查是否在排除路径中
        if (excludePaths.contains(entityPath)) {
          if (entity is Directory) {
            stats.skippedDirs++;
            log('${_indent(indentLevel)}跳过排除目录: ${_getFileName(entityPath)}');
          } else {
            stats.skippedFilesIgnored++;
            log('${_indent(indentLevel)}跳过排除文件: ${_getFileName(entityPath)}');
          }
          continue;
        }

        // 检查路径是否应该被忽略
        if (shouldIgnorePath(entityPath)) {
          if (entity is Directory) {
            stats.skippedDirs++;
            log('${_indent(indentLevel)}跳过忽略目录: ${_getFileName(entityPath)}');
          } else {
            stats.skippedFilesIgnored++;
            log('${_indent(indentLevel)}跳过忽略文件: ${_getFileName(entityPath)}');
          }
          continue;
        }

        // 分类条目（目录或文件）
        if (entity is Directory) {
          subdirs.add(entity);
        } else if (entity is File) {
          files.add(entity);
        } else {
          stats.skippedFilesIgnored++;
          log('${_indent(indentLevel)}跳过非目录/常规文件: ${_getFileName(entityPath)}');
        }
      }
    } catch (e) {
      log('错误: 迭代目录时发生异常 ${currentDir.path}: $e');
      return;
    }

    // 按文件名排序（与 C++ 版本保持一致）
    subdirs.sort((a, b) => _getFileName(a.path).compareTo(_getFileName(b.path)));
    files.sort((a, b) => _getFileName(a.path).compareTo(_getFileName(b.path)));

    // 先处理子目录
    for (final subdir in subdirs) {
      final dirName = _getFileName(subdir.path);
      
      // 检查目录是否只包含空文件夹
      final isOnlyEmptyFolders = await _isDirectoryOnlyEmptyFolders(subdir, excludePaths);
      if (isOnlyEmptyFolders) {
        log('${_indent(indentLevel)}跳过空目录: $dirName (只包含空文件夹)');
        stats.skippedDirs++;
        continue;
      }
      
      log('${_indent(indentLevel)}处理目录: $dirName');
      buffer.writeln('${_indent(indentLevel)}<dir name="${_escapeXmlAttribute(dirName)}">');
      
      await _processDirectoryRecursive(
        subdir,
        buffer,
        indentLevel + 1,
        stats,
        log,
        excludePaths,
        mergedFilePaths,
      );
      
      buffer.writeln('${_indent(indentLevel)}</dir>');
    }

    // 再处理文件
    for (final file in files) {
      final fileName = _getFileName(file.path);
      final extension = _getFileExtension(file.path);

      // 检查是否为代码文件或特殊文件（与 C++ 版本逻辑一致）
      if (isCodeFile(file.path) || isSpecialFile(fileName)) {
        log('${_indent(indentLevel)}处理文件: $fileName');
        
        try {
          String content;
          try {
            // 尝试以 UTF-8 读取
            content = await file.readAsString(encoding: utf8);
          } catch (e) {
            // 如果 UTF-8 失败，尝试系统默认编码
            final bytes = await file.readAsBytes();
            content = String.fromCharCodes(bytes);
          }

          // 检查文件是否为空
          if (content.isEmpty && await file.length() > 0) {
            log('${_indent(indentLevel + 1)}警告: 文件 \'$fileName\' 读取内容为空或失败，跳过XML写入。');
            stats.skippedFilesIgnored++;
            continue;
          }

          buffer.writeln('${_indent(indentLevel)}<file name="${_escapeXmlAttribute(fileName)}">');
          buffer.writeln('${_indent(indentLevel + 1)}<![CDATA[');

          // 处理内容
          if (content.isNotEmpty) {
            // 移除可能的 BOM
            if (content.startsWith('\uFEFF')) {
              content = content.substring(1);
            }

            // 转义 CDATA 内容
            content = _escapeCDataContent(content);

            // 按行处理内容，添加适当的缩进
            final lines = content.split('\n');
            for (int i = 0; i < lines.length; i++) {
              final line = lines[i];
              // 移除行尾的回车符
              final cleanLine = line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
              
              if (i == 0) {
                buffer.writeln(); // 在第一行前添加换行
              }
              buffer.write('${_indent(indentLevel + 2)}$cleanLine');
              if (i < lines.length - 1) {
                buffer.writeln();
              }
            }
            buffer.writeln(); // 在内容后添加换行
            buffer.write(_indent(indentLevel + 1));
          }

          buffer.writeln(']]>');
          buffer.writeln('${_indent(indentLevel)}</file>');
          stats.mergedFiles++;
          mergedFilePaths.add(file.path);
        } catch (e) {
          log('错误: 读取文件失败 ${file.path}: $e');
          stats.skippedFilesIgnored++;
        }
      } else {
        log('${_indent(indentLevel)}跳过文件(非代码/特殊文件): $fileName');
        stats.skippedFilesNonCode++;
      }
    }
  }

  /// 生成缩进字符串
  static String _indent(int level) {
    return '  ' * level; // 每级缩进 2 个空格
  }
}

/// 合并统计信息类
class _MergeStats {
  int mergedFiles = 0;
  int skippedFilesNonCode = 0;
  int skippedFilesIgnored = 0;
  int skippedDirs = 0;
} 