import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gomhor_alahly_clean_new/core/chat/chat_message_vm.dart';
import 'package:gomhor_alahly_clean_new/core/chat/chat_service.dart';
import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';
import 'package:gomhor_alahly_clean_new/core/services/shared_friend_chat_service.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/core/widgets/club_badge.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/custom_button.dart';
import 'package:gomhor_alahly_clean_new/features/social/presentation/widgets/chat_message_bubble.dart';

/// دردشة مع صديق متبادل — رأس الشاشة يعرض [UserNameWithClubBadge].
class MutualFriendChatPage extends StatefulWidget {
  const MutualFriendChatPage({
    super.key,
    required this.peerUid,
    this.fallbackName = '',
    this.fallbackAvatar = '',
  });

  final String peerUid;
  final String fallbackName;
  final String fallbackAvatar;

  @override
  State<MutualFriendChatPage> createState() => _MutualFriendChatPageState();
}

class _MutualFriendChatPageState extends State<MutualFriendChatPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();
  bool _sending = false;

  String? get _me => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openChatOrPop() async {
    final me = _me;
    if (me == null) return;
    final ok = await SharedFriendChatService.isMutualFriend(
      viewerUid: me,
      peerUid: widget.peerUid,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يمكن الدردشة فقط مع الأصدقاء المتبادلين.',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      Navigator.of(context).pop();
      return;
    }
    await SharedFriendChatService.ensureChatRoom(
      myUid: me,
      peerUid: widget.peerUid,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openChatOrPop());
  }

  Future<void> _sendText() async {
    final me = _me;
    if (me == null || _sending) return;
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    setState(() => _sending = true);
    try {
      await SharedFriendChatService.sendTextMessage(
        peerUid: widget.peerUid,
        text: t,
      );
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e', style: GoogleFonts.cairo())),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final me = _me;
    if (me == null || _sending) return;
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (file == null) return;
    if (!_cloudinary.isReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'إعدادات Cloudinary غير مكتملة.',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
      return;
    }
    setState(() => _sending = true);
    try {
      final url = await _cloudinary.uploadImage(File(file.path));
      if (url.isEmpty) throw Exception('فشل الرفع');
      await SharedFriendChatService.sendImageMessage(
        peerUid: widget.peerUid,
        imageUrl: url,
        caption: _controller.text.trim(),
      );
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e', style: GoogleFonts.cairo())),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    final accent = Theme.of(context).colorScheme.primary;

    if (me == null) {
      return const Scaffold(
        body: Center(child: Text('سجّل الدخول للدردشة')),
      );
    }

    final chatId = SharedFriendChatService.pairChatId(me, widget.peerUid);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF101115),
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.peerUid)
              .snapshots(),
          builder: (context, snap) {
            final d = snap.data?.data();
            final name = (d?['name'] ??
                    d?['displayName'] ??
                    widget.fallbackName)
                .toString()
                .trim();
            final appSrc = (d?['fcmAppSource'] ??
                    d?['firestoreAppSource'] ??
                    d?['app_source'])
                .toString()
                .trim();
            return UserNameWithClubBadge(
              name: name.isEmpty ? 'صديق' : name,
              appSource: appSrc.isEmpty ? null : appSrc,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 17,
              ),
              badgeSize: 16,
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _SharedChatMessagesList(
              chatId: chatId,
              me: me,
              accent: accent,
              scrollController: _scroll,
            ),
          ),
          Material(
            color: AppColors.mediumBlack,
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    CustomIconButton(
                      tooltip: 'إرفاق صورة',
                      icon: Icons.image_outlined,
                      semanticsLabel: 'زر إرفاق صورة للمحادثة',
                      color: AppColors.white,
                      onPressed: _sending ? null : _pickAndSendImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        style: GoogleFonts.cairo(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'رسالة…',
                          hintStyle:
                              GoogleFonts.cairo(color: AppColors.mediumGray),
                          filled: true,
                          fillColor: AppColors.darkBlack,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _sendText(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      tooltip: 'إرسال الرسالة',
                      onPressed: _sending ? null : _sendText,
                      icon: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// قائمة رسائل مع [StreamSubscription] يُلغى في [dispose] — يطابق متطلبات التنظيف (Robo / app-test).
class _SharedChatMessagesList extends StatefulWidget {
  const _SharedChatMessagesList({
    required this.chatId,
    required this.me,
    required this.accent,
    required this.scrollController,
  });

  final String chatId;
  final String me;
  final Color accent;
  final ScrollController scrollController;

  @override
  State<_SharedChatMessagesList> createState() =>
      _SharedChatMessagesListState();
}

class _SharedChatMessagesListState extends State<_SharedChatMessagesList> {
  StreamSubscription<List<ChatMessageVm>>? _sub;
  List<ChatMessageVm> _items = const [];
  Object? _error;
  var _waiting = true;

  @override
  void initState() {
    super.initState();
    _attachSubscription();
  }

  void _attachSubscription() {
    _sub?.cancel();
    _sub = null;
    if (mounted) {
      setState(() {
        _waiting = true;
        _error = null;
      });
    }
    _sub = ChatService.instance.watchSharedChatMessages(widget.chatId).listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _items = list;
          _waiting = false;
          _error = null;
        });
      },
      onError: (Object e, StackTrace _) {
        if (!mounted) return;
        setState(() {
          _error = e;
          _waiting = false;
        });
      },
    );
  }

  @override
  void didUpdateWidget(covariant _SharedChatMessagesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      setState(() => _items = const []);
      _attachSubscription();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(
          'تعذّر تحميل الرسائل',
          style: GoogleFonts.cairo(color: AppColors.mediumGray),
        ),
      );
    }
    if (_waiting && _items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final list = _items;
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      cacheExtent: 400,
      itemCount: list.length,
      itemBuilder: (context, i) {
        final row = list[i];
        final isMine = row.senderUid == widget.me;
        return RepaintBoundary(
          child: Align(
            alignment:
                isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: ChatMessageBubble(
              text: row.text,
              imageUrl: row.imageUrl,
              isMine: isMine,
              accentColor: widget.accent,
            ),
          ),
        );
      },
    );
  }
}
