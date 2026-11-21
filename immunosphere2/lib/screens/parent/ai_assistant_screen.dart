/*import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_markdown/flutter_markdown.dart';

// Model definition for Chat Sessions
class ChatSession {
  final String id;
  String title;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
  });
}

class ChatMessage {
  final String? id; // Firestore document id (null until saved)
  final String text;
  final bool isUser;
  final String? imagePath;
  final Uint8List? imageBytes;
  final bool hasImage; // true if an image was attached, even after reload
  final DateTime time;

  ChatMessage({
    this.id,
    required this.text,
    required this.isUser,
    this.imagePath,
    this.imageBytes,
    bool? hasImage,
    DateTime? time,
  })  : hasImage = hasImage ?? (imageBytes != null),
        time = time ?? DateTime.now();
}

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  static const Color primaryGreen = Color(0xFF0E9F6E);

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  // Replace with your actual Google AI Studio API Key (starts with "AIzaSy...")
  static const String _apiKey = 'AQ.Ab8RN6JQJflSdhGMSkwu6eF2ctd4h3bVUJmTlVcqsKG_VIvoIw';

  late final GenerativeModel _model;
  ChatSession? _currentSession;
  final List<ChatSession> _allSessions = [];

  // ---- Firestore persistence ----
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _uid;
  bool _sessionsLoading = true;
  // --------------------------------

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // ---- Voice input ----
  late final stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  // ----------------------

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'You are ImmunoBot, the AI Health Assistant for ImmunoSphere app. '
        'Provide accurate, friendly, and helpful guidance regarding child vaccination schedules, '
        'immunization precautions, and general pediatric health. '
        'Always remind parents to consult a licensed medical doctor for serious symptoms or medical emergencies. '
        'You understand Urdu, Roman Urdu, and English fluently.',
      ),
    );

    _speech = stt.SpeechToText();
    _initSpeech();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    if (_uid == null) {
      // Not logged in — history won't persist across app restarts.
      debugPrint('No logged-in user; chat history will not be saved.');
      _startLocalOnlySession();
      if (mounted) setState(() => _sessionsLoading = false);
      return;
    }

    try {
      final sessionsSnap = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('chatSessions')
          .orderBy('createdAt', descending: true)
          .get();

      final List<ChatSession> loaded = [];
      for (final doc in sessionsSnap.docs) {
        final data = doc.data();
        final messagesSnap = await doc.reference
            .collection('messages')
            .orderBy('time')
            .get();

        final messages = messagesSnap.docs.map((m) {
          final md = m.data();
          return ChatMessage(
            id: m.id,
            text: (md['text'] ?? '') as String,
            isUser: (md['isUser'] ?? false) as bool,
            hasImage: (md['hasImage'] ?? false) as bool,
            time: (md['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList();

        loaded.add(ChatSession(
          id: doc.id,
          title: (data['title'] ?? 'New Conversation') as String,
          messages: messages,
        ));
      }

      if (!mounted) return;
      setState(() {
        _allSessions
          ..clear()
          ..addAll(loaded);
        _sessionsLoading = false;
      });

      if (_allSessions.isEmpty) {
        await _createNewChat();
      } else {
        setState(() => _currentSession = _allSessions.first);
      }
    } catch (e) {
      debugPrint('Failed to load chat history from Firestore: $e');
      _startLocalOnlySession();
      if (mounted) setState(() => _sessionsLoading = false);
    }
  }

  // Fallback used only when there's no logged-in user or Firestore fails.
  void _startLocalOnlySession() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newSession =
        ChatSession(id: newId, title: 'New Conversation', messages: []);
    _allSessions.insert(0, newSession);
    _currentSession = newSession;
  }

  Future<void> _persistMessage(ChatMessage msg) async {
    if (_uid == null || _currentSession == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('chatSessions')
          .doc(_currentSession!.id)
          .collection('messages')
          .add({
        'text': msg.text,
        'isUser': msg.isUser,
        'hasImage': msg.hasImage,
        'time': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to save message to Firestore: $e');
    }
  }

  Future<void> _updateSessionTitle(String sessionId, String title) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('chatSessions')
          .doc(sessionId)
          .update({'title': title});
    } catch (e) {
      debugPrint('Failed to update chat title in Firestore: $e');
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) {
            setState(() => _isListening = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Voice error: ${error.errorMsg}')),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('Speech init exception: $e');
      _speechAvailable = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      await _initSpeech();
    }

    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Microphone available nahi hai. Browser/device permission check karein.'),
          ),
        );
      }
      return;
    }

    try {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        localeId: 'en_US', // 'ur_PK' try kar sakti ho agar device support kare
      );
    } catch (e) {
      debugPrint('Listen exception: $e');
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice input start nahi ho saka: $e')),
        );
      }
    }
  }

  Future<void> _createNewChat() async {
    String newId;
    if (_uid != null) {
      try {
        final docRef = await _firestore
            .collection('users')
            .doc(_uid)
            .collection('chatSessions')
            .add({
          'title': 'New Conversation',
          'createdAt': FieldValue.serverTimestamp(),
        });
        newId = docRef.id;
      } catch (e) {
        debugPrint('Failed to create chat session in Firestore: $e');
        newId = DateTime.now().millisecondsSinceEpoch.toString();
      }
    } else {
      newId = DateTime.now().millisecondsSinceEpoch.toString();
    }

    final newSession = ChatSession(
      id: newId,
      title: 'New Conversation',
      messages: [],
    );

    if (!mounted) return;
    setState(() {
      _allSessions.insert(0, newSession);
      _currentSession = newSession;
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  Future<void> _deleteChat(String id) async {
    if (_uid != null) {
      try {
        final sessionRef = _firestore
            .collection('users')
            .doc(_uid)
            .collection('chatSessions')
            .doc(id);
        final messagesSnap = await sessionRef.collection('messages').get();
        for (final m in messagesSnap.docs) {
          await m.reference.delete();
        }
        await sessionRef.delete();
      } catch (e) {
        debugPrint('Failed to delete chat session from Firestore: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _allSessions.removeWhere((s) => s.id == id);
    });

    if (_allSessions.isEmpty) {
      await _createNewChat();
    } else if (mounted) {
      setState(() => _currentSession = _allSessions.first);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = picked;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    final imageToUpload = _selectedImage;
    final imageBytesToUpload = _selectedImageBytes;
    _textController.clear();

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      imagePath: imageToUpload?.path,
      imageBytes: imageBytesToUpload,
    );

    final isFirstMessage = _currentSession!.messages.isEmpty;

    setState(() {
      _currentSession!.messages.add(userMessage);
      if (isFirstMessage) {
        _currentSession!.title = text.isNotEmpty ? text : 'Image Inquiry';
      }
      _selectedImage = null;
      _selectedImageBytes = null;
      _isLoading = true;
    });

    _scrollToBottom();
    _persistMessage(userMessage);
    if (isFirstMessage) {
      _updateSessionTitle(_currentSession!.id, _currentSession!.title);
    }

    try {
      final List<Content> history = [];
      for (var msg in _currentSession!.messages) {
        if (msg == userMessage) break;
        history.add(msg.isUser
            ? Content.text(msg.text)
            : Content.model([TextPart(msg.text)]));
      }

      final chat = _model.startChat(history: history);

      final List<Part> parts = [];
      if (text.isNotEmpty) {
        parts.add(TextPart(text));
      }
      if (imageBytesToUpload != null) {
        parts.add(DataPart('image/jpeg', imageBytesToUpload));
      }

      final response = await chat.sendMessage(Content.multi(parts));

      final botMessage = ChatMessage(
        text: response.text ?? 'Sorry, I could not process your request.',
        isUser: false,
      );
      setState(() {
        _currentSession!.messages.add(botMessage);
      });
      _persistMessage(botMessage);
    } catch (e) {
      debugPrint("Gemini Exception Details: $e");
      final errorMessage = ChatMessage(
        text: 'Error connecting: $e',
        isUser: false,
      );
      setState(() {
        _currentSession!.messages.add(errorMessage);
      });
      _persistMessage(errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionsLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(
          child: CircularProgressIndicator(
            color: AIAssistantScreen.primaryGreen,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_rounded,
                color: AIAssistantScreen.primaryGreen, size: 22),
            SizedBox(width: 8),
            Text(
              'ImmunoBot AI',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // NOTE: top-right "new chat" plus icon removed as requested.
        // "Start New Chat" is still available inside the drawer.
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration:
                  const BoxDecoration(color: AIAssistantScreen.primaryGreen),
              accountName: const Text('ImmunoSphere AI Assistant',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: const Text('Conversations History'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.smart_toy_rounded,
                    color: AIAssistantScreen.primaryGreen, size: 36),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_rounded,
                  color: AIAssistantScreen.primaryGreen),
              title: const Text('Start New Chat',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _createNewChat();
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _allSessions.length,
                itemBuilder: (context, index) {
                  final session = _allSessions[index];
                  final isSelected = session.id == _currentSession?.id;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor:
                        AIAssistantScreen.primaryGreen.withOpacity(0.1),
                    leading: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: isSelected
                          ? AIAssistantScreen.primaryGreen
                          : Colors.grey,
                    ),
                    title: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: Colors.redAccent),
                      onPressed: () => _deleteChat(session.id),
                    ),
                    onTap: () {
                      setState(() {
                        _currentSession = session;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: (_currentSession?.messages.isEmpty ?? true) && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Start a new conversation with ImmunoBot',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: (_currentSession?.messages.length ?? 0) +
                          (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        final msgCount = _currentSession?.messages.length ?? 0;
                        if (index == msgCount && _isLoading) {
                          return const _TypingBubble();
                        }
                        final msg = _currentSession!.messages[index];
                        return _buildMessageBubble(msg);
                      },
                    ),
            ),
            if (_selectedImageBytes != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_selectedImageBytes!,
                          height: 50, width: 50, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Image Attached',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_rounded,
                          color: Colors.grey),
                      onPressed: () => setState(() {
                        _selectedImage = null;
                        _selectedImageBytes = null;
                      }),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_a_photo_outlined,
                        color: AIAssistantScreen.primaryGreen),
                    onPressed: () => _showImageSourceDialog(),
                  ),
                  IconButton(
                    icon: _isListening
                        ? const _PulsingMicIcon()
                        : const Icon(Icons.mic_none_rounded,
                            color: AIAssistantScreen.primaryGreen),
                    onPressed: _toggleListening,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? 'Sun raha hoon... boliye'
                            : 'Ask anything about vaccines...',
                        hintStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AIAssistantScreen.primaryGreen,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                      onPressed: _sendMessage,
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

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final bubble = Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      decoration: BoxDecoration(
        color: msg.isUser ? AIAssistantScreen.primaryGreen : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft:
              msg.isUser ? const Radius.circular(16) : const Radius.circular(2),
          bottomRight:
              msg.isUser ? const Radius.circular(2) : const Radius.circular(16),
        ),
        border: msg.isUser ? null : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.imageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(msg.imageBytes!,
                  height: 150, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
          ] else if (msg.hasImage) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_outlined,
                    size: 14,
                    color: msg.isUser
                        ? Colors.white70
                        : Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Image attached (session only)',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: msg.isUser
                        ? Colors.white70
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          msg.isUser
              ? Text(
                  msg.text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    height: 1.4,
                  ),
                )
              : MarkdownBody(
                  data: msg.text,
                  shrinkWrap: true,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    strong: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                    em: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                    listBullet: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    h1: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    h2: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    h3: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    code: TextStyle(
                      fontSize: 12,
                      backgroundColor: Colors.grey.shade100,
                      color: AIAssistantScreen.primaryGreen,
                    ),
                  ),
                ),
        ],
      ),
    );

    final timestamp = Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: msg.isUser ? 0 : 4,
        right: msg.isUser ? 4 : 0,
      ),
      child: Text(
        _formatTime(msg.time),
        style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
      ),
    );

    final row = msg.isUser
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [bubble, timestamp],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AIAssistantScreen.primaryGreen,
                child: const Icon(Icons.smart_toy_rounded,
                    size: 15, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [bubble, timestamp],
                ),
              ),
            ],
          );

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 6),
            child: child,
          ),
        ),
        child: row,
      ),
    );
  }
}

// Animated three-dot "typing" bubble shown while ImmunoBot is generating a reply.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AIAssistantScreen.primaryGreen,
            child: const Icon(Icons.smart_toy_rounded,
                size: 15, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(2),
              ),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final t = (_controller.value + (i * 0.2)) % 1.0;
                    final bounce = (1 - (2 * t - 1).abs()); // 0 -> 1 -> 0
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Transform.translate(
                        offset: Offset(0, -4 * bounce),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AIAssistantScreen.primaryGreen
                                .withOpacity(0.5 + 0.5 * bounce),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// Mic icon with a subtle pulsing animation while actively listening.
class _PulsingMicIcon extends StatefulWidget {
  const _PulsingMicIcon();

  @override
  State<_PulsingMicIcon> createState() => _PulsingMicIconState();
}

class _PulsingMicIconState extends State<_PulsingMicIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.25);
        return Transform.scale(
          scale: scale,
          child: Icon(Icons.mic_rounded,
              color: Colors.redAccent.withOpacity(0.9)),
        );
      },
    );
  }
} */
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_markdown/flutter_markdown.dart';

