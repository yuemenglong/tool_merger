import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import '../entity/entity.dart';
import '../services/xml_merger.dart';
import '../utils/windows_clipboard.dart';
import '../explorer/uni_file.dart';
import 'project_data_controller.dart';

class ProjectGenerationController extends GetxController {
  final RxString lastGenerateLog = ''.obs;
  final RxBool isGenerating = false.obs;
  final Rx<GenerateStatus?> lastGenerateStatus = Rx<GenerateStatus?>(null);
  
  ProjectDataController get _dataController => Get.find<ProjectDataController>();

  Future<void> generateProject([Project? targetProject]) async {
    if (isGenerating.value) {
      return;
    }

    final project = targetProject ?? _dataController.selectedProject.value;
    if (project == null) {
      Get.snackbar('错误', '请先选择一个项目');
      return;
    }
    if (project.outputPath == null || project.outputPath!.isEmpty) {
      Get.snackbar('错误', '请先设置输出路径');
      return;
    }

    final projectItems = project.items ?? [];
    final enabledItems = projectItems.where((item) => item.enabled == true && (item.isExclude ?? false) == false).toList();
    if (enabledItems.isEmpty) {
      Get.snackbar('错误', '没有启用的文件');
      return;
    }

    isGenerating.value = true;

    final logBuffer = StringBuffer();
    final startTime = DateTime.now();
    
    try {
      logBuffer.writeln('=== Tool Merger Generate Log ===');
      logBuffer.writeln('开始时间: ${startTime.toString()}');
      logBuffer.writeln('项目名称: ${project.name}');
      logBuffer.writeln('输出路径: ${project.outputPath}');
      logBuffer.writeln('');
      
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
      
      logBuffer.writeln('=== 输出文件准备 ===');
      final outputDir = Directory(project.outputPath!);
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
        logBuffer.writeln('创建输出目录: ${project.outputPath}');
      } else {
        logBuffer.writeln('输出目录已存在: ${project.outputPath}');
      }

      final outputFilePath = '${project.outputPath}/${project.name}.xml';
      logBuffer.writeln('输出文件路径: $outputFilePath');
      logBuffer.writeln('');
      
      logBuffer.writeln('=== XML 生成过程 ===');
      logBuffer.writeln('开始调用 XmlMerger.mergeXml()...');
      logBuffer.writeln('');
      
      logBuffer.writeln('=== Project Properties Debug Info ===');
      logBuffer.writeln('项目基本信息:');
      logBuffer.writeln('  - 项目名称: ${project.name}');
      logBuffer.writeln('  - 输出路径: ${project.outputPath}');
      logBuffer.writeln('  - 创建时间: ${project.createTime}');
      logBuffer.writeln('  - 更新时间: ${project.updateTime}');
      logBuffer.writeln('  - 排序序号: ${project.sortOrder}');
      logBuffer.writeln('');
      
      logBuffer.writeln('目标后缀配置:');
      if (project.targetExt != null && project.targetExt!.isNotEmpty) {
        logBuffer.writeln('  - 总数: ${project.targetExt!.length}');
        final enabledExts = project.targetExt!.where((ext) => ext.enabled);
        final disabledExts = project.targetExt!.where((ext) => !ext.enabled);
        logBuffer.writeln('  - 启用: ${enabledExts.length} 个');
        logBuffer.writeln('  - 禁用: ${disabledExts.length} 个');
        
        logBuffer.writeln('  - 启用的后缀:');
        for (final ext in enabledExts) {
          logBuffer.writeln('    * ${ext.ext}');
        }
        
        if (disabledExts.isNotEmpty) {
          logBuffer.writeln('  - 禁用的后缀:');
          for (final ext in disabledExts) {
            logBuffer.writeln('    * ${ext.ext} (disabled)');
          }
        }
      } else {
        logBuffer.writeln('  - 无目标后缀配置');
      }
      logBuffer.writeln('');
      
      logBuffer.writeln('项目项配置:');
      if (project.items != null && project.items!.isNotEmpty) {
        logBuffer.writeln('  - 总数: ${project.items!.length}');
        final enabledItems = project.items!.where((item) => item.enabled == true);
        final disabledItems = project.items!.where((item) => item.enabled != true);
        logBuffer.writeln('  - 启用: ${enabledItems.length} 个');
        logBuffer.writeln('  - 禁用: ${disabledItems.length} 个');
        
        logBuffer.writeln('  - 启用的项目项:');
        for (final item in enabledItems) {
          final includeExclude = (item.isExclude ?? false) ? '[exclude]' : '[include]';
          logBuffer.writeln('    * ${item.name} -> ${item.path} $includeExclude');
        }
        
        if (disabledItems.isNotEmpty) {
          logBuffer.writeln('  - 禁用的项目项:');
          for (final item in disabledItems) {
            final includeExclude = (item.isExclude ?? false) ? '[exclude]' : '[include]';
            logBuffer.writeln('    * ${item.name} -> ${item.path} $includeExclude (disabled)');
          }
        }
      } else {
        logBuffer.writeln('  - 无项目项配置');
      }
      logBuffer.writeln('===============================');
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
      
      logBuffer.writeln('=== 文件写入 ===');
      final outputFile = File(outputFilePath);
      await outputFile.writeAsString(xmlContent, encoding: utf8);
      logBuffer.writeln('文件写入完成: $outputFilePath');
      
      bool clipboardSuccess = false;
      final writtenFile = LocalFile.create(outputFilePath);
      if (await writtenFile.isFile()) {
        final fileSize = await writtenFile.getSize();
        logBuffer.writeln('文件验证成功:');
        logBuffer.writeln('  - 文件大小: ${(fileSize / 1024).toStringAsFixed(1)} KB');
        logBuffer.writeln('  - 文件路径: $outputFilePath');
        
        logBuffer.writeln('');
        logBuffer.writeln('=== 剪切板操作 ===');
        if (Platform.isWindows) {
          logBuffer.writeln('尝试将文件复制到剪切板...');
          clipboardSuccess = await WindowsClipboard.copyFileToClipboard(outputFilePath);
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
      logBuffer.writeln('  - 合并文件: ${mergeResult.mergedFilePaths.length} 个');
      logBuffer.writeln('  - 输出文件: $outputFilePath');
      
      logBuffer.writeln('');
      logBuffer.writeln('=== 收集文件状态信息 ===');
      final fileStatuses = await _collectFileStatuses(mergeResult.mergedFilePaths, logBuffer);
      logBuffer.writeln('收集到 ${fileStatuses.length} 个文件的状态信息');
      
      lastGenerateStatus.value = GenerateStatus(
        generateTime: DateTime.now(),
        projectName: project.name,
        fileStatuses: fileStatuses,
      );
      
      lastGenerateLog.value = logBuffer.toString();
      
      project.updateTime = DateTime.now();
      await _dataController.saveProjects();
      
      String successMessage = '文件生成成功!\n路径: $outputFilePath\n大小: ${(xmlContent.length / 1024).toStringAsFixed(1)} KB';
      
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
      
      lastGenerateLog.value = logBuffer.toString();
      project.updateTime = DateTime.now();
      await _dataController.saveProjects();
      
      Get.snackbar('错误', '生成文件失败: $e');
    } finally {
      isGenerating.value = false;
    }
  }

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

  Future<FileStatusInfo?> _getFileStatus(String filePath) async {
    try {
      final file = LocalFile.create(filePath);
      if (!await file.isFile()) return null;
      
      final contentBytes = await file.read();
      final content = String.fromCharCodes(contentBytes);
      final lines = content.split('\n');
      final fileSize = await file.getSize();
      
      String? extension;
      final lastDotIndex = filePath.lastIndexOf('.');
      if (lastDotIndex != -1 && lastDotIndex < filePath.length - 1) {
        extension = filePath.substring(lastDotIndex + 1);
      }
      
      return FileStatusInfo(
        fullPath: filePath,
        extension: extension,
        lineCount: lines.length,
        fileSize: fileSize,
        processTime: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }
}