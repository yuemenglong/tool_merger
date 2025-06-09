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
