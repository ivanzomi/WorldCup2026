import 'dart:async';
import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveMatchScreen extends StatefulWidget {
  final String matchTitle;
  final String streamUrl;
  final String accessType; // Free hiam Paid hiam

  const LiveMatchScreen({
    Key? key,
    required this.matchTitle,
    required this.streamUrl,
    required this.accessType
  }) : super(key: key);

  @override
  _LiveMatchScreenState createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> {
  late BetterPlayerController _betterPlayerController;
  Timer? _pointTimer;
  int _currentPoints = 0;
  bool _isLoading = true;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref().child('users');

  @override
  void initState() {
    super.initState();
    _checkInitialPointsAndStart();
  }

  // 1. Point check na
  Future<void> _checkInitialPointsAndStart() async {
    try {
      final snapshot = await _userRef.child(_uid).child('points').get();
      if (snapshot.exists) {
        _currentPoints = (snapshot.value as num).toInt();
      }
    } catch (e) {
      _currentPoints = 0;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (widget.accessType == 'Free') {
        _setupVideoPlayer();
      } else {
        if (_currentPoints > 0) {
          _setupVideoPlayer();
          _startPointDeductionTimer();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showBuyPointsDialog();
          });
        }
      }
    }
  }

  // 2. Video Player Setup
  void _setupVideoPlayer() {
    BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.streamUrl,
      liveStream: true,
      videoFormat: BetterPlayerVideoFormat.hls,
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        // HIH A NUAI A REFERER LIAN BEHLAP IN
        "Referer": "https://www.tonton.com.my/",
        "Origin": "https://www.tonton.com.my"
      },
    );

    _betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        fit: BoxFit.contain,
        aspectRatio: 16 / 9,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          enableSkips: false,
          enableFullscreen: true,
          controlBarColor: Colors.black45,
        ),
      ),
      betterPlayerDataSource: betterPlayerDataSource,
    );
  }

  // 3. Point Kiamna
  void _startPointDeductionTimer() {
    _pointTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_currentPoints > 1) {
        setState(() {
          _currentPoints--;
        });
        await _userRef.child(_uid).update({'points': _currentPoints});
      } else {
        timer.cancel();
        _betterPlayerController.pause();
        await _userRef.child(_uid).update({'points': 0});
        _showBuyPointsDialog(isFinished: true);
      }
    });
  }

  // 4. Point Lei Theihsakna (Telegram)
  void _showBuyPointsDialog({bool isFinished = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
            isFinished ? "Points Empty!" : "Insufficient Points",
            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)
        ),
        content: const Text(
            "Live en theih na ding point na nei nai kei hi. Admin kiang ah lei phot in.",
            style: TextStyle(color: Colors.white)
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);

              final Uri tgAppUrl = Uri.parse("tg://resolve?domain=worldcupadmin_bot");
              final Uri webUrl = Uri.parse("https://t.me/worldcupadmin_bot");

              try {
                if (await canLaunchUrl(tgAppUrl)) {
                  await launchUrl(tgAppUrl, mode: LaunchMode.externalApplication);
                } else {
                  await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Telegram link kihong thei lo hi.")),
                  );
                }
              }
            },
            icon: const Icon(Icons.telegram, color: Colors.white),
            label: const Text("Buy Points", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pointTimer?.cancel();
    if ((widget.accessType == 'Free' || _currentPoints > 0) && !_isLoading) {
      _betterPlayerController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.matchTitle),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        actions: [
          if (!_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 15.0),
                child: Text(
                  widget.accessType == 'Free' ? "FREE MATCH" : "Pts: $_currentPoints",
                  style: TextStyle(
                      color: widget.accessType == 'Free' ? Colors.greenAccent : Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : (widget.accessType != 'Free' && _currentPoints <= 0)
          ? Center(
          child: Text(
              "You need points to watch this stream.",
              style: TextStyle(color: Colors.grey[600], fontSize: 16)
          )
      )
          : Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _betterPlayerController),
          ),
          Expanded(
            child: Center(
              child: Text(
                  widget.accessType == 'Free'
                      ? "Enjoy the free live stream!"
                      : "Points will be deducted 1 per minute.",
                  style: TextStyle(color: Colors.grey[600])
              ),
            ),
          )
        ],
      ),
    );
  }
}