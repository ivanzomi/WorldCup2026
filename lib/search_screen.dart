import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          autofocus: true, // A lut phet in keyboard pusuak pah ding
          decoration: const InputDecoration(
            hintText: "Search videos...",
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = "");
            },
          )
        ],
      ),
      body: _searchQuery.isEmpty
          ? const Center(child: Text("Search for highlights, news, etc.", style: TextStyle(color: Colors.grey)))
          : StreamBuilder(
          stream: FirebaseDatabase.instance.ref().child('home_videos').onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return const Center(child: Text("Video om nai lo hi.", style: TextStyle(color: Colors.grey)));
            }

            Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            List<dynamic> videoList = [];

            map.forEach((key, value) {
              String title = (value['title'] ?? '').toString().toLowerCase();
              String category = (value['category'] ?? '').toString().toLowerCase();

              if (title.contains(_searchQuery) || category.contains(_searchQuery)) {
                videoList.add({"key": key, ...value});
              }
            });

            if (videoList.isEmpty) return const Center(child: Text("Na zon na kimu lo hi.", style: TextStyle(color: Colors.grey)));

            return ListView.builder(
              itemCount: videoList.length,
              itemBuilder: (context, index) {
                final video = videoList[index];
                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(5),
                        image: video['thumbnailUrl'] != null && video['thumbnailUrl'].toString().isNotEmpty
                            ? DecorationImage(image: NetworkImage(video['thumbnailUrl']), fit: BoxFit.cover)
                            : null,
                      ),
                      child: video['thumbnailUrl'] == null || video['thumbnailUrl'].toString().isEmpty
                          ? const Icon(Icons.play_arrow, color: Colors.white)
                          : null,
                    ),
                    title: Text(video['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(video['category'] ?? '', style: const TextStyle(color: Colors.greenAccent)),
                    onTap: () {
                      // Hih lai ah Video Play na ding screen ah na link thei ding hi
                    },
                  ),
                );
              },
            );
          }
      ),
    );
  }
}