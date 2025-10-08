// note_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotePage extends StatefulWidget {
  final String filePath;
  const NotePage({super.key, required this.filePath});
  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> with WidgetsBindingObserver {
  late TextEditingController _controller;
  late File _file;
  final FocusNode _focusNode = FocusNode();
  String _lastSavedText = "";
  String _searchKeyword = "";
  int _searchIndex = -1;

  static const platform = MethodChannel('com.notes.app/shortcut');

  // 构造函数
  @override
  void initState() {
    super.initState();
    _file = File(widget.filePath);
    _controller = TextEditingController(text: "");
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addObserver(this);
    _loadFile();
  }
  
  // 转到后台时候保存, 来自WidgetsBindingObserver
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('App state changed to: $state');
    if (state == AppLifecycleState.paused) {
      _saveFile(showSnackbar: false);
    }
  }
  // 读取txt文件内容, 同时记录上次读的是什么
  Future<void> _loadFile() async {
    if (await _file.exists()) {
      final content = await _file.readAsString();
      _lastSavedText = content; 
      setState(() {
        _controller.text = content;
        // 光标移动到末尾
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
      // 等一下然后使用键盘获取焦点
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(_focusNode);
        }
      });
    }
  }

  // 没焦点则意味着失去焦点, 要保存一次, 由focusnode控制
  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      print("focus change");
      _saveFile(showSnackbar: false);
    }
  }

  // 保存controller的修改过的内容
  Future<void> _saveFile({bool showSnackbar = true}) async {
    if (_controller.text == _lastSavedText) {
      return; 
    }   
    await _file.writeAsString(_controller.text);
    _lastSavedText = _controller.text;
    // 只有在需要时（例如用户手动点击保存按钮）才显示提示
    if (showSnackbar && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("已保存")));
    }
  }

  // 向原生代码发生创建桌面快捷方式的请求
  Future<void> _createShortcut() async {
    try {
      final fileName = widget.filePath.split(Platform.pathSeparator).last;
      final noteName = fileName.replaceAll('.txt', '');

      final result = await platform.invokeMethod('createShortcut', {
        'filePath': widget.filePath,
        'noteName': noteName,
      });

      if (context.mounted) {
        if (result == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("快捷方式已添加到桌面")));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("创建快捷方式失败")));
        }
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("错误: ${e.message}")));
      }
    }
  }

  void _searchNext() {
    if (_searchKeyword.isEmpty) return;

    final text = _controller.text;
    final startIndex = _searchIndex + 1;
    final index = text.indexOf(_searchKeyword, startIndex);

    if (index != -1) {
      setState(() {
        _searchIndex = index;
        _controller.selection = TextSelection(
          baseOffset: index,
          extentOffset: index + _searchKeyword.length,
        );
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("没有更多匹配项")));
    }
  }

  void _startSearch() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("搜索"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "输入关键词"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () {
              final keyword = controller.text.trim();
              if (keyword.isNotEmpty) {
                setState(() {
                  _searchKeyword = keyword;
                  _searchIndex = -1;
                });
                _searchNext();
              }
              Navigator.pop(ctx);
            },
            child: const Text("搜索"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // 编辑一个note时候的页面
  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split(Platform.pathSeparator).last;

     // AppBar 的 actions
    final appBarActions = <Widget>[
      IconButton(
        onPressed: () => _saveFile(showSnackbar: true),
        icon: const Icon(Icons.save),
      ),
      IconButton(
        onPressed: _startSearch,
        icon: const Icon(Icons.search),
      ),
      if (_searchKeyword.isNotEmpty)
        IconButton(
          onPressed: _searchNext,
          icon: const Icon(Icons.arrow_downward),
        ),
      IconButton(
        onPressed: _createShortcut,
        icon: const Icon(Icons.add_to_home_screen),
        tooltip: "添加到桌面",
      ),
    ];

    // AppBar
    final appBar = AppBar(
      title: Text(fileName),
      actions: appBarActions,
    );

    // TextField
    final textField = Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: "在这里输入笔记内容...",
        ),
      ),
    );

    return Scaffold(
      appBar: appBar,
      body: textField,
    );
  }
}