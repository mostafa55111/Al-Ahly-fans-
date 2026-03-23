# معمارية تطبيق جمهور الأهلي

## 📐 نظرة عامة على المعمارية

يتبع التطبيق **Clean Architecture** مع **Bloc Pattern** للـ State Management.

```
┌─────────────────────────────────────────────────────────────┐
│                   Presentation Layer                         │
│  (Screens, Widgets, Pages, Bloc - Events, States)           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   Domain Layer                               │
│  (Entities, Repositories Interface, Use Cases)              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   Data Layer                                 │
│  (Models, Data Sources, Repository Implementation)          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   External Layer                             │
│  (Firebase, APIs, Local Storage)                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 هيكل المشروع

```
lib/
├── core/                          # الأساسيات المشتركة
│   ├── exceptions/               # الاستثناءات المخصصة
│   ├── usecases/                # Base Use Cases
│   ├── utils/                   # الأدوات المساعدة
│   └── theme/                   # الثيم والألوان
│
├── features/                     # المميزات الرئيسية
│   ├── social_feed/             # الفيد الاجتماعي
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       └── widgets/
│   │
│   ├── stories/                 # نظام القصص
│   ├── follow_system/           # نظام المتابعة
│   ├── achievements/            # نظام الإنجازات
│   ├── leaderboard/             # لوحة المتصدرين
│   ├── live_match_updates/      # تحديثات المباريات المباشرة
│   ├── reels/                   # الريلز
│   ├── direct_messages/         # الرسائل المباشرة
│   ├── search/                  # البحث
│   ├── profile/                 # البروفايل
│   ├── voting_match_center/     # مركز التصويت
│   ├── marketplace/             # السوق
│   ├── bus_booking/             # حجز الحافلات
│   └── admin_panel/             # لوحة التحكم
│
├── shared/                       # الموارد المشتركة
│   ├── widgets/                 # الـ Widgets المشتركة
│   ├── utils/                   # الأدوات المشتركة
│   ├── constants/               # الثوابت
│   └── models/                  # النماذج المشتركة
│
├── main.dart                    # نقطة الدخول
└── firebase_options.dart        # إعدادات Firebase
```

---

## 🏗️ طبقات المعمارية

### 1️⃣ Presentation Layer

**المسؤولية**: عرض البيانات للمستخدم والتعامل مع الإدخال

**المكونات**:
- **Screens/Pages**: الشاشات الرئيسية
- **Widgets**: الـ Widgets المخصصة
- **Bloc**: إدارة الحالة
  - Events: الأحداث التي تحدث
  - States: الحالات المختلفة
  - Bloc: منطق معالجة الأحداث

**مثال**:
```dart
// Event
class LoadFeedPostsEvent extends SocialFeedEvent {
  final int page;
  const LoadFeedPostsEvent(this.page);
}

// State
class SocialFeedLoaded extends SocialFeedState {
  final List<PostEntity> posts;
  const SocialFeedLoaded(this.posts);
}

// Bloc
class SocialFeedBloc extends Bloc<SocialFeedEvent, SocialFeedState> {
  SocialFeedBloc() : super(SocialFeedInitial()) {
    on<LoadFeedPostsEvent>(_onLoadFeedPosts);
  }
}
```

### 2️⃣ Domain Layer

**المسؤولية**: تعريف منطق الأعمال والعقود

**المكونات**:
- **Entities**: كائنات البيانات الأساسية
- **Repositories Interface**: العقود
- **Use Cases**: حالات الاستخدام

**مثال**:
```dart
// Entity
class PostEntity extends Equatable {
  final String id;
  final String content;
  // ...
}

// Repository Interface
abstract class SocialFeedRepository {
  Future<Either<AppException, List<PostEntity>>> getFeedPosts({
    required int page,
  });
}

// Use Case
class GetFeedPostsUseCase implements UseCase<List<PostEntity>, GetFeedPostsParams> {
  final SocialFeedRepository repository;
  
  @override
  Future<Either<AppException, List<PostEntity>>> call(GetFeedPostsParams params) {
    return repository.getFeedPosts(page: params.page);
  }
}
```

### 3️⃣ Data Layer

**المسؤولية**: جلب البيانات من مصادر مختلفة

**المكونات**:
- **Models**: نماذج البيانات (توسيع Entities)
- **Data Sources**: مصادر البيانات (Remote, Local)
- **Repositories Implementation**: تطبيق العقود

**مثال**:
```dart
// Model
class PostModel extends PostEntity {
  const PostModel({
    required String id,
    required String content,
    // ...
  }) : super(
    id: id,
    content: content,
    // ...
  );
  
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      content: json['content'],
      // ...
    );
  }
}

// Data Source
abstract class SocialFeedRemoteDataSource {
  Future<List<PostModel>> getFeedPosts({required int page});
}

// Repository Implementation
class SocialFeedRepositoryImpl implements SocialFeedRepository {
  final SocialFeedRemoteDataSource remoteDataSource;
  
