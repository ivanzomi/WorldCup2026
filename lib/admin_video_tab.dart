import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class AdminVideoTab extends StatefulWidget {
  const AdminVideoTab({Key? key}) : super(key: key);

  @override
  _AdminVideoTabState createState() => _AdminVideoTabState();
}

class _AdminVideoTabState extends State<AdminVideoTab> {
  final _vidTitleController = TextEditingController();
  final _vidThumbController = TextEditingController();
  final _vidUrlController = TextEditingController();

  // Category thak thunna ding
  final _newCategoryController = TextEditingController();

  String _vidCategory = 'Highlight';
  bool _isLoading = false;

  // A ngeina sa (Default) te
  List<String> _videoCategories = ['Feature', 'Highlight', 'News&interview', 'Classic Match'];
  late Stream<DatabaseEvent> _homeVideosStream;

  @override
  void initState() {
    super.initState();
    _homeVideosStream = FirebaseDatabase.instance.ref().child('home_videos').onValue.asBroadcastStream();
    _listenToCategories(); // Database pan Category thak te la ding
  }

  // Database pan Category thak te lakna
  void _listenToCategories() {
    FirebaseDatabase.instance.ref().child('categories').onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> map = event.snapshot.value as Map<dynamic, dynamic>;
        Set<String> cats = {'Feature', 'Highlight', 'News&interview', 'Classic Match'};
        map.forEach((key, value) {
          cats.add(value.toString());
        });
        setState(() {
          _videoCategories = cats.toList();
          if (!_videoCategories.contains(_vidCategory)) {
            _vidCategory = _videoCategories.first;
          }
        });
      }
    });
  }

  // Category thak Firebase ah thunna
  Future<void> _addNewCategory() async {
    String newCat = _newCategoryController.text.trim();
    if (newCat.isEmpty) return;

    try {
      await FirebaseDatabase.instance.ref().child('categories').push().set(newCat);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Category thak '$newCat' kithun ta!")));
      _newCategoryController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _addHomeVideo() async {
    if (_vidTitleController.text.isEmpty || _vidUrlController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseDatabase.instance.ref().child('home_videos').push().set({
        "title": _vidTitleController.text.trim(),
        "category": _vidCategory,
        "thumbnailUrl": _vidThumbController.text.trim(),
        "videoUrl": _vidUrlController.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Video kithun ta!")));
      _vidTitleController.clear(); _vidThumbController.clear(); _vidUrlController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteVideo(String key) async {
    await FirebaseDatabase.instance.ref().child('home_videos').child(key).remove();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Video kiphat ta hi!")));
  }

  void _showEditVideoDialog(String key, Map videoData) {
    final editTitleCtrl = TextEditingController(text: videoData['title']);
    final editThumbCtrl = TextEditingController(text: videoData['thumbnailUrl']);
    final editUrlCtrl = TextEditingController(text: videoData['videoUrl']);
    String editCat = videoData['category'] ?? 'Highlight';
    if (!_videoCategories.contains(editCat)) editCat = _videoCategories.first;

    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], title: const Text("Edit Video", style: TextStyle(color: Colors.blueAccent)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: editTitleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Title")),
              DropdownButtonFormField<String>(
                value: editCat, dropdownColor: Colors.grey[800], style: const TextStyle(color: Colors.white),
                items: _videoCategories.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (val) => setDialogState(() => editCat = val!),
              ),
              TextField(controller: editThumbCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Thumb URL")),
              TextField(controller: editUrlCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Video URL")),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
            ElevatedButton(onPressed: () async {
              await FirebaseDatabase.instance.ref().child('home_videos').child(key).update({
                "title": editTitleCtrl.text.trim(), "category": editCat, "thumbnailUrl": editThumbCtrl.text.trim(), "videoUrl": editUrlCtrl.text.trim(),
              });
              Navigator.pop(context);
            }, child: const Text("Save"))
          ],
        );
      });
    });
  }

  @override
  void dispose() {
    _vidTitleController.dispose();
    _vidThumbController.dispose();
    _vidUrlController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- CATEGORY THUNNA THAK ---
          const Text("Manage Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _newCategoryController,
                      decoration: const InputDecoration(labelText: "New Category Name (e.g. UFC, MMA)")
                  )
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: _addNewCategory,
                child: const Text("Add", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.grey),
          const SizedBox(height: 10),

          // --- VIDEO THUNNA ---
          const Text("Add New Video", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          TextField(controller: _vidTitleController, decoration: const InputDecoration(labelText: "Video Title")),
          DropdownButtonFormField<String>(
            value: _vidCategory, decoration: const InputDecoration(labelText: "Category"),
            items: _videoCategories.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (val) => setState(() => _vidCategory = val!),
          ),
          TextField(controller: _vidThumbController, decoration: const InputDecoration(labelText: "Thumbnail URL")),
          TextField(controller: _vidUrlController, decoration: const InputDecoration(labelText: "Video Link")),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blueAccent),
            onPressed: _isLoading ? null : _addHomeVideo,
            child: _isLoading ? const CircularProgressIndicator() : const Text("Upload Video", style: TextStyle(color: Colors.white)),
          ),

          const SizedBox(height: 30),
          const Text("Manage Uploaded Videos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          StreamBuilder(
              stream: _homeVideosStream,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Text("Video om lo hi.", style: TextStyle(color: Colors.grey));

                Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<Map<dynamic, dynamic>> list = [];
                map.forEach((key, value) {
                  if(value is Map) {
                    Map<dynamic, dynamic> item = Map<dynamic, dynamic>.from(value);
                    item['key'] = key;
                    list.add(item);
                  }
                });

                return ListView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final video = list[index];
                    return Card(
                      color: Colors.grey[900], margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(video['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text(video['category'] ?? '', style: const TextStyle(color: Colors.greenAccent)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showEditVideoDialog(video['key'], video)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteVideo(video['key'])),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
          )
        ],
      ),
    );
  }
}