import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/curb_object.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/users_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final SocketService _socket = SocketService();
  final UsersService _usersService = UsersService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final String _currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? '';
  String _currentUserName = 'Usuario';

  List<ChatMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChat();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    final object =
        ModalRoute.of(context)?.settings.arguments as CurbObject?;
    if (object != null) {
      _socket.leaveObject(object.id);
    }
    _socket.off('newMessage');
    super.dispose();
  }

  Future<void> _initChat() async {
    final object =
        ModalRoute.of(context)?.settings.arguments as CurbObject?;
    if (object == null) return;

    // Load current user name
    try {
      final user = await _usersService.getMyProfile();
      if (user != null && mounted) {
        setState(() {
          _currentUserName =
              user.username.isNotEmpty ? user.username : user.name;
        });
      }
    } catch (_) {}

    // Load initial messages via REST
    try {
      final msgs = await _chatService.getMessages(object.id);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }

    // Join socket room and listen for new messages
    _socket.joinObject(object.id);
    _socket.on('newMessage', _onNewMessage);
  }

  void _onNewMessage(dynamic data) {
    if (!mounted) return;
    try {
      final Map<String, dynamic> json = Map<String, dynamic>.from(data as Map);
      final message = ChatMessage.fromJson(json);
      setState(() => _messages.add(message));
      _scrollToBottom();
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final object =
        ModalRoute.of(context)?.settings.arguments as CurbObject?;
    if (object == null) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    try {
      final sent = await _chatService.sendMessage(object.id, text);
      // Add locally only if not already received via socket
      if (mounted &&
          !_messages.any((m) => m.id == sent.id)) {
        setState(() => _messages.add(sent));
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al enviar mensaje: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final CurbObject? object =
        ModalRoute.of(context)?.settings.arguments as CurbObject?;

    if (object == null) {
      return const Scaffold(
          body: Center(child: Text('Error: No se encontró el objeto')));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat: ${object.title}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              object.status == CurbObjectStatus.onMyWay
                  ? 'En camino'
                  : 'Disponible',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF8A00)))
                : _messages.isEmpty
                    ? const Center(
                        child: Text('Sé el primero en escribir',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final bool isMe = msg.senderId == _currentUserId;
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFFF8A00) : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe
                ? const Radius.circular(0)
                : const Radius.circular(20),
            bottomLeft: isMe
                ? const Radius.circular(20)
                : const Radius.circular(0),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 5)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                '@${msg.senderName}',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
            Text(
              msg.text,
              style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFFFF8A00),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
