class Project {
  String? name;
  String? outputPath;
  int? sortOrder;
  List<ProjectItem>? items;
  List<TargetExtension>? targetExt; // 新增字段
  DateTime? createTime;
  DateTime? updateTime;

  Project({
    this.name,
    this.outputPath,
    this.sortOrder,
    this.items,
    this.targetExt, // 新增
    this.createTime,
    this.updateTime,
  });

  Project.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    outputPath = json['outputPath'];
    sortOrder = json['sortOrder'];
    if (json['items'] != null) {
      items = <ProjectItem>[];
      json['items'].forEach((v) {
        items!.add(ProjectItem.fromJson(v));
      });
    }
    // 解析 targetExt
    if (json['targetExt'] != null) {
      targetExt = <TargetExtension>[];
      json['targetExt'].forEach((v) {
        targetExt!.add(TargetExtension.fromJson(v));
      });
    }
    createTime = json['createTime'] != null ? DateTime.parse(json['createTime']) : null;
    updateTime = json['updateTime'] != null ? DateTime.parse(json['updateTime']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['outputPath'] = outputPath;
    data['sortOrder'] = sortOrder;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    // 序列化 targetExt
    if (targetExt != null) {
      data['targetExt'] = targetExt!.map((v) => v.toJson()).toList();
    }
    data['createTime'] = createTime?.toIso8601String();
    data['updateTime'] = updateTime?.toIso8601String();
    return data;
  }
}

// 新增：目标文件后缀实体
class TargetExtension {
  String ext;
  bool enabled;

  TargetExtension({
    required this.ext,
    required this.enabled,
  });

  TargetExtension.fromJson(Map<String, dynamic> json)
      : ext = json['ext'],
        enabled = json['enabled'];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ext'] = ext;
    data['enabled'] = enabled;
    return data;
  }
}

enum FileType { local, sftp }

class ProjectItem {
  String? name;
  String? path;
  int? sortOrder;
  bool? enabled;
  bool? isExclude;
  FileType? fileType;
  // SFTP connection info (only used when fileType is sftp)
  String? sftpHost;
  int? sftpPort;
  String? sftpUser;
  String? sftpPassword;

  ProjectItem({
    this.name,
    this.path,
    this.sortOrder,
    this.enabled,
    this.isExclude,
    this.fileType,
    this.sftpHost,
    this.sftpPort,
    this.sftpUser,
    this.sftpPassword,
  });

  ProjectItem.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    path = json['path'];
    sortOrder = json['sortOrder'];
    enabled = json['enabled'];
    isExclude = json['isExclude'] ?? false;
    fileType = json['fileType'] != null 
        ? FileType.values.firstWhere(
            (e) => e.toString() == 'FileType.${json['fileType']}',
            orElse: () => FileType.local,
          )
        : FileType.local;
    sftpHost = json['sftpHost'];
    sftpPort = json['sftpPort'];
    sftpUser = json['sftpUser'];
    sftpPassword = json['sftpPassword'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['path'] = path;
    data['sortOrder'] = sortOrder;
    data['enabled'] = enabled;
    data['isExclude'] = isExclude ?? false;
    data['fileType'] = (fileType ?? FileType.local).toString().split('.').last;
    if (fileType == FileType.sftp) {
      data['sftpHost'] = sftpHost;
      data['sftpPort'] = sftpPort;
      data['sftpUser'] = sftpUser;
      data['sftpPassword'] = sftpPassword;
    }
    return data;
  }
}

class FileStatusInfo {
  String? fullPath;
  String? extension;
  int? lineCount;
  int? fileSize;
  DateTime? processTime;

  FileStatusInfo({
    this.fullPath,
    this.extension,
    this.lineCount,
    this.fileSize,
    this.processTime,
  });

  FileStatusInfo.fromJson(Map<String, dynamic> json) {
    fullPath = json['fullPath'];
    extension = json['extension'];
    lineCount = json['lineCount'];
    fileSize = json['fileSize'];
    processTime = json['processTime'] != null ? DateTime.parse(json['processTime']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['fullPath'] = fullPath;
    data['extension'] = extension;
    data['lineCount'] = lineCount;
    data['fileSize'] = fileSize;
    data['processTime'] = processTime?.toIso8601String();
    return data;
  }
}

class GenerateStatus {
  DateTime? generateTime;
  String? projectName;
  List<FileStatusInfo>? fileStatuses;

  GenerateStatus({
    this.generateTime,
    this.projectName,
    this.fileStatuses,
  });

  GenerateStatus.fromJson(Map<String, dynamic> json) {
    generateTime = json['generateTime'] != null ? DateTime.parse(json['generateTime']) : null;
    projectName = json['projectName'];
    if (json['fileStatuses'] != null) {
      fileStatuses = <FileStatusInfo>[];
      json['fileStatuses'].forEach((v) {
        fileStatuses!.add(FileStatusInfo.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['generateTime'] = generateTime?.toIso8601String();
    data['projectName'] = projectName;
    if (fileStatuses != null) {
      data['fileStatuses'] = fileStatuses!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class MergeResult {
  String xmlContent;
  List<String> mergedFilePaths;

  MergeResult({
    required this.xmlContent,
    required this.mergedFilePaths,
  });
}

class SftpFileRoot {
  String? name;
  String? host;
  int? port;
  String? user;
  String? password;
  String? path;
  bool? enabled;
  DateTime? createTime;
  DateTime? updateTime;

  SftpFileRoot({
    this.name,
    this.host,
    this.port,
    this.user,
    this.password,
    this.path,
    this.enabled,
    this.createTime,
    this.updateTime,
  });

  SftpFileRoot.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    host = json['host'];
    port = json['port'];
    user = json['user'];
    password = json['password'];
    path = json['path'];
    enabled = json['enabled'] ?? true;
    createTime = json['createTime'] != null ? DateTime.parse(json['createTime']) : null;
    updateTime = json['updateTime'] != null ? DateTime.parse(json['updateTime']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['host'] = host;
    data['port'] = port;
    data['user'] = user;
    data['password'] = password;
    data['path'] = path;
    data['enabled'] = enabled ?? true;
    data['createTime'] = createTime?.toIso8601String();
    data['updateTime'] = updateTime?.toIso8601String();
    return data;
  }
}