// If your folders are different, fix these paths.
import '../../helpers/epi_schedule_helper.dart';
import '../../models/child_model.dart';
import '../../models/vaccination_task_model.dart';
import '../../services/chatbot_data_service.dart';

// ===================================================================
// MODELS
// ===================================================================
class ChatSession {
  final String id;
  String title;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
  });
}

enum MsgKind {
  text,
  children,
  due,
  missed,
  list, // schedule / completed / history
  precautions,
  precautionDetail,
  warning,
}

enum _Intent { none, schedule, due, missed, completed, history, precautions }

class QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  QuickAction(this.label, this.icon, this.onTap);
}

class ChatMessage {
  final String? id;
  final String text; // plain text (saved in Firestore + sent to AI as history)
  final bool isUser;
  final String? imagePath;
  final Uint8List? imageBytes;
  final bool hasImage;
  final DateTime time;
  final MsgKind kind; // how the message is drawn (text or a card)
  final Object? payload; // data for cards (in memory only)
  final List<QuickAction> actions; // follow-up buttons (in memory only)

  ChatMessage({
    this.id,
    required this.text,
    required this.isUser,
    this.imagePath,
    this.imageBytes,
    bool? hasImage,
    DateTime? time,
    this.kind = MsgKind.text,
    this.payload,
    this.actions = const [],
  })  : hasImage = hasImage ?? (imageBytes != null),
        time = time ?? DateTime.now();
}

class _QuickOption {
  final String label;
  final IconData icon;
  const _QuickOption(this.label, this.icon);
}

class _Pending {
  final _Intent intent;
  final String text;
  final bool advise;
  _Pending(this.intent, this.text, this.advise);
}

// One line inside a card (vaccine name, small text, coloured status).
class _Row {
  final String title;
  final String subtitle;
  final _Status status;
  _Row(this.title, this.subtitle, this.status);
}

class _DueData {
  final ChildModel child;
  final String stage;
  final String dueLabel;
  final List<_Row> rows;
  final List<_Row> polio;
  final String empty;
  _DueData(this.child, this.stage, this.dueLabel, this.rows, this.polio,
      this.empty);
}

class _MissedData {
  final ChildModel child;
  final List<_Row> missed;
  final List<_Row> attempts; // refused / absent attempts
  _MissedData(this.child, this.missed, this.attempts);
}

class _Section {
  final String title;
  final List<_Row> rows;
  _Section(this.title, this.rows);
}

class _ListData {
  final ChildModel child;
  final String title;
  final IconData icon;
  final List<_Section> sections;
  final String empty;
  _ListData(this.child, this.title, this.icon, this.sections, this.empty);
}

// ---- AI generated precautions ----
class _PrecSection {
  final String key;
  final String title;
  final List<String> points;
  _PrecSection(this.key, this.title, this.points);
}

class _PrecData {
  final String intro;
  final List<_PrecSection> sections;
  _PrecData(this.intro, this.sections);
}

class _PrecautionPayload {
  final String key; // '' = overview of all sections
  final _PrecData data;
  _PrecautionPayload(this.key, this.data);
}

// ---- AI understanding of the parent's message ----
class _RouteResult {
  final _Intent intent;
  final bool needsChild;
  final bool advice;
  final String childName;
  final String language; // english | urdu | roman_urdu
  final String emergency; // AI written warning, empty if none
  _RouteResult({
    required this.intent,
    required this.needsChild,
    required this.advice,
    required this.childName,
    required this.language,
    required this.emergency,
  });
}

class _Parsed {
  final String text;
  final List<String> options;
  _Parsed(this.text, this.options);
}

// ===================================================================
// HELPERS (dates, status, json, matching)
// ===================================================================
DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

// Dose number is part of the vaccine name in the EPI schedule
// (Pentavalent-2, OPV-0, Measles-Rubella (MR-1)).
String _doseLabel(String vaccine) {
  final m = RegExp(r'(\d+)\)?\s*$').firstMatch(vaccine.trim());
  if (m == null) return '';
  final n = int.parse(m.group(1)!);
  return n == 0 ? 'Birth dose' : 'Dose $n';
}

String _withDose(String vaccine) {
  final d = _doseLabel(vaccine);
  return d.isEmpty ? vaccine : '$vaccine  ($d)';
}

// Polio campaign tasks: still waiting for an outcome.
bool _isPending(VaccinationTaskModel t) => t.status == VaccineStatus.dueToday;

int _byDue(VaccinationTaskModel a, VaccinationTaskModel b) =>
    a.dueDate.compareTo(b.dueDate);

class _Status {
  final String label;
  final Color fg;
  final Color bg;
  const _Status(this.label, this.fg, this.bg);
}

const _Status _stGreen =
    _Status('Vaccinated', Color(0xFF1B6B3A), Color(0xFFD9F0E0));

_Status _doseStatus(DoseItem d) {
  switch (d.state) {
    case DoseState.vaccinated:
      return _stGreen;
    case DoseState.refused:
      return const _Status('Refused', Color(0xFFC2410C), Color(0xFFFFE4D1));
    case DoseState.missed:
      return const _Status('Missed', Color(0xFFD32F2F), Color(0xFFFDE2E2));
    case DoseState.overdue:
      return const _Status('Overdue', Color(0xFFC2410C), Color(0xFFFFE4D1));
    case DoseState.dueToday:
      return const _Status('Due Today', Color(0xFFC2410C), Color(0xFFFFE4D1));
    case DoseState.upcoming:
      return const _Status('Pending', Color(0xFF92400E), Color(0xFFFFF3C4));
  }
}

_Status _recordStatus(String s) {
  switch (s) {
    case 'vaccinated':
      return _stGreen;
    case 'refused':
      return const _Status('Refused', Color(0xFFC2410C), Color(0xFFFFE4D1));
    case 'missed':
      return const _Status('Missed', Color(0xFFD32F2F), Color(0xFFFDE2E2));
    default:
      final label =
          s.isEmpty ? 'Recorded' : s[0].toUpperCase() + s.substring(1);
      return _Status(label, const Color(0xFFC2410C), const Color(0xFFFFE4D1));
  }
}

