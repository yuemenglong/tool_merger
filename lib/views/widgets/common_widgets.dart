import 'package:flutter/material.dart';
import '../../config.dart';

class CommonWidgets {
  /// 构建通用操作按钮
  static Widget buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 28,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 12),
        label: Text(label, style: TextStyle(fontSize: AppConfig.buttonFontSize)),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : Colors.grey.shade300,
          foregroundColor: onPressed != null ? Colors.white : Colors.grey.shade600,
          elevation: onPressed != null ? 1 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
      ),
    );
  }

  /// 构建表格表头单元格
  static Widget buildHeaderCell(BuildContext context, String title, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppConfig.secondaryFontSize,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  /// 构建项目文件表格表头单元格
  static Widget buildItemHeaderCell(BuildContext context, String title, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppConfig.secondaryFontSize,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  /// 格式化日期时间
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// 获取文件图标
  static IconData getFileIcon(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'txt':
      case 'md':
        return Icons.description;
      case 'cpp':
      case 'c':
      case 'h':
        return Icons.code;
      case 'xml':
      case 'html':
        return Icons.web;
      case 'json':
        return Icons.data_object;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// 获取文件名
  static String getFileName(String path) {
    if (path.isEmpty) return '';
    return path.split('/').last.split('\\').last;
  }
}