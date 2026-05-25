import 'dart:math' as math;

/// مستوى تكلفة الرسوم المتحركة على الملعب.
enum CrowdAnimationBudget {
  full,
  reduced,
  minimal,
}

CrowdAnimationBudget stricterCrowdAnimationBudget(
  CrowdAnimationBudget a,
  CrowdAnimationBudget b,
) {
  const order = [
    CrowdAnimationBudget.full,
    CrowdAnimationBudget.reduced,
    CrowdAnimationBudget.minimal,
  ];
  return order[math.max(order.indexOf(a), order.indexOf(b))];
}
