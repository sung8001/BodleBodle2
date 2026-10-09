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
                // 1. 상단 SKIP 버튼 (마우스 커서 모션 및 호버 효과 적용)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _SkipButton(onTap: widget.onComplete),
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

// 마우스 호버 커서 및 스케일 모션이 적용된 SKIP 버튼 위젯
class _SkipButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SkipButton({required this.onTap});

  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            opacity: _isHovered ? 0.85 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
      color: const Color(0xFF1F1F1F),
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
                final double h = constraints.maxHeight;

                final double titleFontSize = w * 0.125; // "나만의", "취", "향"
                final double bottomFontSize = w * 0.11; // "기록하는", "법"

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // --- [1. 이미지 카드 3개 배치] ---

                    // 중간: 애니메이션 & 음악 재생창
                    Positioned(
                      top: h * 0.22,
                      left: 0,
                      child: _buildImageCard(
                        imagePath: 'assets/images/onboarding1_2.jpg',
                        width: w * 0.48,
                        height: h * 0.52,
                      ),
                    ),

                    // 상단: 유선 이어폰 남녀
                    Positioned(
                      top: h * 0.04,
                      right: 0,
                      child: _buildImageCard(
                        imagePath: 'assets/images/onboarding1_1.jpg',
                        width: w * 0.54,
                        height: h * 0.28,
                      ),
                    ),

                    // 하단: 노트북 영화
                    Positioned(
                      top: h * 0.52,
                      right: 0,
                      child: _buildImageCard(
                        imagePath: 'assets/images/onboarding1_3.jpg',
                        width: w * 0.54,
                        height: h * 0.42,
                      ),
                    ),

                    // --- [2. 텍스트 분리 및 정밀 위치 고정] ---

                    // "나만의"
                    Positioned(
                      top: h * 0.02,
                      left: 0,
                      child: Text(
                        '나만의',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -2.0,
                          height: 1.0,
                        ),
                      ),
                    ),

                    // "취"
                    Positioned(
                      top: h * 0.425,
                      left: w * 0.355,
                      child: Text(
                        '취',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -2.0,
                          height: 1.0,
                        ),
                      ),
                    ),

                    // "향"
                    Positioned(
                      top: h * 0.425,
                      left: w * 0.485,
                      child: Text(
                        '향',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -2.0,
                          height: 1.0,
                        ),
                      ),
                    ),

                    // "기록하는"
                    Positioned(
                      top: h * 0.88,
                      left: w * 0.08,
                      child: Text(
                        '기록하는',
                        style: TextStyle(
                          fontSize: bottomFontSize,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -1.5,
                          height: 1.0,
                        ),
                      ),
                    ),

                    // "법"
                    Positioned(
                      top: h * 0.88,
                      left: w * 0.49,
                      child: Text(
                        '법',
                        style: TextStyle(
                          fontSize: bottomFontSize,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.5,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),

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
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
