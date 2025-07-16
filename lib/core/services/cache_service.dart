import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger.dart';

final _log = Log.component('cache');

/// Cache service for offline support and performance
class CacheService {
  static const _cachePrefix = 'invoice_pe_cache_';
  static const _cacheExpiry = Duration(hours: 24);

  /// Cache data with expiry
  static Future<void> cacheData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString('$_cachePrefix$key', jsonEncode(cacheData));
      _log.info('Cached data for key: $key');
    } catch (e) {
      _log.error('Cache write failed', error: e);
    }
  }

  /// Get cached data if not expired
  static Future<T?> getCachedData<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_cachePrefix$key');
      if (cached == null) return null;

      final cacheData = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;

      if (age > _cacheExpiry.inMilliseconds) {
        await prefs.remove('$_cachePrefix$key');
        return null;
      }

      return cacheData['data'] as T;
    } catch (e) {
_log.error('Cache read failed', error: e);
      return null;
    }
  }

  /// Clear all cache
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
    _log.info('Cache cleared');
  }

  /// Queue operations for offline sync
  static Future<void> queueOperation(
    String type,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('offline_queue') ?? [];
    queue.add(
      jsonEncode({
        'type': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
    await prefs.setStringList('offline_queue', queue);
  }

  /// Get and clear offline queue
  static Future<List<Map<String, dynamic>>> getOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('offline_queue') ?? [];
    await prefs.remove('offline_queue');
    return queue
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
  }
}
