import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Represents a single chat message that can be rendered in the UI.
class ChatMessage {
  ChatMessage({
    required this.text,
    required this.timestamp,
    required this.isMine,
  });

  final String text;
  final DateTime timestamp;
  final bool isMine;
}

/// Controller that owns the chat state and WebSocket lifecycle.
class ChatController extends ChangeNotifier {
  ChatController({required String endpoint}) : _endpoint = endpoint {
    inputController.addListener(_handleTextChanged);
  }

  final TextEditingController inputController = TextEditingController();
  final List<ChatMessage> _messages = <ChatMessage>[];
  UnmodifiableListView<ChatMessage> get messages => UnmodifiableListView<ChatMessage>(_messages);

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  String _endpoint;
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _error;
  bool _canSend = false;

  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  bool get canSend => _canSend;
  String? get error => _error;
  String get endpoint => _endpoint;

  /// Initiates a connection to the current WebSocket endpoint.
  Future<void> connect() async {
    _setStatus(isConnecting: true, isConnected: false, error: null);

    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;

    try {
      final WebSocketChannel channel = _createChannel(_endpoint);
      _subscription = channel.stream.listen(
        (dynamic event) {
          if (event == null) {
            return;
          }
          _messages.insert(
            0,
            ChatMessage(
              text: event.toString(),
              timestamp: DateTime.now(),
              isMine: false,
            ),
          );
          notifyListeners();
        },
        onDone: () {
          _channel = null;
          _setStatus(isConnecting: false, isConnected: false);
        },
        onError: (Object error, StackTrace _) {
          _channel = null;
          _setStatus(isConnecting: false, isConnected: false, error: error.toString());
        },
        cancelOnError: true,
      );

      _channel = channel;
      _setStatus(isConnecting: false, isConnected: true, error: null);
    } catch (Object error, StackTrace _) {
      _channel = null;
      _setStatus(
        isConnecting: false,
        isConnected: false,
        error: error.toString(),
      );
    }
  }

  /// Attempts to send the message currently stored in [inputController].
  ///
  /// Returns `true` when the message was queued for delivery, otherwise `false`.
  bool sendCurrentMessage() {
    if (!_canSend || !_isConnected || _channel == null) {
      return false;
    }

    final String text = inputController.text.trim();
    if (text.isEmpty) {
      return false;
    }

    inputController.clear();
    _canSend = false;
    _messages.insert(
      0,
      ChatMessage(
        text: text,
        timestamp: DateTime.now(),
        isMine: true,
      ),
    );
    _channel!.sink.add(text);
    notifyListeners();
    return true;
  }

  /// Changes the WebSocket endpoint and reconnects if needed.
  Future<void> changeEndpoint(String nextEndpoint) async {
    if (nextEndpoint.isEmpty || nextEndpoint == _endpoint) {
      return;
    }
    _endpoint = nextEndpoint;
    notifyListeners();
    await connect();
  }

  /// Cancels the active WebSocket subscription and closes the socket.
  Future<void> disconnect() async {
    _setStatus(isConnecting: false, isConnected: false);
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }

  void _handleTextChanged() {
    final bool nextValue = inputController.text.trim().isNotEmpty;
    if (_canSend != nextValue) {
      _canSend = nextValue;
      notifyListeners();
    }
  }

  void _setStatus({bool? isConnecting, bool? isConnected, String? error}) {
    bool shouldNotify = false;

    if (isConnecting != null && _isConnecting != isConnecting) {
      _isConnecting = isConnecting;
      shouldNotify = true;
    }
    if (isConnected != null && _isConnected != isConnected) {
      _isConnected = isConnected;
      shouldNotify = true;
    }
    if (_error != error) {
      _error = error;
      shouldNotify = true;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    inputController.removeListener(_handleTextChanged);
    unawaited(_subscription?.cancel());
    _channel?.sink.close();
    inputController.dispose();
    super.dispose();
  }

  WebSocketChannel _createChannel(String url) {
    final Uri uri = Uri.parse(url);
    if (kIsWeb) {
      return WebSocketChannel.connect(uri);
    }
    return IOWebSocketChannel.connect(uri.toString());
  }
}
