import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/widgets/glass_card.dart';
import '../widgets/admin_layout.dart';

final _timeFormat = DateFormat('HH:mm');

class AdminChatPage extends StatefulWidget {
  const AdminChatPage({super.key});

  @override
  State<AdminChatPage> createState() => _AdminChatPageState();
}

class _AdminChatPageState extends State<AdminChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedConversationId;

  @override
  void initState() {
    super.initState();
    // Auto-select the first conversation if list is loaded and not empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      if (chatProvider.adminConversations.isNotEmpty) {
        _selectConversation(chatProvider.adminConversations.first);
      }
    });
  }

  void _selectConversation(String id) {
    setState(() {
      _selectedConversationId = id;
    });
    context.read<ChatProvider>().listenToMessages(id);
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

    // Trigger scroll to bottom on message list update
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return AdminLayout(
      currentPath: '/admin/chat',
      title: 'Quản lý Chat hỗ trợ',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel: Conversations list
          Expanded(
            flex: 3,
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Các cuộc trò chuyện', style: AppTextStyles.h5),
                  const SizedBox(height: 16),
                  if (chatProvider.adminConversations.isEmpty)
                    const Expanded(child: Center(child: Text('Chưa có tin nhắn nào.')))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: chatProvider.adminConversations.length,
                        itemBuilder: (context, index) {
                          final id = chatProvider.adminConversations[index];
                          final isSelected = id == _selectedConversationId;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              selected: isSelected,
                              selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                              leading: CircleAvatar(
                                backgroundColor: isSelected ? AppColors.primary : Colors.grey[300],
                                child: Icon(Icons.person, color: isSelected ? Colors.white : Colors.grey[600]),
                              ),
                              title: Text(id.replaceAll('chat_', 'Khách '), style: AppTextStyles.label),
                              subtitle: const Text('Xem tin nhắn hỗ trợ'),
                              onTap: () => _selectConversation(id),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Right panel: Active chat window
          Expanded(
            flex: 5,
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: _selectedConversationId == null
                  ? const Center(child: Text('Vui lòng chọn một cuộc trò chuyện để bắt đầu trả lời.'))
                  : Column(
                      children: [
                        // Chat window header
                        Container(
                          padding: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3))),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _selectedConversationId!.replaceAll('chat_', 'Hỗ trợ Khách hàng: '),
                                style: AppTextStyles.label,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Chat list messages
                        Expanded(
                          child: chatProvider.isLoading
                              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                              : ListView.builder(
                                  controller: _scrollController,
                                  itemCount: chatProvider.messages.length,
                                  itemBuilder: (context, index) {
                                    final msg = chatProvider.messages[index];
                                    final isMe = msg.senderId == 'admin';
                                    return _buildMessageBubble(msg, isMe);
                                  },
                                ),
                        ),
                        const SizedBox(height: 16),
                        // Message input box
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                style: AppTextStyles.body,
                                decoration: InputDecoration(
                                  hintText: 'Nhập câu trả lời của admin...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                              onPressed: _sendMessage,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
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
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.symmetric(vertical: 4),
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
              style: AppTextStyles.body.copyWith(color: isMe ? Colors.white : AppColors.textPrimary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
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
    if (text.isEmpty || _selectedConversationId == null) return;

    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendMessage(_selectedConversationId!, 'admin', text);
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
