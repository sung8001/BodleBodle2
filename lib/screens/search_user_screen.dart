import 'package:flutter/material.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _users = [
    {'id': 'minsuskim', 'nickname': '김민수', 'badge': '영화 평론가'},
    {'id': 'miiimimimimi', 'nickname': '미둠', 'badge': '음악 덕후'},
    {'id': 'wooseong_dev', 'nickname': '우성', 'badge': '독서가'},
  ];

  @override
  Widget build(BuildContext context) {
    final searchKeyword = _searchController.text.trim();
    final searchResults = searchKeyword.isEmpty
        ? []
        : _users
              .where(
                (u) =>
                    u['id']!.contains(searchKeyword) ||
                    u['nickname']!.contains(searchKeyword),
              )
              .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 6-1. 검색창
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '사용자 ID 또는 닉네임 검색',
              prefixIcon: const Icon(Icons.search, color: Colors.black),
              filled: true,
              fillColor: const Color(0xFFF2F2F2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 검색 결과 영역
          if (searchKeyword.isNotEmpty) ...[
            const Text(
              '검색 결과',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final u = searchResults[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE5E5E5),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text('${u['nickname']} (@${u['id']})'),
                    subtitle: Text('칭호: ${u['badge']}'),
                  );
                },
              ),
            ),
          ] else ...[
            // 6-2. 추천 피드 영역
            const Text(
              '추천 피드',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: List.generate(4, (index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/onboarding1_2.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
