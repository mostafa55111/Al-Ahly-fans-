import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/shared_marketplace/presentation/pages/main_marketplace_page.dart';
import 'package:gomhor_alahly_clean_new/features/store/data/marketplace_repository.dart';
import 'package:gomhor_alahly_clean_new/features/store/data/marketplace_repository_rtdb.dart';
import 'package:gomhor_alahly_clean_new/features/store/presentation/cubit/marketplace_cubit.dart';

/// نقطة دخول السوق — مستودع Realtime Database + حالة السوق.
class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<MarketplaceRepository>(
      create: (_) => MarketplaceRepositoryRtdb(FirebaseDatabase.instance),
      child: BlocProvider(
        create: (c) =>
            MarketplaceCubit(repository: c.read<MarketplaceRepository>()),
        child: const MainMarketplacePage(),
      ),
    );
  }
}
