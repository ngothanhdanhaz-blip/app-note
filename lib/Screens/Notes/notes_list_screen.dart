import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/firebase_service.dart';

import 'note_provider.dart'; 
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

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getNotesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return const Center(child: Text('Đã xảy ra lỗi tải dữ liệu Firebase!', style: TextStyle(color: Colors.red)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Chưa có ghi chú nào.\nHãy sang Tab "Tạo ghi chú" để thêm nhé!', 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: Colors.grey, fontSize: 16)
                    )
                  );
                }

                final rawNotes = snapshot.data!.docs;
                final displayNotes = rawNotes.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isPrivate = data['isPrivate'] ?? false;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final content = (data['content'] ?? '').toString().toLowerCase();
                  final topic = data['topic'] ?? '';

                  // TAB NÀY CHỈ LẤY GHI CHÚ BÌNH THƯỜNG
                  if (isPrivate) return false; 
                  
                  final matchTopic = _selectedTopic == 'Tất cả' || topic == _selectedTopic;
                  final matchSearch = title.contains(_searchQuery) || content.contains(_searchQuery);
                  
                  return matchTopic && matchSearch;
                }).toList();

                if (displayNotes.isEmpty) {
                  return const Center(child: Text('Không tìm thấy ghi chú nào phù hợp.', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: displayNotes.length,
                  itemBuilder: (context, index) {
                    final doc = displayNotes[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;

                    final note = NoteItem(
                      id: docId, 
                      title: data['title'] ?? '',
                      content: data['content'] ?? '',
                      topic: data['topic'] ?? 'Cá nhân',
                      imagePath: (data['imagePath'] == null || data['imagePath'].toString().isEmpty) ? null : data['imagePath'],
                      url: (data['url'] == null || data['url'].toString().isEmpty) ? null : data['url'],
                      isPrivate: false,
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
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
                          onPressed: () => _showDeleteConfirmDialog(context, docId),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ghi chú'),
        content: const Text('Bạn có chắc chắn muốn xóa ghi chú này không? Dữ liệu trên Cloud sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _firebaseService.deleteNote(docId); 
              Navigator.pop(context); 
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa ghi chú thành công!')),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}