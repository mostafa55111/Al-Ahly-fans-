import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/profile/data/repositories/api_user_repository.dart';
import 'package:gomhor_alahly_clean_new/features/profile/domain/entities/user.dart';
import 'package:gomhor_alahly_clean_new/features/profile/domain/repositories/user_repository.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserRepository _userRepository;
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userRepository = ApiUserRepository();
    _userFuture = _userRepository.getUserProfile(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('User not found.'));
          } else {
            final user = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user.profilePicUrl),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  // Add other user details here
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
