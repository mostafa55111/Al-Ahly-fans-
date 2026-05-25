import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/travel/data/travel_rtdb_paths.dart';

/// شات الرحلة — قراءة لحظية من `travel/trips/{tripId}/chats` (مزامنة Firebase).
///
/// يُفترض أن الوصول لهذه الصفحة مقيد في الواجهة بـ [FanTravelStatus.canAccessTripChat]
/// (صعود مسجّل + `chatSessionActive` + رحلة غير منتهية).
///
/// [readOnly] يُستعمل بعد مسح QR نهاية الرحلة من «ساحة الجمهور».
class TravelTripChatPage extends StatefulWidget {
  const TravelTripChatPage({
    super.key,
    required this.tripId,
    required this.tripCompanyName,
    this.readOnly = false,
    this.readOnlyBanner,
  });

  final String tripId;
  final String tripCompanyName;

  /// للعرض فقط — لا إرسال رسائل.
  final bool readOnly;

  /// رسالة تظهر أسفل الشريط عند [readOnly] (مثلاً بعد انتهاء الرحلة).
  final String? readOnlyBanner;

  @override
  State<TravelTripChatPage> createState() => _TravelTripChatPageState();
}

/// غرفة دردشة الرحلة (اسم واجهة ساحة الجمهور) — يفتحها مسح QR البداية/النهاية.
class TripChatRoom extends TravelTripChatPage {
  const TripChatRoom({
    super.key,
    required super.tripId,
    required super.tripCompanyName,
    super.readOnly = false,
    super.readOnlyBanner,
  });
}

class _TravelTripChatPageState extends State<TravelTripChatPage> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  DatabaseReference get _chatsRef =>
      FirebaseDatabase.instance.ref(TravelRtdbPaths.tripChats(widget.tripId));

  Future<void> _send() async {
    if (widget.readOnly) return;

    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : 'مشجع';

    await _chatsRef.push().set({
      'text': text,
      'uid': user.uid,
      'fanName': name,
      'createdAt': ServerValue.timestamp,
    });
    if (!mounted) return;
    _textCtrl.clear();
  }

  List<_ChatMsg> _parseMessages(DataSnapshot snap) {
    final out = <_ChatMsg>[];
    if (!snap.exists || snap.value is! Map) return out;
    final map = Map<dynamic, dynamic>.from(snap.value! as Map);
    for (final e in map.entries) {
      final id = e.key.toString();
      final v = e.value;
      if (v is! Map) continue;
      final m = Map<String, dynamic>.from(v);
      final ts = m['createdAt'];
      int? ms;
      if (ts is int) ms = ts;
      if (ts is num) ms = ts.toInt();
      out.add(
        _ChatMsg(
          id: id,
          text: m['text'] as String? ?? '',
          uid: m['uid'] as String? ?? '',
          fanName: m['fanName'] as String? ?? '',
          createdAtMs: ms,
        ),
      );
    }
    out.sort((a, b) {
      final ca = a.createdAtMs ?? 0;
      final cb = b.createdAtMs ?? 0;
      return ca.compareTo(cb);
    });
    return out;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final endBanner = widget.readOnlyBanner ??
        'انتهت الرحلة.. نلتقي في المدرج القادم';

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text(
          'شات الرحلة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.readOnly)
            Material(
              color: primary.withValues(alpha: 0.18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        endBanner,
                        style: GoogleFonts.cairo(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.tripCompanyName,
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.readOnly
                      ? 'الدردشة للقراءة فقط'
                      : 'مزامنة فورية من قاعدة البيانات (Firebase)',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _chatsRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'خطأ في تحميل الرسائل',
                      style: GoogleFonts.cairo(color: AppColors.error),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: primary),
                  );
                }
                final msgs =
                    _parseMessages(snapshot.data!.snapshot);
                if (msgs.isEmpty) {
                  return Center(
                    child: Text(
                      widget.readOnly
                          ? 'لا رسائل بعد.'
                          : 'لا رسائل بعد. ابدأ المحادثة!',
                      style: GoogleFonts.cairo(color: AppColors.mediumGray),
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final mine = myUid != null && m.uid == myUid;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                        ),
                        decoration: BoxDecoration(
                          color: mine
                              ? primary.withValues(alpha: 0.35)
                              : AppColors.mediumBlack,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: secondary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: mine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!mine)
                              Text(
                                m.fanName,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: secondary,
                                ),
                              ),
                            Text(
                              m.text,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: AppColors.white,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      readOnly: widget.readOnly,
                      enabled: !widget.readOnly,
                      style: GoogleFonts.cairo(color: AppColors.white),
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: widget.readOnly
                            ? 'انتهت صلاحية الكتابة'
                            : 'اكتب رسالة…',
                        hintStyle:
                            GoogleFonts.cairo(color: AppColors.mediumGray),
                        filled: true,
                        fillColor: AppColors.mediumBlack,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: widget.readOnly ? null : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.mediumBlack,
                    ),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMsg {
  _ChatMsg({
    required this.id,
    required this.text,
    required this.uid,
    required this.fanName,
    this.createdAtMs,
  });

  final String id;
  final String text;
  final String uid;
  final String fanName;
  final int? createdAtMs;
}