// Status of polio / registration tasks.
_Status _statusOf(VaccinationTaskModel t) {
  switch (t.status) {
    case VaccineStatus.vaccinated:
      return _stGreen;
    case VaccineStatus.missed:
      return const _Status('Missed', Color(0xFFD32F2F), Color(0xFFFDE2E2));
    case VaccineStatus.absent:
      return const _Status('Absent', Color(0xFFC2410C), Color(0xFFFFE4D1));
    case VaccineStatus.refused:
      return const _Status('Refused', Color(0xFFC2410C), Color(0xFFFFE4D1));
    case VaccineStatus.dueToday:
      final today = _dayOnly(DateTime.now());
      final d = _dayOnly(t.dueDate);
      if (d.isBefore(today)) {
        return const _Status('Overdue', Color(0xFFC2410C), Color(0xFFFFE4D1));
      }
      if (d == today) {
        return const _Status('Due Today', Color(0xFFC2410C), Color(0xFFFFE4D1));
      }
      return const _Status('Pending', Color(0xFF92400E), Color(0xFFFFF3C4));
  }
}

_Row _doseRow(DoseItem d) {
  String sub;
  if (d.state == DoseState.vaccinated) {
    sub = d.givenOn != null ? 'Given: ${_fmtDate(d.givenOn!)}' : 'Given';
    if (d.centre.isNotEmpty) sub += ' • ${d.centre}';
  } else if (d.state == DoseState.refused) {
    sub = d.givenOn != null ? 'Refused on ${_fmtDate(d.givenOn!)}' : 'Refused';
  } else {
    sub = 'Due: ${_fmtDate(d.dueDate)}';
  }
  return _Row(_withDose(d.vaccine), sub, _doseStatus(d));
}

_Row _taskRow(VaccinationTaskModel t) =>
    _Row(t.vaccines, 'Due: ${_fmtDate(t.dueDate)}', _statusOf(t));

// Reads a JSON object out of an AI reply (even if it has ```json fences).
Map<String, dynamic>? _parseJson(String raw) {
  final s = raw.trim();
  final a = s.indexOf('{');
  final b = s.lastIndexOf('}');
  if (a < 0 || b <= a) return null;
  try {
    final v = jsonDecode(s.substring(a, b + 1));
    if (v is Map<String, dynamic>) return v;
  } catch (_) {}
  return null;
}

// Matches the child name chosen by the AI with the real registered children.
ChildModel? _matchChild(String name, List<ChildModel> kids) {
  final n = name.trim().toLowerCase();
  if (n.isEmpty) return null;
  for (final k in kids) {
    if (k.name.trim().toLowerCase() == n) return k;
  }
  for (final k in kids) {
    final kn = k.name.trim().toLowerCase();
    if (kn.isEmpty) continue;
    if (kn.contains(n) || n.contains(kn)) return k;
  }
  return null;
}

_Intent _intentFrom(String s) {
  switch (s.trim().toLowerCase()) {
    case 'due':
      return _Intent.due;
    case 'missed':
      return _Intent.missed;
    case 'schedule':
      return _Intent.schedule;
    case 'completed':
      return _Intent.completed;
    case 'history':
      return _Intent.history;
    case 'precautions':
      return _Intent.precautions;
    default:
      return _Intent.none;
  }
}

IconData _precIcon(String key) {
  switch (key) {
    case 'before':
      return Icons.health_and_safety_rounded;
    case 'after':
      return Icons.shield_rounded;
    case 'side_effects':
      return Icons.info_outline_rounded;
    case 'doctor':
      return Icons.local_hospital_rounded;
    default:
      return Icons.medical_information_rounded;
  }
}

