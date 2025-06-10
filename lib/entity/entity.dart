class Project {
  String? name;
  String? outputPath;
  int? sortOrder;
  List<ProjectItem>? items;
  DateTime? createTime;
  DateTime? updateTime;

  Project({
    this.name,
    this.outputPath,
    this.sortOrder,
    this.items,
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
    data['createTime'] = createTime?.toIso8601String();
    data['updateTime'] = updateTime?.toIso8601String();
    return data;
  }
}

class ProjectItem {
  String? name;
  String? path;
  int? sortOrder;
  bool? enabled;
  bool? isExclude;

  ProjectItem({
    this.name,
    this.path,
    this.sortOrder,
    this.enabled,
    this.isExclude,
  });

  ProjectItem.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    path = json['path'];
    sortOrder = json['sortOrder'];
    enabled = json['enabled'];
    isExclude = json['isExclude'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['path'] = path;
    data['sortOrder'] = sortOrder;
    data['enabled'] = enabled;
    data['isExclude'] = isExclude ?? false;
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
