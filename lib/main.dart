import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart'; 

// ---- BỔ SUNG THƯ VIỆN FIREBASE ----
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
// ------------------------------------

import 'theme_provider.dart';
import 'package:demo/Screens/Notes/note_provider.dart';
import 'package:demo/Screens/Notes/Note_editer_screen.dart';
import 'package:demo/Screens/Notes/notes_list_screen.dart';
import 'package:demo/Screens/Private/private_list_screen.dart';
import 'package:demo/Screens/Settings/Setting_Screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  // ---- KHỞI TẠO FIREBASE ----
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // ---------------------------

  // Khởi tạo cơ sở dữ liệu cục bộ Hive (Cũ)
  await Hive.initFlutter();
  Hive.registerAdapter(NoteItemAdapter());
  await Hive.openBox<NoteItem>('notes_box');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NoteProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Quản lý ghi chú',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainTab(),
    );
  }
}

class MainTab extends StatefulWidget {
  const MainTab({super.key});

  @override
  State<MainTab> createState() => _MainTabState();
}

class _MainTabState extends State<MainTab> {
  int _selectedIndex = 1;
  Key _privateScreenKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Thay thế IndexedStack thông thường bằng FadeIndexedStack (Viết ở cuối file)
      body: FadeIndexedStack(
        index: _selectedIndex,
        children: [
          NoteEditorScreen(
            // Bắt tín hiệu từ màn hình tạo ghi chú để chuyển đổi
            onNavigate: (int targetIndex) {
              setState(() {
                _selectedIndex = targetIndex;
              });
            },
          ),
          const NotesListScreen(),
          _selectedIndex == 2 ? PrivateListScreen(key: _privateScreenKey) : const SizedBox(),
          const SettingScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          if (_selectedIndex == 2 && index == 2) {
            setState(() {
              _privateScreenKey = UniqueKey(); 
            });
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle, color: Colors.blue),
            label: 'Tạo ghi chú',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description, color: Colors.blue),
            label: 'Ghi chú',
          ),
          NavigationDestination(
            icon: Icon(Icons.lock_outline),
            selectedIcon: Icon(Icons.lock, color: Colors.blue),
            label: 'Riêng tư',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Colors.blue),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

// ==== WIDGET: TẠO HIỆU ỨNG CHUYỂN TRANG FADE (MỜ DẦN) MƯỢT MÀ ====
class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 250), // Thời gian mờ
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward();
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Kích hoạt hiệu ứng mỗi khi chuyển Tab
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: IndexedStack(
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}