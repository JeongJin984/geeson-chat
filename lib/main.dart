import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'chat_controller.dart';

const _defaultEndpoint = 'wss://echo.websocket.events';

class Friend {
  Friend({required this.name, required this.statusMessage});

  final String name;
  final String statusMessage;
}

class ChatRoom {
  ChatRoom({
    required this.id,
    required this.name,
    required this.endpoint,
  });

  final String id;
  final String name;
  final String endpoint;
}

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
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);
  final GlobalKey<FormState> _roomFormKey = GlobalKey<FormState>();
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _roomEndpointController = TextEditingController(text: _defaultEndpoint);

  final List<Friend> _friends = <Friend>[
    Friend(name: '홍길동', statusMessage: '밥 먹고 있어요'),
    Friend(name: '김지은', statusMessage: '곧 연락드릴게요'),
    Friend(name: 'Alex Kim', statusMessage: 'Working remotely'),
  ];

  final List<ChatRoom> _rooms = <ChatRoom>[
    ChatRoom(
      id: 'default-room',
      name: 'Geeson 채팅방',
      endpoint: _defaultEndpoint,
    ),
  ];

  @override
  void dispose() {
    _tabController.dispose();
    _roomNameController.dispose();
    _roomEndpointController.dispose();
    super.dispose();
  }

  void _addFriend(Friend friend) {
    setState(() {
      _friends.add(friend);
    });
  }

  void _removeFriend(Friend friend) {
    setState(() {
      _friends.remove(friend);
    });
  }

  void _createRoom() {
    final FormState? state = _roomFormKey.currentState;
    if (state == null || !state.validate()) {
      return;
    }

    final ChatRoom room = ChatRoom(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _roomNameController.text.trim(),
      endpoint: _roomEndpointController.text.trim(),
    );

    setState(() {
      _rooms.add(room);
    });

    _roomNameController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${room.name}" 방이 생성되었습니다.')),
    );

    _tabController.animateTo(2);
  }

  void _openChat(ChatRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ChatPage(room: room),
      ),
    );
  }

  Future<void> _showAddFriendDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController statusController = TextEditingController();

    final Friend? newFriend = await showDialog<Friend>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('친구 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '이름'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: statusController,
                decoration: const InputDecoration(labelText: '상태 메시지'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final String name = nameController.text.trim();
                if (name.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(
                  Friend(
                    name: name,
                    statusMessage: statusController.text.trim(),
                  ),
                );
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );

    if (newFriend != null) {
      _addFriend(newFriend);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: const <Widget>[
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.black87,
              child: Text(
                'K',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'KakaoTalk 스타일 채팅',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black87,
          tabs: const <Tab>[
            Tab(text: '친구'),
            Tab(text: '채팅방 만들기'),
            Tab(text: '채팅방 참가'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _FriendsTab(
            friends: _friends,
            onRemove: _removeFriend,
          ),
          _CreateRoomTab(
            formKey: _roomFormKey,
            roomNameController: _roomNameController,
            endpointController: _roomEndpointController,
            onCreateRoom: _createRoom,
          ),
          _JoinRoomTab(
            rooms: _rooms,
            onJoinRoom: _openChat,
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (BuildContext context, _) {
          final int tabIndex = _tabController.index;
          if (tabIndex != 0) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            backgroundColor: const Color(0xFFFEE500),
            foregroundColor: Colors.black,
            onPressed: _showAddFriendDialog,
            child: const Icon(Icons.person_add_alt_1),
          );
        },
      ),
    );
  }
}

class _FriendsTab extends StatelessWidget {
  const _FriendsTab({required this.friends, required this.onRemove});

  final List<Friend> friends;
  final void Function(Friend friend) onRemove;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return const _EmptyState(
        icon: Icons.person_outline,
        message: '등록된 친구가 없습니다.\n오른쪽 아래 버튼을 눌러 친구를 추가해 보세요!',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: friends.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (BuildContext context, int index) {
        final Friend friend = friends[index];
        return Dismissible(
          key: ValueKey<String>('friend-${friend.name}-$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            color: Colors.redAccent,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete_forever, color: Colors.white),
          ),
          onDismissed: (_) => onRemove(friend),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFEE500),
              foregroundColor: Colors.black87,
              child: Text(_initialFor(friend.name)),
            ),
            title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(friend.statusMessage.isEmpty ? '상태 메시지가 없습니다.' : friend.statusMessage),
            trailing: IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: '대화 시작',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${friend.name}님과의 대화방을 준비 중입니다.')),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CreateRoomTab extends StatelessWidget {
  const _CreateRoomTab({
    required this.formKey,
    required this.roomNameController,
    required this.endpointController,
    required this.onCreateRoom,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController roomNameController;
  final TextEditingController endpointController;
  final VoidCallback onCreateRoom;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '새로운 채팅방 만들기',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: roomNameController,
              decoration: const InputDecoration(
                labelText: '채팅방 이름',
                hintText: '예: 주말 여행 계획',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return '채팅방 이름을 입력해 주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: endpointController,
              decoration: const InputDecoration(
                labelText: 'WebSocket 주소',
                hintText: 'wss://example.com/socket',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'WebSocket 주소를 입력해 주세요.';
                }
                final Uri? uri = Uri.tryParse(value.trim());
                if (uri == null || (uri.scheme != 'ws' && uri.scheme != 'wss')) {
                  return 'ws:// 또는 wss:// 로 시작하는 주소여야 합니다.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onCreateRoom,
                child: const Text('채팅방 만들기'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '채팅방을 만들면 "채팅방 참가" 탭에서 바로 입장할 수 있습니다. KakaoTalk 스타일의 인터페이스로 손쉽게 대화를 즐겨보세요!',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinRoomTab extends StatelessWidget {
  const _JoinRoomTab({required this.rooms, required this.onJoinRoom});

  final List<ChatRoom> rooms;
  final void Function(ChatRoom room) onJoinRoom;

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return const _EmptyState(
        icon: Icons.meeting_room_outlined,
        message: '생성된 채팅방이 없습니다.\n"채팅방 만들기" 탭에서 새로운 방을 만들어 보세요!',
      );
    }

    return ListView.builder(
      itemCount: rooms.length,
      itemBuilder: (BuildContext context, int index) {
        final ChatRoom room = rooms[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFEE500),
              foregroundColor: Colors.black,
              child: Text('${index + 1}'),
            ),
            title: Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(room.endpoint),
            trailing: FilledButton(
              onPressed: () => onJoinRoom(room),
              child: const Text('입장'),
            ),
            onTap: () => onJoinRoom(room),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 72, color: Colors.black26),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }
}

String _initialFor(String name) {
  final String trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed.substring(0, 1).toUpperCase();
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.room});

  final ChatRoom room;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _controller = ChatController(endpoint: widget.room.endpoint);

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
                    'C',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      widget.room.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.room.endpoint,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
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