  @override
  Future<Either<AppException, List<PostEntity>>> getFeedPosts({
    required int page,
  }) async {
    try {
      final posts = await remoteDataSource.getFeedPosts(page: page);
      return Right(posts);
    } catch (e) {
      return Left(ServerException(message: e.toString()));
    }
  }
}
```

### 4️⃣ External Layer

**المسؤولية**: التواصل مع الخدمات الخارجية

**المكونات**:
- **Firebase**: قاعدة البيانات والتخزين
- **APIs**: الخدمات الخارجية
- **Local Storage**: التخزين المحلي

---

## 🔄 تدفق البيانات

```
User Action (UI)
    ↓
Bloc Event
    ↓
Bloc Logic
    ↓
Use Case
    ↓
Repository
    ↓
Data Source (Remote/Local)
    ↓
External Service (Firebase/API)
    ↓
Response
    ↓
Model → Entity
    ↓
Bloc State
    ↓
Widget Rebuild
    ↓
UI Update
```

---

## 🎯 أفضل الممارسات

### 1. Separation of Concerns
- كل طبقة لها مسؤولية واحدة فقط
- عدم الخلط بين منطق الأعمال والواجهة

### 2. Dependency Injection
```dart
// استخدام GetIt أو Provider
final getIt = GetIt.instance;

void setupServiceLocator() {
  // Data Sources
  getIt.registerSingleton<SocialFeedRemoteDataSource>(
    SocialFeedRemoteDataSourceImpl(getIt()),
  );
  
  // Repositories
  getIt.registerSingleton<SocialFeedRepository>(
    SocialFeedRepositoryImpl(getIt()),
  );
  
  // Use Cases
  getIt.registerSingleton<GetFeedPostsUseCase>(
    GetFeedPostsUseCase(getIt()),
  );
  
  // Blocs
  getIt.registerSingleton<SocialFeedBloc>(
    SocialFeedBloc(
      repository: getIt(),
      getFeedPostsUseCase: getIt(),
    ),
  );
}
```

### 3. Error Handling
```dart
// استخدام Either للتعامل مع الأخطاء
Either<AppException, List<PostEntity>> result = 
  await repository.getFeedPosts(page: 1);

result.fold(
  (exception) => print('Error: ${exception.message}'),
  (posts) => print('Success: ${posts.length} posts'),
);
```

### 4. State Management
```dart
// استخدام Bloc للـ State Management
BlocBuilder<SocialFeedBloc, SocialFeedState>(
  builder: (context, state) {
    if (state is SocialFeedLoading) {
      return LoadingWidget();
    } else if (state is SocialFeedLoaded) {
      return PostsList(posts: state.posts);
    } else if (state is SocialFeedError) {
      return ErrorWidget(message: state.message);
    }
    return SizedBox();
  },
);
```

---

## 📊 الاعتماديات الرئيسية

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.0.0
  
  # Functional Programming
  dartz: ^0.10.0
  
  # Firebase
  firebase_core: ^2.0.0
  firebase_database: ^10.0.0
  firebase_storage: ^11.0.0
  
  # Networking
  http: ^0.13.0
  
  # Local Storage
  shared_preferences: ^2.0.0
  hive: ^2.0.0
  
  # Utilities
  equatable: ^2.0.0
  get_it: ^7.0.0
  
  # UI
  cached_network_image: ^3.0.0
  shimmer: ^2.0.0
```

---

## 🧪 الاختبار

### Unit Tests
```dart
void main() {
  group('SocialFeedBloc', () {
    late SocialFeedBloc socialFeedBloc;
    late MockSocialFeedRepository mockRepository;

    setUp(() {
      mockRepository = MockSocialFeedRepository();
      socialFeedBloc = SocialFeedBloc(
        repository: mockRepository,
      );
    });

    test('emit [SocialFeedLoading, SocialFeedLoaded] when posts are fetched successfully', () async {
      // Arrange
      when(mockRepository.getFeedPosts(page: 1))
        .thenAnswer((_) async => Right([mockPost]));

      // Act
      socialFeedBloc.add(const LoadFeedPostsEvent());

      // Assert
      expect(
        socialFeedBloc.stream,
        emitsInOrder([
          isA<SocialFeedLoading>(),
          isA<SocialFeedLoaded>(),
        ]),
      );
    });
  });
}
```

---

## 🚀 الأداء

### تحسينات الأداء المطبقة
1. **Lazy Loading**: تحميل البيانات عند الحاجة
2. **Pagination**: تقسيم البيانات إلى صفحات
3. **Caching**: تخزين البيانات مؤقتاً
4. **Image Optimization**: تحسين الصور
5. **Memory Management**: إدارة الذاكرة

---

## 📚 المراجع

- [Flutter Documentation](https://flutter.dev)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Bloc Pattern](https://bloclibrary.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
