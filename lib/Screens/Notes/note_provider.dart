import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'note_provider.g.dart'; 

@HiveType(typeId: 0)
class NoteItem {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String content;
  
  @HiveField(3)
  final String topic;
  
  @HiveField(4)
  final String? imagePath;
  
  @HiveField(5)
  final String? url;
  
  @HiveField(6)
  final bool isPrivate;

  NoteItem({
    required this.id, 
    required this.title, 
    required this.content,
    required this.topic, 
    this.imagePath, 
    this.url,
    this.isPrivate = false,
  });
}

class NoteProvider extends ChangeNotifier {
  final String _boxName = 'notes_box';
  List<NoteItem> _notes = [];

  List<NoteItem> get notes => _notes;

  NoteProvider() {
    _loadNotesFromHive();
  }

  void _loadNotesFromHive() {
    final box = Hive.box<NoteItem>(_boxName);
    _notes = box.values.toList().cast<NoteItem>();
    _notes.sort((a, b) => b.id.compareTo(a.id));
    notifyListeners();
  }

  void addNote(NoteItem note) {
    final box = Hive.box<NoteItem>(_boxName);
    box.put(note.id, note); 
    _notes.insert(0, note); 
    notifyListeners();
  }

  void deleteNote(String id) {
    final box = Hive.box<NoteItem>(_boxName);
    box.delete(id);
    _notes.removeWhere((note) => note.id == id);
    notifyListeners();
  }
}