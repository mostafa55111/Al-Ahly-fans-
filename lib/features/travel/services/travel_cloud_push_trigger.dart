import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// يجب أن يطابق `region` في `travel_system/index.js` → `exports.notifyTravelTrip`.
const String kTravelFunctionsRegion = 'me-central1';

/// يستدعي Cloud Function `notifyTravelTrip` بعد أن يكتب الأدمن على RTDB.
///
/// انشر دالة تعتمد `tripId` و`type`:
/// - `chat_open` → ترسل لمشتركي موضوع الشات فقط (`tr_{tripId}_chat`).
/// - `bus_move` → ترسل لمشتركي موضوع الحافلة (`tr_{tripId}_bus`).
///
/// إذا لم تكن الدالة منشورة يُهمَل الخطأ ولا يتوقف التطبيق.
Future<void> triggerTravelTripPush({
  required String tripId,
  required String type,
}) async {
  try {
    await FirebaseFunctions.instanceFor(
      app: Firebase.app(),
      region: kTravelFunctionsRegion,
    )
        .httpsCallable('notifyTravelTrip')
        .call(<String, dynamic>{
      'tripId': tripId,
      'type': type,
    });
  } catch (e) {
    if (kDebugMode) {
      debugPrint('notifyTravelTrip callable: $e');
    }
  }
}
