/**
 * إشعار دفع عند إنشاء edge جديد في social_graph/{target}/followers/{follower}
 * (تُكتب من التطبيق عبر SocialGraphService عند المتابعة).
 */
import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {onDocumentCreated} from "firebase-functions/v2/firestore";

initializeApp();

export const onSocialGraphNewFollower = onDocumentCreated(
  {
    document: "social_graph/{targetUid}/followers/{followerUid}",
    region: "me-west1",
  },
  async (event) => {
    const targetUid = event.params.targetUid as string;
    const followerUid = event.params.followerUid as string;
    if (!targetUid || !followerUid || targetUid === followerUid) {
      return;
    }

    const db = getFirestore();
    const [targetSnap, followerSnap] = await Promise.all([
      db.collection("users").doc(targetUid).get(),
      db.collection("users").doc(followerUid).get(),
    ]);

    const f = followerSnap.data() ?? {};
    const followerName = String(
      f.name ?? f.displayName ?? f.username ?? "مشجع",
    );
    const actorAvatarUrl = String(f.profilePic ?? f.photoURL ?? "");

    const title = "متابع جديد";
    const body = `${followerName} بدأ يتابعك`;

    const notifRef = db
      .collection("users")
      .doc(targetUid)
      .collection("notifications")
      .doc();

    const batch = db.batch();
    batch.set(notifRef, {
      type: "follow",
      title,
      body,
      actorUid: followerUid,
      actorName: followerName,
      actorAvatarUrl,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
      videoId: "",
    });
    batch.set(
      db.collection("users").doc(targetUid),
      {notificationsUnreadCount: FieldValue.increment(1)},
      {merge: true},
    );
    await batch.commit();

    const targetData = targetSnap.data();
    const fcmToken = targetData?.fcmToken as string | undefined;
    if (!fcmToken) {
      return;
    }

    await getMessaging().send({
      token: fcmToken,
      notification: {title, body},
      data: {
        type: "follow",
        videoId: "",
        actorUid: followerUid,
      },
    });
  },
);

function clubGlyphFromUserAppSource(raw: string | undefined): string {
  const s = (raw ?? "").toLowerCase();
  if (s.includes("zamalek")) return "🏹";
  return "🦅";
}

export const onSharedChatNewMessage = onDocumentCreated(
  {
    document: "shared_chats/{chatId}/messages/{messageId}",
    region: "me-west1",
  },
  async (event) => {
    const chatId = event.params.chatId as string;
    const snap = event.data;
    if (!snap) return;

    const msg = snap.data();
    const senderUid = msg?.senderUid as string | undefined;
    const text = String(msg?.text ?? "").trim();
    const imageUrl = String(msg?.imageUrl ?? "").trim();

    if (!senderUid) return;

    const db = getFirestore();
    const chatDoc = await db.collection("shared_chats").doc(chatId).get();
    const participants = chatDoc.data()?.participantUids as string[] | undefined;

    let recipient: string | undefined;
    if (Array.isArray(participants)) {
      recipient = participants.find((u) => u !== senderUid);
    }
    if (!recipient && chatId.includes("__")) {
      const parts = chatId.split("__");
      if (parts.length === 2) {
        recipient = parts[0] === senderUid ? parts[1] : parts[0];
      }
    }
    if (!recipient || recipient === senderUid) return;

    const [senderSnap, recipientSnap] = await Promise.all([
      db.collection("users").doc(senderUid).get(),
      db.collection("users").doc(recipient).get(),
    ]);

    const s = senderSnap.data() ?? {};
    const senderName = String(
      s.name ?? s.displayName ?? s.username ?? "صديق",
    );
    const clubGlyph = clubGlyphFromUserAppSource(s.fcmAppSource as string | undefined);

    const preview =
      imageUrl.length > 0 ? "📷 صورة" : (text.length > 0 ? text : "رسالة");

    const title = `رسالة جديدة من ${senderName}`;
    const body =
      preview.length > 120 ? preview.substring(0, 117) + "…" : preview;

    const fcmToken = recipientSnap.data()?.fcmToken as string | undefined;
    if (!fcmToken) return;

    await getMessaging().send({
      token: fcmToken,
      notification: {title, body},
      data: {
        type: "mutual_chat",
        chatId,
        senderUid,
        senderName,
        clubGlyph,
        title,
        body,
      },
    });
  },
);
