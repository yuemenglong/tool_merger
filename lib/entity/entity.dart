class Project {
  String? name;
  String? outputPath;
  int? sortOrder;
  List<ProjectItem>? items;
  DateTime? createTime;
  DateTime? updateTime;
}

class ProjectItem {
  String? path;
  int? sortOrder;
  bool? enabled;
}
