import 'package:cloud_functions/cloud_functions.dart';

/// Callable Cloud Functions wrapper لتصويت "نسر المباراة".
///
/// ملاحظة: اسم الـ callable function لازم يطابق backend.
/// حالياً نفترض الاسم التالي: `submitEagleOfTheMatchVote`
class VotingCloudFunctionsService {
  VotingCloudFunctionsService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  static const String submitEagleOfTheMatchVoteFn = 'submitEagleOfTheMatchVote';

  Future<void> submitEagleOfTheMatchVote({
    required String fixtureId,
    required String playerId,
    required String userId,
  }) async {
    final callable = _functions.httpsCallable(submitEagleOfTheMatchVoteFn);
    await callable.call(<String, dynamic>{
      'fixtureId': fixtureId,
      'playerId': playerId,
      'userId': userId,
    });
  }
}
