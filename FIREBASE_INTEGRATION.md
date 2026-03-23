# 🔥 Firebase Integration Guide

## نظرة عامة

هذا المشروع متكامل بالكامل مع Firebase ويستخدم:
- **Firebase Realtime Database** لتخزين البيانات
- **Firebase Authentication** للمصادقة
- **Firebase Storage** لتخزين الملفات

---

## 🏗️ معمارية Firebase

```
Firebase Project
├── Realtime Database
│   ├── posts/
│   ├── users/
│   ├── follows/
│   ├── achievements/
│   ├── leaderboard/
│   ├── matches/
│   ├── stories/
│   ├── comments/
│   └── notifications/
│
├── Authentication
│   ├── Email/Password
│   ├── Google Sign-In
│   └── Apple Sign-In
│
└── Storage
    ├── images/
    ├── videos/
    └── documents/
```

---

## 📋 هيكل البيانات

### 1. Posts (المنشورات)
```json
{
  "posts": {
    "postId1": {
      "id": "postId1",
      "userId": "userId1",
      "content": "محتوى المنشور",
      "mediaUrls": ["url1", "url2"],
      "likesCount": 150,
      "commentsCount": 25,
      "sharesCount": 10,
      "hashtags": ["#الأهلي", "#كرة"],
      "createdAt": "2026-03-06T10:30:00Z",
      "updatedAt": "2026-03-06T10:30:00Z",
      "likes": {
        "userId2": true,
        "userId3": true
      }
    }
  }
}
```

### 2. Users (المستخدمين)
```json
{
  "users": {
    "userId1": {
      "id": "userId1",
      "userName": "أحمد محمد",
      "email": "ahmed@example.com",
      "profileImage": "url",
      "bio": "مشجع أهلاوي",
      "followersCount": 500,
      "followingCount": 300,
      "postsCount": 50,
      "isVerified": true,
      "createdAt": "2026-01-01T00:00:00Z"
    }
  }
}
```

### 3. Follows (المتابعات)
```json
{
  "follows": {
    "userId1": {
      "userId2": true,
      "userId3": true
    }
  }
}
```

### 4. Achievements (الإنجازات)
```json
{
  "achievements": {
    "userId1": {
      "achievementId1": {
        "id": "achievementId1",
        "name": "أول منشور",
        "description": "نشر أول منشور",
        "icon": "url",
        "unlockedAt": "2026-03-06T10:30:00Z"
      }
    }
  }
}
```

### 5. Leaderboard (الترتيبات)
```json
{
  "leaderboard": {
    "userId1": {
      "rank": 1,
      "points": 5000,
      "level": 10,
      "achievements": 15,
      "updatedAt": "2026-03-06T10:30:00Z"
    }
  }
}
```

### 6. Matches (المباريات)
```json
{
  "matches": {
    "matchId1": {
      "id": "matchId1",
      "homeTeam": "الأهلي",
      "awayTeam": "الزمالك",
      "homeScore": 2,
      "awayScore": 1,
      "status": "live",
      "matchDate": "2026-03-06T20:00:00Z",
      "tournament": "الدوري المصري",
      "season": "2025-2026"
    }
  }
}
```

### 7. Stories (القصص)
```json
{
  "stories": {
    "storyId1": {
      "id": "storyId1",
      "userId": "userId1",
      "mediaUrl": "url",
      "mediaType": "image",
      "caption": "نص القصة",
      "viewsCount": 100,
      "reactionsCount": 25,
      "createdAt": "2026-03-06T10:30:00Z",
      "expiresAt": "2026-03-07T10:30:00Z"
    }
  }
}
```

### 8. Comments (التعليقات)
```json
{
  "comments": {
    "postId1": {
      "commentId1": {
        "id": "commentId1",
        "userId": "userId1",
        "content": "تعليق رائع",
        "likesCount": 5,
        "createdAt": "2026-03-06T10:30:00Z"
      }
    }
  }
}
```

### 9. Notifications (الإشعارات)
```json
{
  "notifications": {
    "userId1": {
      "notificationId1": {
        "id": "notificationId1",
        "type": "follow",
        "title": "متابع جديد",
        "message": "أحمد بدأ متابعتك",
        "isRead": false,
        "createdAt": "2026-03-06T10:30:00Z"
      }
    }
  }
}
```

---

## 🔧 إعداد Firebase

### 1. إنشاء Firebase Project

```bash
# تثبيت Firebase CLI
npm install -g firebase-tools

# تسجيل الدخول
firebase login

# إنشاء مشروع جديد
firebase init
```

### 2. تفعيل Realtime Database

```bash
firebase database:set / '{}'
```

### 3. قواعد الأمان (Security Rules)

