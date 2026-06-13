import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/glass_card.dart';


final _timeFormat = DateFormat('HH:mm');

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _conversationId;
  bool _showNotificationBanner = false;
  bool _isRequestingPermission = false;
  String _permissionState = 'default';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      _conversationId = chatProvider.userConversationId;
      chatProvider.listenToMessages(_conversationId);
      _checkNotificationPermission();
    });
  }

  Future<void> _checkNotificationPermission() async {
    bool shouldShowBanner = false;
    String state = 'default';
    try {
      // 1. Thử kiểm tra bằng Web API trước vì chính xác nhất trên trình duyệt web
      try {
        final permission = web.Notification.permission;
        print('FCM: Trạng thái quyền native: $permission');
        state = permission;
        if (permission == 'default') {
          shouldShowBanner = true;
        } else if (permission == 'granted') {
          shouldShowBanner = false;
          NotificationService().initNotifications(conversationId: _conversationId);
        } else {
          // 'denied'
          shouldShowBanner = true;
        }
      } catch (e) {
        // 2. Nếu không hỗ trợ native API (ví dụ trên iOS Safari cũ), fallback qua Firebase Messaging
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        print('FCM: Trạng thái quyền Firebase: ${settings.authorizationStatus}');
        if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
          state = 'default';
          shouldShowBanner = true;
        } else if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          state = 'granted';
          shouldShowBanner = false;
          NotificationService().initNotifications(conversationId: _conversationId);
        } else {
          state = 'denied';
          shouldShowBanner = true;
        }
      }
    } catch (e) {
      print('FCM ERROR inside _checkNotificationPermission: $e');
    }

    if (mounted) {
      setState(() {
        _permissionState = state;
        _showNotificationBanner = shouldShowBanner;
      });
    }
  }

  /// Xin quyền thông báo bằng Web API gốc (đảm bảo popup hiện ra trong user gesture)
  Future<void> _requestNotificationPermission() async {
    if (_isRequestingPermission) return;
    setState(() {
      _isRequestingPermission = true;
    });

    try {
      String permissionResult = 'default';
      // 1. Thử xin quyền bằng Web API trực tiếp trước
      try {
        final result = await web.Notification.requestPermission().toDart;
        permissionResult = result.toDart;
        print('FCM: Kết quả xin quyền trình duyệt: $permissionResult');
      } catch (e) {
        print('FCM: Không thể xin quyền qua Web API native, thử dùng Firebase: $e');
        // 2. Thử dùng Firebase Messaging requestPermission làm phương án dự phòng (iOS PWA)
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          permissionResult = 'granted';
        } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
          permissionResult = 'denied';
        }
      }

      if (permissionResult == 'granted') {
        // Quyền đã được cấp, lấy FCM token
        await NotificationService().initNotifications(conversationId: _conversationId);
        if (mounted) {
          setState(() {
            _permissionState = 'granted';
            _showNotificationBanner = false;
          });
        }
      } else if (permissionResult == 'denied') {
        // Người dùng từ chối — đổi trạng thái banner để hiển thị hướng dẫn mở thủ công
        if (mounted) {
          setState(() {
            _permissionState = 'denied';
            _showNotificationBanner = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Bạn đã từ chối thông báo. Vui lòng bật lại trong phần cài đặt trình duyệt.'),
              backgroundColor: AppColors.primaryDark,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('FCM ERROR during _requestNotificationPermission: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPermission = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppTheme.animFast,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    // Trigger scroll to bottom when messages list updates
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Spacing for Floating Navbar
            const SizedBox(height: AppTheme.navbarHeight + 16),

            // Chat Header
            Container(
              padding: const EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 64),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    radius: 20,
                    child: const Icon(Icons.local_florist, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hỗ trợ Flower Shop', style: AppTextStyles.label),
                      Text('Flower Shop sẽ trả lời bạn sớm nhất nha!', style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_showNotificationBanner) ...[
              Container(
                margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 64),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _permissionState == 'denied'
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.primaryLight.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: _permissionState == 'denied'
                        ? AppColors.error.withValues(alpha: 0.3)
                        : AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _permissionState == 'denied'
                          ? Icons.warning_amber_rounded
                          : Icons.notifications_active,
                      color: _permissionState == 'denied' ? AppColors.error : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _permissionState == 'denied'
                            ? 'Bạn đã chặn thông báo. Vui lòng bấm vào biểu tượng ổ khóa ở đầu thanh địa chỉ trình duyệt để bật lại nhé!'
                            : 'Bật thông báo để nhận phản hồi kịp thời của shop nhé.',
                        style: AppTextStyles.caption.copyWith(
                          color: _permissionState == 'denied' ? AppColors.error : AppColors.primaryDark,
                          fontWeight: _permissionState == 'denied' ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_permissionState != 'denied')
                      TextButton(
                        onPressed: _isRequestingPermission ? null : _requestNotificationPermission,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          backgroundColor: _isRequestingPermission ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                        ),
                        child: _isRequestingPermission
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Bật ngay',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Message List
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 64),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: chatProvider.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : chatProvider.messages.isEmpty
                          ? _buildEmptyChat()
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: chatProvider.messages.length,
                              itemBuilder: (context, index) {
                                final msg = chatProvider.messages[index];
                                final isMe = msg.senderId != 'admin';
                                return _buildMessageBubble(msg, isMe);
                              },
                            ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Message Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              margin: EdgeInsets.only(
                left: isMobile ? 16 : 64,
                right: isMobile ? 16 : 64,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: TextField(
                        controller: _messageController,
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn đến Flower Shop...',
                          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textLight),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'Bắt đầu cuộc trò chuyện với Flower Shop!',
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy gửi tin nhắn, chúng tôi sẽ phản hồi bạn sớm nhất.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.only(bottom: 4, top: 4),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Text(
              msg.message,
              style: AppTextStyles.body.copyWith(
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 0 : 4,
              right: isMe ? 4 : 0,
              bottom: 8,
            ),
            child: Text(
              _timeFormat.format(msg.createdAt),
              style: AppTextStyles.caption.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendMessage(_conversationId, _conversationId, text);
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
