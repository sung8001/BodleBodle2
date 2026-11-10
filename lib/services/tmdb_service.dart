import 'dart:convert';

import 'package:http/http.dart' as http;

class TmdbService {
  // VS Code launch.json에서 tmdb.local.json의 값을 전달받습니다.
  static const String _apiKey = String.fromEnvironment('TMDB_API_KEY');

  // 영화 상세 정보는 같은 영화를 반복 조회하지 않도록 캐시합니다.
  static final Map<int, Future<Map<String, dynamic>>> _detailsCache = {};

  static Future<List<Map<String, dynamic>>> searchMovies({
    required String query,
  }) async {
    final keyword = query.trim();
    if (keyword.isEmpty) return [];

    if (_apiKey.isEmpty) {
      throw Exception('TMDB API 키가 설정되지 않았습니다. F5 실행 설정을 확인하세요.');
    }

    final url = Uri.https('api.themoviedb.org', '/3/search/movie', {
      'api_key': _apiKey,
      'query': keyword,
      'language': 'ko-KR',
      'include_adult': 'false',
    });

    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('영화 검색에 실패했습니다. (${response.statusCode})');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results.whereType<Map<String, dynamic>>().toList();
  }

  // 검색 결과에는 감독과 러닝타임이 없으므로 상세 정보 + 제작진을 조회합니다.
  // TMDB의 append_to_response=credits를 사용하여 한 번에 받아옵니다.
  static Future<Map<String, dynamic>> getMovieDetails(int movieId) {
    return _detailsCache.putIfAbsent(movieId, () async {
      try {
        return await _fetchMovieDetails(movieId);
      } catch (_) {
        // 네트워크 오류는 캐시하지 않아 다음에 재시도할 수 있도록 합니다.
        _detailsCache.remove(movieId);
        rethrow;
      }
    });
  }

  static Future<Map<String, dynamic>> _fetchMovieDetails(int movieId) async {
    if (_apiKey.isEmpty) {
      throw Exception('TMDB API 키가 설정되지 않았습니다.');
    }

    final url = Uri.https('api.themoviedb.org', '/3/movie/$movieId', {
      'api_key': _apiKey,
      'language': 'ko-KR',
      'append_to_response': 'credits',
    });

    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('영화 상세 정보를 가져오지 못했습니다. (${response.statusCode})');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;
    final credits = data['credits'];
    final crew = credits is Map<String, dynamic>
        ? (credits['crew'] as List<dynamic>? ?? [])
        : <dynamic>[];

    // 감독이 여러 명일 수도 있으므로 모두 표시하며 중복은 제거합니다.
    final directors = crew
        .whereType<Map<String, dynamic>>()
        .where((person) => person['job'] == 'Director')
        .map((person) => (person['name'] as String? ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    final rawRuntime = data['runtime'];
    final int? runtime = rawRuntime is int && rawRuntime > 0
        ? rawRuntime
        : null;

    return {
      'director': directors.join(', '),
      'runtime': runtime, // 분 단위; 없으면 null
    };
  }
}
