import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/travel/data/travel_repository.dart';
import 'package:gomhor_alahly_clean_new/features/travel/data/travel_repository_rtdb.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/cubit/travel_user_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/pages/travel_home_page.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/widgets/travel_connectivity_banner.dart';

/// نقطة الدخول — الترحال الذكي (Firebase Realtime Database).
class TravelPage extends StatelessWidget {
  const TravelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<TravelRepository>(
      create: (_) => TravelRepositoryRtdb(FirebaseDatabase.instance),
      child: BlocProvider(
        create: (context) => TravelUserCubit(
          repository: context.read<TravelRepository>(),
          auth: FirebaseAuth.instance,
        )..initGovernorates(),
        child: const TravelConnectivityBanner(child: TravelHomePage()),
      ),
    );
  }
}
