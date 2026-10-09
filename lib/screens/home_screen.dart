import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'create_record_screen.dart';
import 'popular_content_screen.dart';
import 'profile_screen.dart';
import 'search_user_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _HomeFeedTab(),
    const PopularContentScreen(),
    const SizedBox.shrink(),
    const SearchUserScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'POV-IE',
          style: GoogleFonts.anton(
            color: Colors.black,
            fontSize: 32,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        height: 68,
        decoration: const BoxDecoration(
          color: Color(0xFFE5E5E5),
          border: Border(top: BorderSide(color: Color(0xFFD0D0D0), width: 0.8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SplashNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              index: 0,
              selectedIndex: _selectedIndex,
              onTap: () => setState(() => _selectedIndex = 0),
            ),
            _SplashNavItem(
              icon: Icons.local_fire_department_outlined,
              activeIcon: Icons.local_fire_department_rounded,
              index: 1,
              selectedIndex: _selectedIndex,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            _SplashNavItem(
              icon: Icons.add,
              activeIcon: Icons.add,
              index: 2,
              selectedIndex: _selectedIndex,
              isAdd: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateRecordScreen()),
                );
              },
            ),
            _SplashNavItem(
              icon: Icons.search_rounded,
              activeIcon: Icons.search_rounded,
              index: 3,
              selectedIndex: _selectedIndex,
              onTap: () => setState(() => _selectedIndex = 3),
            ),
            _SplashNavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              index: 4,
              selectedIndex: _selectedIndex,
              onTap: () => setState(() => _selectedIndex = 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final int selectedIndex;
  final bool isAdd;
  final VoidCallback onTap;

  const _SplashNavItem({
    required this.icon,
    required this.activeIcon,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    this.isAdd = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        splashColor: Colors.black.withValues(alpha: 0.12),
        highlightColor: Colors.black.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutBack,
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: isAdd ? 32 : 26,
                  color: isAdd
                      ? Colors.black
                      : (isSelected ? Colors.black : Colors.black54),
                ),
              ),
              const SizedBox(height: 3),
              if (isSelected && !isAdd)
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeFeedTab extends StatefulWidget {
  const _HomeFeedTab();

  @override
  State<_HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends State<_HomeFeedTab> {
  String _selectedCategory = '전체';
  final List<String> _categories = ['전체', '🎬 영화', '🎵 음악', '📚 도서'];

  final List<Map<String, dynamic>> _storyList = [
    {'name': '내 피드', 'image': '', 'isMy': true, 'hasNew': false},
    {
      'name': '김민수',
      'image': 'assets/images/onboarding1_1.jpg',
      'isMy': false,
      'hasNew': true,
    },
    {
      'name': '미둠',
      'image': 'assets/images/onboarding1_2.jpg',
      'isMy': false,
      'hasNew': true,
    },
    {'name': '우성', 'image': '', 'isMy': false, 'hasNew': false},
    {
      'name': '하가연',
      'image': 'assets/images/onboarding1_3.jpg',
      'isMy': false,
      'hasNew': true,
    },
  ];

  final List<Map<String, dynamic>> _feedList = [
    {
      'id': 1,
      'userId': 'minsuskim',
      'category': '🎬 영화',
      'postImage': 'assets/images/onboarding1_3.jpg',
      'rating': 5.0,
      'title': '아름다운 영화',
      'content': '우연히 만난 낯선 이와의 하룻밤 대화. 시간에 쫓기는 사랑이 주는 애틋함이 길게 남는다.',
      'date': '2026/09/24',
      'likes': 128,
      'isLiked': false,
      'isBookmarked': false,
    },
    {
      'id': 2,
      'userId': 'miiimimimimi',
      'category': '🎬 영화',
      'postImage': 'assets/images/onboarding1_2.jpg',
      'rating': 4.5,
      'title': '펄프 픽션 (PULP FICTION)',
      'content': '타란티노 감독 특유의 독특한 오프닝과 감각적인 스타일리시 연출!',
      'date': '2026/09/22',
      'likes': 95,
      'isLiked': false,
      'isBookmarked': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredFeed = _selectedCategory == '전체'
        ? _feedList
        : _feedList
              .where((item) => item['category'] == _selectedCategory)
              .toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 95,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _storyList.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final story = _storyList[index];
                final bool isMy = story['isMy'] == true;
                final bool hasNew = story['hasNew'] == true;

                return Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(hasNew ? 2.5 : 0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: hasNew
                                ? Border.all(color: Colors.black, width: 2)
                                : null,
                          ),
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE5E5E5),
                              image: story['image']!.isNotEmpty
                                  ? DecorationImage(
                                      image: AssetImage(story['image']!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: story['image']!.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 36,
                                  )
                                : null,
                          ),
                        ),
                        if (isMy)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      story['name']!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 12.5,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                  backgroundColor: const Color(0xFFF2F2F2),
                  selectedColor: Colors.black,
                  showCheckmark: false,
                  elevation: 0,
                  pressElevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                );
              },
            ),
          ),
          const Divider(color: Color(0xFFEEEEEE), thickness: 1, height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredFeed.length,
            itemBuilder: (context, index) {
              final feed = filteredFeed[index];
              return _buildFeedCard(feed);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeedCard(Map<String, dynamic> feed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Color(0xFFE5E5E5),
                  child: Icon(Icons.person, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  feed['userId'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    feed['category'],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 280,
            color: const Color(0xFF1F1F1F),
            child: Image.asset(
              feed['postImage'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.image_not_supported, color: Colors.white38),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < feed['rating'].toInt()
                              ? Icons.star_rounded
                              : Icons.star_half_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${feed['rating']}/5.0',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  feed['title'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feed['content'],
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      feed['date'],
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          feed['isLiked'] = !feed['isLiked'];
                          feed['likes'] += feed['isLiked'] ? 1 : -1;
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            feed['isLiked']
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: feed['isLiked']
                                ? Colors.red
                                : Colors.black87,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${feed['likes']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        setState(
                          () => feed['isBookmarked'] = !feed['isBookmarked'],
                        );
                      },
                      child: Icon(
                        feed['isBookmarked']
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
