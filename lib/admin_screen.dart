import 'package:flutter/material.dart';
import 'admin_match_tab.dart';
import 'admin_video_tab.dart';
import 'admin_user_tab.dart';
import 'admin_noti_tab.dart'; // Noti file import khinsa

class AdminScreen extends StatelessWidget {
  const AdminScreen({Key? key}) : super(key: key);

  // List pan a tuam in screen a hon theih na ding function
  void _openScreen(BuildContext context, String title, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.redAccent,
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          body: screen, // A beisa a Tab file lui te hih lai ah full screen in a suak ding hi
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          _buildAdminCard(
              context,
              "Live Matches",
              "Match thak thun leh puahna",
              Icons.sports_soccer,
              const AdminMatchTab()
          ),
          _buildAdminCard(
              context,
              "Home Videos",
              "Highlights & Classic matches",
              Icons.video_library,
              const AdminVideoTab()
          ),
          _buildAdminCard(
              context,
              "User Management",
              "Points thun leh User block na",
              Icons.manage_accounts,
              const AdminUserTab()
          ),
          _buildAdminCard(
              context,
              "Notifications",
              "Global Noti khakna",
              Icons.notifications_active,
              const AdminNotiTab()
          ),
        ],
      ),
    );
  }

  // Menu List Design bawlna
  Widget _buildAdminCard(BuildContext context, String title, String subtitle, IconData icon, Widget screen) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        leading: CircleAvatar(
          backgroundColor: Colors.redAccent.withOpacity(0.2),
          child: Icon(icon, color: Colors.redAccent),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
        onTap: () => _openScreen(context, title, screen), // Mek ciang a lut theihna
      ),
    );
  }
}