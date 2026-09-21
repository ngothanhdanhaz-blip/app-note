import 'dart:io';
import 'package:flutter/material.dart';
import 'note_provider.dart';

class NoteDetailScreen extends StatelessWidget {
  final NoteItem note; // Nhận dữ liệu ghi chú được truyền sang

  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    // Nhận diện giao diện Sáng/Tối
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết ghi chú'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tiêu đề
            Text(
              note.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // 2. Các thẻ (Tags) Chủ đề & Trạng thái bảo mật
            Row(
              children: [
                Chip(
                  label: Text(note.topic),
                  backgroundColor: isDark ? Colors.blue.shade900 : Colors.blue.shade50,
                  labelStyle: TextStyle(color: isDark ? Colors.blue.shade100 : Colors.blue.shade900),
                  side: BorderSide.none,
                ),
                const SizedBox(width: 8),
                if (note.isPrivate)
                  Chip(
                    avatar: const Icon(Icons.lock, size: 16, color: Colors.white),
                    label: const Text('Riêng tư'),
                    backgroundColor: Colors.red.shade400,
                    labelStyle: const TextStyle(color: Colors.white),
                    side: BorderSide.none,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // 3. Hình ảnh đính kèm (Nếu có)
            if (note.imagePath != null && note.imagePath!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(note.imagePath!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 4. Đường dẫn URL (Nếu có)
            if (note.url != null && note.url!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note.url!,
                        style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 5. Nội dung chi tiết
            Text(
              note.content,
              style: TextStyle(
                fontSize: 16,
                height: 1.6, // Tăng khoảng cách dòng cho dễ đọc
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}