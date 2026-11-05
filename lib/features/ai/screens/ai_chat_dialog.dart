import 'package:flutter/material.dart';
import '../services/ai_service.dart'; // Sửa đúng đường dẫn ra ngoài thư mục screens để vào thư mục ai

class AiChatDialog extends StatefulWidget {
  final VoidCallback onClose;

  const AiChatDialog({super.key, required this.onClose});

  @override
  State<AiChatDialog> createState() => _AiChatDialogState();
}

class _AiChatDialogState extends State<AiChatDialog> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final AiService _aiService = AiService();

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();

    try {
      final response = await _aiService.processTaskWithAI(text);
      setState(() {
        if (response != null && response['data'] != null) {
          final data = response['data'];
          _messages.add({
            'sender': 'ai',
            'text':
            "🤖 **Đã phân tích task thành công!**\n\n📌 **Tiêu đề:** ${data['title']}\n📝 **Mô tả:** ${data['description'] ?? 'Không có'}\n⚡ **Độ ưu tiên:** ${data['priority']}"
          });
        } else {
          _messages.add({
            'sender': 'ai',
            'text': '❌ Không thể phân tích phản hồi từ AI.'
          });
        }
      });
    } catch (e) {
      setState(() {
        _messages.add({'sender': 'ai', 'text': '❌ Lỗi kết nối server backend!'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, size: 20, color: Colors.purpleAccent),
            SizedBox(width: 8),
            Text('AI Assistant', style: TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: widget.onClose,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment:
                  isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style:
                      const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Hỏi AI hoặc nhập task...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}