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
    final provider = context.read<ChatProvider>();
    provider.listenToMessages(id);
    provider.markAsRead(id);
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
    final isMobile = MediaQuery.of(context).size.width < 768;

    // Trigger scroll to bottom on message list update
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    Widget buildConversationsList() {
      return GlassCard(
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
                    final customName = chatProvider.conversationNames[id];
                    final displayName = customName != null && customName.isNotEmpty
                        ? customName
                        : id.replaceAll('chat_', 'Khách ');
                    final unreadCount = chatProvider.unreadCounts[id] ?? 0;
                    final hasUnread = unreadCount > 0;

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
                        title: Text(
                          displayName,
                          style: AppTextStyles.label.copyWith(
                            fontWeight: hasUnread ? FontWeight.w900 : (isSelected ? FontWeight.w600 : FontWeight.w500),
                            color: hasUnread ? AppColors.textPrimary : null,
                          ),
                        ),
                        subtitle: Text(
                          hasUnread ? 'Có tin nhắn mới chưa đọc' : 'Xem tin nhắn hỗ trợ',
                          style: AppTextStyles.caption.copyWith(
                            color: hasUnread ? AppColors.primaryDark : null,
                            fontWeight: hasUnread ? FontWeight.w600 : null,
                          ),
                        ),
                        trailing: hasUnread
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () => _selectConversation(id),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    }

    Widget buildActiveChat() {
      // Mark as read when active chat builds/receives new messages
      if (_selectedConversationId != null && (chatProvider.unreadCounts[_selectedConversationId] ?? 0) > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          chatProvider.markAsRead(_selectedConversationId!);
        });
      }

      return GlassCard(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isMobile) ...[
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                            onPressed: () {
                              setState(() {
                                _selectedConversationId = null;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            chatProvider.conversationNames[_selectedConversationId] != null &&
                                    chatProvider.conversationNames[_selectedConversationId]!.isNotEmpty
                                ? 'Hỗ trợ: ${chatProvider.conversationNames[_selectedConversationId]}'
                                : _selectedConversationId!.replaceAll('chat_', 'Hỗ trợ Khách hàng: '),
                            style: AppTextStyles.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                              tooltip: 'Đổi tên cuộc hội thoại',
                              onPressed: () => _showRenameDialog(context, chatProvider, _selectedConversationId!),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 20),
                              tooltip: 'Xóa cuộc hội thoại',
                              onPressed: () => _showDeleteDialog(context, chatProvider, _selectedConversationId!),
                            ),
                          ],
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
      );
    }

    return AdminLayout(
      currentPath: '/admin/chat',
      title: 'Quản lý Chat hỗ trợ',
      child: isMobile
          ? (_selectedConversationId == null
              ? buildConversationsList()
              : buildActiveChat())
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left panel: Conversations list
                Expanded(
                  flex: 3,
                  child: buildConversationsList(),
                ),
                const SizedBox(width: 24),
                // Right panel: Active chat window
                Expanded(
                  flex: 5,
                  child: buildActiveChat(),
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

  void _showRenameDialog(BuildContext context, ChatProvider provider, String conversationId) {
    final currentName = provider.conversationNames[conversationId] ?? '';
    final controller = TextEditingController(text: currentName.isEmpty ? conversationId.replaceAll('chat_', 'Khách ') : currentName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đổi tên cuộc hội thoại'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhập tên gợi nhớ (chỉ hiện ở admin)...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                try {
                  await provider.renameConversation(conversationId, newName);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã đổi tên cuộc hội thoại thành công!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: Hãy chắc chắn bạn đã cập nhật và publish firestore.rules lên Firebase Console. Chi tiết: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ChatProvider provider, String conversationId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa cuộc hội thoại'),
        content: const Text('Hành động này sẽ xóa vĩnh viễn tất cả tin nhắn trong cuộc hội thoại này. Bạn có chắc chắn muốn tiếp tục?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Close dialog first
                Navigator.pop(dialogContext);
                
                final targetId = conversationId;
                setState(() {
                  _selectedConversationId = null;
                });
                
                await provider.deleteConversation(targetId);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa cuộc hội thoại thành công!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi xóa cuộc hội thoại: $e. Hãy kiểm tra lại cấu hình phân quyền Firestore.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
