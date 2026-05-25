import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/cubit/motm_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/cubit/motm_voting_state.dart';
import 'package:gomhor_alahly_clean_new/features/public_arena/presentation/cubit/squad_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/public_arena/presentation/widgets/lineup_widget.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/squad_field_page.dart';

/// ساحة الجمهور (Fan): الملعب والكروت فقط — التصويت يتم من الكروت عند فتح جلسة MOTM.
class PublicArenaPage extends StatelessWidget {
  const PublicArenaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MotmVotingCubit()..bootstrap()),
        BlocProvider(create: (_) => SquadCubit(FirebaseDatabase.instance)..start()),
      ],
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            'Fan Arena',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<MotmVotingCubit, MotmVotingState>(
            buildWhen: (p, c) => p.players != c.players || p.status != c.status,
            builder: (context, state) {
              return RefreshIndicator(
                color: primary,
                onRefresh: () => context.read<MotmVotingCubit>().bootstrap(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                      sliver: SliverFillRemaining(
                        hasScrollBody: false,
                        child: SquadFieldPage(
                          child: LineupWidget.motm(lineupPlayers: state.players),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
