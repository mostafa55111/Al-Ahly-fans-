/// حالة عنصر تحقق بشري — لا أتمتة وهمية.
enum HumanValidationStatus {
  pending,
  validated,
  failed,
  blocked,
}

/// فئة التحقق.
enum HumanValidationCategory {
  fanFlow,
  ownerFlow,
  reconnect,
  finalize,
  idleState,
}

/// عنصر قائمة تحقق يدوي.
class HumanValidationItem {
  const HumanValidationItem({
    required this.id,
    required this.category,
    required this.titleAr,
    required this.stepsAr,
    this.status = HumanValidationStatus.pending,
    this.notes = '',
  });

  final String id;
  final HumanValidationCategory category;
  final String titleAr;
  final List<String> stepsAr;
  final HumanValidationStatus status;
  final String notes;

  HumanValidationItem copyWith({
    HumanValidationStatus? status,
    String? notes,
  }) {
    return HumanValidationItem(
      id: id,
      category: category,
      titleAr: titleAr,
      stepsAr: stepsAr,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

/// تقرير التحقق البشري.
class HumanValidationReport {
  const HumanValidationReport({
    required this.items,
    required this.validatedCount,
    required this.failedCount,
    required this.blockedCount,
    required this.pendingCount,
    required this.readyForGoLive,
  });

  final List<HumanValidationItem> items;
  final int validatedCount;
  final int failedCount;
  final int blockedCount;
  final int pendingCount;
  final bool readyForGoLive;
}

/// قوائم تحقق منظمة — للمختبرين الحقيقيين.
class HumanValidationSuite {
  HumanValidationSuite();

  final List<HumanValidationItem> _items = _defaultChecklist();

  List<HumanValidationItem> get items => List.unmodifiable(_items);

  static List<HumanValidationItem> _defaultChecklist() => [
        const HumanValidationItem(
          id: 'fan_stadium_load',
          category: HumanValidationCategory.fanFlow,
          titleAr: 'تحميل الميدان',
          stepsAr: [
            'افتح تبويب الجمهور بإنترنت عادي',
            'تأكد من ظهور الملعب أو idle بدون crash',
            'لا شاشات debug',
          ],
        ),
        const HumanValidationItem(
          id: 'fan_vote_live',
          category: HumanValidationCategory.fanFlow,
          titleAr: 'تصويت مباشر',
          stepsAr: [
            'أثناء جلسة live صوّت على لاعب',
            'تأكد من استجابة الكرت < 120ms',
            'لا تجميد ولا ازدواجية صوت',
          ],
        ),
        const HumanValidationItem(
          id: 'fan_idle',
          category: HumanValidationCategory.idleState,
          titleAr: 'بدون جلسة',
          stepsAr: [
            'أغلق التصويت من المالك',
            'تأكد idle واضح للمشجع',
            'لا أخطاء أو شاشة فارغة مربكة',
          ],
        ),
        const HumanValidationItem(
          id: 'owner_login',
          category: HumanValidationCategory.ownerFlow,
          titleAr: 'دخول المالك',
          stepsAr: [
            'سجّل دخول Firebase للمالك',
            'غير المالك = لا وصول',
            'تسجيل خروج يمسح الصلاحية',
          ],
        ),
        const HumanValidationItem(
          id: 'owner_publish',
          category: HumanValidationCategory.ownerFlow,
          titleAr: 'نشر جلسة',
          stepsAr: [
            'قالب → معاينة → نشر',
            'أقل من 30 ثانية عند قالب جاهز',
            'منع النشر المكرر',
          ],
        ),
        const HumanValidationItem(
          id: 'reconnect_weak',
          category: HumanValidationCategory.reconnect,
          titleAr: 'شبكة ضعيفة',
          stepsAr: [
            'فعّل وضع الطيران 10 ثوانٍ',
            'أعد الاتصال — التصويت يستأنف',
            'لا finalize تلقائي',
          ],
        ),
        const HumanValidationItem(
          id: 'finalize_winner',
          category: HumanValidationCategory.finalize,
          titleAr: 'إنهاء وإعلان الفائز',
          stepsAr: [
            'بعد إغلاق التصويت انتظر finalize',
            'تأكد إظهار الفائز مرة واحدة',
            'لا duplicate finalize',
          ],
        ),
      ];

  void setStatus(String id, HumanValidationStatus status, {String? notes}) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _items[i] = _items[i].copyWith(status: status, notes: notes ?? _items[i].notes);
  }

  HumanValidationReport buildReport() {
    var validated = 0;
    var failed = 0;
    var blocked = 0;
    var pending = 0;
    for (final item in _items) {
      switch (item.status) {
        case HumanValidationStatus.validated:
          validated++;
        case HumanValidationStatus.failed:
          failed++;
        case HumanValidationStatus.blocked:
          blocked++;
        case HumanValidationStatus.pending:
          pending++;
      }
    }
    final ready = failed == 0 && blocked == 0 && pending == 0 && validated > 0;
    return HumanValidationReport(
      items: List.unmodifiable(_items),
      validatedCount: validated,
      failedCount: failed,
      blockedCount: blocked,
      pendingCount: pending,
      readyForGoLive: ready,
    );
  }
}
