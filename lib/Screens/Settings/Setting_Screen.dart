import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:demo/theme_provider.dart'; // Đảm bảo đường dẫn đúng với nơi lưu file

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _showChangePinDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Đổi mã PIN mới'),
          content: TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nhập 4 số mã PIN', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('HỦY', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPin = _pinController.text;
                if (newPin.length == 4) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('my_pin', newPin);
                  
                  if (context.mounted) {
                    Navigator.pop(context); 
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đổi mã PIN thành công!'), backgroundColor: Colors.green),
                    );
                  }
                  _pinController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập đủ 4 số!'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('LƯU'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Giao diện', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode, 
                color: themeProvider.isDarkMode ? Colors.amber : Colors.orange
              ),
              title: const Text('Chế độ tối (Dark Mode)'),
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text('Bảo mật', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.password, color: Colors.redAccent),
              title: const Text('Đổi mã PIN Vùng riêng tư'),
              subtitle: const Text('Bảo vệ các ghi chú an toàn hơn'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showChangePinDialog,
            ),
          ),
        ],
      ),
    );
  }
}