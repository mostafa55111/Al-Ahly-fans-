/**
 * Cloud Functions v2 — نظام الترحال (codebase: travel_system)
 *
 * النشر: firebase deploy --only functions:travel_system
 *
 * المواضيع تطابق TravelTripFcmService في Flutter: tr_{sanitizedTripId}_bus | _chat
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

/** يطابق RegExp في Flutter: [^a-zA-Z0-9\-_.~%] → '_' */
function sanitizeTripIdSegment(id) {
  return String(id).replace(/[^a-zA-Z0-9\-_.~%]/g, "_");
}

const ALLOWED_TYPES = new Set(["chat_open", "bus_move"]);

exports.notifyTravelTrip = onCall(
  {
    region: "me-central1",
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError(
        "unauthenticated",
        "يجب تسجيل الدخول لإرسال إشعارات الرحلة."
      );
    }

    const data = request.data || {};
    const tripId = data.tripId;
    const type = data.type;

    if (typeof tripId !== "string" || tripId.trim().length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "tripId مطلوب ويجب أن يكون نصاً غير فارغ."
      );
    }

    if (typeof type !== "string" || !ALLOWED_TYPES.has(type)) {
      throw new HttpsError(
        "invalid-argument",
        "type يجب أن يكون chat_open أو bus_move."
      );
    }

    const safe = sanitizeTripIdSegment(tripId.trim());
    let topic;
    let title;
    let body;

    if (type === "bus_move") {
      topic = `tr_${safe}_bus`;
      title = "حافلة الترحال 🚌";
      body = "استعدوا، الحافلة بدأت التحرك الآن!";
    } else {
      topic = `tr_${safe}_chat`;
      title = "شات الرحلة 💬";
      body = "تم فتح الشات الآن للتواصل مع رفاق الرحلة";
    }

    const message = {
      topic,
      notification: {
        title,
        body,
      },
      android: {
        notification: {
          channelId: "high_importance_channel",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
      data: {
        tripId: tripId.trim(),
        type,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    try {
      const messageId = await admin.messaging().send(message);
      return {
        success: true,
        messageId,
        topic,
        type,
      };
    } catch (err) {
      console.error("notifyTravelTrip send failed:", err);
      throw new HttpsError(
        "internal",
        "تعذر إرسال الإشعار. حاول مرة أخرى."
      );
    }
  }
);
