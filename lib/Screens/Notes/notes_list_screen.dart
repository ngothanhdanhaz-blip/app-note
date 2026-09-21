import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'note_provider.dart'; 
// IMPORT MÀN HÌNH CHI TIẾT
import 'note_detail_screen.dart'; 

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _topics = ['Tất cả', 'Công việc', 'Học tập', 'Cá nhân'];
  String _selectedTopic = 'Tất cả';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allNotes = Provider.of<NoteProvider>(context).notes;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayNotes = allNotes.where((note) {
      if (note.isPrivate) return false; 
      final matchTopic = _selectedTopic == 'Tất cả' || note.topic == _selectedTopic;
      final matchSearch = note.title.toLowerCase().contains(_searchQuery) || note.content.toLowerCase().contains(_searchQuery);
      return matchTopic && matchSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách ghi chú'), elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tiêu đề, nội dung...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _topics.length,
              itemBuilder: (context, index) {
                final topic = _topics[index];
                final isSelected = topic == _selectedTopic;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      topic,
                      style: TextStyle(
                        color: isSelected 
                            ? (isDark ? Colors.white : Colors.blue.shade900) 
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: isDark ? Colors.blue.shade700 : Colors.blue.shade100,
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTopic = topic);
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: displayNotes.isEmpty
                ? const Center(child: Text('Chưa có ghi chú nào.\nHãy sang Tab "Tạo ghi chú" để thêm nhé!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)))
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: displayNotes.length,
                    itemBuilder: (context, index) {
                      final note = displayNotes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        // BỌC LIST TILE BẰNG INKWELL HOẶC DÙNG TRỰC TIẾP ONTAP CỦA LISTTILE
                        child: ListTile(
                          // SỰ KIỆN CHẠM ĐỂ MỞ MÀN HÌNH CHI TIẾT
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NoteDetailScreen(note: note),
                              ),
                            );
                          },
                          leading: note.imagePath != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(File(note.imagePath!), width: 50, height: 50, fit: BoxFit.cover))
                              : const Icon(Icons.description, size: 40, color: Colors.blueGrey),
                          title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.label, size: 14, color: isDark ? Colors.blue.shade300 : Colors.blue.shade400), 
                                  const SizedBox(width: 4),
                                  Text(
                                    note.topic, 
                                    style: TextStyle(
                                      fontSize: 12, 
                                      color: isDark ? Colors.blue.shade300 : Colors.blue.shade700, 
                                      fontWeight: FontWeight.w500
                                    )
                                  ),
                                  if (note.url != null && note.url!.isNotEmpty) ...[
                                    const SizedBox(width: 12), const Icon(Icons.link, size: 14, color: Colors.grey),
                                  ]
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              Provider.of<NoteProvider>(context, listen: false).deleteNote(note.id);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}