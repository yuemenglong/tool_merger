import '../entity/entity.dart';
import '../explorer/uni_file.dart';

class XmlMerger {
  // 代码文件扩展名（与 C++ 版本保持一致）
  // 公开默认后缀集合
  static const Set<String> targetExt = {
    '.c',
    '.cpp',
    '.h',
    '.hpp',
    '.cc',
    '.cxx',
    '.hxx',
    '.java',
    '.py',
    '.js',
    '.ts',
    '.go',
    '.dart',
    '.kt',
    '.kts',
    '.cs',
    '.gradle',
    '.properties',
    '.yml',
    '.yaml',
    '.mdc',
    '.rs',
    ".sh",
    ".cnf",
    '.proto',
    ".md"
  };

  // 特殊文件模式（与 C++ 版本保持一致）
  static const List<String> _specialFilePatterns = ['cmakelists.txt', 'readme.txt', "Dockerfile"];

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
  static const List<String> _antiIgnorePatterns = ['.cursor'];

  /// 检查文件是否为代码文件（通过扩展名和启用的后缀集合）
  static bool isCodeFile(String filePath, Set<String> enabledExtensions) {
    final extension = _getFileExtension(filePath).toLowerCase();
    return enabledExtensions.contains(extension);
  }

  /// 检查文件是否为特殊文件（如 README, CMakeLists 等）
  static bool isSpecialFile(String fileName) {
    final lowerName = fileName.toLowerCase();
    return _specialFilePatterns.any((pattern) => lowerName == pattern.toLowerCase());
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
  static bool shouldIncludeFile(String filePath, Set<String> enabledExtensions) {
    if (shouldIgnorePath(filePath)) {
      return false;
    }

    final fileName = _getFileName(filePath);
    return isCodeFile(filePath, enabledExtensions) || isSpecialFile(fileName);
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

    final enabledItems = project.items!.where((item) => item.enabled == true && (item.isExclude ?? false) == false).toList();
    if (enabledItems.isEmpty) {
      throw Exception('没有启用的包含项目');
    }

    // 从 project.targetExt 提取启用的后缀
    final enabledExtensions = project.targetExt
            ?.where((ext) => ext.enabled)
            .map((ext) => ext.ext.toLowerCase())
            .toSet() ??
        {};

    return await _generateXmlContent(project, enabledItems, logCallback, enabledExtensions);
  }

  /// 生成 XML 内容（处理目录列表）
  static Future<MergeResult> _generateXmlContent(
      Project project,
      List<ProjectItem> enabledItems,
      Function(String)? logCallback,
      Set<String> enabledExtensions) async {
    final buffer = StringBuffer();

    // XML 头部
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<project name="${_escapeXmlAttribute(project.name ?? '')}" output_path="${_escapeXmlAttribute(project.outputPath ?? '')}">');

    final stats = _MergeStats();
    final mergedFilePaths = <String>[];

    // **新增**: 创建一个包含所有项目路径到项目对象的映射
    final allItemsMap = <String, ProjectItem>{
      for (var item in project.items ?? [])
        if (item.path != null) item.path!: item,
    };

    void log(String message) {
      print(message);
      logCallback?.call(message);
    }

    // 主循环处理启用的根项目
    for (final item in enabledItems) {
      try {
        final itemPath = item.path ?? '';

        // isExclude 已在 Controller 中过滤，这里无需再检查

        final itemFile = _createUniFileFromProjectItem(item);

        if (await itemFile.isFile()) {
          // 处理单个文件（无视过滤规则，必然引入）
          log('处理文件: ${item.name} (${itemPath})');

          final contentBytes = await itemFile.read();
          String content = String.fromCharCodes(contentBytes);

          // 检查文件是否为空
          if (content.isEmpty && await itemFile.getSize() > 0) {
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
        } else if (await itemFile.isDir()) {
          // 处理目录
          log('检查目录: ${item.name} (${itemPath})');

          // 检查目录是否只包含空文件夹
          final isOnlyEmptyFolders = await _isDirectoryOnlyEmptyFolders(itemFile, allItemsMap, enabledExtensions);
          if (isOnlyEmptyFolders) {
            log('跳过空目录: ${item.name} (只包含空文件夹)');
            stats.skippedDirs++;
            continue;
          }

          log('处理目录: ${item.name} (${itemPath})');

          // 为每个根目录创建一个 <dir> 元素
          buffer.writeln('  <dir name="${_escapeXmlAttribute(item.name ?? '')}">');

          // **修改**: 调用递归函数时传入 allItemsMap 和 enabledExtensions
          await _processDirectoryRecursive(
            itemFile,
            buffer,
            2,
            // 缩进级别
            stats,
            log,
            allItemsMap,
            mergedFilePaths,
            enabledExtensions,
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
    return input.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&apos;');
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
    UniFile dir,
    Map<String, ProjectItem> allItemsMap,
    Set<String> enabledExtensions,
  ) async {
    try {
      final entities = await dir.list();
      for (final entity in entities) {
        final entityPath = entity.getPath();

        // 检查此路径是否是一个显式的 ProjectItem
        final explicitItem = allItemsMap[entityPath];
        if (explicitItem != null) {
          // 如果一个路径在 items 列表中有显式条目，跳过它
          continue;
        }

        // 跳过应该被忽略的路径
        if (shouldIgnorePath(entityPath)) {
          continue;
        }

        if (await entity.isFile()) {
          // 如果找到任何文件，检查是否为代码文件或特殊文件
          final fileName = _getFileName(entity.getPath());
          if (isCodeFile(entity.getPath(), enabledExtensions) || isSpecialFile(fileName)) {
            return false; // 找到了有效文件，不是空文件夹
          }
        } else if (await entity.isDir()) {
          // 递归检查子目录
          final hasValidContent = await _isDirectoryOnlyEmptyFolders(entity, allItemsMap, enabledExtensions);
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
    UniFile currentDir,
    StringBuffer buffer,
    int indentLevel,
    _MergeStats stats,
    Function(String) log,
    Map<String, ProjectItem> allItemsMap,
    List<String> mergedFilePaths,
    Set<String> enabledExtensions,
  ) async {
    final List<UniFile> subdirs = [];
    final List<UniFile> files = [];

    try {
      // 遍历目录中的所有条目
      final entities = await currentDir.list();
      for (final entity in entities) {
        final entityPath = entity.getPath();

        // **核心修改**: 检查此路径是否是一个显式的 ProjectItem
        final explicitItem = allItemsMap[entityPath];
        if (explicitItem != null) {
          // 如果一个路径在 items 列表中有显式条目，
          // 那么在递归扫描其父目录时就跳过它。
          // 它将由 _generateXmlContent 的主循环根据其自身的 enabled 和 isExclude 状态决定如何处理。
          if (explicitItem.isExclude ?? false) {
            log('${_indent(indentLevel)}跳过显式排除的项: ${_getFileName(entityPath)}');
            if (await entity.isDir())
              stats.skippedDirs++;
            else
              stats.skippedFilesIgnored++;
          } else {
            log('${_indent(indentLevel)}跳过显式定义的项: ${_getFileName(entityPath)} (将由主循环独立处理)');
          }
          continue;
        }

        // 如果不是显式条目，则走通用规则
        if (shouldIgnorePath(entityPath)) {
          if (await entity.isDir()) {
            stats.skippedDirs++;
            log('${_indent(indentLevel)}跳过忽略目录: ${_getFileName(entityPath)}');
          } else {
            stats.skippedFilesIgnored++;
            log('${_indent(indentLevel)}跳过忽略文件: ${_getFileName(entityPath)}');
          }
          continue;
        }

        // 分类条目（目录或文件）
        if (await entity.isDir()) {
          subdirs.add(entity);
        } else if (await entity.isFile()) {
          files.add(entity);
        } else {
          stats.skippedFilesIgnored++;
          log('${_indent(indentLevel)}跳过非目录/常规文件: ${_getFileName(entityPath)}');
        }
      }
    } catch (e) {
      log('错误: 迭代目录时发生异常 ${currentDir.getPath()}: $e');
      return;
    }

    // 按文件名排序（与 C++ 版本保持一致）
    subdirs.sort((a, b) => _getFileName(a.getPath()).compareTo(_getFileName(b.getPath())));
    files.sort((a, b) => _getFileName(a.getPath()).compareTo(_getFileName(b.getPath())));

    // 先处理子目录
    for (final subdir in subdirs) {
      final dirName = _getFileName(subdir.getPath());

      // 检查目录是否只包含空文件夹
      final isOnlyEmptyFolders = await _isDirectoryOnlyEmptyFolders(subdir, allItemsMap, enabledExtensions);
      if (isOnlyEmptyFolders) {
        log('${_indent(indentLevel)}跳过空目录: $dirName (只包含空文件夹)');
        stats.skippedDirs++;
        continue;
      }

      log('${_indent(indentLevel)}处理目录: $dirName');
      buffer.writeln('${_indent(indentLevel)}<dir name="${_escapeXmlAttribute(dirName)}">');

      // **修改**: 递归调用时继续传递 allItemsMap
      await _processDirectoryRecursive(
        subdir,
        buffer,
        indentLevel + 1,
        stats,
        log,
        allItemsMap,
        mergedFilePaths,
        enabledExtensions,
      );

      buffer.writeln('${_indent(indentLevel)}</dir>');
    }

    // 再处理文件
    for (final file in files) {
      final fileName = _getFileName(file.getPath());

      // 检查是否为代码文件或特殊文件（与 C++ 版本逻辑一致）
      if (isCodeFile(file.getPath(), enabledExtensions) || isSpecialFile(fileName)) {
        log('${_indent(indentLevel)}处理文件: $fileName');

        try {
          final contentBytes = await file.read();
          String content = String.fromCharCodes(contentBytes);

          // 检查文件是否为空
          if (content.isEmpty && await file.getSize() > 0) {
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
          mergedFilePaths.add(file.getPath());
        } catch (e) {
          log('错误: 读取文件失败 ${file.getPath()}: $e');
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

  /// 根据ProjectItem的类型创建相应的UniFile实例
  static UniFile _createUniFileFromProjectItem(ProjectItem item) {
    final itemPath = item.path ?? '';
    
    if (item.fileType == ProjectFileType.sftp) {
      // 创建SFTP文件
      return SftpFile.create(
        item.sftpHost ?? '',
        item.sftpPort ?? 22,
        item.sftpUser ?? '',
        item.sftpPassword ?? '',
        itemPath,
      );
    } else {
      // 默认创建本地文件
      return LocalFile.create(itemPath);
    }
  }
}

/// 合并统计信息类
class _MergeStats {
  int mergedFiles = 0;
  int skippedFilesNonCode = 0;
  int skippedFilesIgnored = 0;
  int skippedDirs = 0;
}
