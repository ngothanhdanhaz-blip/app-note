import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Đảm bảo đường dẫn này khớp với project của bạn
import 'package:demo/firebase_service.dart';
import '../Notes/note_provider.dart'; 
import '../Notes/note_detail_screen.dart'; 

class PrivateListScreen extends StatefulWidget {
  const PrivateListScreen({super.key});

  @override
  State<PrivateListScreen> createState() => _PrivateListScreenState();
}

class _PrivateListScreenState extends State<PrivateListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _pinController = TextEditingController();
  
  bool _isAuthenticated = false;
  final String _correctPin = "1234"; 

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _checkPin() {
    if (_pinController.text == _correctPin) {
      setState(() => _isAuthenticated = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu không chính xác!'), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteConfirmDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ghi chú mật'),
        content: const Text('Dữ liệu trên Cloud sẽ bị xóa vĩnh viễn. Bạn có chắc không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _firebaseService.deleteNote(docId); 
              Navigator.pop(context); 
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vùng Riêng Tư', style: TextStyle(color: Colors.red))),
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text('Vui lòng nhập mật khẩu để xem ghi chú mật.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Mã PIN (Mặc định: 1234)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.password),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, 
                  minimumSize: const Size.fromHeight(50)
                ),
                onPressed: _checkPin,
                child: const Text('MỞ KHÓA', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi Chú Mật', style: TextStyle(color: Colors.red)),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_open, color: Colors.red),
            tooltip: 'Khóa lại',
            onPressed: () => setState(() {
              _isAuthenticated = false;
              _pinController.clear();
            }),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.getNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Đã xảy ra lỗi tải dữ liệu!', style: TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có ghi chú mật nào.'));
          }

          // TAB NÀY CHỈ LẤY GHI CHÚ CÓ ISPRIVATE = TRUE
          final privateNotes = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isPrivate'] == true;
          }).toList();

          if (privateNotes.isEmpty) {
            return const Center(child: Text('Không có ghi chú riêng tư nào phù hợp.', style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            itemCount: privateNotes.length,
            itemBuilder: (context, index) {
              final doc = privateNotes[index];
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;

              final note = NoteItem(
                id: docId, 
                title: data['title'] ?? '',
                content: data['content'] ?? '',
                topic: data['topic'] ?? 'Cá nhân',
                imagePath: (data['imagePath'] == null || data['imagePath'].toString().isEmpty) ? null : data['imagePath'],
                url: (data['url'] == null || data['url'].toString().isEmpty) ? null : data['url'],
                isPrivate: true,
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.withOpacity(0.5), width: 1)
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => NoteDetailScreen(note: note)));
                  },
                  leading: note.imagePath != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(File(note.imagePath!), width: 50, height: 50, fit: BoxFit.cover))
                      : Icon(Icons.security, size: 40, color: Colors.red.shade300),
                  title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis),
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
    );
  }
}