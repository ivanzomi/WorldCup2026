import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Copy theih na ding package
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Nangma Admin Email hih lai ah puah in
  final String adminEmail = "ivanzomi@gmail.com";

  final User? user = FirebaseAuth.instance.currentUser;

  // Telegram ah lut na function (Puah thak sa)
  Future<void> _buyPoints() async {
    // 1. Telegram App taktak a om leh direct a lut theih na ding (tg://)
    final Uri tgAppUrl = Uri.parse("tg://resolve?domain=worldcupadmin_bot");
    // 2. Telegram App a om loh a Browser pan a lut theih na ding (https://)
    final Uri webUrl = Uri.parse("https://t.me/worldcupadmin_bot");

    try {
      if (await canLaunchUrl(tgAppUrl)) {
        // Telegram app a om leh lut pah ding
        await launchUrl(tgAppUrl, mode: LaunchMode.externalApplication);
      } else {
        // Telegram app a om loh leh Browser tawh lut ding
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Telegram link kihong thei lo hi."))
        );
      }
    }
  }

  // ID Copy theihna Function (Mal 10 guak)
  void _copyToClipboard() {
    if (user != null) {
      // Mal 10 guak lakna
      String shortId = user!.uid.length > 10 ? user!.uid.substring(0, 10) : user!.uid;

      Clipboard.setData(ClipboardData(text: shortId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User ID Copy khin ta!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text("Not logged in"));

    // User point Firebase pan lak theihna ding reference
    final userRef = FirebaseDatabase.instance.ref().child('users').child(user!.uid);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("My Profile"), backgroundColor: Colors.black, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Lim leh Email
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.greenAccent,
              child: Icon(Icons.person, size: 40, color: Colors.black),
            ),
            const SizedBox(height: 15),
            Text(
              user!.email ?? "No Email",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),

            // --- USER ID LEH COPY BUTTON ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    // Mal 10 guak a UI ah suaksakna
                    "ID: ${user!.uid.length > 10 ? user!.uid.substring(0, 10) : user!.uid}",
                    style: const TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _copyToClipboard,
                    child: const Icon(Icons.copy, color: Colors.blueAccent, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Points Dashboard Card
            StreamBuilder(
                stream: userRef.onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  int points = 0;
                  if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                    Map<dynamic, dynamic> userData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    points = userData['points'] ?? 0;
                  }

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text("Available Points", style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 10),
                        Text(
                          "$points",
                          style: const TextStyle(color: Colors.amber, fontSize: 45, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                            ),
                            onPressed: _buyPoints,
                            icon: const Icon(Icons.shopping_cart, color: Colors.black),
                            label: const Text("Buy Points", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  );
                }
            ),
            const SizedBox(height: 40),

            // Admin Panel Button (Nangma email guak in a muh theih ding)
            if (user!.email == adminEmail)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  tileColor: Colors.redAccent.withOpacity(0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  leading: const Icon(Icons.admin_panel_settings, color: Colors.redAccent),
                  title: const Text("Admin Panel", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.redAccent, size: 16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
                  },
                ),
              ),

            // Logout Button
            ListTile(
              tileColor: Colors.grey[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text("Logout", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}