import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          // PC나 큰 화면에서도 스마트폰 모바일 가로 비율(최대 420px)로 고정
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                // 1. 상단 SKIP 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: widget.onComplete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SKIP',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.fast_forward_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. 메인 슬라이드 영역
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: [
                      const _FirstOnboardingSlide(),
                      Container(
                        alignment: Alignment.center,
                        child: const Text('두 번째 슬라이드 (준비중)'),
                      ),
                      Container(
                        alignment: Alignment.center,
                        child: const Text('세 번째 슬라이드 (준비중)'),
                      ),
                    ],
                  ),
                ),

                // 3. 하단 점 인디케이터 & 시작하기 버튼
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 24,
                    left: 24,
                    right: 24,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _totalPages,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _currentPage == index
                                    ? Colors.black
                                    : Colors.grey[400]!,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentPage == index
                                      ? Colors.black
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_currentPage == _totalPages - 1)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: widget.onComplete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '시작하기',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FirstOnboardingSlide extends StatelessWidget {
  const _FirstOnboardingSlide();

  Widget _buildImageCard({
    required String imagePath,
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(color: Color(0xFF1F1F1F)),
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.image_not_supported,
              color: Colors.white38,
              size: 24,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double w = constraints.maxWidth;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // --- [1단계: 사진들을 먼저 바닥에 배치] ---

                    // 1. 상단: 유선 이어폰 남녀 사진 (우측)
                    Positioned(
                      top: 25,
                      right: 0,
                      child: _buildImageCard(
                        imagePath: 'assets/images/onboarding1_1.jpg',
                        width: w * 0.52,
                        height: 120,
                      ),
                    ),

                    // 2. 중간: 애니메이션 & 음악 재생창 (좌측)
                    Positioned(
                      top: 90,
                      left: 0,
                      child: _buildImageCard(
                        imagePath: 'assets/images/onboarding1_2.jpg',
                        width: w * 0.48,
                        height: 250,
                      ),
                    ),

                    // 3. 하단: 노트북 영화 사진 (우측)
                    Positioned(
                      top: 235,
                      right: 0,
                      child: _buildImageCard(
                        imagePath: 'assets/images/onboarding1_3.jpg',
                        width: w * 0.52,
                        height: 190,
                      ),
                    ),

                    // --- [2단계: 글자를 사진 '위'에 얹어서 오버랩 표현] ---

                    // 4. "나만의"
                    const Positioned(
                      top: 5,
                      left: 0,
                      child: Text(
                        '나만의',
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -2.0,
                          height: 1.0,
                        ),
                      ),
                    ),

                    // 5. "취향" ('취'는 사진 위 흰색, '향'은 배경 위 검은색)
                    Positioned(
                      top: 175,
                      left: w * 0.35, // '취' 자가 중간 사진 상단 구석에 딱 걸치도록 조정
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2.0,
                            height: 1.0,
                          ),
                          children: [
                            TextSpan(
                              text: '취',
                              style: TextStyle(color: Colors.white), // 사진 위 흰색
                            ),
                            TextSpan(
                              text: '향',
                              style: TextStyle(
                                color: Colors.black,
                              ), // 바깥 배경 검은색
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 6. "기록하는법"
                    const Positioned(
                      bottom: 0,
                      left: 0,
                      child: Text(
                        '기록하는법',
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -2.0,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 25),

          // 하단 설명글
          const Text(
            '책, 영화, 음악 등 다양한 문화 콘텐츠를 감상하고\n나만의 감상 기록을 하나의 콘텐츠로 만들어 저장하고 공유하는 플랫폼',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF222222),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}
