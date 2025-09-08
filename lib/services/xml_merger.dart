import '../entity/entity.dart';
import '../explorer/uni_file.dart';

class XmlMerger {
  // 代码文件扩展名（与 C++ 版本保持一致）
  // 公开默认后缀集合
  static const Set<String> targetExt = {'.c', '.cpp', '.h', '.hpp', '.cc', '.cxx', '.hxx', '.java', '.py', '.js', '.jsx', '.ts', '.tsx', '.go', '.dart', '.kt', '.kts', '.cs', '.gradle', '.properties', '.yml', '.yaml', '.mdc', '.rs', ".sh", ".cnf", '.proto', ".md"};

  // 特殊文件模式（与 C++ 版本保持一致）
  static const List<String> _specialFilePatterns = ['cmakelists.txt', 'readme.txt', "Dockerfile"];

  // 忽略的路径模式（与 C++ 版本保持一致）
  static const List<String> _ignorePatterns = ['venv', 'node_modules', '__pycache__', 'build', 'dist', 'bin', 'obj', 'target', 'cmake-build-debug', 'cmake-build-release', 'json.hpp'];

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

  /// 收集合并任务 - 第一阶段：收集所有需要处理的文件/目录信息
  ///
  /// [project] 要处理的项目
  /// [logCallback] 可选的日志回调函数
  /// 返回包含所有任务的MergeTaskCollection对象
  static Future<MergeTaskCollection> collectMergeTasks(Project project, {Function(String)? logCallback}) async {
    if (project.items == null || project.items!.isEmpty) {
      throw Exception('项目中没有目录');
    }

    final enabledItems = project.items!.where((item) => item.enabled == true && (item.isExclude ?? false) == false).toList();
    if (enabledItems.isEmpty) {
      throw Exception('没有启用的包含项目');
    }

    // 从 project.targetExt 提取启用的后缀
    final enabledExtensions = project.targetExt?.where((ext) => ext.enabled).map((ext) => ext.ext.toLowerCase()).toSet() ?? {};

    final taskCollection = MergeTaskCollection();
    final allItemsMap = <String, ProjectItem>{
      for (var item in project.items ?? [])
        if (item.path != null) item.path!: item,
    };

    void log(String message) {
      print(message);
      logCallback?.call(message);
    }

    // 收集任务信息
    final List<Future<void>> directoryFutures = [];
    final List<Future<void>> fileFutures = [];
    
    for (final item in enabledItems) {
      try {
        final itemPath = item.path ?? '';
        final itemFile = _createUniFileFromProjectItem(item);

        if (await itemFile.isFile()) {
          // 添加文件读取任务到并行执行队列
          log('收集文件任务: ${item.name} (${itemPath})');
          fileFutures.add(_readFileTask(item, itemFile, taskCollection, log));
        } else if (await itemFile.isDir()) {
          log('收集目录任务: ${item.name} (${itemPath})');

          // 添加目录任务
          taskCollection.addTask(XmlWriteTask(
            name: item.name ?? '',
            path: itemPath,
            isDirectory: true,
            file: itemFile,
            indentLevel: 1, // 根级目录
          ));

          // 收集目录的递归任务用于并行执行
          directoryFutures.add(_collectDirectoryTasksRecursive(
            itemFile,
            2, // 子级缩进
            taskCollection,
            log,
            allItemsMap,
            enabledExtensions,
          ));
        } else {
          log('警告: 路径不存在: ${itemPath}');
          taskCollection.stats.skippedFilesIgnored++;
        }
      } catch (e) {
        log('错误: 处理项目项失败 ${item.path}: $e');
        taskCollection.stats.skippedFilesIgnored++;
      }
    }
    
    // 并行等待所有根级文件读取完成
    if (fileFutures.isNotEmpty) {
      await Future.wait(fileFutures);
    }
    
    // 并行等待所有目录的递归收集完成
    if (directoryFutures.isNotEmpty) {
      await Future.wait(directoryFutures);
    }

    log('任务收集完成: 收集到 ${taskCollection.tasks.length} 个处理任务');
    return taskCollection;
  }

