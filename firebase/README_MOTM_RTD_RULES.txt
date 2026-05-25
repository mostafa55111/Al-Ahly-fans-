قواعد Firebase Realtime Database — تصويت رجل المباراة (motm)
================================================================

الملف: rtdb_motm_voting_rules.SNIPPET.json
هذا المقطع يُدمج داخل كائن "rules" الجذر في Firebase Console (أو في database.rules.json مع firebase deploy).

السلوك:
1) الكتابة على motm/{fixtureId}/votes/{voteUid} مسموحة فقط إذا كان المستخدم مسجلاً (auth != null) و voteUid يطابق auth.uid.
   → لا يمكن لمستخدم زيادة أصوات لاعب آخر أو كتابة عقد متعددة لنفسه تحت UIDs مختلفة بدون حسابات متعددة.
2) كل عقدة تصويت = قيمة واحدة فقط (معرّف اللاعب كرقم). تغيير الصوت يستبدل القيمة؛ الحذف مرفوض (.validate يتطلب newData.exists()).
3) الرقم يجب أن يكون > 0 وأن يوجد مفتاحه تحت motm/{fixtureId}/players/ (نفس هيكل التطبيق).
4) يرفض الكتابة بعد انتهاء الجلسة: endsAt > now (بالمللي ثانية كما يخزّنها التطبيق).

مهم — إنشاء الجلسة (sessionRef.set على motm/{fixtureId}):
التطبيق الحالي ينشئ الجلسة من العميل. إذا جعلت قواعد motm/{fixtureId} للقراءة فقط للجميع، سيفشل الإنشاء.
الخيارات:
- أ) الإبقاء على قواعدك الحالية لمسار motm/{fixtureId} (تسمح بالكتابة للمستخدمين المسجلين أو كما تحدد)، مع دمج مقطع votes أعلاه فقط.
- ب) نقل إنشاء الجلسة إلى Cloud Function أو Console بصلاحيات Admin، ثم تقييد .write على العقدة الجذرية لـ motm.

النشر: firebase deploy --only database (من مشروع يحتوي database.rules.json مدمج).
