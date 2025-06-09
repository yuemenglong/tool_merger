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
      if (OpenClipboard(0) == 0) {
        return false;
      }

      // 清空剪切板
      EmptyClipboard();

      // 准备文件路径数据 (使用简化的方法)
      final filePathUtf16 = filePath.toNativeUtf16();
      final filePathLength = (filePath.length + 1) * 2; // UTF-16 字符长度

      // DROPFILES 结构的大小 (手动定义)
      const dropFilesSize = 20; // sizeof(DROPFILES) = 20 bytes
      final totalSize = dropFilesSize + filePathLength + 2; // +2 for double null terminator

      // 分配全局内存
      final hGlobal = GlobalAlloc(0x0002, totalSize); // GMEM_MOVEABLE = 0x0002
      if (hGlobal == 0) {
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

      // 手动填充 DROPFILES 结构
      final bytes = pGlobal.cast<Uint8>();
      
      // pFiles (DWORD) - offset to file list
      bytes[0] = dropFilesSize & 0xFF;
      bytes[1] = (dropFilesSize >> 8) & 0xFF;
      bytes[2] = (dropFilesSize >> 16) & 0xFF;
      bytes[3] = (dropFilesSize >> 24) & 0xFF;
      
      // pt.x (LONG) - cursor position x
      bytes[4] = 0; bytes[5] = 0; bytes[6] = 0; bytes[7] = 0;
      
      // pt.y (LONG) - cursor position y  
      bytes[8] = 0; bytes[9] = 0; bytes[10] = 0; bytes[11] = 0;
      
      // fNC (BOOL) - non-client area
      bytes[12] = 0; bytes[13] = 0; bytes[14] = 0; bytes[15] = 0;
      
      // fWide (BOOL) - Unicode flag
      bytes[16] = 1; bytes[17] = 0; bytes[18] = 0; bytes[19] = 0;

      // 复制文件路径 (UTF-16)
      final filePathDest = Pointer<Uint16>.fromAddress(pGlobal.address + dropFilesSize);
      for (int i = 0; i < filePath.length; i++) {
        filePathDest[i] = filePath.codeUnitAt(i);
      }
      filePathDest[filePath.length] = 0; // null terminator
      filePathDest[filePath.length + 1] = 0; // double null terminator

      // 解锁内存
      GlobalUnlock(hGlobal);

      // 设置剪切板数据 (CF_HDROP = 15)
      final result = SetClipboardData(15, hGlobal.address);
      
      // 关闭剪切板
      CloseClipboard();

      // 释放 UTF-16 字符串内存
      malloc.free(filePathUtf16);

      if (result == 0) {
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