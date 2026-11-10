import 'dart:convert';

import 'package:http/http.dart' as http;

/// 도서 메타데이터는 카카오 검색 API 하나만 사용합니다.
/// 제목과 저자를 함께 검색한 뒤, 관련도가 낮거나 중복된 판본을 정리합니다.
class KakaoBookService {
  static const String _apiKey = String.fromEnvironment('KAKAO_REST_API_KEY');

  static const int _pageSize = 30;
  static const int _maxResults = 30;

  static Future<List<Map<String, dynamic>>> searchBooks({
    required String query,
  }) async {
    final keyword = query.trim();
    if (keyword.isEmpty) return [];
    if (_apiKey.isEmpty) {
      throw Exception('카카오 REST API 키가 설정되지 않았습니다.');
    }

    // 제목/인명 검색 결과가 서로 다르므로 각각 조회합니다.
    // 2개의 요청은 병렬로 실행해 대기 시간을 줄입니다.
    final responses = await Future.wait([
      _searchByTarget(keyword, 'title'),
      _searchByTarget(keyword, 'person'),
    ]);
    return filterAndRankBooks(keyword, [...responses[0], ...responses[1]]);
  }

  static Future<List<Map<String, dynamic>>> _searchByTarget(
    String query,
    String target,
  ) async {
    final url = Uri.https('dapi.kakao.com', '/v3/search/book', {
      'query': query,
      'target': target,
      'sort': 'accuracy',
      'size': '$_pageSize',
    });
    final response = await http.get(url, headers: {
      'Authorization': 'KakaoAK $_apiKey',
    }).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      // API 키와 요청 URL 등의 상세 정보를 화면에 노출하지 않습니다.
      throw Exception('카카오 도서 검색 오류 (HTTP ${response.statusCode})');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('도서 검색 응답 형식이 올바르지 않습니다.');
    }
    final documents = decoded['documents'];
    if (documents is! List) return [];
    return documents.whereType<Map<String, dynamic>>().toList();
  }

  /// 검색 결과를 점수순으로 정리하고 동일 판본의 중복만 제거합니다.
  /// 출판연도가 다르거나 제목에 개정판 표기가 있으면 별도 판본으로 남깁니다.
  static List<Map<String, dynamic>> filterAndRankBooks(
    String query,
    List<Map<String, dynamic>> books,
  ) {
    final keyword = _normalize(query);
    if (keyword.isEmpty) return [];

    final matches = <({int order, int score, Map<String, dynamic> book})>[];
    for (var i = 0; i < books.length; i++) {
      final score = _matchScore(keyword, books[i]);
      if (score == null) continue; // 제목/작가와 무관한 결과 제외
      matches.add((order: i, score: score, book: books[i]));
    }

    matches.sort((a, b) {
      final byScore = a.score.compareTo(b.score);
      if (byScore != 0) return byScore;
      // 동일한 관련도라면 표지가 있는 결과를 먼저 표시합니다.
      final aHasCover = _hasCover(a.book);
      final bHasCover = _hasCover(b.book);
      if (aHasCover != bHasCover) return aHasCover ? -1 : 1;
      return a.order.compareTo(b.order); // 카카오 기본 정확도 순서 유지
    });

    final seenIsbns = <String>{};
    final seenEditions = <String>{};
    final selected = <Map<String, dynamic>>[];
    for (final match in matches) {
      final book = match.book;
      final isbn = _preferredIsbn(book['isbn']?.toString() ?? '');
      final editionKey = _editionKey(book);
      if ((isbn != null && seenIsbns.contains(isbn)) ||
          seenEditions.contains(editionKey)) {
        continue;
      }
      if (isbn != null) seenIsbns.add(isbn);
      seenEditions.add(editionKey);
      selected.add(book);
      if (selected.length == _maxResults) break;
    }
    return selected;
  }

  static int? _matchScore(String query, Map<String, dynamic> book) {
    final title = _normalize(book['title']?.toString() ?? '');
    final rawAuthors = book['authors'];
    final authors = rawAuthors is List
        ? rawAuthors.whereType<String>().map(_normalize).toList()
        : <String>[];
    if (title == query) return 0;
    if (title.startsWith(query)) return 1;
    if (title.contains(query)) return 2;
    if (authors.any((name) => name == query)) return 3;
    if (authors.any((name) => name.startsWith(query))) return 4;
    if (authors.any((name) => name.contains(query))) return 5;
    return null;
  }

  static bool _hasCover(Map<String, dynamic> book) =>
      (book['thumbnail']?.toString().trim() ?? '').isNotEmpty;

  static String _editionKey(Map<String, dynamic> book) {
    final rawAuthors = book['authors'];
    final authors = rawAuthors is List
        ? rawAuthors.whereType<String>().map(_normalize).join(',')
        : '';
    final published = book['datetime']?.toString() ?? '';
    final year = published.length >= 4 ? published.substring(0, 4) : '';
    return '${_normalize(book['title']?.toString() ?? '')}|'
        '$authors|${_normalize(book['publisher']?.toString() ?? '')}|$year';
  }

  static String _normalize(String input) => input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s\.,\-:;!?()\[\]{}·〈〉《》「」『』]+'), '');

  /// 카카오 ISBN은 `ISBN10 ISBN13` 형태일 수 있습니다.
  /// 보조 표지를 찾을 때 ISBN13을 우선 사용합니다.
  static String? _preferredIsbn(String value) {
    final isbns = value
        .split(RegExp(r'\s+'))
        .map((isbn) => isbn.replaceAll('-', '').trim())
        .where((isbn) => RegExp(r'^(?:\d{13}|\d{9}[\dXx])$').hasMatch(isbn))
        .toList();
    if (isbns.isEmpty) return null;
    for (final isbn in isbns) {
      if (isbn.length == 13) return isbn;
    }
    return isbns.first;
  }

  /// 표지를 찾을 수 없으면 Open Library가 HTTP 404를 반환합니다.
  /// 이 주소는 카카오 표지가 없거나 로딩에 실패한 경우에만 사용합니다.
  static String? fallbackCoverUrl(String? isbn) {
    final selected = _preferredIsbn(isbn ?? '');
    if (selected == null) return null;
    return 'https://covers.openlibrary.org/b/isbn/$selected-M.jpg?default=false';
  }
}
