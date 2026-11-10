import 'package:flutter_test/flutter_test.dart';
import 'package:bodlebodle/services/kakao_book_service.dart';

Map<String, dynamic> book({
  required String title,
  String author = '작가',
  String isbn = '',
  String publisher = '출판사',
  String date = '2024-01-01T00:00:00.000+09:00',
  String thumbnail = '',
}) => {
  'title': title,
  'authors': [author],
  'isbn': isbn,
  'publisher': publisher,
  'datetime': date,
  'thumbnail': thumbnail,
};

void main() {
  group('카카오 도서 검색 결과 후처리', () {
    test('제목 완전일치가 부분 일치와 작가 일치보다 먼저 나온다', () {
      final result = KakaoBookService.filterAndRankBooks('아몬드', [
        book(title: '초콜릿과 아몬드'),
        book(title: '다른 책', author: '아몬드'),
        book(title: '아몬드'),
      ]);
      expect(result.map((b) => b['title']),
          ['아몬드', '초콜릿과 아몬드', '다른 책']);
    });

    test('공백 차이를 무시하고 작가명 검색을 지원한다', () {
      final result = KakaoBookService.filterAndRankBooks('손 원 평', [
        book(title: '아몬드', author: '손원평'),
        book(title: '관련 없는 책', author: '다른 작가'),
      ]);
      expect(result.length, 1);
      expect(result.single['title'], '아몬드');
    });

    test('동일 ISBN 및 동일 판본 중복은 제거하고 표지 있는 책을 우선한다', () {
      final result = KakaoBookService.filterAndRankBooks('아몬드', [
        book(title: '아몬드', isbn: '1234567890 9781234567897'),
        book(
          title: '아몬드',
          isbn: '9781234567897',
          thumbnail: 'https://example.org/cover.jpg',
        ),
        book(title: '아몬드', isbn: '9781234567897'),
      ]);
      expect(result.length, 1);
      expect(result.single['thumbnail'], 'https://example.org/cover.jpg');
    });

    test('출판연도가 다른 판본은 구분한다', () {
      final result = KakaoBookService.filterAndRankBooks('아몬드', [
        book(title: '아몬드', date: '2020-01-01', isbn: '9781234567897'),
        book(title: '아몬드', date: '2024-01-01', isbn: '9781234567898'),
      ]);
      expect(result.length, 2);
    });

    test('ISBN13 보조 표지 주소를 생성하며 없는 경우 null을 반환한다', () {
      expect(
        KakaoBookService.fallbackCoverUrl('1234567890 9781234567897'),
        'https://covers.openlibrary.org/b/isbn/9781234567897-M.jpg?default=false',
      );
      expect(KakaoBookService.fallbackCoverUrl(''), isNull);
    });
  });
}
