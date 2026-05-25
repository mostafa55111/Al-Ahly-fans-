import 'package:flutter/widgets.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/responsive_card_asset.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_scale_runtime_report.dart';

/// عنصر في طابور التحميل المسبق.
class StadiumPreloadItem {
  const StadiumPreloadItem({
    required this.playerId,
    required this.asset,
    required this.priority,
    this.isStartingEleven = false,
  });

  final String playerId;
  final ResponsiveCardAsset asset;
  final int priority;
  final bool isStartingEleven;
}

/// تحميل مسبق ذو أولوية — التشكيلة الأساسية ثم مقاعد قريبة فقط.
class StadiumMediaPreloader {
  StadiumMediaPreloader({int maxConcurrent = 3}) : _maxConcurrent = maxConcurrent;

  final int _maxConcurrent;
  final List<StadiumPreloadItem> _pending = [];
  final Set<String> _completed = {};
  int _inFlight = 0;

  int get queueSize => _pending.length;

  void enqueueStartingEleven(List<StadiumPreloadItem> starters) {
    for (final item in starters) {
      _enqueue(
        StadiumPreloadItem(
          playerId: item.playerId,
          asset: item.asset,
          priority: 100,
          isStartingEleven: true,
        ),
      );
    }
    VoteScaleRuntimeReport.instance.recordPreloadQueueSize(_pending.length);
  }

  void enqueueNearbyBench(List<StadiumPreloadItem> bench, {int maxItems = 6}) {
    var n = 0;
    for (final item in bench) {
      if (n >= maxItems) break;
      _enqueue(
        StadiumPreloadItem(
          playerId: item.playerId,
          asset: item.asset,
          priority: 40,
        ),
      );
      n++;
    }
    VoteScaleRuntimeReport.instance.recordPreloadQueueSize(_pending.length);
  }

  void _enqueue(StadiumPreloadItem item) {
    if (_completed.contains(item.playerId)) return;
    _pending.add(item);
    _pending.sort((a, b) => b.priority.compareTo(a.priority));
  }

  Future<void> drain(BuildContext context, {double deviceWidth = 400}) async {
    while (_pending.isNotEmpty && _inFlight < _maxConcurrent) {
      final item = _pending.removeAt(0);
      if (_completed.contains(item.playerId)) continue;
      _inFlight++;
      try {
        final url = item.asset.urlFor(
          context: item.isStartingEleven
              ? CardDisplayContext.liveStadium
              : CardDisplayContext.bench,
          deviceWidthLogical: deviceWidth,
          stadiumBenchMode: !item.isStartingEleven,
        );
        if (url.isNotEmpty) {
          await precacheImage(NetworkImage(url), context);
        }
        _completed.add(item.playerId);
      } catch (_) {
        // تجاهل فشل التحميل المسبق — لا يعطل الواجهة.
      } finally {
        _inFlight--;
        VoteScaleRuntimeReport.instance.recordPreloadQueueSize(_pending.length);
      }
    }
  }

  void clear() {
    _pending.clear();
    _completed.clear();
    _inFlight = 0;
  }
}