// ===================================================================
// SCREEN
// ===================================================================
class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  static const Color primaryGreen = Color(0xFF1B6B3A);
  static const Color lightGreen = Color(0xFFE6F4EA);
  static const Color borderGreen = Color(0xFFB9DEC4);
  static const Color warningRed = Color(0xFFD32F2F);
  static const Color attentionOrange = Color(0xFFF59E0B);

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  // IMPORTANT: put your NEW Google AI Studio key here. Never share it publicly.
  static const String _apiKey = 'PASTE_YOUR_NEW_KEY_HERE';

  static const String _welcomeText =
      'Assalam-o-Alaikum! Welcome to ImmunoBot. I am your vaccination and '
      'child-health assistant. How can I help you today?';

  static const List<_QuickOption> _welcomeOptions = [
    _QuickOption('View Vaccination Schedule', Icons.calendar_month_rounded),
    _QuickOption('Check Next Due Vaccine', Icons.event_available_rounded),
    _QuickOption('Check Missed Vaccines', Icons.warning_amber_rounded),
    _QuickOption('Vaccination Precautions', Icons.health_and_safety_rounded),
    _QuickOption('Ask a Question', Icons.help_outline_rounded),
  ];

  late final GenerativeModel _model; // chat answers
  late final GenerativeModel _jsonModel; // understanding + precautions (JSON)
  final ChatbotDataService _data = ChatbotDataService();

  ChatSession? _currentSession;
  final List<ChatSession> _allSessions = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _uid;
  bool _sessionsLoading = true;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  late final stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  final String _speechLocale = 'en_US'; // 'ur_PK' try kar sakti hain

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;
  final DateTime _welcomeTime = DateTime.now();

  // ---- guided-flow state ----
  ChildModel? _selectedChild; // child chosen in this conversation
  _Pending? _pending; // what to do once a child is picked
  String _lang = 'english'; // english | urdu | roman_urdu (decided by the AI)
  final Map<String, _PrecData> _precCache = {}; // AI precautions per language

  bool get _useRoman => _lang != 'english';
  String _t(String en, String ro) => _useRoman ? ro : en;

  String get _langName {
    switch (_lang) {
      case 'urdu':
        return 'Urdu (written in Urdu script)';
      case 'roman_urdu':
        return 'Roman Urdu (Urdu written with English letters)';
      default:
        return 'English';
    }
  }

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'You are ImmunoBot, the AI Health Assistant for the ImmunoSphere app. '
        'You help parents with child vaccination and general pediatric health. '
        'You understand Urdu, Roman Urdu and English. '
        'You never diagnose and never prescribe medicines or doses. '
        'For serious symptoms or emergencies you tell the parent to seek medical care immediately.',
      ),
    );
    _jsonModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(temperature: 0.2),
    );

    _speech = stt.SpeechToText();
    _initSpeech();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadSessions();
  }

  // ---------------------------------------------------------------
  // Chat history (Firestore) - unchanged logic
  // ---------------------------------------------------------------
  Future<void> _loadSessions() async {
    if (_uid == null) {
      debugPrint('No logged-in user; chat history will not be saved.');
      _startLocalOnlySession();
      if (mounted) setState(() => _sessionsLoading = false);
      return;
    }

    try {
      final sessionsSnap = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('chatSessions')
          .orderBy('createdAt', descending: true)
          .get();

      final List<ChatSession> loaded = [];
      for (final doc in sessionsSnap.docs) {
        final data = doc.data();
        final messagesSnap =
            await doc.reference.collection('messages').orderBy('time').get();

        final messages = messagesSnap.docs.map((m) {
          final md = m.data();
          return ChatMessage(
            id: m.id,
            text: (md['text'] ?? '') as String,
            isUser: (md['isUser'] ?? false) as bool,
            hasImage: (md['hasImage'] ?? false) as bool,
            time: (md['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList();

        loaded.add(ChatSession(
          id: doc.id,
          title: (data['title'] ?? 'New Conversation') as String,
          messages: messages,
        ));
      }

      if (!mounted) return;
      setState(() {
        _allSessions
          ..clear()
          ..addAll(loaded);
        _sessionsLoading = false;
      });

      if (_allSessions.isEmpty) {
        await _createNewChat();
      } else {
        setState(() => _currentSession = _allSessions.first);
      }
    } catch (e) {
      debugPrint('Failed to load chat history from Firestore: $e');
      _startLocalOnlySession();
      if (mounted) setState(() => _sessionsLoading = false);
    }
  }

  void _startLocalOnlySession() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newSession =
        ChatSession(id: newId, title: 'New Conversation', messages: []);
    _allSessions.insert(0, newSession);
    _currentSession = newSession;
  }

  Future<void> _persistMessage(ChatMessage msg) async {
    if (_uid == null || _currentSession == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('chatSessions')
          .doc(_currentSession!.id)
          .collection('messages')
          .add({
        'text': msg.text,
        'isUser': msg.isUser,
        'hasImage': msg.hasImage,
        'time': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to save message to Firestore: $e');
    }
  }

  Future<void> _updateSessionTitle(String sessionId, String title) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('chatSessions')
          .doc(sessionId)
          .update({'title': title});
    } catch (e) {
      debugPrint('Failed to update chat title in Firestore: $e');
    }
  }

  Future<void> _createNewChat() async {
    String newId;
    if (_uid != null) {
      try {
        final docRef = await _firestore
            .collection('users')
            .doc(_uid)
            .collection('chatSessions')
            .add({
          'title': 'New Conversation',
          'createdAt': FieldValue.serverTimestamp(),
        });
        newId = docRef.id;
      } catch (e) {
        debugPrint('Failed to create chat session in Firestore: $e');
        newId = DateTime.now().millisecondsSinceEpoch.toString();
      }
    } else {
      newId = DateTime.now().millisecondsSinceEpoch.toString();
    }

    final newSession = ChatSession(
      id: newId,
      title: 'New Conversation',
      messages: [],
    );

    if (!mounted) return;
    setState(() {
      _allSessions.insert(0, newSession);
      _currentSession = newSession;
      _selectedImage = null;
      _selectedImageBytes = null;
      _selectedChild = null;
      _pending = null;
      _lang = 'english';
    });
  }

  Future<void> _deleteChat(String id) async {
    if (_uid != null) {
      try {
        final sessionRef = _firestore
            .collection('users')
            .doc(_uid)
            .collection('chatSessions')
            .doc(id);
        final messagesSnap = await sessionRef.collection('messages').get();
        for (final m in messagesSnap.docs) {
          await m.reference.delete();
        }
        await sessionRef.delete();
      } catch (e) {
        debugPrint('Failed to delete chat session from Firestore: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _allSessions.removeWhere((s) => s.id == id);
    });

    if (_allSessions.isEmpty) {
      await _createNewChat();
    } else if (mounted &&
        !_allSessions.any((s) => s.id == _currentSession?.id)) {
      setState(() {
        _currentSession = _allSessions.first;
        _selectedChild = null;
        _pending = null;
      });
    }
  }

  // ---------------------------------------------------------------
  // Voice + image (unchanged)
  // ---------------------------------------------------------------
  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) {
            setState(() => _isListening = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Voice error: ${error.errorMsg}')),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('Speech init exception: $e');
      _speechAvailable = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      await _initSpeech();
    }

    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Microphone available nahi hai. Device permission check karein.'),
          ),
        );
      }
      return;
    }

    try {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        localeId: _speechLocale,
      );
    } catch (e) {
      debugPrint('Listen exception: $e');
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice input start nahi ho saka: $e')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = picked;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // ---------------------------------------------------------------
  // Adding messages
  // ---------------------------------------------------------------
  void _addUser(String text, {Uint8List? imageBytes, String? imagePath}) {
    final session = _currentSession;
    if (session == null) return;
    final isFirst = session.messages.isEmpty;
    final msg = ChatMessage(
      text: text,
      isUser: true,
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
    setState(() {
      session.messages.add(msg);
      if (isFirst) session.title = text.isNotEmpty ? text : 'Image Inquiry';
    });
    _persistMessage(msg);
    if (isFirst) _updateSessionTitle(session.id, session.title);
    _scrollToBottom();
  }

  void _addBot(ChatMessage m) {
    if (!mounted || _currentSession == null) return;
    setState(() => _currentSession!.messages.add(m));
    _persistMessage(m);
    _scrollToBottom();
  }

  void _botText(String text, {List<QuickAction> actions = const []}) {
    _addBot(ChatMessage(text: text, isUser: false, actions: actions));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _busy() {
    if (_isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jawab aane tak intezar karein.'),
          duration: Duration(seconds: 2),
        ),
      );
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------
  // Sending typed text
  // ---------------------------------------------------------------
  Future<void> _sendMessage() async {
    if (_isLoading) return;
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    }

    final imgBytes = _selectedImageBytes;
    final imgPath = _selectedImage?.path;
    _textController.clear();
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });

    _addUser(text, imageBytes: imgBytes, imagePath: imgPath);

    if (imgBytes != null) {
      await _askAI(
        text.isEmpty
            ? 'Please look at this image and tell me what you can.'
            : text,
        image: imgBytes,
      );
      return;
    }

    await _routeText(text);
  }

  // ---------------------------------------------------------------
  // The AI reads the message and decides what the parent wants.
  // ---------------------------------------------------------------
  String _recentContext() {
    final msgs = _currentSession?.messages ?? const <ChatMessage>[];
    final recent = msgs.length > 6 ? msgs.sublist(msgs.length - 6) : msgs;
    return recent.where((m) => m.text.trim().isNotEmpty).map((m) {
      final t = m.text.trim();
      final s = t.length > 160 ? t.substring(0, 160) : t;
      return '${m.isUser ? 'Parent' : 'Bot'}: $s';
    }).join('\n');
  }

  String _classifierPrompt(String text, List<ChildModel> kids) {
    final names = kids.isEmpty ? '(none)' : kids.map((k) => k.name).join(', ');
    final b = StringBuffer();
    b.writeln(
        'You are the message router of a child vaccination assistant app. The parent writes in English, Urdu script or Roman Urdu (informal spelling is common).');
    b.writeln(
        'Read the parent\'s LAST message and reply with ONLY one JSON object (no markdown, no extra text) with these fields:');
    b.writeln(
        '"intent": one of "due" (asks when the next vaccine is or what is due), "missed" (asks about missed, skipped or late vaccines, or what to do about them), "schedule" (wants the full vaccination schedule), "completed" (wants vaccines already given), "history" (wants vaccination records or history), "precautions" (asks generally about precautions before or after vaccination, common side effects, or when to see a doctor, without describing a specific child), "general" (anything else: symptoms, health questions, other topics).');
    b.writeln(
        '"needs_child": true if a good answer depends on one specific child of this parent (for example "my child has fever", "meri beti ko daane hain"), otherwise false.');
    b.writeln(
        '"wants_advice": true if the parent also asks what to do next (for example "ab kya karun"), otherwise false.');
    b.writeln(
        '"child_name": the exact spelling from the registered list if the parent mentioned one of these children, otherwise an empty string.');
    b.writeln(
        '"language": the language of the last message: "english", "urdu" (Urdu script) or "roman_urdu".');
    b.writeln(
        '"emergency": if the message describes a possible emergency (trouble breathing, seizure, blue colour, unresponsive or very drowsy child, severe allergic reaction) write ONE short warning sentence in the same language telling the parent to go to the nearest hospital or emergency immediately, otherwise an empty string.');
    b.writeln('Registered children: $names');
    b.writeln(
        'Child already selected in this chat: ${_selectedChild?.name ?? '(none)'}');
    final ctx = _recentContext();
    if (ctx.isNotEmpty) {
      b.writeln('Recent conversation:');
      b.writeln(ctx);
    }
    b.writeln('LAST MESSAGE: $text');
    return b.toString();
  }

  Future<_RouteResult?> _classify(String text, List<ChildModel> kids) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await _jsonModel
          .generateContent([Content.text(_classifierPrompt(text, kids))]);
      final m = _parseJson(res.text ?? '');
      if (m == null) return null;

      var lang = (m['language'] ?? 'english').toString().toLowerCase();
      if (lang != 'urdu' && lang != 'roman_urdu') lang = 'english';

      return _RouteResult(
        intent: _intentFrom((m['intent'] ?? 'general').toString()),
        needsChild: m['needs_child'] == true,
        advice: m['wants_advice'] == true,
        childName: (m['child_name'] ?? '').toString(),
        language: lang,
        emergency: (m['emergency'] ?? '').toString().trim(),
      );
    } catch (e) {
      debugPrint('Classifier failed: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _routeText(String text) async {
    _pending = null;

    final kids = await _fetchChildren(silent: true); // null = could not load
    final kidList = kids ?? <ChildModel>[];

    final r = await _classify(text, kidList);
    if (r == null) {
      await _askAI(text); // fall back to a normal AI answer
      return;
    }
    _lang = r.language;

    if (r.emergency.isNotEmpty) {
      _addBot(ChatMessage(
        text: r.emergency,
        isUser: false,
        kind: MsgKind.warning,
      ));
    }

    if (r.intent == _Intent.precautions) {
      await _showPrecautions();
      return;
    }

    final named = _matchChild(r.childName, kidList);
    if (named != null) _selectedChild = named;

    // General / symptom questions
    if (r.intent == _Intent.none) {
      if (!r.needsChild ||
          kidList.isEmpty ||
          named != null ||
          _selectedChild != null) {
        await _askAI(text);
        return;
      }
      // Personal question but we do not know which child yet.
      _pending = _Pending(_Intent.none, text, false);
      _showChildPicker(kidList);
      return;
    }

    // Child-specific vaccination questions
    if (kids == null) {
      _showLoadError();
      return;
    }
    if (kids.isEmpty) {
      _showNoChildren();
      return;
    }
    if (named != null) {
      await _runIntent(named, r.intent, text, r.advice);
      return;
    }
    _pending = _Pending(r.intent, text, r.advice);
    _showChildPicker(kids);
  }

  // ---------------------------------------------------------------
  // Quick-reply handling
  // ---------------------------------------------------------------
  void _onQuickReply(String label) {
    if (_isLoading) return;
    _addUser(label);
    switch (label) {
      case 'View Vaccination Schedule':
        _beginChildFlow(_Intent.schedule, label);
        break;
      case 'Check Next Due Vaccine':
        _beginChildFlow(_Intent.due, label);
        break;
      case 'Check Missed Vaccines':
        _beginChildFlow(_Intent.missed, label);
        break;
      case 'Vaccination Precautions':
        _showPrecautions();
        break;
      default:
        _askAnother();
    }
  }

  void _onActionTap(QuickAction a) {
    if (_isLoading) return;
    _addUser(a.label);
    a.onTap();
  }

  void _askAnother() {
    _selectedChild = null;
    _pending = null;
    _botText(_t(
      'Sure! Type your question below. You can also use the mic or the camera.',
      'Zaroor! Apna sawal neeche likhein. Aap mic ya camera bhi istemal kar sakti hain.',
    ));
    _inputFocus.requestFocus();
  }

  QuickAction get _askAnotherAction => QuickAction(
      'Ask Another Question', Icons.help_outline_rounded, _askAnother);

  // ---------------------------------------------------------------
  // Child selection
  // ---------------------------------------------------------------
  void _showLoadError() {
    _botText(
      _t(
        'Sorry, I could not load your children. Please check your internet and try again.',
        'Maaf kijiye, bachon ki list load nahi ho saki. Internet check karke dobara koshish karein.',
      ),
      actions: [_askAnotherAction],
    );
  }

  Future<List<ChildModel>?> _fetchChildren({bool silent = false}) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      return await _data.getMyChildren();
    } catch (e) {
      debugPrint('Failed to load children: $e');
      if (!silent) _showLoadError();
      return null;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _beginChildFlow(_Intent intent, String text,
      {bool advise = false}) async {
    final kids = await _fetchChildren();
    if (kids == null) return;
    if (kids.isEmpty) {
      _showNoChildren();
      return;
    }
    _pending = _Pending(intent, text, advise);
    _showChildPicker(kids);
  }

  void _showNoChildren() {
    _botText(
      _t(
        'No child is registered under your account yet. Children are registered through your health centre or vaccinator, so please contact them to add your child. Once registered, the records will appear here.',
        'Aap ke account mein abhi koi bacha registered nahi hai. Bachon ki registration health centre ya vaccinator ke zariye hoti hai, isliye bachay ko add karwane ke liye unse rabta karein. Registration ke baad records yahan nazar aayenge.',
      ),
      actions: [_askAnotherAction],
    );
  }

  void _showChildPicker(List<ChildModel> kids) {
    _botText(_t(
      "Which child's information would you like to check?",
      'Zaroor! Pehle batayein kis bachay ki information dekhni hai?',
    ));
    _addBot(ChatMessage(
      text:
          'Children: ${kids.map((k) => '${k.name} (${k.formattedAge})').join(', ')}',
      isUser: false,
      kind: MsgKind.children,
      payload: kids,
    ));
  }

  void _onChildSelected(ChildModel c) {
    if (_isLoading) return;
    _addUser(c.name);
    _selectedChild = c;
    final p = _pending;
    _pending = null;
    if (p != null) {
      _runIntent(c, p.intent, p.text, p.advise);
    } else {
      _showChildMenu(c);
    }
  }

  void _showChildMenu(ChildModel c) {
    _botText(
      _t(
        "What would you like to know about ${c.name}'s vaccination?",
        '${c.name} ki vaccination ke baare mein kya dekhna hai?',
      ),
      actions: [
        QuickAction('Complete Vaccination Schedule',
            Icons.calendar_month_rounded, () => _showSchedule(c)),
        QuickAction(
            'Next Due Vaccine', Icons.event_available_rounded, () => _showDue(c)),
        QuickAction('Completed Vaccines', Icons.check_circle_outline_rounded,
            () => _showCompleted(c)),
        QuickAction('Missed Vaccines', Icons.warning_amber_rounded,
            () => _showMissed(c)),
        QuickAction(
            'Vaccination History', Icons.history_rounded, () => _showHistory(c)),
      ],
    );
  }

  Future<void> _runIntent(
      ChildModel c, _Intent intent, String text, bool advise) async {
    switch (intent) {
      case _Intent.due:
        await _showDue(c);
        break;
      case _Intent.missed:
        await _showMissed(c, advise: advise);
        break;
      case _Intent.schedule:
        await _showSchedule(c);
        break;
      case _Intent.completed:
        await _showCompleted(c);
        break;
      case _Intent.history:
        await _showHistory(c);
        break;
      case _Intent.precautions:
        await _showPrecautions();
        break;
      case _Intent.none:
        await _askAI(text);
        break;
    }
  }

  // ---------------------------------------------------------------
  // Firebase-backed answers
  // ---------------------------------------------------------------
  Future<ChildVaccineData?> _loadData(ChildModel child) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      return await _data.getChildVaccineData(child);
    } catch (e) {
      debugPrint('Failed to load vaccination data: $e');
      _botText(
        _t(
          'Sorry, I could not load the vaccination records. Please check your internet and try again.',
          'Maaf kijiye, vaccination records load nahi ho sake. Internet check karke dobara koshish karein.',
        ),
        actions: [_askAnotherAction],
      );
      return null;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showDue(ChildModel child) async {
    final d = await _loadData(child);
    if (d == null) return;

    final next = d.nextDue;

    // Polio campaign (kept separate from routine immunization)
    final today = _dayOnly(DateTime.now());
    final polioPending = d.polio.where(_isPending).toList()..sort(_byDue);
    final upcoming = polioPending
        .where((t) => !_dayOnly(t.dueDate).isBefore(today))
        .toList();
    final base = upcoming.isNotEmpty ? upcoming : polioPending;
    final polioNext = base.isEmpty
        ? <VaccinationTaskModel>[]
        : base
            .where((t) => _dayOnly(t.dueDate) == _dayOnly(base.first.dueDate))
            .toList();

    final stage = next.isEmpty ? '' : next.first.stage;
    final dueLabel = next.isEmpty ? '' : _fmtDate(next.first.dueDate);
    final names = next.map((x) => x.vaccine).join('; ');

    final emptyMsg = d.allDone
        ? 'All routine vaccines in the schedule are completed.'
        : 'No pending routine vaccine was found in the records.';

    final summary = next.isEmpty
        ? '$emptyMsg (${child.name})'
        : 'Next due for ${child.name} ($stage, $dueLabel): ${next.map((x) => '${x.vaccine} (${_doseStatus(x).label})').join('; ')}.';

    _addBot(ChatMessage(
      text: summary,
      isUser: false,
      kind: MsgKind.due,
      payload: _DueData(child, stage, dueLabel, next.map(_doseRow).toList(),
          polioNext.map(_taskRow).toList(), emptyMsg),
      actions: next.isEmpty
          ? [
              QuickAction('Vaccination History', Icons.history_rounded,
                  () => _showHistory(child)),
              QuickAction('View Complete Schedule',
                  Icons.calendar_month_rounded, () => _showSchedule(child)),
              _askAnotherAction,
            ]
          : [
              QuickAction(
                  'Why Is This Vaccine Important?',
                  Icons.info_outline_rounded,
                  () => _askAI(
                      'Explain simply why the vaccine(s) "$names" are important for ${child.name} (${child.formattedAge}).')),
              QuickAction(
                  'What If I Miss the Date?',
                  Icons.event_busy_rounded,
                  () => _askAI(
                      'What happens if ${child.name} misses the due date ($dueLabel) for "$names"? What should the parent do?')),
              QuickAction('View Complete Schedule',
                  Icons.calendar_month_rounded, () => _showSchedule(child)),
              _askAnotherAction,
            ],
    ));
  }

  Future<void> _showMissed(ChildModel child, {bool advise = false}) async {
    final d = await _loadData(child);
    if (d == null) return;

    final missed = d.missed;
    final attempts = <_Row>[
      ...d.refused.map(_doseRow),
      ...d.attempts.map(_taskRow),
    ];
    final names = missed.map((x) => x.vaccine).join('; ');

    _addBot(ChatMessage(
      text: missed.isEmpty
          ? 'No missed doses found for ${child.name}.'
          : '${missed.length} missed dose(s) for ${child.name}: ${missed.map((x) => '${x.vaccine} (due ${_fmtDate(x.dueDate)})').join('; ')}.',
      isUser: false,
      kind: MsgKind.missed,
      payload: _MissedData(child, missed.map(_doseRow).toList(), attempts),
      actions: missed.isEmpty
          ? [
              QuickAction('Check Next Due Vaccine',
                  Icons.event_available_rounded, () => _showDue(child)),
              QuickAction('View Complete Schedule',
                  Icons.calendar_month_rounded, () => _showSchedule(child)),
              _askAnotherAction,
            ]
          : [
              QuickAction(
                  'Why Was This Vaccine Important?',
                  Icons.info_outline_rounded,
                  () => _askAI(
                      'Explain simply why these vaccines are important for ${child.name}: $names.')),
              QuickAction(
                  'What Should I Do Now?',
                  Icons.help_outline_rounded,
                  () => _askAI(
                      "${child.name} has missed these doses: $names. What should I do now? Explain the next steps simply.")),
              QuickAction('Contact Vaccinator', Icons.support_agent_rounded,
                  () => _showContactVaccinator(child)),
              QuickAction('View Complete Schedule',
                  Icons.calendar_month_rounded, () => _showSchedule(child)),
            ],
    ));

    // Parent also asked "what should I do?" in the same sentence.
    if (advise && missed.isNotEmpty) {
      await _askAI(
          "${child.name} has missed these doses: $names. What should I do now? Explain the next steps simply.");
    }
  }

  Future<void> _showSchedule(ChildModel child) async {
    final d = await _loadData(child);
    if (d == null) return;

    final byStage = <String, List<_Row>>{};
    for (final x in d.doses) {
      byStage.putIfAbsent(x.stage, () => []).add(_doseRow(x));
    }
    final sections =
        byStage.entries.map((e) => _Section(e.key, e.value)).toList();
    if (d.polio.isNotEmpty) {
      sections.add(_Section('Polio Campaign',
          ([...d.polio]..sort(_byDue)).map(_taskRow).toList()));
    }

    _addBot(ChatMessage(
      text:
          'Complete schedule for ${child.name}: ${d.doses.length} routine dose(s) and ${d.polio.length} polio campaign record(s).',
      isUser: false,
      kind: MsgKind.list,
      payload: _ListData(
        child,
        'Complete Vaccination Schedule',
        Icons.calendar_month_rounded,
        sections,
        'No vaccination schedule is available for this child yet.',
      ),
      actions: [
        QuickAction('Next Due Vaccine', Icons.event_available_rounded,
            () => _showDue(child)),
        QuickAction('Missed Vaccines', Icons.warning_amber_rounded,
            () => _showMissed(child)),
        QuickAction('Vaccination History', Icons.history_rounded,
            () => _showHistory(child)),
        _askAnotherAction,
      ],
    ));
  }

  Future<void> _showCompleted(ChildModel child) async {
    final d = await _loadData(child);
    if (d == null) return;

    final polioDone = ([...d.polio]..sort(_byDue))
        .where((t) => t.status == VaccineStatus.vaccinated)
        .map(_taskRow)
        .toList();

    _addBot(ChatMessage(
      text:
          'Completed vaccines for ${child.name}: ${d.completed.length} routine dose(s), ${polioDone.length} polio record(s).',
      isUser: false,
      kind: MsgKind.list,
      payload: _ListData(
        child,
        'Completed Vaccines',
        Icons.check_circle_outline_rounded,
        [
          _Section('Routine Immunization', d.completed.map(_doseRow).toList()),
          _Section('Polio Campaign', polioDone),
        ],
        'No completed vaccines are recorded for this child yet.',
      ),
      actions: [
        QuickAction('Next Due Vaccine', Icons.event_available_rounded,
            () => _showDue(child)),
        QuickAction('View Complete Schedule', Icons.calendar_month_rounded,
            () => _showSchedule(child)),
        _askAnotherAction,
      ],
    ));
  }

  Future<void> _showHistory(ChildModel child) async {
    final d = await _loadData(child);
    if (d == null) return;

    final routine = d.records.map((r) {
      final sub = <String>[
        if (r.date != null) _fmtDate(r.date!),
        if (r.centre.isNotEmpty) r.centre,
      ].join(' • ');
      return _Row(_withDose(r.vaccineName), sub.isEmpty ? 'Recorded' : sub,
          _recordStatus(r.status));
    }).toList();

    final polioRecorded = ([...d.polio]..sort(_byDue))
        .where((t) => !_isPending(t))
        .map(_taskRow)
        .toList();

    _addBot(ChatMessage(
      text:
          'Vaccination history for ${child.name}: ${routine.length} routine record(s), ${polioRecorded.length} polio record(s).',
      isUser: false,
      kind: MsgKind.list,
      payload: _ListData(
        child,
        'Vaccination History',
        Icons.history_rounded,
        [
          _Section('Routine Immunization', routine),
          _Section('Polio Campaign', polioRecorded),
        ],
        'No vaccination history is recorded for this child yet.',
      ),
      actions: [
        QuickAction('Next Due Vaccine', Icons.event_available_rounded,
            () => _showDue(child)),
        QuickAction('Missed Vaccines', Icons.warning_amber_rounded,
            () => _showMissed(child)),
        _askAnotherAction,
      ],
    ));
  }

  void _showContactVaccinator(ChildModel child) {
    final hc = child.healthCenter.trim();
    _botText(
      hc.isEmpty
          ? _t(
              "${child.name}'s health centre is not recorded in the app. Please visit or call your nearest health centre and ask for the vaccinator.",
              '${child.name} ka health centre app mein darj nahi hai. Apne qareebi health centre jayein ya wahan call karke vaccinator se baat karein.',
            )
          : _t(
              "${child.name} is registered at $hc. Please visit or call this health centre and ask for the vaccinator to arrange the missed dose.",
              '${child.name} $hc mein registered hai. Is health centre jayein ya call karke vaccinator se missed dose ke liye baat karein.',
            ),
      actions: [
        QuickAction('View Complete Schedule', Icons.calendar_month_rounded,
            () => _showSchedule(child)),
        _askAnotherAction,
      ],
    );
  }

  // ---------------------------------------------------------------
  // Precautions: written by the AI (not stored in the app)
  // ---------------------------------------------------------------
  String _precautionsPrompt() {
    final b = StringBuffer();
    b.writeln(
        'You are a pediatric vaccination health educator writing for parents in Pakistan (national EPI programme).');
    b.writeln(
        'Write general, medically appropriate guidance about child vaccination precautions. Do not diagnose. Do not name medicines or doses.');
    b.writeln('Write in: $_langName.');
    b.writeln('Reply with ONLY one JSON object (no markdown) in exactly this shape:');
    b.writeln(
        '{"intro":"one short friendly sentence","sections":[{"key":"before","title":"...","points":["..."]},{"key":"after","title":"...","points":["..."]},{"key":"side_effects","title":"...","points":["..."]},{"key":"doctor","title":"...","points":["..."]}]}');
    b.writeln(
        'The four titles mean: Before Vaccination, After Vaccination, Common Side Effects, When to Contact a Doctor (translate them into the requested language).');
    b.writeln(
        'Each section has 3 to 5 short, simple points (maximum 20 words each). The "doctor" section must clearly list urgent signs such as trouble breathing, swelling of face or lips, seizure, very high or long-lasting fever, or a child who is very weak or unresponsive.');
    return b.toString();
  }

  Future<_PrecData?> _loadPrecautions() async {
    final cached = _precCache[_lang];
    if (cached != null) return cached;

    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await _jsonModel
          .generateContent([Content.text(_precautionsPrompt())]);
      final m = _parseJson(res.text ?? '');
      final list = (m?['sections'] as List?) ?? const [];
      final sections = <_PrecSection>[];
      for (final s in list) {
        if (s is! Map) continue;
        final key = (s['key'] ?? '').toString().trim();
        final title = (s['title'] ?? '').toString().trim();
        final pts = ((s['points'] as List?) ?? const [])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (key.isEmpty || title.isEmpty || pts.isEmpty) continue;
        sections.add(_PrecSection(key, title, pts));
      }
      if (sections.isEmpty) throw Exception('No precaution sections returned');
      final data = _PrecData((m?['intro'] ?? '').toString().trim(), sections);
      _precCache[_lang] = data;
      return data;
    } catch (e) {
      debugPrint('Failed to load precautions: $e');
      _botText(
        _t(
          'Sorry, I could not load the precautions right now. Please try again.',
          'Maaf kijiye, abhi precautions load nahi ho sakin. Dobara koshish karein.',
        ),
        actions: [_askAnotherAction],
      );
      return null;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<QuickAction> _topicActions(_PrecData data, String exceptKey) => [
        for (final s in data.sections)
          if (s.key != exceptKey)
            QuickAction(
                s.title, _precIcon(s.key), () => _showPrecautionDetail(s.key)),
        _askAnotherAction,
      ];

  Future<void> _showPrecautions() async {
    final data = await _loadPrecautions();
    if (data == null) return;
    if (data.intro.isNotEmpty) _botText(data.intro);
    _addBot(ChatMessage(
      text: data.sections
          .map((s) => '${s.title}: ${s.points.join(' ')}')
          .join('\n'),
      isUser: false,
      kind: MsgKind.precautions,
      payload: _PrecautionPayload('', data),
      actions: _topicActions(data, ''),
    ));
  }

  Future<void> _showPrecautionDetail(String key) async {
    final data = await _loadPrecautions();
    if (data == null) return;
    final matches = data.sections.where((s) => s.key == key).toList();
    if (matches.isEmpty) return;
    final s = matches.first;
    _addBot(ChatMessage(
      text: '${s.title}: ${s.points.join(' ')}',
      isUser: false,
      kind: MsgKind.precautionDetail,
      payload: _PrecautionPayload(key, data),
      actions: _topicActions(data, key),
    ));
  }

  // ---------------------------------------------------------------
  // AI (Gemini) answers with real child records + dynamic follow-ups
  // ---------------------------------------------------------------
  List<Content> _buildHistory() {
    final msgs = List<ChatMessage>.from(_currentSession!.messages);
    if (msgs.isNotEmpty && msgs.last.isUser) msgs.removeLast();
    final recent = msgs.length > 20 ? msgs.sublist(msgs.length - 20) : msgs;

    final merged = <MapEntry<bool, String>>[];
    for (final m in recent) {
      final t = m.text.trim();
      if (t.isEmpty) continue;
      if (merged.isNotEmpty && merged.last.key == m.isUser) {
        merged[merged.length - 1] =
            MapEntry(m.isUser, '${merged.last.value}\n$t');
      } else {
        merged.add(MapEntry(m.isUser, t));
      }
    }
    while (merged.isNotEmpty && !merged.first.key) {
      merged.removeAt(0);
    }
    while (merged.isNotEmpty && merged.last.key) {
      merged.removeLast();
    }
    return merged
        .map((e) =>
            e.key ? Content.text(e.value) : Content.model([TextPart(e.value)]))
        .toList();
  }

  // Writes one child's real records for the AI.
  void _writeChildData(StringBuffer b, ChildVaccineData d) {
    final c = d.child;
    final hc = c.healthCenter.trim().isEmpty ? 'not recorded' : c.healthCenter.trim();
    b.writeln(
        'Child: ${c.name}, ${c.gender}, age ${c.formattedAge}, health centre: $hc');
    b.writeln('Routine EPI schedule status for this child:');
    for (final x in d.doses) {
      final rec = x.givenOn == null ? '' : ' | record date ${_fmtDate(x.givenOn!)}';
      b.writeln(
          '- ${x.stage} | ${x.vaccine} | due ${_fmtDate(x.dueDate)} | ${_doseStatus(x).label}$rec');
    }
    if (d.polio.isNotEmpty) {
      b.writeln('Polio campaign records for this child:');
      for (final t in d.polio.take(20)) {
        b.writeln(
            '- ${t.vaccines} | due ${_fmtDate(t.dueDate)} | ${_statusOf(t).label}');
      }
    }
  }

  String _buildPrompt(String userText, ChildModel? child, ChildVaccineData? data,
      bool hasImage, List<ChildVaccineData> all) {
    final b = StringBuffer();
    b.writeln('[APP CONTEXT - for you only, do not mention this block]');
    b.writeln('Today: ${_fmtDate(DateTime.now())}');
    if (child != null) {
      if (data == null) {
        b.writeln(
            'Selected child: ${child.name}, age ${child.formattedAge}. Vaccination records could not be loaded right now.');
      } else {
        b.writeln('Selected child and the real vaccination records:');
        _writeChildData(b, data);
      }
    } else if (all.isNotEmpty) {
      b.writeln(
          'No single child is selected. These are ALL of the parent\'s registered children with their real vaccination records. Answer using only the matching child. If the question is about one child and it is unclear which one, ask the parent which child.');
      for (final d in all) {
        _writeChildData(b, d);
      }
    } else {
      b.writeln(
          'No child is selected. Do not assume any child details or vaccination records.');
    }

    b.writeln(
        'Approved EPI schedule of this app (stage: vaccines). Use ONLY this schedule when explaining which vaccines are given at which age; never add other vaccines or ages:');
    for (final s in EpiScheduleHelper.generateEpiSchedule(DateTime.now())) {
      b.writeln(
          '- ${s['stage']}: ${(s['vaccines'] as List<String>).join(', ')}');
    }

    b.writeln('[RULES]');
    b.writeln(
        '1. Facts about a child\'s vaccines, due dates and status come ONLY from the records above. Never invent doses, dates or schedules. If something is not in the records, say so and suggest asking the vaccinator or health centre.');
    b.writeln(
        '2. Reply in $_langName. If the parent message is clearly written in another one of English, Urdu or Roman Urdu, reply in that language instead. The parent message may be an app-generated English question from a button; still reply in the language above.');
    b.writeln(
        '3. Use simple, warm words. Keep it short (about 120 words max). Short bullet points are fine. No headings, no tables.');
    b.writeln(
        '4. Do not diagnose. Do not prescribe medicines or give doses. For fever or pain you may say a doctor or pharmacist can advise on suitable medicine. For serious signs (trouble breathing, seizure, blue colour, very drowsy or unresponsive, repeated vomiting, very high or long-lasting fever, spreading rash or swelling) clearly advise urgent medical care.');
    b.writeln(
        '5. If a child is known, use the child\'s name and age, and make clear what comes from the records versus general guidance.');
    b.writeln(
        '6. Status meanings: Vaccinated = given; Pending = not due yet; Due Today = due today; Overdue = past the due date with no record that it was given (do NOT call it missed); Missed = officially marked missed in the records; Refused = the parent refused it.');
    if (hasImage) {
      b.writeln(
          '7. An image is attached. Do NOT diagnose from it. Describe only general visible things carefully, explain that a photo cannot confirm a diagnosis, and recommend a doctor or health-centre check when appropriate.');
    }
    b.writeln(
        '8. End with one final line exactly like: FOLLOWUPS: option one | option two | option three  (2 to 3 short follow-up questions the parent may tap next, max 5 words each, same language as your reply, relevant to your answer). Write nothing after that line.');
    b.writeln('[PARENT MESSAGE]');
    b.writeln(userText);
    return b.toString();
  }

  _Parsed _splitFollowUps(String raw) {
    final re = RegExp(r'FOLLOW-?UPS?\s*:\s*(.+)$',
        caseSensitive: false, multiLine: true);
    final matches = re.allMatches(raw).toList();
    if (matches.isEmpty) return _Parsed(raw, []);
    final m = matches.last;
    final opts = m
        .group(1)!
        .split('|')
        .map((e) => e.trim().replaceAll(RegExp(r'^[\-\*\s"]+|["\s]+$'), ''))
        .where((e) => e.isNotEmpty && e.length <= 45)
        .take(3)
        .toList();
    final text = raw.substring(0, m.start).trim();
    return _Parsed(text.isEmpty ? raw : text, opts);
  }

  Future<void> _askAI(String prompt, {Uint8List? image}) async {
    if (mounted) setState(() => _isLoading = true);
    _scrollToBottom();
    try {
      final child = _selectedChild;
      ChildVaccineData? data;
      var all = <ChildVaccineData>[];

      if (child != null) {
        try {
          data = await _data.getChildVaccineData(child);
        } catch (e) {
          debugPrint('Could not load records for AI context: $e');
        }
      } else {
        try {
          final kids = await _data.getMyChildren();
          final res = await Future.wait(kids.map((k) async {
            try {
              return await _data.getChildVaccineData(k);
            } catch (_) {
              return null;
            }
          }));
          all = res.whereType<ChildVaccineData>().toList();
        } catch (e) {
          debugPrint('Could not load all records for AI context: $e');
        }
      }

      final chat = _model.startChat(history: _buildHistory());
      final parts = <Part>[
        TextPart(_buildPrompt(prompt, child, data, image != null, all)),
      ];
      if (image != null) parts.add(DataPart('image/jpeg', image));

      final response = await chat.sendMessage(Content.multi(parts));
      var raw = (response.text ?? '').trim();
      if (raw.isEmpty) {
        raw = _t('Sorry, I could not process your request.',
            'Maaf kijiye, main aap ki request process nahi kar saka.');
      }

      final parsed = _splitFollowUps(raw);
      final actions = <QuickAction>[
        for (final label in parsed.options)
          QuickAction(
              label, Icons.chat_bubble_outline_rounded, () => _askAI(label)),
        _askAnotherAction,
      ];
      _addBot(ChatMessage(text: parsed.text, isUser: false, actions: actions));
    } catch (e) {
      debugPrint("Gemini Exception Details: $e");
      final err = e.toString().toLowerCase();
      String reason;
      if (err.contains('api key') ||
          err.contains('api_key') ||
          err.contains('403')) {
        reason =
            'API key sahi nahi hai ya kaam nahi kar rahi. Nayi key check karein.';
      } else if (err.contains('quota') || err.contains('429')) {
        reason = 'AI ki limit abhi khatam hai. Thori der baad try karein.';
      } else if (err.contains('socket') ||
          err.contains('network') ||
          err.contains('xmlhttprequest')) {
        reason = 'Internet connection check karein.';
      } else {
        reason =
            'Sorry, abhi jawab nahi mil saka. Please dobara koshish karein.';
      }
      _botText(reason, actions: [_askAnotherAction]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  // ---------------------------------------------------------------
  // Drawer helpers
  // ---------------------------------------------------------------
  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: const Text(
            'Yeh conversation hamesha ke liye delete ho jayegi. Kya aap yaqeen se delete karna chahti hain?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Delete',
                style: TextStyle(color: AIAssistantScreen.warningRed)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _formatDate(DateTime t) {
    final now = DateTime.now();
    final isToday =
        t.year == now.year && t.month == now.month && t.day == now.day;
    if (isToday) return 'Today, ${_formatTime(t)}';
    return '${t.day} ${_months[t.month - 1]}, ${t.year}';
  }

  String _formatTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _speech.stop();
    _textController.dispose();
    _inputFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ===============================================================
  // UI
  // ===============================================================
  @override
  Widget build(BuildContext context) {
    if (_sessionsLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(
          child: CircularProgressIndicator(
            color: AIAssistantScreen.primaryGreen,
          ),
        ),
      );
    }

    final messages = _currentSession?.messages ?? const <ChatMessage>[];
    final noMessages = messages.isEmpty;
    final canGoBack = Navigator.of(context).canPop();

    final showActions = !_isLoading &&
        messages.isNotEmpty &&
        !messages.last.isUser &&
        messages.last.actions.isNotEmpty;
    final extra = (_isLoading || showActions) ? 1 : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: AIAssistantScreen.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leadingWidth: canGoBack ? 96 : 56,
        leading: Builder(
          builder: (context) => Row(
            children: [
              if (canGoBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ],
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.smart_toy_rounded,
                  color: AIAssistantScreen.primaryGreen, size: 22),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('ImmunoBot AI',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                  Text('Your Immunization Assistant',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (value) {
              if (value == 'new' && !_busy()) _createNewChat();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'new', child: Text('Start New Chat')),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: noMessages && !_isLoading
                  ? _buildWelcome()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + extra,
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          if (_isLoading) return const _TypingBubble();
                          return _buildActions(messages.last.actions);
                        }
                        final msg = messages[index];
                        final isLast = index == messages.length - 1;
                        if (msg.kind == MsgKind.text) {
                          return _buildMessageBubble(msg);
                        }
                        return _buildRich(msg, isLast);
                      },
                    ),
            ),
            if (_selectedImageBytes != null) _buildImagePreview(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(List<QuickAction> actions) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        children: actions
            .map((a) => _QuickReplyButton(
                  label: a.label,
                  icon: a.icon,
                  onTap: () => _onActionTap(a),
                ))
            .toList(),
      ),
    );
  }

  // Cards (child picker, due, missed, lists, precautions, warning)
  Widget _buildRich(ChatMessage msg, bool isLast) {
    Widget content;
    switch (msg.kind) {
      case MsgKind.children:
        content = _ChildGrid(
          kids: msg.payload as List<ChildModel>,
          enabled: isLast && !_isLoading,
          onSelect: _onChildSelected,
        );
        break;
      case MsgKind.due:
        content = _DueCard(data: msg.payload as _DueData);
        break;
      case MsgKind.missed:
        content = _MissedCard(data: msg.payload as _MissedData);
        break;
      case MsgKind.list:
        content = _ListCard(data: msg.payload as _ListData);
        break;
      case MsgKind.precautions:
        final p = msg.payload as _PrecautionPayload;
        content = Column(
          children: p.data.sections
              .map((s) => _PrecautionSection(section: s, full: false))
              .toList(),
        );
        break;
      case MsgKind.precautionDetail:
        final p = msg.payload as _PrecautionPayload;
        final s = p.data.sections.firstWhere((x) => x.key == p.key);
        content = _PrecautionSection(section: s, full: true);
        break;
      case MsgKind.warning:
        content = _WarningBox(text: msg.text);
        break;
      case MsgKind.text:
        content = const SizedBox.shrink();
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          content,
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(_formatTime(msg.time),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 20, 20, 16),
            color: AIAssistantScreen.primaryGreen,
            child: const Row(
              children: [
                Icon(Icons.history_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Chat History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AIAssistantScreen.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Start New Chat'),
                onPressed: () {
                  if (_busy()) return;
                  Navigator.pop(context);
                  _createNewChat();
                },
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _allSessions.length,
              itemBuilder: (context, index) {
                final session = _allSessions[index];
                final isSelected = session.id == _currentSession?.id;
                final subtitle = session.messages.isEmpty
                    ? 'No messages yet'
                    : _formatDate(session.messages.last.time);
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AIAssistantScreen.lightGreen
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.chat_bubble_outline_rounded,
                        color: AIAssistantScreen.primaryGreen),
                    title: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle:
                        Text(subtitle, style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.grey),
                      onPressed: () async {
                        if (_busy()) return;
                        final ok = await _confirmDelete();
                        if (ok) await _deleteChat(session.id);
                      },
                    ),
                    onTap: () {
                      if (_busy()) return;
                      setState(() {
                        _currentSession = session;
                        _selectedChild = null;
                        _pending = null;
                      });
                      Navigator.pop(context);
                      _scrollToBottom();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const CircleAvatar(
              radius: 14,
              backgroundColor: AIAssistantScreen.primaryGreen,
              child: Icon(Icons.smart_toy_rounded,
                  size: 15, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.circular(2),
                  ),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text(
                  _welcomeText,
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 36, top: 4, bottom: 14),
          child: Text(_formatTime(_welcomeTime),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
        ),
        ..._welcomeOptions.map(
          (o) => _QuickReplyButton(
            label: o.label,
            icon: o.icon,
            onTap: () => _onQuickReply(o.label),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(_selectedImageBytes!,
                height: 50, width: 50, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Image Attached',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_rounded, color: Colors.grey),
            onPressed: () => setState(() {
              _selectedImage = null;
              _selectedImageBytes = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined,
                color: AIAssistantScreen.primaryGreen),
            onPressed: _showImageSourceDialog,
          ),
          IconButton(
            icon: _isListening
                ? const _PulsingMicIcon()
                : const Icon(Icons.mic_none_rounded,
                    color: AIAssistantScreen.primaryGreen),
            onPressed: _toggleListening,
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _inputFocus,
              decoration: InputDecoration(
                hintText: _isListening
                    ? 'Sun raha hoon... boliye'
                    : 'Type your message...',
                hintStyle: const TextStyle(fontSize: 12),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AIAssistantScreen.primaryGreen,
            child: IconButton(
              icon: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final bubble = Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      decoration: BoxDecoration(
        color: msg.isUser ? AIAssistantScreen.primaryGreen : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft:
              msg.isUser ? const Radius.circular(16) : const Radius.circular(2),
          bottomRight:
              msg.isUser ? const Radius.circular(2) : const Radius.circular(16),
        ),
        border: msg.isUser ? null : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.imageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(msg.imageBytes!,
                  height: 150, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
          ] else if (msg.hasImage) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_outlined,
                    size: 14,
                    color:
                        msg.isUser ? Colors.white70 : Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Image attached (session only)',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color:
                        msg.isUser ? Colors.white70 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (msg.text.isNotEmpty)
            msg.isUser
                ? Text(
                    msg.text,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  )
                : MarkdownBody(
                    data: msg.text,
                    shrinkWrap: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                          fontSize: 13, color: Colors.black87, height: 1.4),
                      strong: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          height: 1.4),
                      em: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontStyle: FontStyle.italic),
                      listBullet:
                          const TextStyle(fontSize: 13, color: Colors.black87),
                      h1: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      h2: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      h3: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      code: TextStyle(
                        fontSize: 12,
                        backgroundColor: Colors.grey.shade100,
                        color: AIAssistantScreen.primaryGreen,
                      ),
                    ),
                  ),
        ],
      ),
    );

    final timestamp = Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: msg.isUser ? 0 : 4,
        right: msg.isUser ? 4 : 0,
      ),
      child: Text(
        _formatTime(msg.time),
        style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
      ),
    );

    final row = msg.isUser
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [bubble, timestamp],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: AIAssistantScreen.primaryGreen,
                child: Icon(Icons.smart_toy_rounded,
                    size: 15, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [bubble, timestamp],
                ),
              ),
            ],
          );

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 6),
            child: child,
          ),
        ),
        child: row,
      ),
    );
  }
}