  /// 执行合并任务 - 第二阶段：从任务集合生成XML内容
  ///
  /// [project] 项目信息
  /// [taskCollection] 任务集合
  /// [logCallback] 可选的日志回调函数
  /// 返回包含XML内容和合并文件列表的MergeResult对象
  static Future<MergeResult> executeMergeTasks(Project project, MergeTaskCollection taskCollection, {Function(String)? logCallback}) async {
    final buffer = StringBuffer();
    final mergedFilePaths = <String>[];

    void log(String message) {
      print(message);
      logCallback?.call(message);
    }

    // XML 头部
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<project name="${_escapeXmlAttribute(project.name ?? '')}" output_path="${_escapeXmlAttribute(project.outputPath ?? '')}">');

    log('开始执行 ${taskCollection.tasks.length} 个任务');

    // 分组任务：根级任务和子任务
    final List<XmlWriteTask> rootTasks = [];
    for (final task in taskCollection.tasks) {
      if (task.indentLevel == 1) {
        rootTasks.add(task);
      } else {
        // 这些是子任务，暂时不直接处理，会在处理父目录时处理
      }
    }

    // 处理根级任务
    for (final task in rootTasks) {
      await _executeTask(task, buffer, taskCollection.stats, log, mergedFilePaths, taskCollection.tasks);
    }

    buffer.writeln('</project>');

    log('执行完成: 合并文件 ${taskCollection.stats.mergedFiles} 个，跳过文件(非代码) ${taskCollection.stats.skippedFilesNonCode} 个，跳过文件(忽略) ${taskCollection.stats.skippedFilesIgnored} 个，跳过目录 ${taskCollection.stats.skippedDirs} 个');

    return MergeResult(
      xmlContent: buffer.toString(),
      mergedFilePaths: mergedFilePaths,
    );
  }

  /// 执行单个任务
  static Future<void> _executeTask(
    XmlWriteTask task,
    StringBuffer buffer,
    _MergeStats stats,
    Function(String) log,
    List<String> mergedFilePaths,
    List<XmlWriteTask> allTasks,
  ) async {
    if (task.isDirectory) {
      // 处理目录任务
      log('${_indent(task.indentLevel)}处理目录: ${task.name}');
      buffer.writeln('${_indent(task.indentLevel)}<dir name="${_escapeXmlAttribute(task.name)}">');

      // 查找并处理此目录下的子任务
      final childTasks = allTasks.where((childTask) => childTask.indentLevel == task.indentLevel + 1 && childTask.path.startsWith(task.path) && childTask.path != task.path).toList();

      // 按名称排序
      childTasks.sort((a, b) => a.name.compareTo(b.name));

      // 先处理子目录
      final childDirs = childTasks.where((child) => child.isDirectory).toList();
      for (final childDir in childDirs) {
        await _executeTask(childDir, buffer, stats, log, mergedFilePaths, allTasks);
      }

      // 再处理子文件
      final childFiles = childTasks.where((child) => !child.isDirectory).toList();
      for (final childFile in childFiles) {
        await _executeTask(childFile, buffer, stats, log, mergedFilePaths, allTasks);
      }

      buffer.writeln('${_indent(task.indentLevel)}</dir>');
    } else {
      // 处理文件任务
      await _executeFileTask(task, buffer, stats, log, mergedFilePaths);
    }
  }

  /// 执行文件任务
  static Future<void> _executeFileTask(
    XmlWriteTask task,
    StringBuffer buffer,
    _MergeStats stats,
    Function(String) log,
    List<String> mergedFilePaths,
  ) async {
    log('${_indent(task.indentLevel)}处理文件: ${task.name}');

    // 使用预读取的文件内容
    String content = task.content ?? '';
    
    // 检查文件内容是否为空（这个检查现在应该在collect阶段已经做过了，但保持兼容性）
    if (content.isEmpty) {
      log('${_indent(task.indentLevel + 1)}警告: 文件 \'${task.name}\' 内容为空，跳过XML写入。');
      stats.skippedFilesIgnored++;
      return;
    }

    if (task.indentLevel == 1) {
      // 根级文件，包含path属性
      buffer.writeln('  <file name="${_escapeXmlAttribute(task.name)}" path="${_escapeXmlAttribute(task.path)}">');
      buffer.writeln('    <![CDATA[');
    } else {
      // 子级文件，不包含path属性
      buffer.writeln('${_indent(task.indentLevel)}<file name="${_escapeXmlAttribute(task.name)}">');
      buffer.writeln('${_indent(task.indentLevel + 1)}<![CDATA[');
    }

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

        final indent = task.indentLevel == 1 ? '      ' : _indent(task.indentLevel + 2);
        buffer.write('$indent$cleanLine');
        if (i < lines.length - 1) {
          buffer.writeln();
        }
      }
      buffer.writeln(); // 在内容后添加换行

