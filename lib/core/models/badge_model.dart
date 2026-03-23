class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final int requiredPoints;
  final DateTime earnedDate;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.requiredPoints,
    required this.earnedDate,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏆',
      color: json['color'] ?? '#FF0000',
      requiredPoints: json['requiredPoints'] ?? 0,
      earnedDate: DateTime.parse(json['earnedDate'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'requiredPoints': requiredPoints,
      'earnedDate': earnedDate.toIso8601String(),
    };
  }
}

// أنواع الأوسمة المتاحة
class BadgeTypes {
  static const List<Badge> allBadges = [
    // Badge(
    //   id: 'loyal_fan',
    //   name: 'مشجع وفي',
    //   description: 'شاهد 10 مباريات متتالية',
    //   icon: '❤️',
    //   color: '#FF0000',
    //   requiredPoints: 100,
    //   earnedDate: DateTime.now(),
    // ),
    // Badge(
    //   id: 'prediction_king',
    //   name: 'ملك التوقعات',
    //   description: 'توقع صح 5 مباريات متتالية',
    //   icon: '👑',
    //   color: '#FFD700',
    //   requiredPoints: 250,
    //   earnedDate: DateTime.now(),
    // ),
    // Badge(
    //   id: 'reel_star',
    //   name: 'نسر الريلز',
    //   description: 'حصل فيديوك على 1000 إعجابة',
    //   icon: '🦅',
    //   color: '#FFA500',
    //   requiredPoints: 500,
    //   earnedDate: DateTime.now(),
    // ),
    // Badge(
    //   id: 'eagle_of_month',
    //   name: 'نسر الشهر',
    //   description: 'فز بنسر الشهر',
    //   icon: '🏅',
    //   color: '#C0C0C0',
    //   requiredPoints: 1000,
    //   earnedDate: DateTime.now(),
    // ),
  ];

  static Badge getLoyalFanBadge() {
    return Badge(
      id: 'loyal_fan',
      name: 'مشجع وفي',
      description: 'شاهد 10 مباريات متتالية',
      icon: '❤️',
      color: '#FF0000',
      requiredPoints: 100,
      earnedDate: DateTime.now(),
    );
  }

  static Badge getPredictionKingBadge() {
    return Badge(
      id: 'prediction_king',
      name: 'ملك التوقعات',
      description: 'توقع صح 5 مباريات متتالية',
      icon: '👑',
      color: '#FFD700',
      requiredPoints: 250,
      earnedDate: DateTime.now(),
    );
  }

  static Badge getReelStarBadge() {
    return Badge(
      id: 'reel_star',
      name: 'نسر الريلز',
      description: 'حصل فيديوك على 1000 إعجابة',
      icon: '🦅',
      color: '#FFA500',
      requiredPoints: 500,
      earnedDate: DateTime.now(),
    );
  }

  static Badge getEagleOfMonthBadge() {
    return Badge(
      id: 'eagle_of_month',
      name: 'نسر الشهر',
      description: 'فز بنسر الشهر',
      icon: '🏅',
      color: '#C0C0C0',
      requiredPoints: 1000,
      earnedDate: DateTime.now(),
    );
  }
}
