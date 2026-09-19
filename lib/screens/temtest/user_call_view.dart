// views/user_call_view.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import './call_api_service.dart';
import '../caling_agent_dashboard/callreceive/shared_call_screen.dart';

class UserCallView extends StatefulWidget {
  const UserCallView({Key? key}) : super(key: key);

  @override
  State<UserCallView> createState() => _UserCallViewState();
}

class _UserCallViewState extends State<UserCallView> {
  bool _isRinging = false;
  String? _roomId;
  String _callType = 'video';
  String _agentName = "Agent";

  StreamSubscription<DocumentSnapshot>? _roomSubscription;
  Timer? _countdownTimer;
  int _remainingSeconds = 90;

  final List<Map<String, String>> _agentsList = [
    {
      "agentId": CallApiService.staticAgentId,
      "name": "Priya Sharma",
      "specialty": "Technical & Audio/Video Support",
    },
  ];

  Future<void> _startCall(String agentId, String agentName, String type) async {
    if (agentId.isEmpty) return;

    setState(() {
      _callType = type;
      _agentName = agentName;
      _isRinging = true;
      _remainingSeconds = 90;
    });

    _startLocalCountdown();

    // बैकएंड एपीआई के माध्यम से सुरक्षित रूप से कॉल रिक्वेस्ट भेजना
    final result = await CallApiService.requestCall(
      callType: type,
      customAgentId: agentId,
      customUserName: "John Doe",
      avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb",
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _roomId = result['callId']?.toString() ?? result['roomId']?.toString();
        _agentName = result['agentName']?.toString() ?? agentName;
      });

      if (_roomId == null || _roomId!.isEmpty) {
        _cleanupAndReset("Invalid room generated from server.");
        return;
      }

      // केवल उसी पर्टिकुलर रूम आईडी पर लिसन करना ताकि दूसरे डेटा से कोई क्रॉस-कनेक्शन न हो
      _roomSubscription = FirebaseFirestore.instance
          .collection('rooms')
          .doc(_roomId)
          .snapshots()
          .listen((snapshot) {
            if (!snapshot.exists) {
              _cleanupAndReset("Call ended by agent.");
              return;
            }

            final data = snapshot.data();
            if (data is! Map<String, dynamic>) return;

            final status = data['status']?.toString();

            if (status == 'accepted') {
              _stopTimers();
              if (!mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SharedCallScreen(
                    roomId: _roomId!,
                    callType: _callType,
                    agentId: agentId,
                    isUserCaller: true,
                  ),
                ),
              ).then((_) => _resetState());
            } else if (status == 'ended' ||
                status == 'rejected' ||
                status == 'timeout') {
              _cleanupAndReset("Call ended.");
            }
          });
    } else {
      _stopTimers();
      setState(() {
        _isRinging = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Failed to connect call',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startLocalCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        _stopTimers();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() async {
    if (_roomId != null && _roomId!.isNotEmpty) {
      try {
        // 1. Firestore में रूम स्टेटस अपडेट करें ताकि एजेंट साइड तुरंत UI हट जाए
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(_roomId!)
            .update({
              'status': 'ended',
              'endedBy': 'user_timeout',
              'disconnectedAt': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        debugPrint("Error updating room on timeout: $e");
      }

      // 2. Backend API call
      await CallApiService.endCall(
        roomId: _roomId!,
        customAgentId: CallApiService.staticAgentId,
      );
    }
    _cleanupAndReset("Call timed out. No response from agent.");
  }

  void _cancelCall() async {
    _stopTimers();
    if (_roomId != null && _roomId!.isNotEmpty) {
      try {
        // 1. Firestore में रूम स्टेटस अपडेट करें ताकि एजेंट साइड तुरंत UI हट जाए
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(_roomId!)
            .update({
              'status': 'ended',
              'endedBy': 'user_cancelled',
              'disconnectedAt': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        debugPrint("Error updating room on cancel: $e");
      }

      // 2. Backend API call
      await CallApiService.endCall(
        roomId: _roomId!,
        customAgentId: CallApiService.staticAgentId,
      );
    }
    _cleanupAndReset("Call cancelled.");
  }

  void _stopTimers() {
    _countdownTimer?.cancel();
    _roomSubscription?.cancel();
  }

  void _cleanupAndReset(String message) {
    _stopTimers();
    if (!mounted) return;
    setState(() {
      _isRinging = false;
      _roomId = null;
    });
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _resetState() {
    _stopTimers();
    if (!mounted) return;
    setState(() {
      _isRinging = false;
      _roomId = null;
    });
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isRinging) {
      return Scaffold(
        backgroundColor: Colors.black87,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                "Calling $_agentName (${_callType.toUpperCase()})...",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Timeout in: ${_remainingSeconds}s",
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: _cancelCall,
                child: const Icon(Icons.call_end, color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Agent to Call"),
        backgroundColor: Colors.indigo,
      ),
      body: ListView.builder(
        itemCount: _agentsList.length,
        itemBuilder: (context, index) {
          final agent = _agentsList[index];
          return Card(
            margin: const EdgeInsets.all(12),
            elevation: 4,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                agent["name"]!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("ID: ${agent["agentId"]}\n${agent["specialty"]}"),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.green),
                    tooltip: "Start Audio Call",
                    onPressed: () =>
                        _startCall(agent["agentId"]!, agent["name"]!, 'audio'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.videocam, color: Colors.blue),
                    tooltip: "The Video Call",
                    onPressed: () =>
                        _startCall(agent["agentId"]!, agent["name"]!, 'video'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
