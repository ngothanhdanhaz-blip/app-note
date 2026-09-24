import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Đã thay thế Provider bằng Firestore

class NoteEditorScreen extends StatefulWidget {
  // Thêm biến nhận vào để truyền tín hiệu chuyển Tab
  final Function(int)? onNavigate; 

  const NoteEditorScreen({super.key, this.onNavigate});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();

  String? _selectedTopic;
  final List<String> _topics = ['Công việc', 'Học tập', 'Cá nhân'];

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  
  bool _isPrivate = false; 
  bool _isLoading = false; // Thêm cờ trạng thái loading khi đẩy dữ liệu lên mạng

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Lỗi khi chọn ảnh: $e");
    }
  }

  void _removeImage() {
    setState(() => _selectedImage = null);
  }

  void _showAddTopicDialog() {
    final newTopicController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm chủ đề mới'),
          content: TextField(
            controller: newTopicController,
            decoration: const InputDecoration(labelText: 'Tên chủ đề', border: OutlineInputBorder()),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('HỦY', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final newTopic = newTopicController.text.trim();
                if (newTopic.isNotEmpty && !_topics.contains(newTopic)) {
                  setState(() {
                    _topics.add(newTopic);
                    _selectedTopic = newTopic;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('THÊM'),
            ),
          ],
        );
      },
    );
  }

  // Chuyển hàm thành async để đợi phản hồi từ Firebase
  void _saveNote() async {
    if (_formKey.currentState!.validate()) {
      // 1. HIỆU ỨNG UX: Ẩn bàn phím đi cho mượt trước khi chuyển tab
      FocusScope.of(context).unfocus();

      setState(() => _isLoading = true);

      try {
        // 2. LƯU TRỰC TIẾP LÊN FIREBASE THAY VÌ HIVE/PROVIDER
        await FirebaseFirestore.instance.collection('notes').add({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'topic': _selectedTopic ?? 'Cá nhân',
          'url': _urlController.text.trim(),
          // Lưu ý: path hiện tại chỉ là text đường dẫn trên máy.
          // Để upload ảnh thật sự lên Cloud, sau này cần dùng thêm Firebase Storage.
          'imagePath': _selectedImage?.path ?? '', 
          'isPrivate': _isPrivate,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 3. THÔNG BÁO THÀNH CÔNG
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isPrivate ? 'Đã lưu vào Vùng riêng tư trên Firebase!' : 'Lưu ghi chú Firebase thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Lưu lại trạng thái ghi chú mật trước khi xóa trắng form
        bool wasPrivate = _isPrivate;

        // 4. RESET FORM & ĐIỀU HƯỚNG
        _titleController.clear();
        _contentController.clear();
        _urlController.clear();
        setState(() {
          _selectedImage = null;
          _selectedTopic = null;
          _isPrivate = false; 
          _isLoading = false;
        });

        if (widget.onNavigate != null) {
          widget.onNavigate!(wasPrivate ? 2 : 1);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu lên Firebase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo ghi chú mới')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) // Hiện vòng quay khi đang lưu mạng
        : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Tiêu đề ghi chú', border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Chủ đề', border: OutlineInputBorder()),
                        value: _selectedTopic,
                        items: _topics.map((String topic) => DropdownMenuItem<String>(value: topic, child: Text(topic))).toList(),
                        onChanged: (String? newValue) => setState(() => _selectedTopic = newValue),
                        validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng chọn một chủ đề' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50, 
                        border: Border.all(color: isDark ? Colors.blue.shade700 : Colors.blue.shade200), 
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: IconButton(icon: const Icon(Icons.add, color: Colors.blue), onPressed: _showAddTopicDialog),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(labelText: 'Đường dẫn URL đính kèm (tùy chọn)', prefixIcon: Icon(Icons.link), border: OutlineInputBorder()),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: 'Nội dung mô tả', alignLabelWithHint: true, border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.isEmpty) ? 'Nội dung không được để trống' : null,
                ),
                const SizedBox(height: 16),
                const Text('Hình ảnh đính kèm (Tối đa 1 ảnh):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                if (_selectedImage == null)
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity, height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey), 
                        borderRadius: BorderRadius.circular(8), 
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100
                      ),
                      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate, size: 40, color: Colors.blue), SizedBox(height: 8),
                        Text('Nhấn để chọn 1 hình ảnh', style: TextStyle(color: Colors.blue)),
                      ]),
                    ),
                  )
                else
                  Stack(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_selectedImage!, width: double.infinity, height: 200, fit: BoxFit.cover)),
                      Positioned(
                        top: 8, right: 8,
                        child: GestureDetector(
                          onTap: _removeImage,
                          child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 20)),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: _isPrivate 
                      ? (isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50) 
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade50), 
                    borderRadius: BorderRadius.circular(8), 
                    border: Border.all(
                        color: _isPrivate 
                            ? (isDark ? Colors.red.shade700 : Colors.red.shade200) 
                            : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
                    )
                  ),
                  child: SwitchListTile(
                    title: const Text('Lưu vào Vùng riêng tư', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Ghi chú này sẽ bị khóa và yêu cầu mật khẩu để xem.', style: TextStyle(fontSize: 12)),
                    value: _isPrivate, activeColor: Colors.red,
                    secondary: Icon(_isPrivate ? Icons.lock : Icons.lock_open, color: _isPrivate ? Colors.red : Colors.grey),
                    onChanged: (bool value) => setState(() => _isPrivate = value),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveNote,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16.0)),
                    child: const Text('LƯU GHI CHÚ', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}