import 'package:equatable/equatable.dart';

/// كيان المجتمع (Community Entity)
/// يمثل مجموعة من المشجعين المتفاعلين حول موضوع معين
class CommunityEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String creatorId;
  final int membersCount;
  final int postsCount;
  final DateTime createdAt;
  final List<String> tags;
  final String category; // 'Match', 'Player', 'Region', 'General'
  final bool isVerified;
  final bool isMuted; // إذا كان المجتمع مكتوماً
  final String privacy; // 'public', 'private'

  const CommunityEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.creatorId,
    required this.membersCount,
    required this.postsCount,
    required this.createdAt,
    required this.tags,
    required this.category,
    required this.isVerified,
    required this.isMuted,
    required this.privacy,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    imageUrl,
    creatorId,
    membersCount,
    postsCount,
    createdAt,
    tags,
    category,
    isVerified,
    isMuted,
    privacy,
  ];
}
