// views/agent_call_view.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import './call_api_service.dart';
import '../caling_agent_dashboard/callreceive/shared_call_screen.dart';

class AgentCallView extends StatefulWidget {
  final String realAgentId;
  const AgentCallView({Key? key, required this.realAgentId}) : super(key: key);

  @override
  State<AgentCallView> createState() => _AgentCallViewState();
}

class _AgentCallViewState extends State<AgentCallView> {
  StreamSubscription<QuerySnapshot>? _incomingCallsSubscription;
  List<Map<String, dynamic>> _pendingCalls = [];
  bool _isLoading = true;
  bool _isLeavingInProgress = false;

  @override
  void initState() {
    super.initState();
    _listenForMultipleIncomingCalls();
  }

  void _listenForMultipleIncomingCalls() {
    if (widget.realAgentId.isEmpty) return;

    // Yahan 'ringing' status walay rooms fetch ho rahe hain.
    // Jaise hi timer out ya cancel hone par status 'ended' ya 'timeout' hoga, yeh list se automatically hat jayega.
    _incomingCallsSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .where('participants.agentId', isEqualTo: widget.realAgentId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;

            List<Map<String, dynamic>> loadedCalls = [];
            for (var doc in snapshot.docs) {
              final data = doc.data();
              if (data is Map<String, dynamic>) {
                debugPrint(
                  "PRINT API/Room Response -> ID: ${doc.id}, Data: $data",
                );

                loadedCalls.add({
                  'roomId': doc.id,
                  'userName': data['userName']?.toString() ?? 'Unknown User',
                  'callType': data['callType']?.toString() ?? 'video',
                  'avatarUrl': data['avatarUrl']?.toString() ?? '',
                  'topic': data['topic']?.toString() ?? 'General',
                  'createdAt': data['createdAt'] ?? 0,
                });
              }
            }

            loadedCalls.sort(
              (a, b) =>
                  (b['createdAt'] as int).compareTo(a['createdAt'] as int),
            );

            setState(() {
              _pendingCalls = loadedCalls;
              _isLoading = false;
            });
          },
          onError: (error) {
            debugPrint("Error in incoming calls stream: $error");
            if (mounted) setState(() => _isLoading = false);
          },
        );
  }

  Future<void> _acceptCall(String roomId, String callType) async {
    if (roomId.isEmpty) return;

    final result = await CallApiService.acceptCall(
      roomId: roomId,
      customAgentId: widget.realAgentId,
    );

    debugPrint("PRINT Accept Call API Response -> $result");

    if (!mounted) return;

    if (result['success'] == true) {
      final finalRoomId = result['callId'] ?? result['roomId'] ?? roomId;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SharedCallScreen(
            roomId: finalRoomId,
            callType: callType,
            agentId: widget.realAgentId,
            isUserCaller: false,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Call accept failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _rejectCall(String roomId) async {
    if (roomId.isEmpty) return;

    try {
      // Database mein room status update karein taaki user aur agent dono taraf sync ho jaye
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'status': 'ended',
        'endedBy': 'agent_rejected',
        'disconnectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error rejecting room $roomId: $e");
    }

    final endResult = await CallApiService.endCall(
      roomId: roomId,
      customAgentId: widget.realAgentId,
    );

    debugPrint("PRINT End/Reject Call API Response -> $endResult");
  }

  Future<bool> _onWillPop() async {
    if (_isLeavingInProgress) return false;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Leave Call Screen?"),
        content: const Text(
          "Kya aap is screen ko chhodna chahte hain? Aisa karne se aapki ringing requests clear ho jayengi.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Yes, Leave",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      setState(() {
        _isLeavingInProgress = true;
      });
      await _resetAgentStatusOnExit();
      return true;
    }
    return false;
  }

  Future<void> _resetAgentStatusOnExit() async {
    try {
      final resetResult = await CallApiService.resetAgentState(
        widget.realAgentId,
      );
      debugPrint("PRINT Reset Agent State API Response -> $resetResult");

      await FirebaseFirestore.instance
          .collection('active_calls')
          .doc(widget.realAgentId)
          .delete()
          .catchError((_) {});

      // Agent ke exit hone par uske saare ringing rooms ko missed/ended mark kar dein
      final ringingRoomsQuery = await FirebaseFirestore.instance
          .collection('rooms')
          .where('participants.agentId', isEqualTo: widget.realAgentId)
          .where('status', isEqualTo: 'ringing')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in ringingRoomsQuery.docs) {
        batch.update(doc.reference, {
          'status': 'ended',
          'endedBy': 'agent_left_screen',
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error resetting agent status: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLeavingInProgress = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _incomingCallsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Agent Incoming Requests"),
          backgroundColor: Colors.indigo,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pendingCalls.isEmpty
            ? const Center(
                child: Text(
                  "No incoming call requests right now.\nWaiting for calls...",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: _pendingCalls.length,
                itemBuilder: (context, index) {
                  final call = _pendingCalls[index];
                  final roomId = call['roomId'] ?? '';
                  final userName = call['userName'] ?? 'Unknown User';
                  final callType = call['callType'] ?? 'video';
                  final avatarUrl = call['avatarUrl'] ?? '';
                  final topic = call['topic'] ?? 'General';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 35,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Type: ${callType.toUpperCase()} | Topic: $topic",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _rejectCall(roomId),
                                      icon: const Icon(
                                        Icons.call_end,
                                        size: 16,
                                      ),
                                      label: const Text("Reject"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _acceptCall(roomId, callType),
                                      icon: const Icon(Icons.call, size: 16),
                                      label: const Text("Accept"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
