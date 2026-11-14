import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Anubis chat application UI for ProjectX Launcher.
///
/// Before running:
/// 1. Add `http: ^1.2.2` (or a compatible current version) to pubspec.yaml.
/// 2. Replace [apiBaseUrl] with your deployed HTTPS backend URL.
/// 3. Keep XAI_API_KEY on the backend only; never put it in this app.
const String apiBaseUrl = 'https://YOUR-ANUBIS-SERVER.example.com';

void main() {
  runApp(const AnubisApp());
}

class AnubisApp extends StatelessWidget {
  const AnubisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProjectX · Anubis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF26C6DA),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF080D16),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF121B2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const AnubisChatPage(),
    );
  }
}

class AnubisChatPage extends StatefulWidget {
  const AnubisChatPage({super.key});

  @override
  State<AnubisChatPage> createState() => _AnubisChatPageState();
}

class _AnubisChatPageState extends State<AnubisChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = <ChatMessage>[
    const ChatMessage(
      text: 'Anubis está preparado. ¿En qué puedo ayudarte?',
      isUser: false,
    ),
  ];

  bool _isSending = false;

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isSending = true;
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      final uri = Uri.parse('$apiBaseUrl/chat');
      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'message': text}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception('El servidor respondió ${response.statusCode}.');
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> ||
          decoded['response'] is! String) {
        throw const FormatException('Respuesta del servidor no válida.');
      }

      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            text: decoded['response'] as String,
            isUser: false,
          ),
        );
      });
    } on FormatException {
      _addError('La respuesta recibida no tiene el formato esperado.');
    } on http.ClientException {
      _addError('No se pudo conectar con Anubis. Comprueba la dirección API.');
    } on Exception catch (error) {
      _addError('No se pudo completar la consulta: $error');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _addError(String message) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: message, isUser: false, isError: true));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1522),
        titleSpacing: 16,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFF123B48),
              child: Icon(Icons.shield_moon, color: Color(0xFF67E8F9)),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANUBIS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'PROJECTX OS · AI ENGINE',
                  style: TextStyle(fontSize: 10, color: Colors.white60),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Estado del servidor',
            onPressed: _checkHealth,
            icon: const Icon(Icons.wifi_tethering),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _MessageBubble(message: _messages[index]);
                },
              ),
            ),
            if (_isSending)
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Anubis está procesando…',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1522),
        border: Border(top: BorderSide(color: Color(0xFF1D2A3D))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje para Anubis…',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              ),
            ),
          ),
          const SizedBox(width: 9),
          IconButton.filled(
            onPressed: _isSending ? null : _sendMessage,
            icon: const Icon(Icons.arrow_upward),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF0891B2),
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl/health'))
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;

      final ok = response.statusCode == 200;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Anubis API responde correctamente.' : 'API no disponible.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo contactar con Anubis API.')),
      );
    }
  }
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });

  final String text;
  final bool isUser;
  final bool isError;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final background = message.isUser
        ? const Color(0xFF075985)
        : message.isError
            ? const Color(0xFF54252B)
            : const Color(0xFF152235);

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: message.isUser
                ? const Color(0xFF0E7490)
                : const Color(0xFF26364D),
          ),
        ),
        child: SelectableText(
          message.text,
          style: TextStyle(
            color: message.isError ? const Color(0xFFFFCDD2) : Colors.white,
            height: 1.4,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
