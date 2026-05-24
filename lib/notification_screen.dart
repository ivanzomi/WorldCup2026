import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? "";
  List<String> _hiddenNotis = [];

  @override
  void initState() {
    super.initState();
    _loadHiddenNotis();
  }

  Future<void> _loadHiddenNotis() async {
    if (_uid.isEmpty) return;
    final snapshot = await FirebaseDatabase.instance.ref().child('users').child(_uid).child('hidden_notis').get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      setState(() => _hiddenNotis = data.keys.cast<String>().toList());
    }
  }

  Future<void> _hideNotification(String notiId) async {
    if (_uid.isEmpty) return;
    setState(() { _hiddenNotis.add(notiId); });
    await FirebaseDatabase.instance.ref().child('users').child(_uid).child('hidden_notis').child(notiId).set(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Notifications"), backgroundColor: Colors.grey[900]),
      body: StreamBuilder(
          stream: FirebaseDatabase.instance.ref().child('global_notifications').onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Center(child: Text("Noti om nai lo hi.", style: TextStyle(color: Colors.grey)));

            Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            List<dynamic> notiList = [];
            map.forEach((key, value) {
              if (!_hiddenNotis.contains(key)) notiList.add({"key": key, ...value});
            });

            notiList.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

            if (notiList.isEmpty) return const Center(child: Text("Noti thak om nai lo hi.", style: TextStyle(color: Colors.grey)));

            return ListView.builder(
              itemCount: notiList.length,
              itemBuilder: (context, index) {
                final noti = notiList[index];
                return Dismissible(
                  key: Key(noti['key']),
                  direction: DismissDirection.endToStart,
                  background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Colors.redAccent, child: const Icon(Icons.delete, color: Colors.white)),
                  onDismissed: (direction) => _hideNotification(noti['key']),
                  child: Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(backgroundColor: Colors.greenAccent, child: Icon(Icons.notifications, color: Colors.black)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(noti['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 5),
                                    Text(noti['body'] ?? '', style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 18), onPressed: () => _hideNotification(noti['key'])),
                            ],
                          ),
                          // LIM (IMAGE) A OM LEH HONG LANG DING
                          if (noti['imageUrl'] != null && noti['imageUrl'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(noti['imageUrl'], width: double.infinity, height: 150, fit: BoxFit.cover),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
      ),
    );
  }
}