import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'chat_controller.dart';

const _defaultEndpoint = 'wss://echo.websocket.events';

void main() {
  runApp(const GeesonChatApp());
}

class GeesonChatApp extends StatelessWidget {
  const GeesonChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geeson Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFEE500),
          primary: const Color(0xFFFEE500),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F6F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFEE500),
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      home: const ChatPage(endpoint: _defaultEndpoint),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.endpoint});

  final String endpoint;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _controller = ChatController(endpoint: widget.endpoint);

  @override
  void initState() {
    super.initState();
    unawaited(_controller.connect());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final bool wasSent = _controller.sendCurrentMessage();
    if (wasSent) {
      FocusScope.of(context).unfocus();
      return;
    }
    if (!_controller.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버에 연결되어 있지 않습니다. 다시 연결해 주세요.')),
      );
    }
  }

  Future<void> _showChangeServerDialog() async {
    final TextEditingController controller = TextEditingController(text: _controller.endpoint);
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('서버 주소 변경'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'WebSocket URL',
              hintText: 'wss://example.com/socket',
            ),
            keyboardType: TextInputType.url,
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('적용'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null || result.isEmpty || result == _controller.endpoint) {
      return;
    }

    await _controller.changeEndpoint(result);
  }

  Widget _buildStatusBanner() {
    if (_controller.isConnecting) {
      return const _StatusBanner(
        color: Color(0xFFFFF0A3),
        icon: Icons.wifi_tethering,
        message: '서버에 연결하는 중입니다...',
        trailing: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_controller.error != null) {
      return _StatusBanner(
        color: const Color(0xFFFFCDD2),
        icon: Icons.error_outline,
        message: '연결 오류: ${_controller.error}',
        trailing: TextButton(
          onPressed: _controller.connect,
          child: const Text('다시 시도'),
        ),
      );
    }

    if (!_controller.isConnected) {
      return _StatusBanner(
        color: const Color(0xFFFFF0A3),
        icon: Icons.wifi_off,
        message: '연결이 끊어졌습니다. 다시 연결해 주세요.',
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _controller.isConnecting ? null : _controller.connect,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: <Widget>[
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.black87,
                  child: Text(
                    'G',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Text(
                      'Geeson 채팅방',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'WebSocket Live',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
            actions: <Widget>[
              IconButton(
                tooltip: '서버 변경',
                icon: const Icon(Icons.cloud_outlined),
                onPressed: _showChangeServerDialog,
              ),
              IconButton(
                tooltip: '재연결',
                icon: const Icon(Icons.refresh),
                onPressed: _controller.isConnecting ? null : _controller.connect,
              ),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                _buildStatusBanner(),
                Expanded(
                  child: _controller.messages.isEmpty
                      ? const _EmptyChatPlaceholder()
                      : ListView.builder(
                          reverse: true,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            20,
                            16,
                            20 + MediaQuery.of(context).padding.bottom,
                          ),
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: _controller.messages.length,
                          itemBuilder: (BuildContext context, int index) {
                            final ChatMessage message = _controller.messages[index];
                            return _MessageBubble(message: message);
                          },
                        ),
                ),
                _MessageInputBar(
                  controller: _controller.inputController,
                  isSendEnabled: _controller.canSend,
                  onSend: _handleSubmit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  static final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final bool isMine = message.isMine;
    final Alignment alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final Color bubbleColor = isMine ? const Color(0xFFFEE500) : Colors.white;
    final BorderRadius borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(22),
      topRight: const Radius.circular(22),
      bottomLeft: isMine ? const Radius.circular(22) : const Radius.circular(6),
      bottomRight: isMine ? const Radius.circular(6) : const Radius.circular(22),
    );
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxBubbleWidth = math.min(screenWidth * (isMine ? 0.68 : 0.78), 420);

    final Widget timeLabel = Text(
      _timeFormat.format(message.timestamp),
      style: TextStyle(
        fontSize: 11,
        color: isMine ? Colors.black54 : Colors.black45,
      ),
    );

    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.only(
          top: 6,
          bottom: 6,
          left: isMine ? 80 : 8,
          right: isMine ? 8 : 80,
        ),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                if (!isMine) ...<Widget>[
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black12,
                    ),
                    child: const Icon(Icons.person, size: 20, color: Colors.black45),
                  ),
                ],
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: borderRadius,
                        boxShadow: isMine
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: isMine ? Colors.black87 : Colors.black87,
                            height: 1.4,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                timeLabel,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  const _MessageInputBar({
    required this.controller,
    required this.isSendEnabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSendEnabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewPadding = MediaQuery.of(context).padding;
    final double viewInset = MediaQuery.of(context).viewInsets.bottom;
    final double resolvedBottomInset = math.max(viewInset - viewPadding.bottom, 0);
    final double baseBottomPadding = 16 + viewPadding.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: resolvedBottomInset),
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, baseBottomPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0x1F000000),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요',
                  filled: true,
                  fillColor: const Color(0xFFF2F2F2),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: isSendEnabled ? const Color(0xFFFEE500) : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded),
                color: Colors.black87,
                onPressed: isSendEnabled ? onSend : null,
                tooltip: '메시지 전송',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.color,
    required this.icon,
    required this.message,
    this.trailing,
  });

  final Color color;
  final IconData icon;
  final String message;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: color,
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _EmptyChatPlaceholder extends StatelessWidget {
  const _EmptyChatPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.black26),
          SizedBox(height: 16),
          Text(
            '아직 대화가 없습니다.\n메시지를 보내 대화를 시작해 보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
