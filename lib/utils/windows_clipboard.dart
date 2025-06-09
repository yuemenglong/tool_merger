import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WindowsClipboard {
  /// 将文件复制到 Windows 剪切板
  static Future<bool> copyFileToClipboard(String filePath) async {
    if (!Platform.isWindows) {
      return false;
    }

    try {
      // 检查文件是否存在
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // 打开剪切板
      if (OpenClipboard(NULL) == 0) {
        return false;
      }

      // 清空剪切板
      EmptyClipboard();

      // 准备文件路径数据
      final filePathPtr = filePath.toNativeUtf16();
      final filePathLength = (filePath.length + 1) * 2; // UTF-16 字符长度

      // 创建 DROPFILES 结构
      final dropFilesSize = sizeOf<DROPFILES>();
      final totalSize = dropFilesSize + filePathLength + 2; // +2 for double null terminator

      // 分配全局内存
      final hGlobal = GlobalAlloc(GMEM_MOVEABLE, totalSize);
      if (hGlobal == NULL) {
        CloseClipboard();
        return false;
      }

      // 锁定内存并填充数据
      final pGlobal = GlobalLock(hGlobal);
      if (pGlobal == nullptr) {
        GlobalFree(hGlobal);
        CloseClipboard();
        return false;
      }

      // 填充 DROPFILES 结构
      final dropFiles = pGlobal.cast<DROPFILES>();
      dropFiles.ref.pFiles = dropFilesSize;
      dropFiles.ref.pt = POINT(x: 0, y: 0);
      dropFiles.ref.fNC = FALSE;
      dropFiles.ref.fWide = TRUE; // 使用 Unicode

      // 复制文件路径
      final filePathDest = pGlobal.elementAt(dropFilesSize).cast<Uint16>();
      for (int i = 0; i < filePath.length; i++) {
        filePathDest[i] = filePath.codeUnitAt(i);
      }
      filePathDest[filePath.length] = 0; // null terminator
      filePathDest[filePath.length + 1] = 0; // double null terminator

      // 解锁内存
      GlobalUnlock(hGlobal);

      // 设置剪切板数据
      final result = SetClipboardData(CF_HDROP, hGlobal);
      
      // 关闭剪切板
      CloseClipboard();

      if (result == NULL) {
        GlobalFree(hGlobal);
        return false;
      }

      return true;
    } catch (e) {
      // 确保剪切板被关闭
      CloseClipboard();
      return false;
    }
  }
} 