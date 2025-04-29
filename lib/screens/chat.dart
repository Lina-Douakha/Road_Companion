import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;

  const ChatScreen({super.key, required this.receiverId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String senderId = "";

  void fetchCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        senderId = user.uid;
      });
    } else {
      print("No user logged in.");
    }
  }

  String? receiverProfilePhotoUrl;
  String receiverName = '';
  String receiverNumber = '';

  @override
  void initState() {
    super.initState();
    fetchCurrentUser();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    });

    _fetchReceiverData();
  }

  Future<void> _fetchReceiverData() async {
    try {
      final receiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverId)
          .get();

      if (receiverDoc.exists) {
        final data = receiverDoc.data();

        setState(() {
          // Safely check if ProfilePhoto exists and is not null
          receiverProfilePhotoUrl = data != null && data.containsKey('ProfilePhoto')
              ? receiverDoc['ProfilePhoto']
              : null;
          receiverName = receiverDoc['Name'] ?? '';
          receiverNumber = receiverDoc['Phone'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching receiver data: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _callClient(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone app')),
      );
    }
  }

  String _getChatId(String senderId, String receiverId) {
    return senderId.compareTo(receiverId) <= 0
        ? '${senderId}_${receiverId}'
        : '${receiverId}_${senderId}';
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      String chatId = _getChatId(senderId, widget.receiverId);

      FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'receiverId': widget.receiverId,
        'message': _controller.text,
        'timestamp': Timestamp.now(),
      }).then((_) {
        _controller.clear();
        _scrollToBottom();
      }).catchError((error) {
        print('Failed to send message: $error');
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _getProfileWidget(String name) {
    if (receiverProfilePhotoUrl != null && receiverProfilePhotoUrl!.isNotEmpty) {
      // If we have a profile photo URL, use it
      return CircleAvatar(
        backgroundImage: AssetImage(receiverProfilePhotoUrl!),
        radius: 18,
      );
    } else {
      // Otherwise, display the first letter of the user's name
      return CircleAvatar(
        backgroundColor: Colors.grey[400],
        radius: 18,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    }
  }

  Widget _getSmallProfileWidget(String name) {
    if (receiverProfilePhotoUrl != null && receiverProfilePhotoUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: AssetImage(receiverProfilePhotoUrl!),
        radius: 16,
      );
    } else {
      return CircleAvatar(
        backgroundColor: Colors.grey[400],
        radius: 16,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String chatId = _getChatId(senderId, widget.receiverId);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          ),
          onPressed: () {Navigator.pop(context);},
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 4),
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF00D47E), width: 2),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: _getProfileWidget(receiverName),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receiverName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.call_outlined),
              color: Color(0xFF00D47E),
              onPressed: () {
                _callClient(receiverNumber);
              },
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          image: DecorationImage(
            image: AssetImage('assets/chat_bg.png'),
            opacity: 0.05,
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _focusNode.unfocus(),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId)
                      .collection('messages')
                      .orderBy('timestamp')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D47E)),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(color: Colors.red[800]),
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_outlined,
                              size: 60,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Start the conversation by saying hi!',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final messages = snapshot.data!.docs;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12.0),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final doc = messages[index];
                        final message = doc['message'];
                        final sender = doc['senderId'];
                        final isMe = sender == senderId;
                        final timestamp = doc['timestamp'];

                        bool showDateHeader = false;
                        if (index == 0) {
                          showDateHeader = true;
                        } else {
                          final prevTimestamp = messages[index - 1]['timestamp'];
                          final prevDate = DateTime.fromMillisecondsSinceEpoch(
                              prevTimestamp is int ? prevTimestamp : prevTimestamp.seconds * 1000);
                          final currentDate = DateTime.fromMillisecondsSinceEpoch(
                              timestamp is int ? timestamp : timestamp.seconds * 1000);
                          showDateHeader = !isSameDay(prevDate, currentDate);
                        }

                        bool showAvatar = !isMe;

                        if (index < messages.length - 1 && !isMe) {
                          final nextSender = messages[index + 1]['senderId'];
                          if (nextSender == sender) {
                            showAvatar = false; // Only group receiver's messages
                          }
                        }
                        return Column(
                          children: [
                            if (showDateHeader)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatDate(timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                padding: EdgeInsets.only(
                                  right: isMe ? 8.0 : 0.0,
                                  left: isMe ? 0.0 : 8.0,
                                ),
                                margin: EdgeInsets.only(bottom: 2, top: showAvatar ? 12 : 2),
                                child: Row(
                                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isMe && showAvatar)
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        child: _getSmallProfileWidget(receiverName),
                                      ),
                                    if (!isMe && !showAvatar)
                                      SizedBox(width: 40),

                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth: MediaQuery.of(context).size.width * 0.65,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isMe ? Color(0xFF00D47E) : Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(18),
                                          topRight: Radius.circular(18),
                                          bottomLeft: isMe ? Radius.circular(18) : Radius.circular(4),
                                          bottomRight: isMe ? Radius.circular(4) : Radius.circular(18),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 3,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message,
                                            style: TextStyle(
                                              color: isMe ? Colors.white : Colors.black87,
                                              fontSize: 15,
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _formatTimestamp(timestamp),
                                                style: TextStyle(
                                                  color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey[500],
                                                  fontSize: 11,
                                                ),
                                              ),
                                              if (isMe) ...[
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.done_all,
                                                  size: 12,
                                                  color: Colors.white.withOpacity(0.7),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    if (isMe && showAvatar)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.transparent,
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // Input area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Text field with enhanced styling
                    Expanded(
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: 120,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),

                    // Send button with enhanced styling
                    Container(
                      margin: const EdgeInsets.only(left: 8, bottom: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF00D47E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  // Helper method to format date for headers
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    final DateTime dateTime = timestamp is int
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : DateTime.fromMillisecondsSinceEpoch(timestamp.seconds * 1000);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }
}