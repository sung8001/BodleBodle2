import 'dart:async';

import 'package:flutter/material.dart';

import '../services/tmdb_service.dart';

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

  // 선택된 작품 데이터
  Map<String, dynamic>? _selectedContent;

  // 감상 작성 데이터
  double _rating = 5.0;
  final TextEditingController _reviewController = TextEditingController();
  final DateTime _selectedDate = DateTime.now();
  String _visibility = '전체 공개'; // 전체 공개, 팔로워에게만 공개, 비공개

  // 도서/음악은 아직 테스트용 목록 사용 (영화는 TMDB 실시간 검색)
  final List<Map<String, dynamic>> _dummyContents = [
    {
      'title': '데미안',
      'category': '도서',
      'creator': '헤르만 헤세 저',
      'image': 'assets/images/onboarding1_1.jpg',
    },
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

  // 도서/음악의 로컬 이미지와 영화의 네트워크 포스터를 같은 위치에 표시
  Widget _buildContentImage(
    String? imagePath, {
    required double width,
    required double height,
  }) {
    final path = imagePath ?? '';

    Widget fallback() => Container(
          width: width,
          height: height,
          color: const Color(0xFFF2F2F2),
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined,
              color: Colors.black38),
        );

    if (path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    }

    if (path.isNotEmpty) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    }

    return fallback();
  }

  void _onMovieSearchChanged(String query) {
    // 이전 검색 예약 취소
    _searchTimer?.cancel();

    final requestId = ++_searchRequestId;

    // 영화 카테고리가 아니거나 검색어가 없는 경우
    if (_selectedCategory != '영화' || query.trim().isEmpty) {
      setState(() {
        _movieResults = [];
        _isSearchingMovies = false;
        _movieSearchError = null;
      });
      return;
    }

    setState(() {
      _isSearchingMovies = true;
      _movieSearchError = null;
    });

    // 입력 후 400ms 동안 추가 입력이 없으면 검색
    _searchTimer = Timer(
      const Duration(milliseconds: 400),
      () async {
        try {
          final results = await TmdbService.searchMovies(
            query: query,
          );

          // 오래된 검색 응답은 무시
          if (!mounted || requestId != _searchRequestId) {
            return;
          }

          setState(() {
            _movieResults = results;
            _isSearchingMovies = false;
          });
        } catch (e) {
          if (!mounted || requestId != _searchRequestId) {
            return;
          }

          setState(() {
            _movieResults = [];
            _isSearchingMovies = false;
            _movieSearchError = e.toString();
          });
        }
      },
    );
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
    final searchText = _searchController.text.trim();

    // 영화는 TMDB 실시간 데이터, 도서/음악은 현재 임시 목록 사용
    final List<Map<String, dynamic>> filtered = isMovie
        ? _movieResults.map(_movieToContent).toList()
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
                      // 진행 중인 이전 영화 검색을 무효화
                      _onMovieSearchChanged('');
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
            onChanged: (value) {
              _onMovieSearchChanged(value);
              if (_selectedCategory != '영화') setState(() {});
            },
            decoration: InputDecoration(
              hintText: '작품 제목 또는 제작자를 검색하세요',
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
        if (isMovie && _isSearchingMovies)
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
        else if (isMovie && searchText.isEmpty)
          const Expanded(
            child: Center(
              child: Text('영화 제목을 검색해 보세요.',
                  style: TextStyle(color: Colors.black54)),
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
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildContentImage(
                      item['image'] as String?,
                      width: 50,
                      height: isMovie ? 70 : 50,
                    ),
                  ),
                  title: Text(
                    item['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${item['creator']} · ${item['category']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() {
                      _selectedContent = item;
                      _step = 2; // 기존 감상 작성 화면으로 이동
                    });
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
                  height: 70,
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
