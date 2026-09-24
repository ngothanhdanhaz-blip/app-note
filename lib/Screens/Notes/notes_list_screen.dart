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

  // Khởi tạo Firebase Service
  final FirebaseService _firebaseService = FirebaseService();

  // --- CÁC BIẾN CHO VÙNG RIÊNG TƯ ---
  bool _showPrivateOnly = false; // Đang ở chế độ xem riêng tư hay bình thường
  bool _isAuthenticated = false; // Đã nhập đúng mã PIN chưa
  final String _correctPin = "1234"; // MÃ PIN MẶC ĐỊNH (Bạn có thể đổi ở đây)

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- HÀM HIỂN THỊ HỘP THOẠI NHẬP MÃ PIN ---
  void _showPinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Vùng riêng tư', style: TextStyle(color: Colors.red)),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nhập mã PIN (Mặc định: 1234)',
            prefixIcon: Icon(Icons.password),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (pinController.text == _correctPin) {
                Navigator.pop(context);
                setState(() {
                  _isAuthenticated = true;
                  _showPrivateOnly = true;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mã PIN không đúng!'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Mở khóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- HÀM CHUYỂN ĐỔI CHẾ ĐỘ (THƯỜNG <-> RIÊNG TƯ) ---
  void _togglePrivateZone() {
    if (_showPrivateOnly) {
      // Đang ở vùng riêng tư -> Thoát ra ngoài
      setState(() {
        _showPrivateOnly = false;
        _isAuthenticated = false; // Xóa trạng thái đăng nhập để lần sau vào lại phải nhập mã
      });
    } else {
      // Đang ở ngoài -> Bấm vào vùng riêng tư
      if (!_isAuthenticated) {
        _showPinDialog();
      } else {
        setState(() => _showPrivateOnly = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showPrivateOnly ? 'Vùng riêng tư' : 'Danh sách ghi chú',
          style: TextStyle(color: _showPrivateOnly ? Colors.red : null, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          // NÚT Ổ KHÓA CHUYỂN ĐỔI GIAO DIỆN
          IconButton(
            icon: Icon(
              _showPrivateOnly ? Icons.lock_open : Icons.lock, 
              color: _showPrivateOnly ? Colors.red : (isDark ? Colors.white : Colors.black87)
            ),
            onPressed: _togglePrivateZone,
          ),
        ],
      ),
      body: Column(
        children: [
          // GIAO DIỆN TÌM KIẾM
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
          
          // GIAO DIỆN LỌC CHỦ ĐỀ
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
          
          // DANH SÁCH GHI CHÚ TỪ FIREBASE
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

                // 1. ÉP KIỂU VÀ LỌC DỮ LIỆU LOGIC MỚI
                final rawNotes = snapshot.data!.docs;
                final displayNotes = rawNotes.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isPrivate = data['isPrivate'] ?? false;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final content = (data['content'] ?? '').toString().toLowerCase();
                  final topic = data['topic'] ?? '';

                  // KIỂM TRA ĐIỀU KIỆN RIÊNG TƯ
                  if (_showPrivateOnly) {
                    if (!isPrivate) return false; // Ở tab Riêng tư -> Ẩn note thường
                  } else {
                    if (isPrivate) return false; // Ở tab Thường -> Ẩn note mật
                  }
                  
                  final matchTopic = _selectedTopic == 'Tất cả' || topic == _selectedTopic;
                  final matchSearch = title.contains(_searchQuery) || content.contains(_searchQuery);
                  
                  return matchTopic && matchSearch;
                }).toList();

                if (displayNotes.isEmpty) {
                  return Center(
                    child: Text(
                      _showPrivateOnly ? 'Vùng riêng tư đang trống.' : 'Không tìm thấy ghi chú nào phù hợp.', 
                      style: const TextStyle(color: Colors.grey)
                    )
                  );
                }

                // 2. HIỂN THỊ UI DANH SÁCH
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
                      isPrivate: data['isPrivate'] ?? false,
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      // Đổi màu viền thẻ nếu là ghi chú mật để dễ nhận diện
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _showPrivateOnly ? Colors.red.withOpacity(0.5) : Colors.transparent,
                          width: 1
                        )
                      ),
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
                            : Icon(Icons.description, size: 40, color: _showPrivateOnly ? Colors.red.shade300 : Colors.blueGrey),
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