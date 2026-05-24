import 'package:flutter/material.dart';

import 'package:firebase_database/firebase_database.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'notification_screen.dart';

import 'search_screen.dart';

import 'live_match_screen.dart';



class HomeScreen extends StatefulWidget {

  const HomeScreen({Key? key}) : super(key: key);



  @override

  _HomeScreenState createState() => _HomeScreenState();

}



class _HomeScreenState extends State<HomeScreen> {

  int _lastReadTimestamp = 0;



  @override

  void initState() {

    super.initState();

    _loadLastReadTime();

  }



  Future<void> _loadLastReadTime() async {

    final prefs = await SharedPreferences.getInstance();

    setState(() {

      _lastReadTimestamp = prefs.getInt('last_read_noti_time') ?? 0;

    });

  }



  Future<void> _openNotifications() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('last_read_noti_time', DateTime.now().millisecondsSinceEpoch);

    setState(() { _lastReadTimestamp = DateTime.now().millisecondsSinceEpoch; });



    if (mounted) {

      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      appBar: AppBar(

        title: const Text("World Cup 2026", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),

        backgroundColor: Colors.black,

        elevation: 0,

        actions: [

          IconButton(

              icon: const Icon(Icons.search, color: Colors.white),

              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()))

          ),

          StreamBuilder(

              stream: FirebaseDatabase.instance.ref().child('global_notifications').orderByChild('timestamp').limitToLast(1).onValue,

              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {

                bool hasNewNoti = false;

                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {

                  Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                  int latestTimestamp = map.values.first['timestamp'] ?? 0;

                  if (latestTimestamp > _lastReadTimestamp) {

                    hasNewNoti = true;

                  }

                }

                return Stack(

                  children: [

                    IconButton(

                      icon: const Icon(Icons.notifications, color: Colors.white),

                      onPressed: _openNotifications,

                    ),

                    if (hasNewNoti)

                      Positioned(

                        right: 12,

                        top: 12,

                        child: Container(

                          padding: const EdgeInsets.all(4),

                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),

                        ),

                      )

                  ],

                );

              }

          ),

        ],

      ),

      body: StreamBuilder(

          stream: FirebaseDatabase.instance.ref().child('home_videos').onValue,

          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {

              return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));

            }



            List<Map<dynamic, dynamic>> featureVideos = [];

            List<Map<dynamic, dynamic>> highlightVideos = [];

            List<Map<dynamic, dynamic>> newsVideos = [];

            List<Map<dynamic, dynamic>> classicVideos = [];



            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {

              Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

              map.forEach((key, value) {

                if(value is Map) {

                  Map<dynamic, dynamic> video = Map<dynamic, dynamic>.from(value);

                  video['key'] = key;

                  if (video['category'] == 'Feature') featureVideos.add(video);

                  else if (video['category'] == 'Highlight') highlightVideos.add(video);

                  else if (video['category'] == 'News&interview') newsVideos.add(video);

                  else if (video['category'] == 'Classic Match') classicVideos.add(video);

                }

              });

            }



            return SingleChildScrollView(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

// 1. Top Banner

                  if (featureVideos.isNotEmpty)

                    _buildTopBanner(context, featureVideos.last)

                  else

                    Container(

                      height: 220, margin: const EdgeInsets.symmetric(horizontal: 15),

                      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(15)),

                      child: const Center(child: Text("No Featured Video", style: TextStyle(color: Colors.grey))),

                    ),



                  const SizedBox(height: 20),



// 2. Highlights

                  _buildVideoCategory(context, "Latest Highlights", highlightVideos.reversed.toList()),

                  const SizedBox(height: 20),



// 3. News

                  _buildVideoCategory(context, "News & Interviews", newsVideos.reversed.toList()),

                  const SizedBox(height: 20),



// 4. Classic

                  _buildVideoCategory(context, "Classic Matches", classicVideos.reversed.toList()),

                  const SizedBox(height: 30),

                ],

              ),

            );

          }

      ),

    );

  }



  Widget _buildTopBanner(BuildContext context, Map video) {

    String thumbUrl = video['thumbnailUrl'] ?? "";

    bool hasImage = thumbUrl.isNotEmpty && thumbUrl.startsWith('http');



    return GestureDetector(

      onTap: () => _playVideo(context, video),

      child: Container(

        height: 220,

        width: double.infinity,

        margin: const EdgeInsets.symmetric(horizontal: 15),

        decoration: BoxDecoration(

            borderRadius: BorderRadius.circular(15),

            color: Colors.grey[800],

            image: hasImage ? DecorationImage(

              image: NetworkImage(thumbUrl),

              fit: BoxFit.cover,

            ) : null

        ),

        child: Container(

          decoration: BoxDecoration(

              borderRadius: BorderRadius.circular(15),

              gradient: LinearGradient(

                colors: [Colors.black.withOpacity(0.8), Colors.transparent],

                begin: Alignment.bottomCenter,

                end: Alignment.topCenter,

              )

          ),

          padding: const EdgeInsets.all(15),

          alignment: Alignment.bottomLeft,

          child: Column(

            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const Text("Featured", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),

              Text(video['title'] ?? 'No Title', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildVideoCategory(BuildContext context, String title, List<Map> videos) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Padding(

          padding: const EdgeInsets.symmetric(horizontal: 15.0),

          child: Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [

              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

            ],

          ),

        ),

        const SizedBox(height: 10),



        if (videos.isEmpty)

          const Padding(

            padding: EdgeInsets.symmetric(horizontal: 15),

            child: Text("Hih category ah video om nai lo hi.", style: TextStyle(color: Colors.grey)),

          )

        else

          SizedBox(

            height: 150,

            child: ListView.builder(

              scrollDirection: Axis.horizontal,

              padding: const EdgeInsets.symmetric(horizontal: 10),

              itemCount: videos.length,

              itemBuilder: (context, index) {

                final video = videos[index];

                String thumbUrl = video['thumbnailUrl'] ?? '';

                bool hasImage = thumbUrl.isNotEmpty && thumbUrl.startsWith('http');



                return GestureDetector(

                  onTap: () => _playVideo(context, video),

                  child: Container(

                    width: 220,

                    margin: const EdgeInsets.symmetric(horizontal: 5),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Expanded(

                          child: Container(

                            decoration: BoxDecoration(

                              color: Colors.grey[900],

                              borderRadius: BorderRadius.circular(10),

                              image: hasImage ? DecorationImage(

                                image: NetworkImage(thumbUrl),

                                fit: BoxFit.cover,

                              ) : null,

                            ),

                            child: const Center(

                              child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 40),

                            ),

                          ),

                        ),

                        const SizedBox(height: 5),

                        Text(

                          video['title'] ?? 'Watch Video',

                          style: const TextStyle(color: Colors.white, fontSize: 14),

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

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

  }



  void _playVideo(BuildContext context, Map video) {

    if (video['videoUrl'] != null && video['videoUrl'] != "") {

      Navigator.push(

        context,

        MaterialPageRoute(

          builder: (context) => LiveMatchScreen(

            matchTitle: video['title'] ?? 'Video',

            streamUrl: video['videoUrl'],

            accessType: 'Free',

          ),

        ),

      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Video link kisia hi!")));

    }

  }

}