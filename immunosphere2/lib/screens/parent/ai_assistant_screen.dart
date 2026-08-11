/*import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

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
  final String text;
  final bool isUser;
  final String? imagePath;
  final Uint8List? imageBytes;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
    this.imageBytes,
  });
}

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  static const Color primaryGreen = Color(0xFF0E9F6E);

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  // Replace with your actual Google AI Studio API Key
  static const String _apiKey = 'AQ.Ab8RN6JQJflSdhGMSkwu6eF2ctd4h3bVUJmTlVcqsKG_VIvoIw';

  late final GenerativeModel _model;
  ChatSession? _currentSession;
  final List<ChatSession> _allSessions = [];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Model changed to standard stable version
    _model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'You are ImmunoBot, the AI Health Assistant for ImmunoSphere app. '
        'Provide accurate, friendly, and helpful guidance regarding child vaccination schedules, '
        'immunization precautions, and general pediatric health. '
        'Always remind parents to consult a licensed medical doctor for serious symptoms or medical emergencies. '
        'You understand Urdu, Roman Urdu, and English fluently.',
      ),
    );

    _createNewChat();
  }

  void _createNewChat() {
    final String newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newSession = ChatSession(
      id: newId,
      title: 'New Conversation',
      messages: [], // Predefined welcome message removed
    );

    setState(() {
      _allSessions.insert(0, newSession);
      _currentSession = newSession;
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  void _deleteChat(String id) {
    setState(() {
      _allSessions.removeWhere((s) => s.id == id);
      if (_allSessions.isEmpty) {
        _createNewChat();
      } else {
        _currentSession = _allSessions.first;
      }
    });
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

    final imageToUpload = _selectedImage;
    final imageBytesToUpload = _selectedImageBytes;
    _textController.clear();

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      imagePath: imageToUpload?.path,
      imageBytes: imageBytesToUpload,
    );

    setState(() {
      _currentSession!.messages.add(userMessage);
      if (_currentSession!.messages.length == 1) {
        _currentSession!.title =
            text.isNotEmpty ? text : 'Image Inquiry';
      }
      _selectedImage = null;
      _selectedImageBytes = null;
      _isLoading = true;
    });

    _scrollToBottom();

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

      setState(() {
        _currentSession!.messages.add(
          ChatMessage(
            text: response.text ?? 'Sorry, I could not process your request.',
            isUser: false,
          ),
        );
      });
    } catch (e) {
      debugPrint("Gemini Exception Details: $e");
      setState(() {
        _currentSession!.messages.add(
          ChatMessage(
            text: 'Error connecting: $e',
            isUser: false,
          ),
        );
      });
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
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded,
                color: AIAssistantScreen.primaryGreen),
            tooltip: 'New Chat',
            onPressed: _createNewChat,
          ),
        ],
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
              child: (_currentSession?.messages.isEmpty ?? true)
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
                      itemCount: _currentSession?.messages.length ?? 0,
                      itemBuilder: (context, index) {
                        final msg = _currentSession!.messages[index];
                        return _buildMessageBubble(msg);
                      },
                    ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AIAssistantScreen.primaryGreen,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('ImmunoBot is thinking...',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
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
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Ask anything about vaccines...',
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

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AIAssistantScreen.primaryGreen
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: msg.isUser
                ? const Radius.circular(16)
                : const Radius.circular(0),
            bottomRight: msg.isUser
                ? const Radius.circular(0)
                : const Radius.circular(16),
          ),
          border: msg.isUser
              ? null
              : Border.all(color: Colors.grey.shade200),
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
            ],
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 13,
                color: msg.isUser ? Colors.white : Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
} */
import 'dart:async';
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
}