```json
{
  "rules": {
    "posts": {
      ".read": true,
      ".write": "auth != null",
      "$postId": {
        ".validate": "newData.hasChildren(['id', 'userId', 'content'])"
      }
    },
    "users": {
      ".read": true,
      ".write": "auth != null && auth.uid == $uid",
      "$uid": {
        ".validate": "newData.hasChildren(['id', 'userName', 'email'])"
      }
    },
    "follows": {
      ".read": true,
      ".write": "auth != null",
      "$userId": {
        ".write": "auth.uid == $userId"
      }
    },
    "achievements": {
      ".read": true,
      ".write": "auth != null",
      "$userId": {
        ".write": "auth.uid == $userId"
      }
    },
    "leaderboard": {
      ".read": true,
      ".write": "auth != null"
    },
    "matches": {
      ".read": true,
      ".write": "auth != null && root.child('admins').child(auth.uid).exists()"
    },
    "stories": {
      ".read": true,
      ".write": "auth != null",
      "$storyId": {
        ".validate": "newData.hasChildren(['id', 'userId', 'mediaUrl'])"
      }
    },
    "comments": {
      ".read": true,
      ".write": "auth != null",
      "$postId": {
        "$commentId": {
          ".validate": "newData.hasChildren(['id', 'userId', 'content'])"
        }
      }
    },
    "notifications": {
      ".read": "auth != null && auth.uid == $userId",
      ".write": "auth != null",
      "$userId": {
        ".read": "auth.uid == $userId"
      }
    }
  }
}
```

---

## 💻 استخدام Firebase Service

### 1. تهيئة Firebase

```dart
import 'package:gomhor_alahly_clean_new/core/firebase/firebase_config.dart';
import 'package:gomhor_alahly_clean_new/core/firebase/firebase_service.dart';

// في main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Firebase
  await FirebaseConfig.initialize();
  
  // تهيئة Firebase Service
  FirebaseService().initialize();
  
  runApp(const MyApp());
}
```

### 2. إنشاء منشور

```dart
final firebaseService = FirebaseService();

final postId = await firebaseService.createPost({
  'userId': 'user123',
  'content': 'محتوى المنشور',
  'mediaUrls': ['url1', 'url2'],
  'hashtags': ['#الأهلي'],
});
```

### 3. الإعجاب بمنشور

```dart
await firebaseService.likePost('postId', 'userId');
```

### 4. متابعة مستخدم

```dart
await firebaseService.followUser('currentUserId', 'targetUserId');
```

### 5. إضافة إنجاز

```dart
await firebaseService.addAchievement('userId', {
  'name': 'أول منشور',
  'description': 'نشر أول منشور',
  'icon': 'url',
});
```

### 6. تحديث الترتيب

```dart
await firebaseService.updateLeaderboardRank('userId', {
  'rank': 1,
  'points': 5000,
  'level': 10,
});
```

### 7. إنشاء مباراة

```dart
final matchId = await firebaseService.createMatch({
  'homeTeam': 'الأهلي',
  'awayTeam': 'الزمالك',
  'homeScore': 0,
  'awayScore': 0,
  'status': 'scheduled',
  'matchDate': DateTime.now().toIso8601String(),
});
```

### 8. إنشاء قصة

```dart
final storyId = await firebaseService.createStory('userId', {
  'mediaUrl': 'url',
  'mediaType': 'image',
  'caption': 'نص القصة',
});
```

### 9. إضافة تعليق

```dart
final commentId = await firebaseService.addComment('postId', {
  'userId': 'userId',
  'content': 'تعليق رائع',
});
```

### 10. رفع صورة

```dart
final imageUrl = await firebaseService.uploadImage(
  '/path/to/image.jpg',
  'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
);
```

---

## 🔐 الأمان والخصوصية

### 1. Authentication
- تحقق من المستخدم قبل أي عملية كتابة
- استخدم Firebase Auth للمصادقة

### 2. Database Rules
- اقرأ البيانات العامة فقط
- اكتب فقط البيانات الخاصة بك
- تحقق من صحة البيانات

### 3. Storage Rules
```json
{
  "rules": {
    "images": {
      ".read": true,
      ".write": "auth != null"
    },
    "videos": {
      ".read": true,
      ".write": "auth != null"
    }
  }
}
```

---

## 📊 مراقبة الأداء

### 1. تفعيل Offline Persistence
```dart
FirebaseDatabase.instance.setPersistenceEnabled(true);
```

### 2. تفعيل Logging
```dart
FirebaseDatabase.instance.setLoggingEnabled(true);
```

### 3. مراقبة الاتصال
```dart
FirebaseDatabase.instance.ref('.info/connected').onValue.listen((event) {
  if (event.snapshot.value == true) {
    print('✅ متصل بـ Firebase');
  } else {
    print('❌ غير متصل بـ Firebase');
  }
});
```

---

## 🚀 نصائح الأداء

1. **استخدم Indexes** للاستعلامات الكبيرة
2. **قلل عدد الاستعلامات** باستخدام Pagination
3. **استخدم Caching** للبيانات المتكررة
4. **حذف البيانات القديمة** بشكل دوري
5. **استخدم Transactions** للعمليات المعقدة

---

## 📚 المراجع

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Realtime Database](https://firebase.google.com/docs/database)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Firebase Storage](https://firebase.google.com/docs/storage)

---

## ✅ قائمة التحقق

- [ ] تم إنشاء Firebase Project
- [ ] تم تفعيل Realtime Database
- [ ] تم تفعيل Authentication
- [ ] تم تفعيل Storage
- [ ] تم إضافة Security Rules
- [ ] تم إضافة Indexes
- [ ] تم اختبار الاتصال
- [ ] تم اختبار العمليات الأساسية

---

**آخر تحديث**: 6 مارس 2026