// ===================================================================
// CARD WIDGETS
// ===================================================================
class _Shell extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? border;
  const _Shell({required this.child, this.color, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border ?? Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _CardTitle(
      {required this.icon,
      required this.text,
      this.color = AIAssistantScreen.primaryGreen});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final _Status status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: status.fg)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ChildAvatar extends StatelessWidget {
  final ChildModel child;
  final double size;
  const _ChildAvatar({required this.child, required this.size});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: AIAssistantScreen.lightGreen,
      child: Icon(Icons.child_care_rounded,
          color: AIAssistantScreen.primaryGreen, size: size * 0.6),
    );
    final url = child.avatarUrl;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: (url != null && url.trim().isNotEmpty)
            ? Image.network(url,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)
            : fallback,
      ),
    );
  }
}

class _ChildBar extends StatelessWidget {
  final ChildModel child;
  const _ChildBar(this.child);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AIAssistantScreen.lightGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AIAssistantScreen.borderGreen),
      ),
      child: Row(
        children: [
          _ChildAvatar(child: child, size: 34),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              '${child.name}  •  ${child.formattedAge}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AIAssistantScreen.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildGrid extends StatelessWidget {
  final List<ChildModel> kids;
  final bool enabled;
  final void Function(ChildModel) onSelect;
  const _ChildGrid(
      {required this.kids, required this.enabled, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = kids.length == 1 ? c.maxWidth : (c.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: kids
            .map((k) => SizedBox(
                  width: w,
                  child: Opacity(
                    opacity: enabled ? 1 : 0.6,
                    child: Material(
                      color: AIAssistantScreen.lightGreen,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: enabled ? () => onSelect(k) : null,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AIAssistantScreen.borderGreen),
                          ),
                          child: Stack(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Column(
                                  children: [
                                    _ChildAvatar(child: k, size: 56),
                                    const SizedBox(height: 8),
                                    Text(k.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    Text(k.formattedAge,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700)),
                                  ],
                                ),
                              ),
                              const Positioned(
                                right: 0,
                                top: 0,
                                child: Icon(Icons.chevron_right_rounded,
                                    color: AIAssistantScreen.primaryGreen),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      );
    });
  }
}

class _DueCard extends StatelessWidget {
  final _DueData data;
  const _DueCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChildBar(data.child),
        _Shell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle(
                  icon: Icons.event_available_rounded,
                  text: 'Next Due Vaccine'),
              if (data.rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    data.empty,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow('Stage', data.stage),
                      _InfoRow('Due Date', data.dueLabel),
                      _InfoRow('Age', data.child.formattedAge),
                      if (data.child.healthCenter.trim().isNotEmpty)
                        _InfoRow('Health Centre', data.child.healthCenter),
                      const SizedBox(height: 6),
                      Text('Vaccines',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      ...data.rows.map((r) => _RecordRow(row: r)),
                    ],
                  ),
                ),
              if (data.polio.isNotEmpty) ...[
                const SizedBox(height: 14),
                const _CardTitle(
                    icon: Icons.campaign_rounded, text: 'Polio Campaign'),
                ...data.polio.map((r) => _RecordRow(row: r)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MissedCard extends StatelessWidget {
  final _MissedData data;
  const _MissedCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final none = data.missed.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChildBar(data.child),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: none ? AIAssistantScreen.lightGreen : const Color(0xFFFDE2E2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                  none ? Icons.check_circle_rounded : Icons.warning_rounded,
                  color: none
                      ? AIAssistantScreen.primaryGreen
                      : AIAssistantScreen.warningRed),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  none
                      ? 'No missed doses found'
                      : '${data.missed.length} Missed Dose${data.missed.length == 1 ? '' : 's'} Found',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: none
                          ? AIAssistantScreen.primaryGreen
                          : AIAssistantScreen.warningRed),
                ),
              ),
            ],
          ),
        ),
        if (!none) ...[
          const SizedBox(height: 8),
          _Shell(
            child: Column(
              children: data.missed.map((r) => _RecordRow(row: r)).toList(),
            ),
          ),
          const SizedBox(height: 8),
          _Shell(
            color: const Color(0xFFEFF6FF),
            border: const Color(0xFFD6E6FB),
            child: const Row(
              children: [
                Icon(Icons.info_rounded, color: Color(0xFF2563EB), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "These vaccines are important for your child's protection. Please contact your vaccinator or health centre.",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (data.attempts.isNotEmpty) ...[
          const SizedBox(height: 8),
          _Shell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle(
                    icon: Icons.history_rounded,
                    text: 'Previous attempts recorded',
                    color: AIAssistantScreen.attentionOrange),
                const SizedBox(height: 4),
                ...data.attempts.map((r) => _RecordRow(row: r)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  final _Row row;
  const _RecordRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(Icons.medical_services_rounded,
              size: 20, color: row.status.fg.withOpacity(0.9)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(row.subtitle,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusChip(row.status),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final _ListData data;
  const _ListCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final nonEmpty = data.sections.where((s) => s.rows.isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChildBar(data.child),
        _Shell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardTitle(icon: data.icon, text: data.title),
              const SizedBox(height: 6),
              if (nonEmpty.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(data.empty,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700)),
                )
              else
                for (final s in nonEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 2),
                    child: Text(s.title,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AIAssistantScreen.primaryGreen)),
                  ),
                  ...s.rows.map((r) => _RecordRow(row: r)),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

// One precaution card. The title and points are written by the AI.
class _PrecautionSection extends StatelessWidget {
  final _PrecSection section;
  final bool full;
  const _PrecautionSection({required this.section, required this.full});

  @override
  Widget build(BuildContext context) {
    final shown = full ? section.points : section.points.take(2).toList();
    final warn = section.key == 'doctor';
    final color =
        warn ? AIAssistantScreen.warningRed : AIAssistantScreen.primaryGreen;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warn ? const Color(0xFFFDECEC) : AIAssistantScreen.lightGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: warn
                ? const Color(0xFFF5C2C2)
                : AIAssistantScreen.borderGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
              icon: _precIcon(section.key), text: section.title, color: color),
          const SizedBox(height: 6),
          ...shown.map((b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.circle, size: 6, color: color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(b,
                          style: const TextStyle(fontSize: 13, height: 1.35)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _WarningBox extends StatelessWidget {
  final String text;
  const _WarningBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5C2C2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_rounded,
              color: AIAssistantScreen.warningRed, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AIAssistantScreen.warningRed,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// SMALL WIDGETS
// ===================================================================
class _QuickReplyButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickReplyButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 12, right: 12),
      child: Material(
        color: AIAssistantScreen.lightGreen,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AIAssistantScreen.borderGreen),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AIAssistantScreen.primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AIAssistantScreen.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: AIAssistantScreen.primaryGreen,
            child: Icon(Icons.smart_toy_rounded, size: 15, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(2),
              ),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final t = (_controller.value + (i * 0.2)) % 1.0;
                    final bounce = (1 - (2 * t - 1).abs());
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Transform.translate(
                        offset: Offset(0, -4 * bounce),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AIAssistantScreen.primaryGreen
                                .withOpacity(0.5 + 0.5 * bounce),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingMicIcon extends StatefulWidget {
  const _PulsingMicIcon();

  @override
  State<_PulsingMicIcon> createState() => _PulsingMicIconState();
}

class _PulsingMicIconState extends State<_PulsingMicIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.25);
        return Transform.scale(
          scale: scale,
          child: Icon(Icons.mic_rounded,
              color: Colors.redAccent.withOpacity(0.9)),
        );
      },
    );
  }
}