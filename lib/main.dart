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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
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
    
    // 取消注释下面这行可以看到空状态效果
    // projects = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Tool Merger',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 上半部分 - 项目列表区域
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题和过滤器行
                      Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '项目列表',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: _filterController,
                              decoration: const InputDecoration(
                                hintText: '搜索项目...',
                                prefixIcon: Icon(Icons.search),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: selectedProject != null ? () {
                              // TODO: 实现生成逻辑
                            } : null,
                            icon: const Icon(Icons.build),
                            label: const Text('Generate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              foregroundColor: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 项目表格
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    // 表头
                                    Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context).colorScheme.primaryContainer,
                                            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
                                          ],
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          topRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: Text(
                                                '项目名称',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Center(
                                              child: Text(
                                                '创建时间',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Center(
                                              child: Text(
                                                '更新时间',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 项目列表
                                    Expanded(
                                      child: projects.isEmpty
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(24),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(50),
                                                  ),
                                                  child: Icon(
                                                    Icons.create_new_folder_outlined,
                                                    size: 48,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                Text(
                                                  '暂无项目',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '点击右侧 "Create" 按钮创建第一个项目',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ListView.builder(
                                        itemCount: projects.length,
                                        itemBuilder: (context, index) {
                                          final project = projects[index];
                                          final isSelected = selectedProject == project;
                                          return Container(
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: isSelected 
                                                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                                                : index % 2 == 0 
                                                  ? Colors.grey.shade50 
                                                  : Colors.white,
                                              border: Border(
                                                bottom: BorderSide(color: Colors.grey.shade200),
                                              ),
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(4),
                                                onTap: () {
                                                  setState(() {
                                                    selectedProject = project;
                                                    currentItems = project.items ?? [];
                                                    selectedItem = null;
                                                    _outputPathController.text = project.outputPath ?? '';
                                                  });
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 2,
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.folder,
                                                              color: isSelected 
                                                                ? Theme.of(context).colorScheme.primary
                                                                : Colors.grey.shade600,
                                                              size: 20,
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                project.name ?? '',
                                                                style: TextStyle(
                                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                                  color: isSelected 
                                                                    ? Theme.of(context).colorScheme.primary
                                                                    : null,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 3,
                                                        child: Center(
                                                          child: Text(
                                                            _formatDateTime(project.createTime),
                                                            style: TextStyle(
                                                              color: Colors.grey.shade700,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 3,
                                                        child: Center(
                                                          child: Text(
                                                            _formatDateTime(project.updateTime),
                                                            style: TextStyle(
                                                              color: Colors.grey.shade700,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
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
                            const SizedBox(width: 16),
                            // 右侧按钮列
                            SizedBox(
                              width: 140,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  _buildActionButton(
                                    icon: Icons.add,
                                    label: 'Create',
                                    onPressed: () async {
                                      final result = await showDialog<String>(
                                        context: context,
                                        builder: (context) => const CreateProjectDialog(),
                                      );
                                      if (result != null) {
                                        // TODO: 实现创建项目逻辑
                                      }
                                    },
                                    color: Colors.green,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildActionButton(
                                    icon: Icons.delete,
                                    label: 'Delete',
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
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildActionButton(
                                    icon: Icons.keyboard_arrow_up,
                                    label: 'Move Up',
                                    onPressed: selectedProject != null ? () {
                                      // TODO: 实现向上移动项目逻辑
                                    } : null,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildActionButton(
                                    icon: Icons.keyboard_arrow_down,
                                    label: 'Move Down',
                                    onPressed: selectedProject != null ? () {
                                      // TODO: 实现向下移动项目逻辑
                                    } : null,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 输出路径行
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_open,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '输出路径:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _outputPathController,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  isDense: true,
                                ),
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: selectedProject != null ? () {
                                // TODO: 实现选择输出路径逻辑
                              } : null,
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Select'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 下半部分 - 项目项列表区域
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题行
                      Row(
                        children: [
                          Icon(
                            Icons.list_alt,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '项目文件',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const Spacer(),
                          if (selectedProject != null) ...[
                            Chip(
                              avatar: Icon(
                                Icons.folder_open,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                              label: Text('${currentItems.length} 个文件'),
                              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              avatar: Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                              label: Text('${currentItems.where((item) => item.enabled == true).length} 已启用'),
                              backgroundColor: Colors.green.shade100,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    // 表头
                                    Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context).colorScheme.secondaryContainer,
                                            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.8),
                                          ],
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          topRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Center(
                                              child: Text(
                                                '启用',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: Text(
                                                '文件名',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 4,
                                            child: Center(
                                              child: Text(
                                                '文件路径',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 项目项列表
                                    Expanded(
                                      child: currentItems.isEmpty
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(24),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(50),
                                                  ),
                                                  child: Icon(
                                                    selectedProject == null 
                                                      ? Icons.folder_outlined
                                                      : Icons.note_add_outlined,
                                                    size: 48,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                Text(
                                                  selectedProject == null 
                                                    ? '请先选择一个项目'
                                                    : '暂无文件',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  selectedProject == null 
                                                    ? '从左侧项目列表中选择一个项目'
                                                    : '拖拽文件到此处添加到项目中',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ListView.builder(
                                            itemCount: currentItems.length,
                                            itemBuilder: (context, index) {
                                              final item = currentItems[index];
                                              final isSelected = selectedItem == item;
                                              return Container(
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  color: isSelected 
                                                    ? Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3)
                                                    : index % 2 == 0 
                                                      ? Colors.grey.shade50 
                                                      : Colors.white,
                                                  border: Border(
                                                    bottom: BorderSide(color: Colors.grey.shade200),
                                                  ),
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius: BorderRadius.circular(4),
                                                    onTap: () {
                                                      setState(() {
                                                        selectedItem = item;
                                                      });
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                                                activeColor: Theme.of(context).colorScheme.secondary,
                                                              ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 2,
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  _getFileIcon(item.path ?? ''),
                                                                  size: 20,
                                                                  color: isSelected 
                                                                    ? Theme.of(context).colorScheme.secondary
                                                                    : Colors.grey.shade600,
                                                                ),
                                                                const SizedBox(width: 8),
                                                                Expanded(
                                                                  child: Text(
                                                                    _getFileName(item.path ?? ''),
                                                                    style: TextStyle(
                                                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                                      color: isSelected 
                                                                        ? Theme.of(context).colorScheme.secondary
                                                                        : null,
                                                                    ),
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 4,
                                                            child: Padding(
                                                              padding: const EdgeInsets.only(left: 8),
                                                              child: Text(
                                                                item.path ?? '',
                                                                style: TextStyle(
                                                                  color: Colors.grey.shade700,
                                                                  fontSize: 13,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
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
                            const SizedBox(width: 16),
                            // 右侧按钮列
                            SizedBox(
                              width: 140,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  _buildActionButton(
                                    icon: Icons.delete,
                                    label: 'Delete',
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
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildActionButton(
                                    icon: Icons.keyboard_arrow_up,
                                    label: 'Move Up',
                                    onPressed: selectedProject != null && selectedItem != null ? () {
                                      // TODO: 实现向上移动项目项逻辑
                                    } : null,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildActionButton(
                                    icon: Icons.keyboard_arrow_down,
                                    label: 'Move Down',
                                    onPressed: selectedProject != null && selectedItem != null ? () {
                                      // TODO: 实现向下移动项目项逻辑
                                    } : null,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: selectedProject != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '当前项目: ${selectedProject?.name}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (currentItems.isNotEmpty) ...[
                  Icon(
                    Icons.folder,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${currentItems.length} 文件',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${currentItems.where((item) => item.enabled == true).length} 已启用',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          )
        : null,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : Colors.grey.shade300,
          foregroundColor: onPressed != null ? Colors.white : Colors.grey.shade600,
          elevation: onPressed != null ? 2 : 0,
        ),
      ),
    );
  }

  IconData _getFileIcon(String path) {
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
