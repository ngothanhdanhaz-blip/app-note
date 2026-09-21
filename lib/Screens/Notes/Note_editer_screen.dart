import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'note_provider.dart'; 

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

  void _saveNote() {
    if (_formKey.currentState!.validate()) {
      // 1. HIỆU ỨNG UX: Ẩn bàn phím đi cho mượt trước khi chuyển tab
      FocusScope.of(context).unfocus();

      final newNote = NoteItem(
        id: DateTime.now().toString(),
        title: _titleController.text,
        content: _contentController.text,
        topic: _selectedTopic ?? 'Cá nhân',
        imagePath: _selectedImage?.path,
        url: _urlController.text,
        isPrivate: _isPrivate,
      );

      Provider.of<NoteProvider>(context, listen: false).addNote(newNote);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPrivate ? 'Đã lưu vào Vùng riêng tư!' : 'Lưu ghi chú thành công!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating, // Hiệu ứng Snackbar nổi
        ),
      );

      // Lưu lại trạng thái ghi chú mật trước khi xóa trắng form
      bool wasPrivate = _isPrivate;

      _titleController.clear();
      _contentController.clear();
      _urlController.clear();
      setState(() {
        _selectedImage = null;
        _selectedTopic = null;
        _isPrivate = false; 
      });

      // 2. ĐIỀU HƯỚNG THÔNG MINH
      if (widget.onNavigate != null) {
        // Nếu là mật -> Đẩy sang Tab 2 (Riêng tư). Nếu thường -> Sang Tab 1 (Danh sách)
        widget.onNavigate!(wasPrivate ? 2 : 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo ghi chú mới')),
      body: Padding(
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
                    onPressed: _saveNote,
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