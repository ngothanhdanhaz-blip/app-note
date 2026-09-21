import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/Screens/Notes/note_provider.dart'; 
// IMPORT MÀN HÌNH CHI TIẾT
import 'package:demo/Screens/Notes/note_detail_screen.dart';

class PrivateListScreen extends StatefulWidget {
  const PrivateListScreen({super.key});

  @override
  State<PrivateListScreen> createState() => _PrivateListScreenState();
}

class _PrivateListScreenState extends State<PrivateListScreen> {
  bool _isAuthenticated = false; 
  String _enteredPin = '';       
  String _correctPin = '1234'; 

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _correctPin = prefs.getString('my_pin') ?? '1234';
    });
  }

  void _onPinKeyPressed(String value) {
    setState(() {
      if (value == 'X') {
        if (_enteredPin.isNotEmpty) _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      } else {
        if (_enteredPin.length < 4) _enteredPin += value;
      }

      if (_enteredPin.length == 4) {
        if (_enteredPin == _correctPin) {
          _isAuthenticated = true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mã PIN không chính xác!'), backgroundColor: Colors.red, duration: Duration(seconds: 1)),
          );
          _enteredPin = ''; 
        }
      }
    });
  }

  Widget _buildLockScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Nhập mã PIN', 
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: isDark ? Colors.white : Colors.black87
              )
            ),
            const SizedBox(height: 8),
            const Text('Vùng riêng tư được bảo vệ', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12), width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    color: index < _enteredPin.length ? Colors.redAccent : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
                  ),
                );
              }),
            ),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildNumberRow(['1', '2', '3'], isDark), const SizedBox(height: 20),
                  _buildNumberRow(['4', '5', '6'], isDark), const SizedBox(height: 20),
                  _buildNumberRow(['7', '8', '9'], isDark), const SizedBox(height: 20),
                  _buildNumberRow(['', '0', 'X'], isDark), 
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNumberRow(List<String> keys, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) return const SizedBox(width: 70, height: 70); 
        return InkWell(
          onTap: () => _onPinKeyPressed(key),
          borderRadius: BorderRadius.circular(35),
          child: Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              color: key == 'X' ? Colors.transparent : (isDark ? Colors.grey.shade800 : Colors.grey.shade100)
            ),
            alignment: Alignment.center,
            child: key == 'X' 
                ? const Icon(Icons.backspace_outlined, color: Colors.grey, size: 28) 
                : Text(
                    key, 
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold, 
                      color: isDark ? Colors.white : Colors.black87
                    )
                  ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrivateNotesList() {
    final allNotes = Provider.of<NoteProvider>(context).notes;
    final privateNotes = allNotes.where((note) => note.isPrivate).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi chú riêng tư'),
        leading: const Icon(Icons.lock_outline, color: Colors.red),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.grey),
            tooltip: 'Khóa lại',
            onPressed: () => setState(() { _isAuthenticated = false; _enteredPin = ''; }),
          )
        ],
      ),
      body: privateNotes.isEmpty
          ? const Center(child: Text('Vùng an toàn trống.\nChưa có ghi chú riêng tư nào được tạo.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)))
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: privateNotes.length,
              itemBuilder: (context, index) {
                final note = privateNotes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  color: isDark ? Colors.red.withOpacity(0.15) : Colors.red.shade50, 
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: isDark ? Colors.red.shade800 : Colors.red.shade200, 
                      width: 1
                    ), 
                    borderRadius: BorderRadius.circular(12)
                  ),
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
                        : const Icon(Icons.security, size: 40, color: Colors.redAccent),
                    title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        note.content, 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis, 
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)
                      ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isAuthenticated ? _buildPrivateNotesList() : _buildLockScreen();
  }
}