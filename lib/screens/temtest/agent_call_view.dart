// views/agent_call_view.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import './call_api_service.dart';
import 'shared_call_screen.dart';

class AgentCallView extends StatefulWidget {
  final String realAgentId;
  const AgentCallView({Key? key, required this.realAgentId}) : super(key: key);

  @override
  State<AgentCallView> createState() => _AgentCallViewState();
}

class _AgentCallViewState extends State<AgentCallView> {
  bool _isIncomingCall = false;
  String? _roomId;
  String _callType = 'video';
  String _callerName = "Unknown Caller";
  StreamSubscription<DocumentSnapshot>? _activeCallSubscription;
  bool _canPopScreen = false;

  @override
  void initState() {
    super.initState();
    _listenForIncomingCalls();
  }

  Future<void> _cleanupAgentState() async {
    try {
      await FirebaseFirestore.instance
          .collection('active_calls')
          .doc(widget.realAgentId)
          .delete();

      if (_roomId != null) {
        await CallApiService.endCall(
          roomId: _roomId!,
          customAgentId: widget.realAgentId,
        );
      }
    } catch (e) {
      debugPrint("Error cleaning up agent state on exit: $e");
    }
  }

  // Confirmation Dialog triggered only on Back button clicks
  Future<void> _handleBackNavigation() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey[800],
        title: const Text(
          "Leave Agent Dashboard?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Going back will clear your active status and you won't receive incoming call requests. Are you sure?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Yes, Leave",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      await _cleanupAgentState();
      setState(() {
        _canPopScreen = true;
      });
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _listenForIncomingCalls() {
    _activeCallSubscription = FirebaseFirestore.instance
        .collection('active_calls')
        .doc(widget.realAgentId)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists) {
            if (mounted) {
              setState(() {
                _isIncomingCall = false;
                _roomId = null;
              });
            }
            return;
          }

          final data = snapshot.data() as Map<String, dynamic>?;
          if (data == null) return;

          final status = data['status'];
          final roomId = data['roomId'];

          if (status == 'ringing' && roomId != null) {
            FirebaseFirestore.instance
                .collection('rooms')
                .doc(roomId)
                .get()
                .then((roomDoc) {
                  if (roomDoc.exists && mounted) {
                    final roomData = roomDoc.data() as Map<String, dynamic>?;
                    if (roomData != null && roomData['status'] == 'ringing') {
                      setState(() {
                        _roomId = roomId?.toString();
                        _callType = roomData['callType']?.toString() ?? 'video';
                        _callerName =
                            roomData['userName']?.toString() ?? "Valued User";
                        _isIncomingCall = true;
                      });
                    } else {
                      setState(() {
                        _isIncomingCall = false;
                      });
                    }
                  }
                });
          } else {
            if (mounted) {
              setState(() {
                _isIncomingCall = false;
                _roomId = null;
              });
            }
          }
        });
  }

  Future<void> _acceptCall() async {
    final currentRoomId = _roomId;
    if (currentRoomId == null || currentRoomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid room ID. Call cannot be accepted.'),
        ),
      );
      return;
    }

    final result = await CallApiService.acceptCall(
      roomId: currentRoomId,
      customAgentId: widget.realAgentId,
    );

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SharedCallScreen(
            roomId: currentRoomId,
            callType: _callType,
            agentId: widget.realAgentId,
            isUserCaller: false,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result?['message']?.toString() ??
                'Call request timed out or expired',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        _isIncomingCall = false;
        _roomId = null;
      });
    }
  }

  Future<void> _rejectCall() async {
    if (_roomId != null) {
      await CallApiService.endCall(
        roomId: _roomId!,
        customAgentId: widget.realAgentId,
      );
    }
    await _cleanupAgentState();
    if (mounted) {
      setState(() {
        _isIncomingCall = false;
        _roomId = null;
      });
    }
  }

  @override
  void dispose() {
    _activeCallSubscription?.cancel();
    // Note: We removed WidgetsBindingObserver so switching to home or
    // other apps will NOT trigger cleanup and the call will stay active!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPopScreen,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Agent Dashboard"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBackNavigation(),
          ),
        ),
        body: _isIncomingCall && _roomId != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 60),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Incoming Call from\n$_callerName",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Type: ${_callType.toUpperCase()}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          backgroundColor: Colors.red,
                          onPressed: _rejectCall,
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 50),
                        FloatingActionButton(
                          backgroundColor: Colors.green,
                          onPressed: _acceptCall,
                          child: const Icon(Icons.call, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : const Center(
                child: Text(
                  "Waiting for incoming calls...",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
      ),
    );
  }
}
