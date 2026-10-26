// lib/features/ai/presentation/widgets/ai_floating_bubble.dart
import 'package:flutter/material.dart';
import '../../screens/ai_chat_dialog.dart';

class AiFloatingBubble extends StatefulWidget {
  const AiFloatingBubble({super.key});

  @override
  State<AiFloatingBubble> createState() => _AiFloatingBubbleState();
}

class _AiFloatingBubbleState extends State<AiFloatingBubble> {
  bool _isOpen = false;

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_isOpen)
          Positioned(
            right: 16,
            bottom: 80,
            width: 380,
            height: 520,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E), // Màu nền tối nổi bật, tách biệt hẳn với nền app để không bị trùng màu
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AiChatDialog(onClose: _toggleChat),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'ai_assistant_bubble',
            backgroundColor: Colors.purpleAccent,
            onPressed: _toggleChat,
            child: Icon(
              _isOpen ? Icons.close : Icons.auto_awesome,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}