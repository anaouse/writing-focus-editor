// main.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'note_page.dart';

// navigatorKey 控制MyApp的 Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 和MainActivity.kt 中的Channel进行通信
  static const platform = MethodChannel('com.notes.app/shortcut');

  List<String> _notes = [];
  int _currentPage = 0;
  Directory? _dir;
  File? _metadataFile;
  Map<String, int> _accessTimes = {}; // 文件名 -> 时间戳

  bool _isLoading = true;

  // 注册和原生的通道以及加载笔记
  @override
  void initState() {
    super.initState();
    _setupMethodChannelHandler();
    _loadNotes();    
  }

  // 注册回调函数处理来自原生的openNote调用用于快捷方式打开
  Future<void> _setupMethodChannelHandler() async {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'openNote') {
        final filePath = call.arguments as String?;
        if (filePath != null) {
          final navigator = navigatorKey.currentState;
          if (navigator == null) return;
          // 可以 pop，说明当前不是在主页, 把它pop掉然后再跳转到新的笔记页
          if (navigator.canPop()) navigator.pop();
          _navigateToNote(filePath);
        }
      }
    });
  }

  // push一个页面
  Future<void> _navigateToNote(String filePath) async {
    if (!await File(filePath).exists()) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("错误: 找不到笔记文件")));
      }
      return;
    }
    // /data/.../test.txt 取最后的test.txt名字
    final fileName = filePath.split(Platform.pathSeparator).last;
    await _updateAccessTime(fileName);

    // 打开一个新的页面 NotePage，就是点进去编辑了
    await navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => NotePage(filePath: filePath)),
    );
    await _loadNotes();
  }

  // Android/data/com.example.learn/files/WHNotesApp
  // 初始化创建文件夹或者加载笔记内容
  Future<void> _loadNotes() async {
    final externalDir = await getExternalStorageDirectory();
    if (externalDir == null) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("错误: 无法访问外部存储"))
         );
      }
      setState(() => _isLoading = false);
      return;
    }

    final notesPath = "${externalDir.path}/WHNotesApp";
    final notesDir = Directory(notesPath);
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }

    print(notesPath);
    _dir = notesDir;
    _metadataFile = File("${_dir!.path}/.note_metadata.json");

    // 元数据->所有txt->LRU排序
    await _loadMetadata();

    final allNotes = _dir!
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith(".txt"))
        .toList();

    allNotes.sort((a, b) {
      final timeA = _accessTimes[a] ?? 0;
      final timeB = _accessTimes[b] ?? 0;
      return timeB.compareTo(timeA);
    });

    setState(() {
      _notes = allNotes;
      _isLoading = false;
    });
  }

  // 加载文件名->时间戳的元数据给Map
  Future<void> _loadMetadata() async {
    if (_metadataFile == null) return;

    if (await _metadataFile!.exists()) {
      try {
        final content = await _metadataFile!.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        _accessTimes = data.map((key, value) => MapEntry(key, value as int));
      } catch (e) {
        _accessTimes = {};
      }
    }
  }

  // 保存Map变为json元数据,
  Future<void> _saveMetadata() async {
    if (_metadataFile == null) return;
    await _metadataFile!.writeAsString(jsonEncode(_accessTimes));
  }

  // 更新 文件名->时间戳这个Map
  Future<void> _updateAccessTime(String fileName) async {
    _accessTimes[fileName] = DateTime.now().millisecondsSinceEpoch;
    await _saveMetadata();
  }

  // 点击创建文件按钮后跳出的页面
  Future<void> _addNote() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("新建笔记"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "输入标题"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isEmpty) return;

              final filePath = "${_dir!.path}/$title.txt";
              final file = File(filePath);

              if (await file.exists()) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("创建失败:文件已存在")));
                }
              } else {
                await file.writeAsString("");
                await _updateAccessTime("$title.txt");
                await _loadNotes();
              }

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("创建"),
          ),
        ],
      ),
    );
  }

  // HomePage的页面
  @override
  Widget build(BuildContext context) {
    // 正在加载的话就转圈, 一般是遇到存储文件获取有问题才会出现
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("我的笔记")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    const notesPerPage = 8;
    final totalPages = (_notes.length / notesPerPage).ceil().clamp(1, 9999);
    final start = _currentPage * notesPerPage;
    final end = (start + notesPerPage).clamp(0, _notes.length);
    final currentNotes = _notes.sublist(start, end);
    // 笔记列表
    final noteList = ListView.builder(
      itemCount: currentNotes.length,
      itemBuilder: (ctx, i) {
        final noteFileName = currentNotes[i];
        return ListTile(
          title: Text(noteFileName),
          onTap: () async {
            final filePath = "${_dir!.path}/$noteFileName";
            await _navigateToNote(filePath);
          },
        );
      },
    );
    // 页面跳转组件
    final paginationBar = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 0
              ? () => setState(() => _currentPage--)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text("第 ${_currentPage + 1} / $totalPages 页"),
        IconButton(
          onPressed: _currentPage < totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
    // 添加笔记的按钮
    final addButton = FloatingActionButton(
      onPressed: _addNote,
      child: const Icon(Icons.add),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("我的笔记")),
      body: Column(
        children: [
          Expanded(child: noteList),
          paginationBar,
        ],
      ),
      floatingActionButton: addButton,
    );
  }
}