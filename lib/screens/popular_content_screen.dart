import 'package:flutter/material.dart';

class PopularContentScreen extends StatefulWidget {
  const PopularContentScreen({super.key});

  @override
  State<PopularContentScreen> createState() => _PopularContentScreenState();
}

class _PopularContentScreenState extends State<PopularContentScreen> {
  String _selectedCategory = '통합';
  final List<String> _tabs = ['통합', '영화', '책', '음악'];

  final List<Map<String, dynamic>> _popularList = [
    {
      'rank': 1,
      'title': '비포 선라이즈',
      'type': '영화',
      'score': 4.9,
      'image': 'assets/images/onboarding1_3.jpg',
    },
    {
      'rank': 2,
      'title': '데미안',
      'type': '책',
      'score': 4.8,
      'image': 'assets/images/onboarding1_1.jpg',
    },
    {
      'rank': 3,
      'title': 'PULP FICTION',
      'type': '영화',
      'score': 4.7,
      'image': 'assets/images/onboarding1_2.jpg',
    },
    {
      'rank': 4,
      'title': 'LOVEずっきゅん',
      'type': '음악',
      'score': 4.6,
      'image': 'assets/images/onboarding1_2.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == '통합'
        ? _popularList
        : _popularList
              .where((item) => item['type'] == _selectedCategory)
              .toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _tabs.map((tab) {
              final isSelected = _selectedCategory == tab;
              return InkWell(
                onTap: () => setState(() => _selectedCategory = tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: isSelected
                        ? const Border(
                            bottom: BorderSide(color: Colors.black, width: 2.5),
                          )
                        : null,
                  ),
                  child: Text(
                    tab,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 15,
                      color: isSelected ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final item = filtered[index];
              return Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${item['rank']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      item['image'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item['type']} · 평균 ★ ${item['score']}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
