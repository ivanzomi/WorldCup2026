import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminUserTab extends StatefulWidget {
  const AdminUserTab({Key? key}) : super(key: key);

  @override
  _AdminUserTabState createState() => _AdminUserTabState();
}

class _AdminUserTabState extends State<AdminUserTab> {
  final _searchIdController = TextEditingController();
  Map<dynamic, dynamic>? _foundUser;
  String? _foundUserKey;
  bool _isLoading = false;

  // MAL 10 TAWH ADVANCED ZON THEIHNA
  Future<void> _searchUser() async {
    String uidToSearch = _searchIdController.text.trim();
    if (uidToSearch.isEmpty) return;
    setState(() { _isLoading = true; _foundUser = null; _foundUserKey = null; });

    try {
      final snapshot = await FirebaseDatabase.instance.ref().child('users').get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
        bool isFound = false;

        users.forEach((key, value) {
          if (key.toString().startsWith(uidToSearch)) {
            _foundUserKey = key.toString();
            _foundUser = value;
            isFound = true;
          }
        });

        if (!isFound) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hih ID tawh user kimu lo hi!")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Database ah user om nai lo hi!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateUserPoints(int additionalPoints) async {
    if (_foundUserKey == null || _foundUser == null) return;
    int currentPoints = _foundUser!['points'] ?? 0;
    int newPoints = currentPoints + additionalPoints;
    try {
      await FirebaseDatabase.instance.ref().child('users').child(_foundUserKey!).update({'points': newPoints});
      setState(() { _foundUser!['points'] = newPoints; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$additionalPoints Points kithun sak ta!")));
    } catch (e) {}
  }

  Future<void> _toggleBlockStatus() async {
    if (_foundUserKey == null || _foundUser == null) return;
    bool isCurrentlyBlocked = _foundUser!['isBlocked'] ?? false;
    try {
      await FirebaseDatabase.instance.ref().child('users').child(_foundUserKey!).update({'isBlocked': !isCurrentlyBlocked});
      setState(() { _foundUser!['isBlocked'] = !isCurrentlyBlocked; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isCurrentlyBlocked ? "User Unblocked!" : "User Blocked!")));
    } catch (e) {}
  }

  Future<void> _deleteUser() async {
    if (_foundUserKey == null) return;
    try {
      await FirebaseDatabase.instance.ref().child('users').child(_foundUserKey!).remove();
      setState(() { _foundUser = null; _foundUserKey = null; });
      _searchIdController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User kiphat sak ta hi!")));
    } catch (e) {}
  }

  void _showEditUserDialog() {
    if (_foundUserKey == null || _foundUser == null) return;
    final editEmailCtrl = TextEditingController(text: _foundUser!['email'] ?? '');
    final editPointsCtrl = TextEditingController(text: (_foundUser!['points'] ?? 0).toString());

    showDialog(context: context, builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Edit User", style: TextStyle(color: Colors.amber)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: editEmailCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Email")),
          TextField(controller: editPointsCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Points"), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () async {
            int updatedPoints = int.tryParse(editPointsCtrl.text) ?? 0;
            await FirebaseDatabase.instance.ref().child('users').child(_foundUserKey!).update({
              'email': editEmailCtrl.text.trim(),
              'points': updatedPoints,
            });
            setState(() {
              _foundUser!['email'] = editEmailCtrl.text.trim();
              _foundUser!['points'] = updatedPoints;
            });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User data kipuah ta hi!")));
          }, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber), child: const Text("Save", style: TextStyle(color: Colors.black)))
        ],
      );
    });
  }

  @override
  void dispose() {
    _searchIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SEARCH SECTION
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchIdController,
                  decoration: const InputDecoration(labelText: "Search User ID (10 chars)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 20)),
                onPressed: _isLoading ? null : _searchUser,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text("Search", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 20),

          // 2. FOUND / SELECTED USER DETAIL CARD
          if (_foundUser != null) ...[
            Card(
              color: Colors.grey[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text("Email: ${_foundUser!['email']}", style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold))),
                        IconButton(icon: const Icon(Icons.edit, color: Colors.amber), onPressed: _showEditUserDialog, tooltip: "Edit User"),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text("ID: ${_foundUserKey!.substring(0, 10)}... (Full ID hidden)", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Text("Current Points: ${_foundUser!['points']}", style: const TextStyle(fontSize: 22, color: Colors.greenAccent, fontWeight: FontWeight.bold)),

                    if (_foundUser!['isBlocked'] == true)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text("⚠️ BLOCKED ACCOUNT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),

                    const Divider(color: Colors.grey, height: 30),
                    const Text("Quick Add Points:", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ActionChip(label: const Text("+10"), backgroundColor: Colors.blueAccent, onPressed: () => _updateUserPoints(10)),
                        ActionChip(label: const Text("+50"), backgroundColor: Colors.blueAccent, onPressed: () => _updateUserPoints(50)),
                        ActionChip(label: const Text("+100"), backgroundColor: Colors.blueAccent, onPressed: () => _updateUserPoints(100)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: _foundUser!['isBlocked'] == true ? Colors.green : Colors.orange),
                            onPressed: _toggleBlockStatus,
                            icon: Icon(_foundUser!['isBlocked'] == true ? Icons.check_circle : Icons.block, color: Colors.white),
                            label: Text(_foundUser!['isBlocked'] == true ? "Unblock" : "Block User", style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () {
                              showDialog(context: context, builder: (context) => AlertDialog(
                                backgroundColor: Colors.grey[800], title: const Text("Delete?", style: TextStyle(color: Colors.red)),
                                content: const Text("Hih user phiat taktak ding?", style: TextStyle(color: Colors.white)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                  ElevatedButton(onPressed: () { Navigator.pop(context); _deleteUser(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Delete", style: TextStyle(color: Colors.white)))
                                ],
                              ));
                            },
                            icon: const Icon(Icons.delete_forever, color: Colors.white),
                            label: const Text("Delete", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 3. ALL USERS LIST SECTION (Thak)
          const Divider(color: Colors.grey, thickness: 1),
          const SizedBox(height: 10),
          const Text("All Registered Users", style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          StreamBuilder(
              stream: FirebaseDatabase.instance.ref().child('users').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.amber));
                }
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Text("User om nai lo hi.", style: TextStyle(color: Colors.grey));
                }

                Map<dynamic, dynamic> usersMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<dynamic> usersList = [];
                usersMap.forEach((key, value) {
                  usersList.add({"key": key, ...value});
                });

                return ListView.builder(
                  shrinkWrap: true, // Scroll buaina a om loh na ding
                  physics: const NeverScrollableScrollPhysics(), // Scroll buaina a om loh na ding
                  itemCount: usersList.length,
                  itemBuilder: (context, index) {
                    final user = usersList[index];
                    bool isBlocked = user['isBlocked'] ?? false;

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: isBlocked ? Colors.red : Colors.transparent, width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isBlocked ? Colors.redAccent : Colors.greenAccent,
                          child: Icon(isBlocked ? Icons.block : Icons.person, color: Colors.black),
                        ),
                        title: Text(user['email'] ?? 'No Email', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text("ID: ${user['key'].toString().substring(0, 10)}... | Points: ${user['points']}", style: const TextStyle(color: Colors.grey)),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.amber, size: 16),
                        onTap: () {
                          // List pan user na mek ciang in a tung lam ah a detail pusuak ding
                          setState(() {
                            _foundUserKey = user['key'];
                            _foundUser = user;
                            // Scroll tuak ding kul leh ScrollController zat theih hi (tu in a tung ah lang pah ding hi)
                          });
                        },
                      ),
                    );
                  },
                );
              }
          ),
        ],
      ),
    );
  }
}