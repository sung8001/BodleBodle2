import 'package:flutter_test/flutter_test.dart';
import 'package:bodlebodle/services/kakao_book_service.dart';

Map<String, dynamic> book({
  required String title,
  String author = '작가',
  String isbn = '9780306406157',
  String publisher = '출판사',
  String date = '2024-01-01T00:00:00.000+09:00',
  String thumbnail = '',
  String contents = '',
  List<String> translators = const [],
}) => {
  'title': title,
  'authors': [author],
  'isbn': isbn,
  'publisher': publisher,
  'datetime': date,
  'thumbnail': thumbnail,
  'contents': contents,
  'translators': translators,
};

void main() {
  group('카카오 도서 검색 결과 후처리', () {
    test('제목 완전일치가 부분 일치와 작가 일치보다 먼저 나온다', () {
      final result = KakaoBookService.filterAndRankBooks('아몬드', [
        book(title: '초콜릿과 아몬드', isbn: '9780140328721'),
        book(title: '다른 책', author: '아몬드', isbn: '9783161484100'),
        book(title: '아몬드', isbn: '9780306406157'),
      ]);
      expect(result.map((b) => b['title']),
          ['아몬드', '초콜릿과 아몬드', '다른 책']);
    });

    test('공백 차이를 무시하고 작가명 검색을 지원한다', () {
      final result = KakaoBookService.filterAndRankBooks('손 원 평', [
        book(title: '아몬드', author: '손원평', isbn: '9780306406157'),
        book(title: '관련 없는 책', author: '다른 작가', isbn: '9780140328721'),
      ]);
      expect(result.length, 1);
      expect(result.single['title'], '아몬드');
    });

    test('동일 ISBN 및 동일 판본 중복은 제거하고 표지 있는 책을 우선한다', () {
      final result = KakaoBookService.filterAndRankBooks('아몬드', [
        book(title: '아몬드', isbn: '0306406152 9780306406157'),
        book(
          title: '아몬드',
          isbn: '9780306406157',
          thumbnail: 'https://example.org/cover.jpg',
        ),
        book(title: '아몬드', isbn: '9780306406157'),
      ]);
      expect(result.length, 1);
      expect(result.single['thumbnail'], 'https://example.org/cover.jpg');
    });

    test('출판연도가 다른 판본은 구분한다', () {
      final result = KakaoBookService.filterAndRankBooks('아몬드', [
        book(title: '아몬드', date: '2020-01-01', isbn: '9780306406157'),
        book(title: '아몬드', date: '2024-01-01', isbn: '9780140328721'),
      ]);
      expect(result.length, 2);
    });

    test('ISBN13 보조 표지 주소를 생성하며 없는 경우 null을 반환한다', () {
      expect(
        KakaoBookService.fallbackCoverUrl('0306406152 9780306406157'),
        'https://covers.openlibrary.org/b/isbn/9780306406157-M.jpg?default=false',
      );
      expect(KakaoBookService.fallbackCoverUrl(''), isNull);
    });

    test('포스터 컬렉션과 직소 퍼즐은 ISBN이 있어도 제외한다', () {
      final result = KakaoBookService.filterAndRankBooks('날씨의 아이', [
        book(title: '날씨의 아이', isbn: '9780306406157'),
        book(title: '날씨의 아이: 포스터 컬렉션', isbn: '9780140328721'),
        book(title: '날씨의 아이 직소퍼즐 500pcs', isbn: '9783161484100'),
      ]);

      expect(result.map((item) => item['title']), ['날씨의 아이']);
    });

    test('ISBN이 없거나 체크섬이 잘못된 결과는 제외한다', () {
      final result = KakaoBookService.filterAndRankBooks('아몬드', [
        book(title: '아몬드', isbn: '9780306406157'),
        book(title: '아몬드 한정 상품', isbn: ''),
        book(title: '아몬드 기타 상품', isbn: '9780306406158'),
      ]);

      expect(result.length, 1);
      expect(result.single['isbn'], '9780306406157');
    });

    test('작품의 공식 비주얼 가이드와 미술화집은 제외한다', () {
      final result = KakaoBookService.filterAndRankBooks('날씨의 아이', [
        book(title: '날씨의 아이', isbn: '9780306406157'),
        book(title: '날씨의 아이 공식 비주얼 가이드', isbn: '9780140328721'),
        book(title: '날씨의 아이 미술화집', isbn: '9783161484100'),
      ]);

      expect(result.map((item) => item['title']), ['날씨의 아이']);
    });

    test('잡지의 작품 커버 기사와 잡지 출판사 결과는 제외한다', () {
      final result = KakaoBookService.filterAndRankBooks('날씨의 아이', [
        book(title: '날씨의 아이', isbn: '9780306406157'),
        book(
          title: '앙앙 ANAN 2019.08.07 (날씨의아이 COVER)',
          isbn: '9780140328721',
          publisher: 'マガジンハウス',
        ),
      ]);

      expect(result.map((item) => item['title']), ['날씨의 아이']);
    });


    test('제목이 평범해도 소개에 부가 자료임이 표시되면 제외한다', () {
      final result = KakaoBookService.filterAndRankBooks('날씨의 아이', [
        book(title: '날씨의 아이', isbn: '9780306406157'),
        book(
          title: '날씨의 아이',
          isbn: '9780140328721',
          contents: '공식 비주얼 가이드 및 원화 자료 수록',
        ),
      ]);

      expect(result, hasLength(1));
      expect(result.single['isbn'], '9780306406157');
    });

    test('OST 피아노 연주곡집과 악보는 제외한다', () {
      final result = KakaoBookService.filterAndRankBooks('너의 이름은', [
        book(title: '너의 이름은', isbn: '9780306406157'),
        book(
          title: '너의 이름은 OST 피아노 연주곡집',
          isbn: '9780140328721',
        ),
        book(
          title: '너의 이름은 Original Soundtrack Piano Score',
          isbn: '9783161484100',
        ),
      ]);

      expect(result.map((item) => item['title']), ['너의 이름은']);
    });

    test('중국 출판사가 발행한 일본 작가의 현지판은 제외한다', () {
      final result = KakaoBookService.filterAndRankBooks('너의 이름은', [
        book(title: '너의 이름은', isbn: '9780306406157'),
        book(
          title: 'ni的名字。 (漫画)(全3冊) 너의 이름은',
          author: '新海誠',
          publisher: '절강인민미술출판사',
          isbn: '9780140328721',
        ),
        book(
          title: '니적명자 너의 이름은',
          author: '新海诚',
          publisher: '浙江人民美术出版社',
          isbn: '9783161484100',
        ),
      ]);

      expect(result.map((item) => item['title']), ['너의 이름은']);
    });

    test('중국 출판사의 번역 출간물은 작가가 목록에 없어도 제외한다', () {
      final result = KakaoBookService.filterAndRankBooks('작품 제목', [
        book(title: '작품 제목', isbn: '9780306406157'),
        book(
          title: '作品标题 작품 제목',
          author: '알려지지 않은 일본 작가',
          publisher: '浙江人民出版社',
          translators: ['번역자'],
          isbn: '9780140328721',
        ),
      ]);

      expect(result.map((item) => item['title']), ['작품 제목']);
    });

    test('중국 원작 작가의 책은 중국 출판사 발행이어도 유지한다', () {
      final result = KakaoBookService.filterAndRankBooks('삼체', [
        book(
          title: '삼체 三体',
          author: '刘慈欣',
          publisher: '重庆出版社',
          isbn: '9780140328721',
        ),
      ]);

      expect(result, hasLength(1));
      expect(result.single['title'], '삼체 三体');
    });

    test('작품 원작 소설은 부가 자료로 오인해 제외하지 않는다', () {
      final result = KakaoBookService.filterAndRankBooks('날씨의 아이', [
        book(title: '小説 天気の子 날씨의 아이', isbn: '9780306406157'),
      ]);

      expect(result, hasLength(1));
      expect(result.single['title'], '小説 天気の子 날씨의 아이');
    });

  });
}
