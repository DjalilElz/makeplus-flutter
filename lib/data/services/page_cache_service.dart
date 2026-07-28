/// In-memory cache for data loaded by screens, keyed by a caller-chosen
/// string (screens scope their key by event id, so switching events never
/// shows stale data from a different event for a moment).
///
/// Lets a screen show its last-loaded content immediately on revisit while
/// it quietly refetches in the background, instead of a blank spinner every
/// time. Lives only for the app process (not persisted to disk), and is
/// cleared on logout so nothing leaks between accounts on the same device.
class PageCacheService {
  PageCacheService._();
  static final PageCacheService instance = PageCacheService._();

  final Map<String, dynamic> _cache = {};

  T? get<T>(String key) => _cache[key] as T?;

  void set<T>(String key, T value) => _cache[key] = value;

  void clear() => _cache.clear();
}
