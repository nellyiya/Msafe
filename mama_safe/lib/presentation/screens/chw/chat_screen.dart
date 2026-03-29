import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../models/mother_model.dart';
import '../../../providers/language_provider.dart';
import '../../../services/api_service.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
const _teal = Color(0xFF1A7A6E);
const _tealLight = Color(0xFFE8F5F3);
const _tealDark = Color(0xFF0F5A50);
const _navy = Color(0xFF1E2D4E);
const _white = Color(0xFFFFFFFF);
const _bgPage = Color(0xFFEDF2F1);
const _neuBase = Color(0xFFEDF2F1);
const _gray = Color(0xFF6B7280);
const _grayLight = Color(0xFFF3F4F6);
const _cardBorder = Color(0xFFE5E9E8);

/// Chat Screen for High-Risk Mother Referrals
class ChatScreen extends StatefulWidget {
  final MotherModel mother;
  final int referralId;

  const ChatScreen({
    super.key,
    required this.mother,
    required this.referralId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ApiService _apiService = ApiService();
  bool _isConnected = false;
  final bool _isTyping = false;
  int? _chatRoomId;
  bool _isLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _apiService.loadToken();
    await _connectToChat();
    await _loadChatHistory();
    setState(() => _isLoading = false);
    _scrollToBottom();
    // Poll every 4 seconds for new messages
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _pollMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pollMessages() async {
    if (_chatRoomId == null || !mounted) return;
    try {
      final messages = await _apiService.getChatMessages(_chatRoomId!);
      final newList = messages.map((msg) => ChatMessage(
        id: msg['id'].toString(),
        message: msg['message'],
        senderId: msg['sender_id'].toString(),
        senderName: msg['sender_name'] ?? 'Unknown',
        timestamp: DateTime.parse(msg['created_at']),
        isFromCurrentUser: msg['is_from_current_user'] ?? false,
      )).toList();
      // Only update if there are new messages
      if (newList.length != _messages.length) {
        setState(() {
          _messages.clear();
          _messages.addAll(newList);
        });
        _scrollToBottom();
      }
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
  Future<void> _connectToChat() async {

    try {
      print('🔗 Attempting to connect to chat...');
      final chatRoom = await _createOrGetChatRoom();
      _chatRoomId = chatRoom['id'];
      print('✅ Chat connected successfully. Room ID: $_chatRoomId');
      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      print('❌ Error connecting to chat: $e');
      setState(() {
        _isConnected = false;
        _chatRoomId = null;
      });
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _createOrGetChatRoom() async {
    try {
      // Parse mother ID safely
      int motherId;
      motherId = int.parse(widget.mother.id);
          
      print('📱 Creating chat room for mother $motherId with referral ${widget.referralId}');
      final chatRoom = await _apiService.createChatRoom(
        motherId: motherId,
        referralId: widget.referralId,
      );
      print('✅ Chat room created/retrieved: ${chatRoom['id']}');
      return chatRoom;
    } catch (e) {
      print('❌ Error creating chat room: $e');
      rethrow;
    }
  }

  Future<void> _loadChatHistory() async {
    if (_chatRoomId == null) return;
    
    try {
      print('📱 Loading chat history for room $_chatRoomId');
      final messages = await _apiService.getChatMessages(_chatRoomId!);
      
      setState(() {
        _messages.clear();
        _messages.addAll(messages.map((msg) => ChatMessage(
          id: msg['id'].toString(),
          message: msg['message'],
          senderId: msg['sender_id'].toString(),
          senderName: msg['sender_name'] ?? 'Unknown',
          timestamp: DateTime.parse(msg['created_at']),
          isFromCurrentUser: msg['is_from_current_user'] ?? false,
        )).toList());
      });
      
      print('✅ Loaded ${_messages.length} messages');
    } catch (e) {
      print('❌ Error loading chat history: $e');
    }
  }

  Future<void> _sendMessage() async {
    print('💬 Attempting to send message...');
    print('   Chat Room ID: $_chatRoomId');
    print('   Message: "${_messageController.text.trim()}"');
    print('   Is Connected: $_isConnected');
    
    if (_messageController.text.trim().isEmpty || _chatRoomId == null) {
      print('❌ Cannot send message: empty text or no chat room');
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // Add message to UI immediately for better UX
    final tempMessage = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      message: messageText,
      senderId: 'current_user',
      senderName: 'You',
      timestamp: DateTime.now(),
      isFromCurrentUser: true,
    );

    setState(() {
      _messages.add(tempMessage);
    });

    _scrollToBottom();

    // Send to API
    try {
      print('🚀 Sending message to API...');
      final savedMessage = await _apiService.sendChatMessage(
        roomId: _chatRoomId!,
        message: messageText,
      );
      
      print('✅ Message sent successfully: ${savedMessage['id']}');
      
      // Replace temp message with saved message (keep original timestamp)
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = ChatMessage(
            id: savedMessage['id'].toString(),
            message: savedMessage['message'],
            senderId: savedMessage['sender_id'].toString(),
            senderName: savedMessage['sender_name'] ?? 'You',
            timestamp: tempMessage.timestamp, // Keep the original timestamp
            isFromCurrentUser: true,
          );
        }
      });
      
      print('✅ Message saved to database');
    } catch (e) {
      print('❌ Error sending message: $e');
      // Remove temp message on error
      setState(() {
        _messages.removeWhere((m) => m.id == tempMessage.id);
      });
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isEnglish = languageProvider.isEnglish;

    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: _white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEnglish
                  ? 'Chat with Healthcare Professional'
                  : 'Ganira n\'umuganga',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.mother.fullName} - ${widget.mother.riskLevel} Risk',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showMotherInfo(context);
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mother info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _neuBase,
              border: Border(
                bottom: BorderSide(color: _teal.withOpacity(0.25), width: 1),
              ),
              boxShadow: [
                const BoxShadow(
                  color: Color(0xFFFFFFFF),
                  blurRadius: 6,
                  offset: Offset(-3, -3),
                ),
                BoxShadow(
                  color: const Color(0xFF1A7A6E).withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRiskColor(widget.mother.riskLevel),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.mother.riskLevel,
                    style: const TextStyle(
                      color: _white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEnglish
                        ? 'Age: ${widget.mother.age} • ${widget.mother.address}'
                        : 'Imyaka: ${widget.mother.age} • ${widget.mother.address}',
                    style: const TextStyle(
                      color: _tealDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _teal))
                : _messages.isEmpty
                    ? _buildEmptyState(isEnglish)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _neuBase,
              border: const Border(
                top: BorderSide(color: _cardBorder, width: 1),
              ),
              boxShadow: [
                const BoxShadow(
                  color: Color(0xFFFFFFFF),
                  blurRadius: 8,
                  offset: Offset(-4, -4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: isEnglish
                          ? 'Type your message...'
                          : 'Andika ubutumwa bwawe...',
                      hintStyle: const TextStyle(color: _gray),
                      filled: true,
                      fillColor: _neuBase,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: (_chatRoomId != null) ? _teal : _gray,
                    shape: BoxShape.circle,
                    boxShadow: [
                      const BoxShadow(
                        color: Color(0xFFFFFFFF),
                        blurRadius: 6,
                        offset: Offset(-3, -3),
                      ),
                      BoxShadow(
                        color: (_chatRoomId != null)
                            ? const Color(0xFF1A7A6E).withOpacity(0.30)
                            : Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: (_chatRoomId != null) ? _sendMessage : null,
                    icon: const Icon(
                      Icons.send,
                      color: _white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isEnglish) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _neuBase,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                const BoxShadow(
                  color: Color(0xFFFFFFFF),
                  blurRadius: 8,
                  offset: Offset(-4, -4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: _teal,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isEnglish
                ? 'Send message to healthcare professional'
                : 'Ohereza ubutumwa ku muganga',
            style: const TextStyle(
              color: _navy,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isEnglish
                ? 'Ask questions about ${widget.mother.fullName}\'s treatment and care'
                : 'Baza ibibazo bijyanye n\'ubuvuzi bwa ${widget.mother.fullName}',
            style: const TextStyle(
              color: _gray,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isFromCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isFromCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _neuBase,
              child: Text(
                message.senderName[0].toUpperCase(),
                style: const TextStyle(
                  color: _teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isFromCurrentUser ? _teal : _white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isFromCurrentUser ? 18 : 4),
                  bottomRight: Radius.circular(message.isFromCurrentUser ? 4 : 18),
                ),
                border: message.isFromCurrentUser
                    ? null
                    : Border.all(color: _teal.withOpacity(0.30), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: message.isFromCurrentUser
                        ? const Color(0xFF1A7A6E).withOpacity(0.25)
                        : const Color(0xFFFFFFFF),
                    blurRadius: 8,
                    offset: message.isFromCurrentUser
                        ? const Offset(3, 3)
                        : const Offset(-3, -3),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isFromCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: const TextStyle(
                          color: _teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: message.isFromCurrentUser ? _white : _navy,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isFromCurrentUser
                          ? _white.withOpacity(0.7)
                          : _gray,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isFromCurrentUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: _tealDark,
              child: Icon(
                Icons.person,
                color: _white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'medium':
      case 'mid':
        return const Color(0xFFD97706);
      case 'low':
        return _teal;
      default:
        return _gray;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 30) {
      return 'Now';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  void _showMotherInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _neuBase,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      const BoxShadow(
                        color: Color(0xFFFFFFFF),
                        blurRadius: 6,
                        offset: Offset(-3, -3),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 6,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pregnant_woman,
                    color: _teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.mother.fullName,
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Age: ${widget.mother.age} years',
                        style: const TextStyle(
                          color: _gray,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRiskColor(widget.mother.riskLevel),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.mother.riskLevel,
                    style: const TextStyle(
                      color: _white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.phone, 'Phone', widget.mother.phoneNumber),
            _buildInfoRow(Icons.location_on, 'Address', widget.mother.address),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: _teal, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              color: _gray,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _navy,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CHAT MESSAGE MODEL
// ─────────────────────────────────────────────
class ChatMessage {
  final String id;
  final String message;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final bool isFromCurrentUser;

  ChatMessage({
    required this.id,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.isFromCurrentUser,
  });
}