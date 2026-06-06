import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const DesktopStickyNoteApp());
class DesktopStickyNoteApp extends StatelessWidget {
  const DesktopStickyNoteApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: '桌面便签', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.yellow, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.yellow, useMaterial3: true, brightness: Brightness.dark),
    home: const StickyNoteHomePage());
}

class StickyNote {
  String id, content;
  int color;
  double x, y, w, h;
  DateTime created;
  StickyNote({required this.id, required this.content, this.color = 0xFFFFF9C4, this.x = 50, this.y = 50, this.w = 200, this.h = 150, required this.created});
  Map<String, dynamic> toJson() => {'id': id, 'content': content, 'color': color, 'x': x, 'y': y, 'w': w, 'h': h, 'created': created.toIso8601String()};
  factory StickyNote.fromJson(Map<String, dynamic> j) => StickyNote(id: j['id'], content: j['content'], color: j['color'] ?? 0xFFFFF9C4, x: j['x']?.toDouble() ?? 50, y: j['y']?.toDouble() ?? 50, w: j['w']?.toDouble() ?? 200, h: j['h']?.toDouble() ?? 150, created: DateTime.parse(j['created']));
}

class StickyNoteHomePage extends StatefulWidget {
  const StickyNoteHomePage({super.key});
  @override
  State<StickyNoteHomePage> setState() => _StickyNoteHomePageState();
}

class _StickyNoteHomePageState extends State<StickyNoteHomePage> {
  List<StickyNote> _notes = [];
  final _colors = [0xFFFFF9C4, 0xFFC8E6C9, 0xFFBBDEFB, 0xFFF8BBD0, 0xFFFFE0B2, 0xFFD1C4E9, 0xFFB2EBF2, 0xFFFFCCBC];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final d = p.getString('sticky_notes');
    if (d != null) setState(() => _notes = (json.decode(d) as List).map((e) => StickyNote.fromJson(e)).toList());
    else { _notes = [
      StickyNote(id: '1', content: '待办事项\n- 完成项目报告\n- 回复邮件\n- 准备会议', color: 0xFFFFF9C4, created: DateTime.now()),
      StickyNote(id: '2', content: '灵感记录\n\n新的App创意：...', color: 0xFFC8E6C9, x: 260, created: DateTime.now()),
    ]; _save(); }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('sticky_notes', json.encode(_notes.map((e) => e.toJson()).toList()));
  }

  void _addNote() {
    setState(() => _notes.add(StickyNote(id: DateTime.now().millisecondsSinceEpoch.toString(), content: '新便签\n\n双击编辑', color: _colors[_notes.length % _colors.length], x: 50 + _notes.length * 20.0, y: 50 + _notes.length * 20.0, created: DateTime.now())));
    _save();
  }

  void _editNote(StickyNote note) {
    final ctrl = TextEditingController(text: note.content);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('编辑便签'),
      content: TextField(controller: ctrl, maxLines: 10, decoration: const InputDecoration(border: OutlineInputBorder())),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), FilledButton(onPressed: () { setState(() => note.content = ctrl.text); _save(); Navigator.pop(ctx); }, child: const Text('保存'))],
    ));
  }

  void _deleteNote(StickyNote note) { setState(() => _notes.removeWhere((n) => n.id == note.id)); _save(); }

  void _changeColor(StickyNote note, int color) { setState(() => note.color = color); _save(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📝 桌面便签'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _addNote, tooltip: '新建便签'),
        IconButton(icon: const Icon(Icons.delete_sweep), onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('清空确认'), content: const Text('删除所有便签？'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), FilledButton(onPressed: () { setState(() => _notes.clear()); _save(); Navigator.pop(ctx); }, child: const Text('删除'))])), tooltip: '清空'),
      ]),
      body: _notes.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.sticky_note_2, size: 80, color: Colors.grey.shade300), const SizedBox(height: 16), Text('点击 + 创建便签', style: TextStyle(color: Colors.grey.shade500))])) : Stack(children: _notes.map((note) => Positioned(left: note.x, top: note.y, child: GestureDetector(
        onPanUpdate: (d) => setState(() { note.x += d.delta.dx; note.y += d.delta.dy; }),
        onDoubleTap: () => _editNote(note),
        child: Container(width: note.w, height: note.h, decoration: BoxDecoration(color: Color(note.color), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(2, 4))]), child: Column(children: [
          Container(height: 28, decoration: BoxDecoration(color: Color(note.color).withOpacity(0.7), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(icon: const Icon(Icons.palette, size: 16), onPressed: () => showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [const Padding(padding: EdgeInsets.all(12), child: Text('选择颜色', style: TextStyle(fontWeight: FontWeight.bold))), Wrap(spacing: 8, runSpacing: 8, children: _colors.map((c) => GestureDetector(onTap: () { _changeColor(note, c); Navigator.pop(ctx); }, child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle, border: Border.all(color: note.color == c ? Colors.black : Colors.transparent, width: 2))))).toList())]))), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 24, minHeight: 24)),
            IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => _deleteNote(note), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 24, minHeight: 24)),
          ])),
          Expanded(child: Padding(padding: const EdgeInsets.all(8), child: Text(note.content, style: const TextStyle(fontSize: 13), overflow: TextOverflow.fade))),
          Padding(padding: const EdgeInsets.all(4), child: Text('${note.created.month}/${note.created.day}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600))),
        ])),
      ))).toList()),
    );
  }
}
