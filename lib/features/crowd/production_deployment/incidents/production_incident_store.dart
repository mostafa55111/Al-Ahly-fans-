import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/incident_severity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incident.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يحتفظ بالحوادث الحرجة محلياً حتى الإقرار.
class ProductionIncidentStore {
  ProductionIncidentStore(this._prefs);

  static const _prefsKey = 'production_incidents_critical_v1';

  final SharedPreferences _prefs;
  final List<ProductionIncident> _ring = [];
  final List<ProductionIncident> _criticalPending = [];

  List<ProductionIncident> get recent => List.unmodifiable(_ring);
  List<ProductionIncident> get criticalUnacknowledged =>
      _criticalPending.where((e) => !e.acknowledged).toList(growable: false);

  Future<void> load() async {
    _criticalPending.clear();
    final raw = _prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          _criticalPending.add(ProductionIncident.fromJson(item));
        } else if (item is Map) {
          _criticalPending.add(
            ProductionIncident.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    } catch (e) {
      debugPrint('[IncidentStore] load failed: $e');
    }
  }

  Future<void> persist(ProductionIncident incident) async {
    _ring.add(incident);
    if (_ring.length > 120) _ring.removeRange(0, _ring.length - 120);

    if (!incident.severity.requiresLocalPersistence) return;
    _criticalPending.add(incident);
    await _flushCritical();
  }

  Future<void> acknowledge(String incidentId) async {
    for (var i = 0; i < _criticalPending.length; i++) {
      if (_criticalPending[i].id == incidentId) {
        _criticalPending[i] = _criticalPending[i].copyWith(acknowledged: true);
      }
    }
    _criticalPending.removeWhere((e) => e.acknowledged);
    await _flushCritical();
  }

  Future<void> _flushCritical() async {
    final payload = _criticalPending
        .where((e) => !e.acknowledged)
        .map((e) => e.toJson())
        .toList();
    await _prefs.setString(_prefsKey, jsonEncode(payload));
  }

  @visibleForTesting
  void reset() {
    _ring.clear();
    _criticalPending.clear();
  }
}
