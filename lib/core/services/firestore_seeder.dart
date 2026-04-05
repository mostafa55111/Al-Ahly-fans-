import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to seed Firestore with sample reel data for testing
class FirestoreSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Seed Firestore with sample reel data
  Future<void> seedSampleReels() async {
    try {
      print('🌱 Seeding Firestore with sample reels...');
      
      final sampleReels = [
        {
          'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          'thumbnailUrl': 'https://picsum.photos/400/700?random=1',
          'caption': 'أهداف الأهلي المميزة في مباراة اليوم ⚽',
          'userId': 'user_1',
          'userName': 'أحمد محمود',
          'userProfilePic': 'https://picsum.photos/100/100?random=1',
          'likes': 1250,
          'comments': 89,
          'shares': 45,
          'saves': 23,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
          'thumbnailUrl': 'https://picsum.photos/400/700?random=2',
          'caption': 'لحظات رائعة من تدريبات الفريق اليوم 🏃‍♂️',
          'userId': 'user_2',
          'userName': 'محمد سالم',
          'userProfilePic': 'https://picsum.photos/100/100?random=2',
          'likes': 892,
          'comments': 67,
          'shares': 34,
          'saves': 18,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
          'thumbnailUrl': 'https://picsum.photos/400/700?random=3',
          'caption': 'احتفالات الجمهور بعد الفوز 🎉',
          'userId': 'user_3',
          'userName': 'خالد أحمد',
          'userProfilePic': 'https://picsum.photos/100/100?random=3',
          'likes': 2103,
          'comments': 156,
          'shares': 89,
          'saves': 67,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
          'thumbnailUrl': 'https://picsum.photos/400/700?random=4',
          'caption': 'مقابلة مع اللاعب بعد المباراة 🎤',
          'userId': 'user_4',
          'userName': 'يوسف محمد',
          'userProfilePic': 'https://picsum.photos/100/100?random=4',
          'likes': 567,
          'comments': 34,
          'shares': 12,
          'saves': 8,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
          'thumbnailUrl': 'https://picsum.photos/400/700?random=5',
          'caption': 'أجمل لحظات المباراة ⭐',
          'userId': 'user_5',
          'userName': 'عمر علي',
          'userProfilePic': 'https://picsum.photos/100/100?random=5',
          'likes': 3456,
          'comments': 234,
          'shares': 123,
          'saves': 89,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
          'thumbnailUrl': 'https://picsum.photos/400/700?random=6',
          'caption': 'خلفية الكواليس 🎬',
          'userId': 'user_6',
          'userName': 'حسن خالد',
          'userProfilePic': 'https://picsum.photos/100/100?random=6',
          'likes': 789,
          'comments': 45,
          'shares': 23,
          'saves': 15,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
          'thumbnailUrl': 'https://picsum.photos/400/700?random=7',
          'caption': 'تحليل أداء الفريق 📊',
          'userId': 'user_7',
          'userName': 'سالم محمد',
          'userProfilePic': 'https://picsum.photos/100/100?random=7',
          'likes': 432,
          'comments': 28,
          'shares': 16,
          'saves': 11,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
          'thumbnailUrl': 'https://picsum.photos/400/700?random=8',
          'caption': 'إحماء الفريق قبل المباراة 🏋️‍♂️',
          'userId': 'user_8',
          'userName': 'راشد أحمد',
          'userProfilePic': 'https://picsum.photos/100/100?random=8',
          'likes': 1567,
          'comments': 98,
          'shares': 56,
          'saves': 34,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
          'thumbnailUrl': 'https://picsum.photos/400/700?random=9',
          'caption': 'لمسة تقنية رائعة 🎯',
          'userId': 'user_9',
          'userName': 'فهد سالم',
          'userProfilePic': 'https://picsum.photos/100/100?random=9',
          'likes': 2341,
          'comments': 167,
          'shares': 78,
          'saves': 45,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
          'thumbnailUrl': 'https://picsum.photos/400/700?random=10',
          'caption': 'روح الفريق لا تقهر 💪',
          'userId': 'user_10',
          'userName': 'نادر علي',
          'userProfilePic': 'https://picsum.photos/100/100?random=10',
          'likes': 3214,
          'comments': 189,
          'shares': 97,
          'saves': 56,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      ];

      // Add sample reels to Firestore
      for (int i = 0; i < sampleReels.length; i++) {
        final reelData = sampleReels[i];
        await _firestore.collection('reels').add(reelData);
        print('🌱 Added sample reel ${i + 1}/10');
      }

      print('✅ Successfully seeded Firestore with ${sampleReels.length} sample reels!');
    } catch (e) {
      print('❌ Error seeding Firestore: $e');
      rethrow;
    }
  }

  /// Clear all sample data from Firestore
  Future<void> clearSampleData() async {
    try {
      print('🧹 Clearing sample data from Firestore...');
      
      final reelsSnapshot = await _firestore.collection('reels').get();
      
      for (final doc in reelsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      print('✅ Cleared ${reelsSnapshot.docs.length} reels from Firestore');
    } catch (e) {
      print('❌ Error clearing sample data: $e');
      rethrow;
    }
  }

  /// Check if Firestore has sample data
  Future<bool> hasSampleData() async {
    try {
      final snapshot = await _firestore.collection('reels').limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking sample data: $e');
      return false;
    }
  }
}
