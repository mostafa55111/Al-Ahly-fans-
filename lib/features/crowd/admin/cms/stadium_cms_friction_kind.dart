/// انقطاع معرفي — ليس خطأ تقنيًا.
enum StadiumCmsFrictionKind {
  hesitation,
  tabSwitch,
  backNavigation,
  previewBeforeReady,
  librarySearch,
  kitSwitch,
  repeatedTap,
  saveHunt,
}

extension StadiumCmsFrictionKindLabel on StadiumCmsFrictionKind {
  String get labelAr {
    switch (this) {
      case StadiumCmsFrictionKind.hesitation:
        return 'توقف للتفكير';
      case StadiumCmsFrictionKind.tabSwitch:
        return 'تنقل مربك';
      case StadiumCmsFrictionKind.backNavigation:
        return 'رجوع';
      case StadiumCmsFrictionKind.previewBeforeReady:
        return 'معاينة مبكرة';
      case StadiumCmsFrictionKind.librarySearch:
        return 'بحث متكرر';
      case StadiumCmsFrictionKind.kitSwitch:
        return 'تبديل Kit';
      case StadiumCmsFrictionKind.repeatedTap:
        return 'ضغط مكرر';
      case StadiumCmsFrictionKind.saveHunt:
        return 'ارتباك الحفظ';
    }
  }

  /// قرار UX المقترح عند تكرار هذا النوع.
  String get uxDecisionHint {
    switch (this) {
      case StadiumCmsFrictionKind.hesitation:
        return 'بسّط الخطوة التالية أو اجعلها أوضح';
      case StadiumCmsFrictionKind.tabSwitch:
        return 'ادمج الإجراء في تبويب واحد';
      case StadiumCmsFrictionKind.backNavigation:
        return 'ثبّت التدفق — تقليل الحاجة للخروج';
      case StadiumCmsFrictionKind.previewBeforeReady:
        return 'أخّر المعاينة حتى اكتمال التشكيلة';
      case StadiumCmsFrictionKind.librarySearch:
        return 'حسّن الفلاتر أو Kit جاهز';
      case StadiumCmsFrictionKind.kitSwitch:
        return 'وضّح Kit النشط — تقليل التبديل';
      case StadiumCmsFrictionKind.repeatedTap:
        return 'أضف تأكيدًا بصريًا أو عطّل الزر مؤقتًا';
      case StadiumCmsFrictionKind.saveHunt:
        return 'زر حفظ واحد واضح في مكان ثابت';
    }
  }
}
