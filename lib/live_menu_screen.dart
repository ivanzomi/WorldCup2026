import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'live_match_screen.dart';

class LiveMenuScreen extends StatelessWidget {
  const LiveMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final databaseRef = FirebaseDatabase.instance.ref().child('matches');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Live Matches', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: databaseRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('Tuni match om lo hi.', style: TextStyle(color: Colors.grey)));
          }

          Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<dynamic> matches = map.values.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final isLive = match['status'] == 'LIVE';
              final isPaid = match['accessType'] == 'Paid (Points)';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: isPaid ? Colors.amber : Colors.transparent, width: 1),
                    borderRadius: BorderRadius.circular(12)
                ),
                color: Colors.grey[900],
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  title: Text(
                    "${match['team1']} vs ${match['team2']}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLive ? "Live - ${match['time']}" : match['time'] ?? '',
                        style: TextStyle(color: isLive ? Colors.redAccent : Colors.grey, fontWeight: FontWeight.w600),
                      ),
                      Text(
                          match['accessType'] ?? 'Free',
                          style: TextStyle(color: isPaid ? Colors.amber : Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.play_circle_fill,
                    color: isLive ? Colors.greenAccent : Colors.grey,
                    size: 36,
                  ),
                  onTap: () {
                    if (isLive && match['streamUrl'] != null && match['streamUrl'] != "") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LiveMatchScreen(
                            matchTitle: "${match['team1']} vs ${match['team2']}",
                            streamUrl: match['streamUrl'],
                            accessType: match['accessType'] ?? 'Free',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hih match kipan nai lo hi!")));
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}