import 'package:flutter/material.dart';

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

  // 선택된 작품 데이터
  Map<String, dynamic>? _selectedContent;

  // 감상 작성 데이터
  double _rating = 5.0;
  final TextEditingController _reviewController = TextEditingController();
  final DateTime _selectedDate = DateTime.now();
  String _visibility = '전체 공개'; // 전체 공개, 팔로워에게만 공개, 비공개

  // 더미 콘텐츠 DB
  final List<Map<String, dynamic>> _dummyContents = [
    {
      'title': '비포 선라이즈 (Before Sunrise)',
      'category': '영화',
      'creator': '리처드 링클레이터 감독',
      'image': 'assets/images/onboarding1_3.jpg',
    },
    {
      'title': 'PULP FICTION',
      'category': '영화',
      'creator': '쿠엔틴 타란티노 감독',
      'image': 'assets/images/onboarding1_2.jpg',
    },
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
    final filtered = _dummyContents
        .where((c) => c['category'] == _selectedCategory)
        .where(
          (c) =>
              c['title'].contains(_searchController.text) ||
              c['creator'].contains(_searchController.text),
        )
        .toList();

    return Column(
      children: [
        // 카테고리 선택 (영화, 도서, 음악)
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
                    onSelected: (_) => setState(() => _selectedCategory = cat),
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

        // 검색창
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
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

        // 작품 리스트
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    item['image'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  item['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${item['creator']} · ${item['category']}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  setState(() {
                    _selectedContent = item;
                    _step = 2; // 다음 단계로 이동
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
                child: Image.asset(
                  _selectedContent!['image'],
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
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
                  color: Colors.black.withOpacity(0.05),
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
                  child: Image.asset(
                    _selectedContent!['image'],
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
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
