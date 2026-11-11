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

  /// 굿즈뿐 아니라 작품의 부가 자료·잡지성 간행물도 검색 결과에서 제외합니다.
  /// 카카오 API에는 '일반 단행본/부가 상품'을 구분하는 유형 필드가 없으므로
  /// 제목·소개·출판사 키워드와 ISBN 유효성을 함께 사용합니다.
  static bool _isBookRecord(Map<String, dynamic> book) {
    final title = _normalize(book['title']?.toString() ?? '');
    if (title.isEmpty) return false;

    final contents = _normalize(book['contents']?.toString() ?? '');
    final publisher = _normalize(book['publisher']?.toString() ?? '');
    final searchableMetadata = '$title $contents';
    final rawTitle = book['title']?.toString() ?? '';
    final rawContents = book['contents']?.toString() ?? '';

    // OST는 다른 영단어의 일부로 오인하지 않도록 독립된 표기일 때만 제외합니다.
    final hasStandaloneOst = RegExp(
      r'(^|[^A-Za-z])OST([^A-Za-z]|$)',
      caseSensitive: false,
    ).hasMatch(rawTitle) ||
        RegExp(
          r'(^|[^A-Za-z])OST([^A-Za-z]|$)',
          caseSensitive: false,
        ).hasMatch(rawContents);
    if (hasStandaloneOst) return false;

    // 중국 출판사가 발행한 일본 원작의 현지판은 제외합니다.
    // Kakao 응답에는 원작 국가/원어 필드가 없으므로 출판사와 저자 정보를
    // 함께 사용합니다. 중국 원작 저자는 이 조건에 해당하지 않아 유지됩니다.
    if (_isLikelyChineseEditionOfJapaneseWork(book)) return false;

    // 도서 ISBN이 있어도 실제로는 굿즈·부록·작품 홍보용 간행물인 경우가 있어
    // ISBN 검사 전에 제목/소개/출판사에서 해당 유형을 제외합니다.
    const nonBookMarkers = [
      // 굿즈 및 문구류
      '포스터', '직소퍼즐', '퍼즐', '엽서', '스티커', '포토카드', '브로마이드',
      '캘린더', '달력', '다이어리', '키링', '아크릴', '마우스패드', '클리어파일',
      '책갈피', '문구', '인형', '굿즈', 'poster', 'puzzle', 'postcard',
      'sticker', 'photocard', 'calendar', 'diary', 'keyring', 'acrylic',
      'mousepad', 'goods',
      // 작품 부가 자료: 일반 도서와 구분하기 위한 제외 키워드
      '공식비주얼가이드', '비주얼가이드', '비주얼북', '공식가이드북',
      '미술화집', '화집', '아트북', '원화집', '설정집', '설정자료집',
      '메이킹북', '포토북', '사진집', '팬북', '대본집', '팸플릿', '팜플렛',
      'visualguide', 'visualbook', 'artbook', 'illustrationbook',
      'photobook', 'fanbook', 'makingbook', 'pamphlet', 'programbook',
      'movieguide', 'moviepamphlet', 'movieprogram', 'animationartbook',
      'artcollection', 'originalartwork',
      // OST·악보·연주곡집 등 작품의 음악 부가 상품
      '피아노연주곡집', '연주곡집', '피아노곡집', '피아노악보',
      '악보집', '악보모음', '반주곡집', '음악곡집', '사운드트랙',
      'soundtrack', 'originalsoundtrack', 'sheetmusic', 'pianoscore',
      'songbook', 'scorebook', 'pianocollection', 'instrumentalcollection',
      'musiccollection',
      // 잡지 및 잡지의 특정 호/표지 수록 상품
      '잡지', 'magazine', 'anan', '앙앙', 'cover', '커버', '특집호',
    ];
    if (nonBookMarkers.any(searchableMetadata.contains)) return false;

    // 출판사 정보가 잡지사인 경우 제목에 잡지 키워드가 없어도 제외합니다.
    const nonBookPublisherMarkers = [
      'マガジンハウス',
      'magazinehouse',
    ];
    if (nonBookPublisherMarkers.any(publisher.contains)) return false;

    // ISBN이 없거나 체크섬이 틀린 상품은 일반 도서로 취급하지 않습니다.
    return _validIsbns(book['isbn']?.toString() ?? '').isNotEmpty;
  }

  static bool _isLikelyChineseEditionOfJapaneseWork(
    Map<String, dynamic> book,
  ) {
    final publisher = _normalize(book['publisher']?.toString() ?? '');
    final title = book['title']?.toString() ?? '';
    final rawAuthors = book['authors'];
    final authors = rawAuthors is List
        ? rawAuthors.whereType<String>().toList()
        : <String>[];
    final authorText = authors.join(' ');
    final searchableNames = _normalize('$title $authorText');
    final rawTranslators = book['translators'];
    final hasTranslator = rawTranslators is List &&
        rawTranslators.whereType<String>().any((name) => name.trim().isNotEmpty);

    const chinesePublisherMarkers = [
      // 국내 API 응답에서 한글로 표기되는 중국 출판사
      '절강인민미술출판사', '절강인민출판사', '인민문학출판사',
      '중국우의출판공사', '베이징연합출판공사', '남해출판공사',
      '장강문예출판사', '상해역문출판사', '중신출판사',
      '중국출판집단', '작가출판사', '중경출판사',
      // 중국어 원문 출판사 표기
      '浙江人民美术出版社', '浙江人民出版社', '人民文学出版社',
      '中国友谊出版公司', '北京联合出版公司', '南海出版公司',
      '长江文艺出版社', '上海译文出版社', '中信出版社',
      '中国出版集团', '作家出版社', '重庆出版社',
      '江苏凤凰文艺出版社', '湖南文艺出版社', '新星出版社',
      '广西师范大学出版社', '人民邮电出版社', '接力出版社',
      '北京十月文艺出版社', '上海人民出版社', '磨铁图书',
    ];
    final isChinesePublisher =
        chinesePublisherMarkers.any(publisher.contains);
    if (!isChinesePublisher) return false;

    // 중국 출판사 + 번역자 정보가 있으면 중국 원작이 아닌 번역 출간물일
    // 가능성이 높으므로 우선 제외합니다. 원작 언어 필드가 없는 API의 보완 규칙입니다.
    if (hasTranslator) return true;

    // 한자 표기 외에도 한글/영문 표기를 포함해 자주 검색되는 일본 작가를 확인합니다.
    // 일본어 가나가 저자 또는 제목에 포함된 경우도 일본 원작 가능성으로 봅니다.
    const japaneseOriginAuthors = [
      '新海誠', '新海诚', '신카이마코토', 'makotoshinkai',
      '村上春樹', '무라카미하루키', 'harukimurakami',
      '東野圭吾', '히가시노게이고', 'keigohigashino',
      '尾田栄一郎', '오다에이치로', 'eiichirooda',
      '吾峠呼世晴', '고토게코요하루',
      '芥見下々', '아쿠타미게게',
      '藤本タツキ', '후지모토타츠키',
      '岸本斉史', '키시모토마사시',
      '鳥山明', '토리야마아키라',
      '宮崎駿', '미야자키하야오',
      '青山剛昌', '아오야마고쇼',
      '伊坂幸太郎', '이사카코타로',
      '湊かなえ', '미나토카나에',
      '夏目漱石', '나쓰메소세키',
      '太宰治', '다자이오사무',
      '芥川龍之介', '아쿠타가와류노스케',
      '吉本ばなな', '요시모토바나나',
      '村田沙耶香', '무라타사야카',
      '辻村深月', '츠지무라미즈키',
    ];
    if (japaneseOriginAuthors.any(searchableNames.contains)) return true;

    final hasJapaneseKana =
        RegExp(r'[\u3040-\u30ff]').hasMatch(title) ||
        RegExp(r'[\u3040-\u30ff]').hasMatch(authorText);
    if (hasJapaneseKana) return true;

    // 원작 국가가 제목에 명시된 중국어판도 제외합니다.
    final normalizedTitle = _normalize(title);
    const explicitJapaneseEditionMarkers = [
      '日本原作', '日本原著', '日本漫画', '日本漫畫',
      '日本小说', '日本小說', '日本作家', '日本作品',
    ];
    return explicitJapaneseEditionMarkers
        .any(normalizedTitle.contains);
  }

  /// ISBN-13 및 ISBN-10 체크섬을 확인합니다.
  /// 단순히 숫자 자릿수만 맞는 상품 코드가 책으로 통과하는 것을 막습니다.
  static bool _isValidIsbn(String value) {
    final isbn = value.replaceAll('-', '').trim().toUpperCase();

    if (RegExp(r'^(978|979)\d{10}$').hasMatch(isbn)) {
      var sum = 0;
      for (var i = 0; i < 12; i++) {
        sum += int.parse(isbn[i]) * (i.isEven ? 1 : 3);
      }
      final checkDigit = (10 - (sum % 10)) % 10;
      return checkDigit == int.parse(isbn[12]);
    }

    if (RegExp(r'^\d{9}[\dX]$').hasMatch(isbn)) {
      var sum = 0;
      for (var i = 0; i < 10; i++) {
        final digit = isbn[i] == 'X' ? 10 : int.parse(isbn[i]);
        sum += digit * (10 - i);
      }
      return sum % 11 == 0;
    }

    return false;
  }

  static List<String> _validIsbns(String value) => value
      .split(RegExp(r'\s+'))
      .map((isbn) => isbn.replaceAll('-', '').trim().toUpperCase())
      .where(_isValidIsbn)
      .toList();

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
      if (!_isBookRecord(books[i])) continue;
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
      final isbns = _validIsbns(book['isbn']?.toString() ?? '');
      final editionKey = _editionKey(book);
      if (isbns.any(seenIsbns.contains) || seenEditions.contains(editionKey)) {
        continue;
      }
      seenIsbns.addAll(isbns);
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
    final isbns = _validIsbns(value);
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