      final indent = task.indentLevel == 1 ? '    ' : _indent(task.indentLevel + 1);
      buffer.write(indent);
    }

    buffer.writeln(']]>');

    if (task.indentLevel == 1) {
      buffer.writeln('  </file>');
    } else {
      buffer.writeln('${_indent(task.indentLevel)}</file>');
    }

    stats.mergedFiles++;
    mergedFilePaths.add(task.path);
  }

  /// 将项目合并为 XML 字符串（便利方法，内部使用新的分离式流程）
  ///
  /// [project] 要合并的项目，其中 items 应该是目录路径列表
  /// [logCallback] 可选的日志回调函数，用于接收处理过程中的日志信息
  /// 返回包含XML内容和合并文件列表的MergeResult对象
  static Future<MergeResult> mergeXml(Project project, {Function(String)? logCallback}) async {
    // 使用新的分离式流程：先收集任务，再执行任务
    final taskCollection = await collectMergeTasks(project, logCallback: logCallback);
    return await executeMergeTasks(project, taskCollection, logCallback: logCallback);
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

  /// 递归收集目录任务
  static Future<void> _collectDirectoryTasksRecursive(
    UniFile currentDir,
    int indentLevel,
    MergeTaskCollection taskCollection,
    Function(String) log,
    Map<String, ProjectItem> allItemsMap,
    Set<String> enabledExtensions,
  ) async {
    final List<UniFile> subdirs = [];
    final List<UniFile> files = [];

    try {
      // 遍历目录中的所有条目
      final entities = await currentDir.list();
      for (final entity in entities) {
        final entityPath = entity.getPath();

        // 检查此路径是否是一个显式的 ProjectItem
        final explicitItem = allItemsMap[entityPath];
        if (explicitItem != null) {
          if (explicitItem.isExclude ?? false) {
            log('${_indent(indentLevel)}跳过显式排除的项: ${_getFileName(entityPath)}');
            if (await entity.isDir()) {
              taskCollection.stats.skippedDirs++;
            } else {
              taskCollection.stats.skippedFilesIgnored++;
            }
          } else {
            log('${_indent(indentLevel)}跳过显式定义的项: ${_getFileName(entityPath)} (将由主循环独立处理)');
          }
          continue;
        }

        // 如果不是显式条目，则走通用规则
        if (shouldIgnorePath(entityPath)) {
          if (await entity.isDir()) {
            taskCollection.stats.skippedDirs++;
            log('${_indent(indentLevel)}跳过忽略目录: ${_getFileName(entityPath)}');
          } else {
            taskCollection.stats.skippedFilesIgnored++;
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
          taskCollection.stats.skippedFilesIgnored++;
          log('${_indent(indentLevel)}跳过非目录/常规文件: ${_getFileName(entityPath)}');
        }
      }
    } catch (e) {
      log('错误: 迭代目录时发生异常 ${currentDir.getPath()}: $e');
      return;
    }

    // 按文件名排序
    subdirs.sort((a, b) => _getFileName(a.getPath()).compareTo(_getFileName(b.getPath())));
    files.sort((a, b) => _getFileName(a.getPath()).compareTo(_getFileName(b.getPath())));

    // 先收集子目录任务
    final List<Future<void>> futures = [];
    
    for (final subdir in subdirs) {
      final dirName = _getFileName(subdir.getPath());

      log('${_indent(indentLevel)}收集目录任务: $dirName');

      // 添加目录任务
      taskCollection.addTask(XmlWriteTask(
        name: dirName,
        path: subdir.getPath(),
        isDirectory: true,
        file: subdir,
        indentLevel: indentLevel,
      ));

      // 收集future用于并行执行
      futures.add(_collectDirectoryTasksRecursive(
        subdir,
        indentLevel + 1,
        taskCollection,
        log,
        allItemsMap,
        enabledExtensions,
      ));
    }
    
    // 并行等待所有子目录任务完成
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    // 并行收集文件任务
    final List<Future<void>> fileReadFutures = [];
    
    for (final file in files) {
      final fileName = _getFileName(file.getPath());

      // 检查是否为代码文件或特殊文件
      if (isCodeFile(file.getPath(), enabledExtensions) || isSpecialFile(fileName)) {
        log('${_indent(indentLevel)}收集文件任务: $fileName');
        // 添加文件读取任务到并行队列
        fileReadFutures.add(_readDirectoryFileTask(
          file,
          fileName,
          indentLevel,
          taskCollection,
          log,
        ));
      } else {
        log('${_indent(indentLevel)}跳过文件(非代码/特殊文件): $fileName');
        taskCollection.stats.skippedFilesNonCode++;
      }
    }
    
    // 并行等待所有文件读取完成
    if (fileReadFutures.isNotEmpty) {
      await Future.wait(fileReadFutures);
    }
  }

  /// 生成缩进字符串
  static String _indent(int level) {
    return '  ' * level; // 每级缩进 2 个空格
  }

  /// 并行读取根级文件任务
  static Future<void> _readFileTask(
    ProjectItem item,
    UniFile itemFile,
    MergeTaskCollection taskCollection,
    Function(String) log,
  ) async {
    final itemPath = item.path ?? '';
    
    try {
      // 预读取文件内容
      final contentBytes = await itemFile.read();
      final fileContent = String.fromCharCodes(contentBytes);
      
      // 检查文件是否为空
      if (fileContent.isEmpty && await itemFile.getSize() > 0) {
        log('警告: 文件 \'${item.name}\' 读取内容为空或失败，跳过。');
        taskCollection.stats.skippedFilesIgnored++;
        return;
      }
      
      taskCollection.addTask(XmlWriteTask(
        name: item.name ?? '',
        path: itemPath,
        isDirectory: false,
        file: itemFile,
        indentLevel: 1, // 根级文件
        content: fileContent,
      ));
    } catch (e) {
      log('错误: 读取文件失败 ${itemPath}: $e');
      taskCollection.stats.skippedFilesIgnored++;
    }
  }

  /// 并行读取目录中的文件任务
  static Future<void> _readDirectoryFileTask(
    UniFile file,
    String fileName,
    int indentLevel,
    MergeTaskCollection taskCollection,
    Function(String) log,
  ) async {
    try {
      // 预读取文件内容
      final contentBytes = await file.read();
      final fileContent = String.fromCharCodes(contentBytes);
      
      // 检查文件是否为空
      if (fileContent.isEmpty && await file.getSize() > 0) {
        log('${_indent(indentLevel + 1)}警告: 文件 \'$fileName\' 读取内容为空或失败，跳过。');
        taskCollection.stats.skippedFilesIgnored++;
        return;
      }

      // 添加文件任务
      taskCollection.addTask(XmlWriteTask(
        name: fileName,
        path: file.getPath(),
        isDirectory: false,
        file: file,
        indentLevel: indentLevel,
        content: fileContent,
      ));
    } catch (e) {
      log('${_indent(indentLevel)}错误: 读取文件失败 ${file.getPath()}: $e');
      taskCollection.stats.skippedFilesIgnored++;
    }
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

/// XML 写入任务类 - 存储单个文件/目录的处理信息
class XmlWriteTask {
  final String name;
  final String path;
  final bool isDirectory;
  final UniFile file;
  final int indentLevel;
  final String? parentName;
  final String? content; // 预读取的文件内容（仅对文件有效）

  XmlWriteTask({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.file,
    required this.indentLevel,
    this.parentName,
    this.content,
  });
}

/// 全局任务结果集合类 - 管理所有待写入的任务
class MergeTaskCollection {
  final List<XmlWriteTask> _tasks = [];
  final _MergeStats stats = _MergeStats();

  void addTask(XmlWriteTask task) {
    _tasks.add(task);
  }

  List<XmlWriteTask> get tasks => List.unmodifiable(_tasks);

  _MergeStats get statistics => stats;

  void clear() {
    _tasks.clear();
    stats.mergedFiles = 0;
    stats.skippedFilesNonCode = 0;
    stats.skippedFilesIgnored = 0;
    stats.skippedDirs = 0;
  }
}

/// 合并统计信息类
class _MergeStats {
  int mergedFiles = 0;
  int skippedFilesNonCode = 0;
  int skippedFilesIgnored = 0;
  int skippedDirs = 0;
}
