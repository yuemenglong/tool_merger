import 'package:flutter/material.dart';
import 'entity/entity.dart';
import 'dialogs.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tool Merger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ToolMergerHomePage(),
    );
  }
}

class ToolMergerHomePage extends StatefulWidget {
  const ToolMergerHomePage({super.key});

  @override
  State<ToolMergerHomePage> createState() => _ToolMergerHomePageState();
}

class _ToolMergerHomePageState extends State<ToolMergerHomePage> {
  final TextEditingController _filterController = TextEditingController();
  final TextEditingController _outputPathController = TextEditingController();
  
  List<Project> projects = [];
  Project? selectedProject;
  List<ProjectItem> currentItems = [];
  ProjectItem? selectedItem;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // 添加一些示例数据用于展示
    projects = [
      Project(
        name: '示例项目1',
        outputPath: '/path/to/output1',
        sortOrder: 0,
        createTime: DateTime.now().subtract(const Duration(days: 2)),
        updateTime: DateTime.now().subtract(const Duration(hours: 1)),
        items: [
          ProjectItem(
            name: 'file1.txt',
            path: '/path/to/file1.txt',
            enabled: true,
            sortOrder: 0,
          ),
          ProjectItem(
            name: 'file2.cpp',
            path: '/path/to/file2.cpp',
            enabled: false,
            sortOrder: 1,
          ),
        ],
      ),
      Project(
        name: '示例项目2',
        outputPath: '/path/to/output2',
        sortOrder: 1,
        createTime: DateTime.now().subtract(const Duration(days: 1)),
        updateTime: DateTime.now().subtract(const Duration(minutes: 30)),
        items: [
          ProjectItem(
            name: 'document.md',
            path: '/path/to/document.md',
            enabled: true,
            sortOrder: 0,
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 上半部分 - 项目列表区域
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // 过滤器和按钮行
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _filterController,
                              decoration: const InputDecoration(
                                hintText: 'filter',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                                                     ElevatedButton(
                             onPressed: selectedProject != null ? () {
                               // TODO: 实现生成逻辑
                             } : null,
                             child: const Text('generate'),
                           ),
                        ],
                      ),
                    ),
                    // 项目表格
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                children: [
                                  // 表头
                                  Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Expanded(flex: 2, child: Center(child: Text('name', style: TextStyle(fontWeight: FontWeight.bold)))),
                                        Expanded(flex: 3, child: Center(child: Text('createTime', style: TextStyle(fontWeight: FontWeight.bold)))),
                                        Expanded(flex: 3, child: Center(child: Text('updateTime', style: TextStyle(fontWeight: FontWeight.bold)))),
                                      ],
                                    ),
                                  ),
                                  // 项目列表
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: projects.length,
                                      itemBuilder: (context, index) {
                                        final project = projects[index];
                                        final isSelected = selectedProject == project;
                                        return Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.blue.shade100 : null,
                                            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                          ),
                                          child: InkWell(
                                                                                         onTap: () {
                                               setState(() {
                                                 selectedProject = project;
                                                 currentItems = project.items ?? [];
                                                 selectedItem = null; // 清除选中的项目项
                                                 _outputPathController.text = project.outputPath ?? '';
                                               });
                                             },
                                            child: Row(
                                                                                             children: [
                                                 Expanded(flex: 2, child: Center(child: Text(project.name ?? ''))),
                                                 Expanded(flex: 3, child: Center(child: Text(_formatDateTime(project.createTime)))),
                                                 Expanded(flex: 3, child: Center(child: Text(_formatDateTime(project.updateTime)))),
                                               ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 右侧按钮列
                          Container(
                            width: 120,
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                                                 SizedBox(
                                   width: double.infinity,
                                   child: ElevatedButton(
                                     onPressed: () async {
                                       final result = await showDialog<String>(
                                         context: context,
                                         builder: (context) => const CreateProjectDialog(),
                                       );
                                       if (result != null) {
                                         // TODO: 实现创建项目逻辑
                                       }
                                     },
                                     child: const Text('create'),
                                   ),
                                 ),
                                const SizedBox(height: 8),
                                                                 SizedBox(
                                   width: double.infinity,
                                   child: ElevatedButton(
                                     onPressed: selectedProject != null ? () async {
                                       final result = await showDialog<bool>(
                                         context: context,
                                         builder: (context) => ConfirmDeleteDialog(
                                           title: '删除项目',
                                           content: '确定要删除项目 "${selectedProject?.name}" 吗？',
                                         ),
                                       );
                                       if (result == true) {
                                         // TODO: 实现删除项目逻辑
                                       }
                                     } : null,
                                     child: const Text('delete'),
                                   ),
                                 ),
                                const SizedBox(height: 8),
                                                                 SizedBox(
                                   width: double.infinity,
                                   child: ElevatedButton(
                                     onPressed: selectedProject != null ? () {
                                       // TODO: 实现向上移动项目逻辑
                                     } : null,
                                     child: const Text('move up'),
                                   ),
                                 ),
                                 const SizedBox(height: 8),
                                 SizedBox(
                                   width: double.infinity,
                                   child: ElevatedButton(
                                     onPressed: selectedProject != null ? () {
                                       // TODO: 实现向下移动项目逻辑
                                     } : null,
                                     child: const Text('move down'),
                                   ),
                                 ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 输出路径行
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Text('outputPath'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _outputPathController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                                                     ElevatedButton(
                             onPressed: selectedProject != null ? () {
                               // TODO: 实现选择输出路径逻辑
                             } : null,
                             child: const Text('select'),
                           ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 下半部分 - 项目项列表区域
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            // 表头
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(flex: 1, child: Center(child: Text('enable', style: TextStyle(fontWeight: FontWeight.bold)))),
                                  Expanded(flex: 2, child: Center(child: Text('name', style: TextStyle(fontWeight: FontWeight.bold)))),
                                  Expanded(flex: 4, child: Center(child: Text('path', style: TextStyle(fontWeight: FontWeight.bold)))),
                                ],
                              ),
                            ),
                            // 项目项列表
                            Expanded(
                              child: ListView.builder(
                                itemCount: currentItems.length,
                                                                 itemBuilder: (context, index) {
                                   final item = currentItems[index];
                                   final isSelected = selectedItem == item;
                                   return Container(
                                     height: 40,
                                     decoration: BoxDecoration(
                                       color: isSelected ? Colors.blue.shade100 : null,
                                       border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                     ),
                                     child: InkWell(
                                       onTap: () {
                                         setState(() {
                                           selectedItem = item;
                                         });
                                       },
                                       child: Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Center(
                                            child: Checkbox(
                                              value: item.enabled ?? false,
                                              onChanged: (value) {
                                                setState(() {
                                                  item.enabled = value;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        Expanded(flex: 2, child: Center(child: Text(_getFileName(item.path ?? '')))),
                                        Expanded(flex: 4, child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(item.path ?? '', overflow: TextOverflow.ellipsis),
                                                                                 )),
                                       ],
                                     ),
                                   ),
                                   );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 右侧按钮列
                    Container(
                      width: 120,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                                                     SizedBox(
                             width: double.infinity,
                             child: ElevatedButton(
                               onPressed: selectedProject != null && selectedItem != null ? () async {
                                 final result = await showDialog<bool>(
                                   context: context,
                                                                        builder: (context) => ConfirmDeleteDialog(
                                       title: '删除项目项',
                                       content: '确定要删除项目项 "${selectedItem?.name}" 吗？',
                                     ),
                                 );
                                 if (result == true) {
                                   // TODO: 实现删除项目项逻辑
                                 }
                               } : null,
                               child: const Text('delete'),
                             ),
                           ),
                          const SizedBox(height: 8),
                                                     SizedBox(
                             width: double.infinity,
                             child: ElevatedButton(
                               onPressed: selectedProject != null && selectedItem != null ? () {
                                 // TODO: 实现向上移动项目项逻辑
                               } : null,
                               child: const Text('move up'),
                             ),
                           ),
                           const SizedBox(height: 8),
                           SizedBox(
                             width: double.infinity,
                             child: ElevatedButton(
                               onPressed: selectedProject != null && selectedItem != null ? () {
                                 // TODO: 实现向下移动项目项逻辑
                               } : null,
                               child: const Text('move down'),
                             ),
                           ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFileName(String path) {
    if (path.isEmpty) return '';
    return path.split('/').last.split('\\').last;
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _filterController.dispose();
    _outputPathController.dispose();
    super.dispose();
  }
}
