import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // get collection of notes
  final CollectionReference notes = FirebaseFirestore.instance.collection(
    'notes',
  );

  //  CREATE: add a new notes
  Future<void> addNote(String note) {
    return notes.add({'note': note, 'timestamp': Timestamp.now()});
  }

  // READ: get notes from database
  Stream<QuerySnapshot> getNotesStream() {
    final notesStream = notes
        .orderBy('timestamp', descending: true)
        .snapshots();
    return notesStream;
  }

  // UPDATE:update a notes

  Future<void> updateNote(String docID, String newNote) {
    return notes.doc(docID).update({
      'note': newNote,
      'timestamp': Timestamp.now(),
    });
  }

  // DELETE:delete a notes
  Future<void> deleteNote(String docID) {
    return notes.doc(docID).delete();
  }

  Future<String> getNoteById(String docID) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('notes')
        .doc(docID)
        .get();
    return (doc.data() as Map<String, dynamic>)['note'] ?? '';
  }
}
