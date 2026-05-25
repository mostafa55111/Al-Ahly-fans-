/// أسطح الإنتاج المسموحة — أي سطح خارج القائمة = legacy/experimental.
enum ProductSurfaceCategory {
  publicFan,
  ownerAdmin,
  internalRuntime,
}

enum ProductSurfaceId {
  crowdScreen,
  matchStadiumVoting,
  hallOfFame,
  matchCountdown,
  matchResultOverlay,
  stadiumCms,
  cardLibrary,
  sessionControl,
  productionOps,
  finalizePipeline,
  voteAggregation,
  voteAuthority,
  sessionRecovery,
  productionEconomics,
}

class ProductSurfaceDescriptor {
  const ProductSurfaceDescriptor({
    required this.id,
    required this.category,
    required this.routeHint,
    required this.ownerService,
  });

  final ProductSurfaceId id;
  final ProductSurfaceCategory category;
  final String routeHint;
  final String ownerService;
}

/// سجل أسطح الإنتاج — Launch Candidate scope فقط.
class ProductSurfaceRegistry {
  ProductSurfaceRegistry._();

  static const productionSurfaces = <ProductSurfaceDescriptor>[
    ProductSurfaceDescriptor(
      id: ProductSurfaceId.crowdScreen,
      category: ProductSurfaceCategory.publicFan,
      routeHint: 'AppShell/CrowdScreen',
      ownerService: 'CrowdScreen',
    ),
    ProductSurfaceDescriptor(
      id: ProductSurfaceId.matchStadiumVoting,
      category: ProductSurfaceCategory.publicFan,
      routeHint: 'MatchStadiumVotingLayer',
      ownerService: 'MatchVotingCubit',
    ),
    ProductSurfaceDescriptor(
      id: ProductSurfaceId.hallOfFame,
      category: ProductSurfaceCategory.publicFan,
      routeHint: 'HallOfFamePanel',
      ownerService: 'HallOfFameCubit',
    ),
    ProductSurfaceDescriptor(
      id: ProductSurfaceId.matchCountdown,
      category: ProductSurfaceCategory.publicFan,
      routeHint: 'MatchVoteClosureOverlay',
      ownerService: 'MatchVotingCubit',
    ),
    ProductSurfaceDescriptor(
      id: ProductSurfaceId.matchResultOverlay,
      category: ProductSurfaceCategory.publicFan,
      routeHint: 'AwardsVotingShell',
      ownerService: 'AwardsRepository',
    ),
    ProductSurfaceDescriptor(
      id: ProductSurfaceId.stadiumCms,
      category: ProductSurfaceCategory.ownerAdmin,
      routeHint: 'StadiumCmsPage',
      ownerService: 'MatchVotesAdminCubit',
    ),
    ProductSurfaceDescriptor(
      id: ProductSurfaceId.cardLibrary,
      category: ProductSurfaceCategory.ownerAdmin,
      routeHint: 'StadiumSmartCardLibraryTab',
      ownerService: 'StadiumCardRegistryRepository',
    ),
    ProductSurfaceDescriptor(
      id: ProductSurfaceId.sessionControl,
      category: ProductSurfaceCategory.ownerAdmin,
      routeHint: 'MatchControlConsolePage',
      ownerService: 'OwnerSessionGuard',
    ),
    ProductSurfaceDescriptor(
      id: ProductSurfaceId.productionOps,
      category: ProductSurfaceCategory.ownerAdmin,
      routeHint: 'ProductionOpsDashboardPage',
      ownerService: 'ProductionVerificationHub',
    ),
    ProductSurfaceDescriptor(
      id: ProductSurfaceId.finalizePipeline,
      category: ProductSurfaceCategory.internalRuntime,
      routeHint: 'internal',
      ownerService: 'ProductionFinalizePipeline',
    ),
    ProductSurfaceDescriptor(
      id: ProductSurfaceId.voteAggregation,
      category: ProductSurfaceCategory.internalRuntime,
      routeHint: 'internal',
      ownerService: 'VoteAggregationService',
    ),
    ProductSurfaceDescriptor(
      id: ProductSurfaceId.voteAuthority,
      category: ProductSurfaceCategory.internalRuntime,
      routeHint: 'internal',
      ownerService: 'AuthorityOrchestrator',
    ),
    ProductSurfaceDescriptor(
      id: ProductSurfaceId.sessionRecovery,
      category: ProductSurfaceCategory.internalRuntime,
      routeHint: 'internal',
      ownerService: 'DeadSessionRecoveryService',
    ),
    ProductSurfaceDescriptor(
      id: ProductSurfaceId.productionEconomics,
      category: ProductSurfaceCategory.internalRuntime,
      routeHint: 'internal',
      ownerService: 'ReadBudgetGuard',
    ),
  ];

  static final Set<ProductSurfaceId> _allowedIds =
      productionSurfaces.map((e) => e.id).toSet();

  static bool isProductionSurface(ProductSurfaceId id) =>
      _allowedIds.contains(id);

  static bool isProductionRouteHint(String hint) {
    final normalized = hint.trim().toLowerCase();
    return productionSurfaces.any(
      (s) => s.routeHint.toLowerCase().contains(normalized) ||
          normalized.contains(s.routeHint.toLowerCase()),
    );
  }

  static void assertProductionSurface(ProductSurfaceId id) {
    if (!isProductionSurface(id)) {
      throw StateError('non_production_surface:$id');
    }
  }

  static List<ProductSurfaceDescriptor> byCategory(
    ProductSurfaceCategory category,
  ) =>
      productionSurfaces.where((s) => s.category == category).toList();
}
