import 'dart:async';

import 'package:flutter/material.dart';

import '../services/tmdb_service.dart';
import '../services/kakao_book_service.dart';
// 4-1. 콘텐츠 검색 및 선택 -> 4-2. 감상 작성 -> 4-3. 티켓/영수증 생성

class CreateRecordScreen extends StatefulWidget {
  const CreateRecordScreen({super.key});
  @override
  State<CreateRecordScreen> createState() => _CreateRecordScreenState();
}

class _CreateRecordScreenState extends State<CreateRecordScreen> {
  int _step = 1; // 1: 작품검색, 2: 작성하기, 3: 영수증/티켓 발행
  String _selectedCategory = '영화';
  final TextEditingController _searchController = TextEditingController();
  // TMDB 영화 검색 결과
  List<Map<String, dynamic>> _movieResults = [];
  // 영화 검색 진행 상태
  bool _isSearchingMovies = false;
  // 검색 실패 메시지
  String? _movieSearchError;
  // 타이핑이 끝난 뒤 검색하기 위한 타이머
  Timer? _searchTimer;
  // 이전 검색 결과가 최신 결과를 덮어쓰지 않도록 관리
  int _searchRequestId = 0;
  // Kakao 도서 검색 결과
  List<Map<String, dynamic>> _bookResults = [];
  bool _isSearchingBooks = false;
  String? _bookSearchError;
  // 영화를 누른 뒤 상세 정보를 불러오는 중인 항목
  int? _openingMovieId;
  // 선택된 작품 데이터
  Map<String, dynamic>? _selectedContent;
  // 감상 작성 데이터
  double _rating = 5.0;
  final TextEditingController _reviewController = TextEditingController();
  final DateTime _selectedDate = DateTime.now();
  String _visibility = '전체 공개'; // 전체 공개, 팔로워에게만 공개, 비공개
  // 음악은 아직 테스트용 목록 사용 (영화/도서는 실시간 검색)
  final List<Map<String, dynamic>> _dummyContents = [
    {
      'title': 'LOVEずっきゅん',
      'category': '음악',
      'creator': 'Soutaiseiriron (상대성이론)',
      'image': 'assets/images/onboarding1_2.jpg',
    },
  ];
  // TMDB의 영화 데이터 -> 기존 감상 작성/티켓 화면에서 쓰는 데이터 형태로 변환
  Map<String, dynamic> _movieToContent(Map<String, dynamic> movie) {
    final title = (movie['title'] as String?)?.trim();
    final originalTitle = (movie['original_title'] as String?)?.trim();
    final releaseDate = (movie['release_date'] as String?) ?? '';
    final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
    final posterPath = (movie['poster_path'] as String?) ?? '';
    return {
      'title': title != null && title.isNotEmpty
          ? title
          : (originalTitle != null && originalTitle.isNotEmpty
              ? originalTitle
              : '제목 정보 없음'),
      'category': '영화',
      'creator': year.isEmpty ? '개봉 연도 정보 없음' : '$year년 개봉',
      'image': posterPath.isEmpty
          ? ''
          : 'https://image.tmdb.org/t/p/w342$posterPath',
      'tmdbId': movie['id'],
      'releaseDate': releaseDate,
      'overview': (movie['overview'] as String?) ?? '',
    };
  }
  // 카카오 도서 검색 응답 -> 기존 감상 기록 데이터 형태
  Map<String, dynamic> _bookToContent(Map<String, dynamic> book) {
    final authors = (book['authors'] is List)
        ? (book['authors'] as List)
            .whereType<String>()
            .where((name) => name.trim().isNotEmpty)
            .toList()
        : <String>[];
    final publishedDate = (book['datetime'] as String? ?? '').trim();
    final publisher = (book['publisher'] as String? ?? '').trim();
    final thumbnail = (book['thumbnail'] as String? ?? '')
        .trim()
        .replaceFirst('http://', 'https://');

    final title = (book['title'] as String? ?? '').trim();
    return {
      'title': title.isEmpty ? '제목 정보 없음' : title,
      'category': '도서',
      'creator': authors.isEmpty ? '정보 없음' : authors.join(', '),
      'authors': authors,
      'publisher': publisher,
      'publishedDate': publishedDate,
      'isbn': book['isbn'],
      'image': thumbnail,
      'fallbackImage': _fallbackBookCoverUrl(
        book['isbn']?.toString(),
      ),
    };
  }
  // 화면 내에서 보조 표지 URL을 계산하여 서비스 파일 버전과 독립적으로 동작합니다.
  String? _fallbackBookCoverUrl(String? rawIsbn) {
    final isbns = (rawIsbn ?? '')
        .split(RegExp(r'\s+'))
        .map((isbn) => isbn.replaceAll('-', '').trim())
        .where((isbn) => RegExp(r'^(?:\d{13}|\d{9}[\dXx])$').hasMatch(isbn))
        .toList();
    if (isbns.isEmpty) return null;
    final isbn = isbns.firstWhere(
      (value) => value.length == 13,
      orElse: () => isbns.first,
    );
    return 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg?default=false';
  }

