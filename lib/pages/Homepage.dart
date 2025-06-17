import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crudfirebase/services/auth_service.dart';
import 'package:crudfirebase/services/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController textController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
  }

  @override
  void dispose() {
    _isMounted = false;
    textController.dispose();
    super.dispose();
  }

  void openNoteBox({String? docID}) async {
    if (docID != null) {
      String noteText = await firestoreService.getNoteById(docID);
      if (!_isMounted) return;

      textController.text = noteText;
      _showDialog(docID: docID);
    } else {
      textController.clear();
      _showDialog();
    }
  }

  void _showDialog({String? docID}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docID == null ? 'Add Note' : 'Edit Note'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Enter note'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              String inputText = textController.text.trim();
              if (inputText.isEmpty) {
                Navigator.of(context).pop();
                if (_isMounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note cannot be empty'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              if (docID == null) {
                firestoreService.addNote(inputText);
              } else {
                firestoreService.updateNote(docID, inputText);
              }

              textController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            // Top profile header
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF6A1B9A)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Color(0xFF6A1B9A)),
              ),
              accountName: const Text('Welcome!'),
              accountEmail: Text(user?.email ?? 'No Email'),
            ),

            // You can add more drawer items here if needed
            const Spacer(), // Pushes the logout to the bottom
            // Logout button at the bottom
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () async {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Notes'),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => openNoteBox(),
        child: const Icon(Icons.add),
      ),

      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: firestoreService.getNotesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No notes available'));
            }

            List notesList = snapshot.data!.docs;
            int noteCount = notesList.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$noteCount Note${noteCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: noteCount,
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = notesList[index];
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;
                      String noteText = data['note'];
                      String docID = doc.id;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 16,
                          ),
                          title: Text(
                            noteText,
                            style: const TextStyle(fontSize: 16),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => openNoteBox(docID: docID),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Note'),
                                      content: const Text(
                                        'Are you sure you want to delete this note?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                  255,
                                                  245,
                                                  59,
                                                  46,
                                                ),
                                          ),
                                          onPressed: () {
                                            firestoreService.deleteNote(docID);
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
