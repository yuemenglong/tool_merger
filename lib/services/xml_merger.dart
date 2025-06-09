import 'dart:convert';
import 'dart:io';
import '../entity/entity.dart';

class XmlMerger {
  /// 将项目合并为 XML 字符串
  /// 
  /// [project] 要合并的项目
  /// 返回生成的 XML 内容字符串
  static Future<String> mergeXml(Project project) async {
    if (project.items == null || project.items!.isEmpty) {
      throw Exception('项目中没有文件');
    }

    final enabledItems = project.items!.where((item) => item.enabled == true).toList();
    if (enabledItems.isEmpty) {
      throw Exception('没有启用的文件');
    }

    return await _generateXmlContent(project, enabledItems);
  }

  /// 生成 XML 内容
  static Future<String> _generateXmlContent(Project project, List<ProjectItem> enabledItems) async {
    final buffer = StringBuffer();
    
    // XML 头部
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<project name="${_escapeXmlAttribute(project.name ?? '')}" output_path="${_escapeXmlAttribute(project.outputPath ?? '')}">');
    
    int mergedFiles = 0;
    int skippedFiles = 0;
    
    // 处理每个启用的文件
    for (final item in enabledItems) {
      try {
        final file = File(item.path ?? '');
        if (await file.exists()) {
          String content;
          try {
            // 尝试以 UTF-8 读取
            content = await file.readAsString(encoding: utf8);
          } catch (e) {
            // 如果 UTF-8 失败，尝试系统默认编码
            final bytes = await file.readAsBytes();
            content = String.fromCharCodes(bytes);
          }
          
          buffer.writeln('  <file name="${_escapeXmlAttribute(item.name ?? '')}" path="${_escapeXmlAttribute(item.path ?? '')}">');
          buffer.writeln('    <![CDATA[');
          
          // 处理内容，确保正确的缩进和换行
          if (content.isNotEmpty) {
            // 移除可能的 BOM
            if (content.startsWith('\uFEFF')) {
              content = content.substring(1);
            }
            
            // 转义 CDATA 内容
            content = _escapeCDataContent(content);
            
            final lines = content.split('\n');
            for (int i = 0; i < lines.length; i++) {
              final line = lines[i];
              // 移除行尾的回车符
              final cleanLine = line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
              buffer.write('      $cleanLine');
              // 除了最后一行，都添加换行符
              if (i < lines.length - 1) {
                buffer.writeln();
              }
            }
            buffer.writeln(); // 在内容后添加一个换行
          }
          
          buffer.writeln('    ]]>');
          buffer.writeln('  </file>');
          
          mergedFiles++;
          print('处理文件: ${item.name}');
        } else {
          print('警告: 文件不存在: ${item.path}');
          skippedFiles++;
        }
      } catch (e) {
        print('错误: 读取文件失败 ${item.path}: $e');
        skippedFiles++;
      }
    }
    
    buffer.writeln('</project>');
    
    print('生成完成: 合并文件 $mergedFiles 个，跳过文件 $skippedFiles 个');
    
    return buffer.toString();
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
} 