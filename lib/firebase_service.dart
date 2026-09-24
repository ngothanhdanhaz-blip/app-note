import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  // Nhắm mục tiêu vào Collection 'notes' trên Firebase
  final CollectionReference notesCollection = FirebaseFirestore.instance.collection('notes');

  // 1. Thêm ghi chú mới (Create)
  Future<void> addNote(String title, String content, String topic, bool isPrivate) {
    return notesCollection.add({
      'title': title,
      'content': content,
      'topic': topic,
      'isPrivate': isPrivate,
      'createdAt': FieldValue.serverTimestamp(), // Tự động lấy giờ hiện tại
    });
  }

  // 2. Lấy danh sách ghi chú theo thời gian thực (Read Realtime)
Stream<QuerySnapshot> getNotesStream() {
    return FirebaseFirestore.instance
        .collection('notes')
        .orderBy('createdAt', descending: true) // Sắp xếp note mới nhất lên đầu
        .snapshots();
  }

  // 3. Xóa ghi chú (Delete)
  Future<void> deleteNote(String docId) {
    return notesCollection.doc(docId).delete();
  }
}