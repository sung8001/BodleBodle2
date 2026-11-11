import 'dart:convert';

import 'package:http/http.dart' as http;

/// Apple iTunes Search API를 이용해 국내 iTunes Store의 음악을 검색합니다.
/// 검색 결과의 previewUrl은 추후 게시물의 30초 미리듣기 기능에 사용합니다.
class ItunesMusicService {
  static const String _host = 'itunes.apple.com';
  // 한국은 iTunes Store 음악 구입 카탈로그를 제공하지 않으므로
  // 음악 검색이 가능한 미국 스토어를 사용합니다.
  static const String _storefrontCountry = 'US';
  static const int _resultLimit = 25;
  static const Duration _cacheDuration = Duration(minutes: 10);
  static const int _maxCacheEntries = 100;

  // 앱이 실행되는 동안 동일 검색어를 반복 호출하지 않도록 하는 메모리 캐시입니다.
  // 여러 사용자가 공유하는 캐시는 아니며, 서비스 확장 시 Firebase 서버 캐시로 보완합니다.
  static final Map<String, _MusicSearchCacheEntry> _cache = {};

  static Future<List<Map<String, dynamic>>> searchSongs({
    required String query,
  }) async {
    final keyword = query.trim();
    if (keyword.isEmpty) return [];

    final cacheKey = _normalize(keyword);
    final cached = _cache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.savedAt) < _cacheDuration) {
      return cached.results.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    if (cached != null) _cache.remove(cacheKey);

    final uri = Uri.https(_host, '/search', {
      'term': keyword,
      'media': 'music',
      'entity': 'song',
      'country': _storefrontCountry,
      'limit': '$_resultLimit',
    });

    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 429) {
      throw Exception('음악 검색 요청이 많아 잠시 제한됐어요. 1분 정도 후 다시 시도해 주세요.');
    }
    if (response.statusCode != 200) {
      throw Exception('음악 검색 오류 (HTTP ${response.statusCode})');
    }

    final results = parseSearchResponse(utf8.decode(response.bodyBytes));
    _cache[cacheKey] = _MusicSearchCacheEntry(
      savedAt: DateTime.now(),
      results: results,
    );

    // 캐시가 지나치게 커지지 않도록 가장 먼저 저장된 항목부터 제거합니다.
    while (_cache.length > _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }

    return results.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// API 응답을 앱에서 사용할 수 있는 곡 목록으로 변환합니다.
  /// 네트워크 요청과 분리되어 있어 테스트에서 응답 파싱을 검증할 수 있습니다.
  static List<Map<String, dynamic>> parseSearchResponse(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('음악 검색 응답 형식이 올바르지 않습니다.');
    }

    final rawResults = decoded['results'];
    if (rawResults is! List) return [];

    final seen = <String>{};
    final tracks = <Map<String, dynamic>>[];

    for (final raw in rawResults) {
      if (raw is! Map) continue;
      final track = Map<String, dynamic>.from(raw);
      final title = (track['trackName']?.toString() ?? '').trim();
      final artist = (track['artistName']?.toString() ?? '').trim();
      if (title.isEmpty || artist.isEmpty) continue;

      // 곡 ID가 있으면 ID를 기준으로 중복을 제거합니다.
      // ID가 없는 응답은 곡명·아티스트·앨범 조합으로 구분합니다.
      final trackId = track['trackId']?.toString() ?? '';
      final album = (track['collectionName']?.toString() ?? '').trim();
      final duplicateKey = trackId.isNotEmpty
          ? 'id:$trackId'
          : 'track:${_normalize(title)}|${_normalize(artist)}|${_normalize(album)}';
      if (!seen.add(duplicateKey)) continue;

      // iTunes 응답의 http 주소는 Flutter Web의 HTTPS 페이지에서 차단될 수 있어
      // 미리듣기 및 스토어 링크를 HTTPS로 정규화합니다.
      for (final field in ['previewUrl', 'trackViewUrl']) {
        final secureUrl = _toHttpsUrl(track[field]);
        if (secureUrl == null) {
          track.remove(field);
        } else {
          track[field] = secureUrl;
        }
      }

      tracks.add(track);
    }

    return tracks;
  }

  static String? _toHttpsUrl(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasAuthority) return null;
    if (uri.scheme == 'https') return uri.toString();
    if (uri.scheme == 'http') return uri.replace(scheme: 'https').toString();
    return null;
  }

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _MusicSearchCacheEntry {
  const _MusicSearchCacheEntry({required this.savedAt, required this.results});

  final DateTime savedAt;
  final List<Map<String, dynamic>> results;
}
