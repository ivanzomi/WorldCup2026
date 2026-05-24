import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminMatchTab extends StatefulWidget {
  const AdminMatchTab({Key? key}) : super(key: key);

  @override
  _AdminMatchTabState createState() => _AdminMatchTabState();
}

class _AdminMatchTabState extends State<AdminMatchTab> {
  final _team1Controller = TextEditingController();
  final _team2Controller = TextEditingController();
  final _timeController = TextEditingController();
  final _streamUrlController = TextEditingController();

  String _matchStatus = 'Upcoming';
  String _accessType = 'Free'; // Free leh Paid teelna ding
  bool _isLoading = false;

  // Stream for Match List
  late Stream<DatabaseEvent> _matchesStream;

  @override
  void initState() {
    super.initState();
    _matchesStream = FirebaseDatabase.instance.ref().child('matches').onValue.asBroadcastStream();
  }

  // ==========================================
  // 1. ADD MATCH
  // ==========================================
  Future<void> _addMatch() async {
    if (_team1Controller.text.isEmpty || _team2Controller.text.isEmpty || _streamUrlController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseDatabase.instance.ref().child('matches').push().set({
        "team1": _team1Controller.text.trim(),
        "team2": _team2Controller.text.trim(),
        "time": _timeController.text.trim(),
        "status": _matchStatus,
        "accessType": _accessType, // Free hiam Paid hiam kikhum ding
        "streamUrl": _streamUrlController.text.trim(),
      }).timeout(const Duration(seconds: 10));

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Live Match kithun ta!")));
      _team1Controller.clear();
      _team2Controller.clear();
      _timeController.clear();
      _streamUrlController.clear();
      setState(() {
        _matchStatus = 'Upcoming';
        _accessType = 'Free';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _isLoading = false);
  }

  // ==========================================
  // 2. DELETE MATCH
  // ==========================================
  Future<void> _deleteMatch(String key) async {
    await FirebaseDatabase.instance.ref().child('matches').child(key).remove();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match kiphat ta hi!")));
  }

  // ==========================================
  // 3. EDIT MATCH DIALOG
  // ==========================================
  void _showEditMatchDialog(String key, Map matchData) {
    final editTeam1Ctrl = TextEditingController(text: matchData['team1']);
    final editTeam2Ctrl = TextEditingController(text: matchData['team2']);
    final editTimeCtrl = TextEditingController(text: matchData['time']);
    final editStreamUrlCtrl = TextEditingController(text: matchData['streamUrl']);

    String editStatus = matchData['status'] ?? 'Upcoming';
    String editAccessType = matchData['accessType'] ?? 'Free';

    final statuses = ['Upcoming', 'LIVE', 'Finished'];
    final accessTypes = ['Free', 'Paid (Points)'];

    if (!statuses.contains(editStatus)) editStatus = 'Upcoming';
    if (!accessTypes.contains(editAccessType)) editAccessType = 'Free';

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text("Edit Match", style: TextStyle(color: Colors.greenAccent)),
                  content: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(controller: editTeam1Ctrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Team 1")),
                          TextField(controller: editTeam2Ctrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Team 2")),
                          TextField(controller: editTimeCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Match Time")),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: editStatus, dropdownColor: Colors.grey[800], style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: "Match Status"),
                            items: statuses.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                            onChanged: (val) => setDialogState(() => editStatus = val!),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: editAccessType, dropdownColor: Colors.grey[800], style: const TextStyle(color: Colors.amber),
                            decoration: const InputDecoration(labelText: "Access Type"),
                            items: accessTypes.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                            onChanged: (val) => setDialogState(() => editAccessType = val!),
                          ),
                          TextField(controller: editStreamUrlCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Stream URL")),
                        ]
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                        onPressed: () async {
                          await FirebaseDatabase.instance.ref().child('matches').child(key).update({
                            "team1": editTeam1Ctrl.text.trim(),
                            "team2": editTeam2Ctrl.text.trim(),
                            "time": editTimeCtrl.text.trim(),
                            "status": editStatus,
                            "accessType": editAccessType,
                            "streamUrl": editStreamUrlCtrl.text.trim(),
                          });
                          if (mounted) Navigator.pop(context);
                        },
                        child: const Text("Save", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                    )
                  ],
                );
              }
          );
        }
    );
  }

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    _timeController.dispose();
    _streamUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- MATCH THUNNA FORM ---
          const Text("Add New Live Match", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
          TextField(controller: _team1Controller, decoration: const InputDecoration(labelText: "Team 1")),
          TextField(controller: _team2Controller, decoration: const InputDecoration(labelText: "Team 2")),
          TextField(controller: _timeController, decoration: const InputDecoration(labelText: "Match Time")),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _matchStatus, decoration: const InputDecoration(labelText: "Status"),
                  items: ['Upcoming', 'LIVE', 'Finished'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  onChanged: (val) => setState(() => _matchStatus = val!),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _accessType, decoration: const InputDecoration(labelText: "Access Type"),
                  items: ['Free', 'Paid (Points)'].map((v) => DropdownMenuItem(value: v, child: Text(v, style: TextStyle(color: v == 'Free' ? Colors.green : Colors.amber)))).toList(),
                  onChanged: (val) => setState(() => _accessType = val!),
                ),
              ),
            ],
          ),

          TextField(controller: _streamUrlController, decoration: const InputDecoration(labelText: "Stream Link (.m3u8)")),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, minimumSize: const Size(double.infinity, 50)),
            onPressed: _isLoading ? null : _addMatch,
            child: _isLoading ? const CircularProgressIndicator() : const Text("Upload Match", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 30),
          const Divider(color: Colors.grey),
          const SizedBox(height: 10),

          // --- MATCH LIST (EDIT / DELETE) ---
          const Text("Manage Matches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
          const SizedBox(height: 10),

          StreamBuilder(
              stream: _matchesStream,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Text("Match om nai lo hi.", style: TextStyle(color: Colors.grey));

                Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<dynamic> list = [];
                map.forEach((key, value) { list.add({"key": key, ...value}); });

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final match = list[index];
                    bool isPaid = match['accessType'] == 'Paid (Points)';

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          side: BorderSide(color: isPaid ? Colors.amber : Colors.transparent, width: 1),
                          borderRadius: BorderRadius.circular(10)
                      ),
                      child: ListTile(
                        title: Text("${match['team1']} vs ${match['team2']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${match['time']} | Status: ${match['status']}", style: const TextStyle(color: Colors.grey)),
                            Text(match['accessType'] ?? 'Free', style: TextStyle(color: isPaid ? Colors.amber : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showEditMatchDialog(match['key'], match)),
                            IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: Colors.grey[800], title: const Text("Delete?", style: TextStyle(color: Colors.red)),
                                        content: const Text("Hih match phiat taktak ding?", style: TextStyle(color: Colors.white)),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                          ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              onPressed: () { Navigator.pop(context); _deleteMatch(match['key']); },
                                              child: const Text("Delete", style: TextStyle(color: Colors.white))
                                          )
                                        ],
                                      )
                                  );
                                }
                            ),
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