import 'dart:async';

import 'package:flutter/material.dart';

import '../services/aqua_firebase_service.dart';
import '../services/gemini_chat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final AquaFirebaseService _firebaseService = AquaFirebaseService();
  final GeminiChatService _geminiService = GeminiChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final StreamSubscription<List<AquaChatMessage>> _messageSubscription;

  List<AquaChatMessage> _messages = _welcomeMessages;
  bool _isLoadingMessages = true;
  bool _isSending = false;
  String? _chatError;

  static List<AquaChatMessage> get _welcomeMessages {
    return [
      AquaChatMessage.localAssistant(
        'Chào bạn! Tôi là Aqua AI, trợ lý ảo chuyên gia thủy sản của bạn.',
      ),
      AquaChatMessage.localAssistant(
        'Bạn có thể hỏi về nhiệt độ, pH, tình trạng tôm, bơm nóng/lạnh hoặc cách xử lý ao. Tôi sẽ dùng dữ liệu Firebase hiện tại để tư vấn sát hơn.',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _messageSubscription = _firebaseService.watchChatMessages().listen(
      (messages) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoadingMessages = false;
          _chatError = null;
          _messages = messages.isEmpty ? _welcomeMessages : messages;
        });
        _scrollToBottom();
      },
      onError: (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoadingMessages = false;
          _chatError = 'Chưa đọc được lịch sử chat từ Firebase.';
          _messages = _welcomeMessages;
        });
      },
    );
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    _geminiService.close();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitted(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) {
      return;
    }

    _textController.clear();

    if (!_geminiService.isConfigured) {
      setState(() {
        _messages = [
          ..._messages,
          AquaChatMessage.localAssistant(
            'Chưa cấu hình Gemini API key. Chạy app bằng:\nflutter run --dart-define=GEMINI_API_KEY=API_KEY_CUA_BAN\n\nKhi build APK:\nflutter build apk --release --dart-define=GEMINI_API_KEY=API_KEY_CUA_BAN',
          ),
        ];
      });
      _scrollToBottom();
      return;
    }

    final userMessage = AquaChatMessage.user(trimmed);
    final historyForGemini = [
      ..._messages.where((message) => !message.isLocal),
      userMessage,
    ];

    setState(() {
      _isSending = true;
      _chatError = null;
    });
    _scrollToBottom();

    try {
      await _firebaseService.saveChatMessage(userMessage);
      final pondData = await _firebaseService.readRealtimeDataOnce();
      final reply = await _geminiService.generateReply(
        recentMessages: historyForGemini,
        pondData: pondData,
      );
      await _firebaseService.saveChatMessage(AquaChatMessage.assistant(reply));
    } catch (error) {
      final errorMessage = AquaChatMessage.assistant(_friendlyError(error));
      try {
        await _firebaseService.saveChatMessage(errorMessage);
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _messages = [..._messages, errorMessage];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  String _friendlyError(Object error) {
    if (error is GeminiChatException) {
      return error.message;
    }
    if (error is TimeoutException) {
      return 'Gemini phản hồi hơi lâu. Bạn thử gửi lại câu hỏi nhé.';
    }
    return 'Mình chưa gọi được Gemini hoặc Firebase lúc này. Bạn kiểm tra mạng, API key và quyền Realtime Database nhé.';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_chatError != null) _buildErrorBanner(_chatError!),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  itemCount: _messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _buildTypingBubble();
                    }
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),
              _buildSuggestions(),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final statusColor = _geminiService.isConfigured
        ? AppTheme.emerald
        : AppTheme.warmAmber;
    final statusText = _geminiService.isConfigured
        ? 'Gemini + Firebase'
        : 'Cần API key Gemini';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: AppTheme.textDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0072FF).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aqua AI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _isLoadingMessages ? 'Đang tải lịch sử' : statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.2,
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
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warmAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warmAmber.withValues(alpha: 0.22)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppTheme.textDark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AquaChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            _buildAssistantAvatar(),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: message.isUser ? AppTheme.deepNavy : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: Radius.circular(message.isUser ? 24 : 6),
                  bottomRight: Radius.circular(message.isUser ? 6 : 24),
                ),
                border: message.isUser
                    ? null
                    : Border.all(color: Colors.black.withValues(alpha: 0.03)),
                boxShadow: [
                  BoxShadow(
                    color: message.isUser
                        ? AppTheme.deepNavy.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: message.isUser
                      ? FontWeight.w500
                      : FontWeight.w400,
                  color: message.isUser ? Colors.white : AppTheme.textDark,
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: AppTheme.textMuted,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAssistantAvatar(),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(24),
              ),
              border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'Aqua AI đang trả lời...',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantAvatar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0072FF).withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      'Nhiệt độ nước cao?',
      'Bệnh phân trắng ở tôm',
      'Đánh giá chất lượng nước',
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _isSending
                    ? null
                    : () => _handleSubmitted(suggestions[index]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: _isSending ? 0.55 : 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF0072FF).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    suggestions[index],
                    style: TextStyle(
                      color: const Color(
                        0xFF0072FF,
                      ).withValues(alpha: _isSending ? 0.45 : 1),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  enabled: !_isSending,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: _isSending
                        ? 'Đang chờ Aqua AI...'
                        : 'Hỏi trợ lý Aqua AI...',
                    hintStyle: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onSubmitted: _handleSubmitted,
                ),
              ),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: _isSending
                  ? null
                  : () => _handleSubmitted(_textController.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: _isSending
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: _isSending ? const Color(0xFFE6EDF5) : null,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0072FF).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isSending ? Icons.hourglass_top : Icons.send_rounded,
                  color: _isSending ? AppTheme.textMuted : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
