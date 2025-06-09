import 'package:flutter/material.dart';

class AppConfig {
  // 字体大小配置
  static const double primaryFontSize = 14.0;    // 主要文本（项目名、目录名）
  static const double secondaryFontSize = 12.0;  // 次要文本（时间、路径）
  static const double buttonFontSize = 10.0;     // 按钮文本
  static const double statusFontSize = 11.0;     // 状态栏文本
  static const double inputFontSize = 11.0;      // 输入框文本
  
  // 颜色配置
  static const Color primaryColor = Colors.grey;           // 主色调
  static const Color generateButtonColor = Colors.green;   // Generate按钮颜色
  static const Color createButtonColor = Colors.green;     // Create按钮颜色
  static const Color deleteButtonColor = Colors.red;       // Delete按钮颜色
  static const Color moveButtonColor = Colors.blue;        // Up/Down按钮颜色
  static const Color logButtonColor = Colors.orange;       // Log按钮颜色
  static const Color enabledCountColor = Colors.green;     // 启用数量显示颜色
  static const Color excludeSwitchActiveColor = Colors.green;  // 排除开关激活颜色
  static const Color excludeSwitchInactiveColor = Colors.red;  // 排除开关非激活颜色
} 