  // 검색 결과/감상 기록에서 해당 '판본'의 출판연도를 표시
  String _bookPublicationYear(Map<String, dynamic> book) {
    final publishedDate = book['publishedDate'] as String? ?? '';
    final match = RegExp(r'^\d{4}').firstMatch(publishedDate);
    return match == null ? '출판연도 정보 없음' : '${match.group(0)}년';
  }
  String _bookListSubtitle(Map<String, dynamic> book) {
    final author = (book['creator'] as String? ?? '정보 없음').trim();
    final publisher = (book['publisher'] as String? ?? '').trim();
    return [
      author,
      _bookPublicationYear(book),
      if (publisher.isNotEmpty) publisher,
    ].join(' · ');
  }
  // 132분 -> 2시간 12분 / 45분 -> 45분
  String _formatRuntime(int? minutes) {
    if (minutes == null || minutes <= 0) return '상영시간 정보 없음';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours == 0) return '$minutes분';
    if (remaining == 0) return '$hours시간';
    return '$hours시간 $remaining분';
  }
  // 영화 검색 목록/감상평 헤더에 개봉연도를 표시합니다.
  String _movieReleaseYear(Map<String, dynamic> movie) {
    final releaseDate = movie['releaseDate'] as String? ?? '';
    if (releaseDate.length < 4) return '개봉연도 정보 없음';
    return '${releaseDate.substring(0, 4)}년';
  }
  // 영화 선택 시 감독 정보를 감상평/티켓에도 전달
  Future<void> _openMovie(Map<String, dynamic> movie) async {
    final movieId = movie['tmdbId'] as int?;
    Map<String, dynamic>? details;
    if (movieId != null) {
      setState(() => _openingMovieId = movieId);
      try {
        details = await TmdbService.getMovieDetails(movieId);
      } catch (_) {
        // 상세 정보가 없더라도 영화 선택 자체는 가능하게 처리
      }
    }
    if (!mounted) return;
    final director = (details?['director'] as String? ?? '').trim();
    final runtime = details?['runtime'] as int?;
    setState(() {
      _openingMovieId = null;
      _selectedContent = {
        ...movie,
        'creator': director.isEmpty ? '감독 정보 없음' : '$director 감독',
        'director': director,
        'runtime': runtime,
      };
      _step = 2;
    });
  }
  // 카카오 썸네일 우선, 실패하면 ISBN 기반 Open Library 표지 사용.
  // 두 곳 모두 실패한 경우에만 기본 아이콘 표시.
  Widget _buildContentImage(
    String? imagePath, {
    required double width,
    required double height,
    String? fallbackImagePath,
  }) {
    final path = (imagePath ?? '').trim();
    final backup = (fallbackImagePath ?? '').trim();

    Widget placeholder() => Container(
          width: width,
          height: height,
          color: const Color(0xFFF2F2F2),
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.black38,
          ),
        );

    Widget networkImage(String url, {required bool useBackup}) => Image.network(
          url,
          width: width,
          height: height,
          fit: BoxFit.cover,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          errorBuilder: (_, _, _) => useBackup && backup.startsWith('https://')
              ? Image.network(
                  backup,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  errorBuilder: (_, _, _) => placeholder(),
                )
              : placeholder(),
        );

    if (path.startsWith('https://')) {
      return networkImage(path, useBackup: path != backup);
    }
    if (path.isNotEmpty && !path.startsWith('http://')) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder(),
      );
    }
    if (backup.startsWith('https://')) {
      return networkImage(backup, useBackup: false);
    }
    return placeholder();
  }
  // 영화/도서 검색: 입력 중 API 호출을 줄이고 이전 검색 결과가 섞이지 않도록 관리
  void _onContentSearchChanged(String query) {
    _searchTimer?.cancel();
    final requestId = ++_searchRequestId;
    final category = _selectedCategory;
    final keyword = query.trim();
    if (keyword.isEmpty || category == '음악') {
      setState(() {
        _movieResults = [];
        _isSearchingMovies = false;
        _movieSearchError = null;
        _bookResults = [];
        _isSearchingBooks = false;
        _bookSearchError = null;
      });
      return;
    }
    setState(() {
      _movieSearchError = null;
      _bookSearchError = null;
      _isSearchingMovies = category == '영화';
      _isSearchingBooks = category == '도서';
      _movieResults = [];
      _bookResults = [];
    });
    _searchTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        if (category == '영화') {
          final movies = await TmdbService.searchMovies(query: keyword);
          if (!mounted || requestId != _searchRequestId ||
              _selectedCategory != category) return;
          setState(() {
            _movieResults = movies;
            _isSearchingMovies = false;
          });
        } else if (category == '도서') {
          final books = await KakaoBookService.searchBooks(query: keyword);
          if (!mounted || requestId != _searchRequestId ||
              _selectedCategory != category) return;
          setState(() {
            _bookResults = books;
            _isSearchingBooks = false;
          });
        }
      } catch (e) {
        if (!mounted || requestId != _searchRequestId ||
            _selectedCategory != category) return;
        setState(() {
          if (category == '영화') {
            _movieResults = [];
            _isSearchingMovies = false;
            _movieSearchError = e.toString();
          } else {
            _bookResults = [];
            _isSearchingBooks = false;
            _bookSearchError = e.toString();
          }
        });
      }
    });
  }
  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _reviewController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_step > 1 && _step < 3) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _step == 1
              ? '기록할 작품 선택'
              : _step == 2
              ? '감상 기록 작성'
              : 'POV-IE 감상 티켓',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildStepBody(),
    );
  }
  Widget _buildStepBody() {
    switch (_step) {
      case 1:
        return _buildContentSearchStep();
      case 2:
        return _buildWriteReviewStep();
      case 3:
        return _buildReceiptTicketStep();
      default:
        return Container();
    }
  }

  // [4-1] 콘텐츠 검색 및 등록 화면
  Widget _buildContentSearchStep() {
    final isMovie = _selectedCategory == '영화';
    final isBook = _selectedCategory == '도서';
    final searchText = _searchController.text.trim();
    // 영화=TMDB, 도서=카카오 도서 검색, 음악=기존 임시 목록
    final List<Map<String, dynamic>> filtered = isMovie
        ? _movieResults.map(_movieToContent).toList()
        : isBook
            ? _bookResults.map(_bookToContent).toList()
            : _dummyContents
                .where((item) => item['category'] == _selectedCategory)
                .where((item) =>
                    (item['title'] as String).contains(searchText) ||
                    (item['creator'] as String).contains(searchText))
                .toList();
    return Column(
      children: [
        // 카테고리 선택 (영화, 도서, 음악) : 기존 스타일 유지
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: ['영화', '도서', '음악'].map((cat) {
              final isSel = _selectedCategory == cat;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Center(child: Text(cat)),
                    selected: isSel,
                    onSelected: (_) {
                      if (isSel) return;
                      setState(() {
                        _selectedCategory = cat;
                        _searchController.clear();
                      });
                      // 카테고리가 바뀌면 기존 검색 요청/결과 모두 무효화
                      _onContentSearchChanged('');
                    },
                    selectedColor: Colors.black,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: const Color(0xFFF2F2F2),
                    showCheckmark: false,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // 검색창: 기존 UI 유지
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _onContentSearchChanged,
            decoration: InputDecoration(
              hintText: isBook
                  ? '책 제목 또는 작가명을 검색하세요'
                  : '작품 제목 또는 제작자를 검색하세요',
              prefixIcon: const Icon(Icons.search, color: Colors.black54),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // 검색 상태: 로딩/오류/빈 결과 처리
        if ((isMovie && _isSearchingMovies) ||
            (isBook && _isSearchingBooks))
          const Expanded(
            child: Center(child: CircularProgressIndicator(color: Colors.black)),
          )
        else if (isMovie && _movieSearchError != null)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '영화 검색에 실패했어요.\n$_movieSearchError\n\n검색어를 수정한 뒤 다시 시도해 주세요.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ),
          )
        else if (isBook && _bookSearchError != null)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '도서 검색에 실패했어요.\n$_bookSearchError\n\n검색어를 수정한 뒤 다시 시도해 주세요.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ),
          )
        else if ((isMovie || isBook) && searchText.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                isMovie ? '영화 제목을 검색해 보세요.' : '책 제목이나 작가명을 검색해 보세요.',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          )
        else if (filtered.isEmpty)
          const Expanded(
            child: Center(
              child: Text('검색 결과가 없어요.',
                  style: TextStyle(color: Colors.black54)),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                return ListTile(
                  isThreeLine: false,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildContentImage(
                      item['image'] as String?,
                      width: 50,
                      height: (isMovie || isBook) ? 70 : 50,
                      fallbackImagePath: isBook
                          ? item['fallbackImage'] as String?
                          : null,
                    ),
                  ),
                  title: Text(
                    item['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: isMovie
                      ? Text('영화 · ${_movieReleaseYear(item)}')
                      : isBook
                          ? Text(
                              _bookListSubtitle(item),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : Text('${item['category']} · ${item['creator']}'),
                  trailing: isMovie && _openingMovieId == item['tmdbId']
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    if (isMovie) {
                      if (_openingMovieId != null) return;
                      _openMovie(item);
                    } else {
                      setState(() {
                        _selectedContent = item;
                        _step = 2;
                      });
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  // [4-2] 감상 기록 작성 화면
  Widget _buildWriteReviewStep() {
    if (_selectedContent == null) return Container();
    final isMovie = _selectedContent!['category'] == '영화';
    final isBook = _selectedContent!['category'] == '도서';
    final director = (_selectedContent!['director'] as String? ?? '').trim();
    final directorLabel =
        director.isEmpty ? '감독 정보 없음' : '감독 $director';
    final runtimeLabel = _formatRuntime(_selectedContent!['runtime'] as int?);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 선택된 작품 카드 헤더
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildContentImage(
                  _selectedContent!['image'] as String?,
                  width: 70,
                  height: isBook ? 98 : 70,
                  fallbackImagePath: isBook
                      ? _selectedContent!['fallbackImage'] as String?
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedContent!['title'],
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isMovie) ...[
                      Text(
                        '영화 · ${_movieReleaseYear(_selectedContent!)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$directorLabel · $runtimeLabel',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else if (isBook) ...[
                      Text(
                        '도서 · ${_bookPublicationYear(_selectedContent!)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '작가 ${_selectedContent!['creator']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '출판사 ${(_selectedContent!['publisher'] as String? ?? '').isEmpty ? '정보 없음' : _selectedContent!['publisher']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ] else
                      Text(
                        _selectedContent!['creator'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          // 평점 입력 (별점)
          const Text(
            '나의 별점',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      index < _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.black,
                      size: 32,
                    ),
                    onPressed: () =>
                        setState(() => _rating = (index + 1).toDouble()),
                  );
                }),
              ),
              const SizedBox(width: 12),
              Text(
                '${_rating.toStringAsFixed(1)} / 5.0',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 한줄평 / 감상 작성 (300자 제한)
          const Text(
            '감상평 (공백 포함 최대 300자)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reviewController,
            maxLength: 300,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '이 작품에 대한 솔직한 감상을 적어주세요.',
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 감상 날짜 & 공개 설정
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '공개 설정',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              DropdownButton<String>(
                value: _visibility,
                items: ['전체 공개', '팔로워에게만 공개', '비공개']
                    .map(
                      (val) => DropdownMenuItem(value: val, child: Text(val)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _visibility = val!),
              ),
            ],
          ),
          const SizedBox(height: 30),
          // 저장 및 티켓 발행 버튼
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (_reviewController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('감상평을 입력해주세요.')));
                  return;
                }
                setState(() => _step = 3);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text(
                '기록 완료 및 티켓 생성',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [4-3] 티켓/영수증 감성 카드 생성 화면
  Widget _buildReceiptTicketStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // 티켓 스타일 컨테이너
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'POV-IE CULTURAL TICKET',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildContentImage(
                    _selectedContent!['image'] as String?,
                    width: double.infinity,
                    height: 180,
                    fallbackImagePath: _selectedContent!['category'] == '도서'
                        ? _selectedContent!['fallbackImage'] as String?
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedContent!['title'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _selectedContent!['creator'],
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const Divider(height: 24, thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RATING',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '★ ${_rating.toStringAsFixed(1)} / 5.0',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DATE',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_selectedDate.year}.${_selectedDate.month}.${_selectedDate.day}',
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 1),
                Text(
                  '"${_reviewController.text}"',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text(
                '닫기 및 피드로 돌아가기',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
