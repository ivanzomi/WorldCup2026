import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminNotiTab extends StatefulWidget {
  const AdminNotiTab({Key? key}) : super(key: key);

  @override
  _AdminNotiTabState createState() => _AdminNotiTabState();
}

class _AdminNotiTabState extends State<AdminNotiTab> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController(); // Lim thunna thak
  bool _isLoading = false;

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseDatabase.instance.ref().child('global_notifications').push().set({
        "title": _titleController.text.trim(),
        "body": _bodyController.text.trim(),
        "imageUrl": _imageUrlController.text.trim(), // Lim khumna
        "timestamp": ServerValue.timestamp,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notification kikhak ta hi!")));
      _titleController.clear();
      _bodyController.clear();
      _imageUrlController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Send Global Notification", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          const SizedBox(height: 20),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Notification Title", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _bodyController, maxLines: 3, decoration: const InputDecoration(labelText: "Message (Body)", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _imageUrlController, decoration: const InputDecoration(labelText: "Image URL (Optional)", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 50)),
            onPressed: _isLoading ? null : _sendNotification,
            icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.send, color: Colors.white),
            label: const Text("Send Notification", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}