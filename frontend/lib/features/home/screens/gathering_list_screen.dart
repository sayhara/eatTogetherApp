import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/gathering_model.dart';
import '../providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';

final _now = DateTime.now();

final _sampleGatherings = <GatheringModel>[
  GatheringModel(
    id: -1, hostId: 0, hostNickname: '맛있어요',
    title: '저녁에 춘천닭갈비 먹으실 분!',
    restaurantName: '홍촌천닭갈비 태장점',
    latitude: 37.495, longitude: 126.936,
    maxParticipants: 4, currentParticipants: 1,
    mealTime: _now.add(const Duration(days: 3, hours: 7)),
    status: 'OPEN', category: 'KOREAN',
  ),
  GatheringModel(
    id: -2, hostId: 0, hostNickname: '파스타러버',
    title: '파스타 먹어요~',
    restaurantName: '덕수파스타 원주일산점',
    latitude: 37.496, longitude: 126.937,
    maxParticipants: 4, currentParticipants: 1,
    mealTime: _now.add(const Duration(days: 4, hours: 18, minutes: 30)),
    status: 'OPEN', category: 'WESTERN',
  ),
  GatheringModel(
    id: -3, hostId: 0, hostNickname: '기사식당팬',
    title: '아침에 같이 기사식당 가요',
    restaurantName: '아줌마기사식당',
    latitude: 37.494, longitude: 126.935,
    maxParticipants: 6, currentParticipants: 1,
    mealTime: _now.add(const Duration(days: 2, hours: 9)),
    status: 'OPEN', category: 'KOREAN',
  ),
  GatheringModel(
    id: -4, hostId: 0, hostNickname: '치맥좋아',
    title: '저녁에 치맥 함께해요!!!!',
    restaurantName: '홍대델리치킨',
    latitude: 37.493, longitude: 126.934,
    maxParticipants: 5, currentParticipants: 1,
    mealTime: _now.add(const Duration(days: 1, hours: 18, minutes: 30)),
    status: 'OPEN', category: 'FAST_FOOD',
  ),
  GatheringModel(
    id: -5, hostId: 0, hostNickname: '갈비마니아',
    title: '갈비 같이 드실 분??',
    restaurantName: '한우가 한우리',
    latitude: 37.492, longitude: 126.933,
    maxParticipants: 4, currentParticipants: 3,
    mealTime: _now.add(const Duration(days: 5, hours: 19)),
    status: 'OPEN', category: 'KOREAN',
  ),
];

class GatheringListScreen extends ConsumerStatefulWidget {
  const GatheringListScreen({super.key});

  @override
  ConsumerState<GatheringListScreen> createState() => _GatheringListScreenState();
}

class _GatheringListScreenState extends ConsumerState<GatheringListScreen> {
  bool _locationInit = false;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initLocation();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { if (mounted) setState(() => _locationInit = true); return; }
    if (!mounted) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) { if (mounted) setState(() => _locationInit = true); return; }
    }
    if (!mounted) return;
    if (permission == LocationPermission.deniedForever) { if (mounted) setState(() => _locationInit = true); return; }

    Position? position = await Geolocator.getLastKnownPosition();
    if (position == null) {
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
        );
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _locationInit = true);

    if (position != null) {
      ref.read(nearbyCoordsProvider.notifier).set(position.latitude, position.longitude);
      ref.read(authProvider.notifier).updateLocation(latitude: position.latitude, longitude: position.longitude);
    }
  }

  void _startSearch() => setState(() { _isSearching = true; _searchController.clear(); });

  void _stopSearch() => setState(() { _isSearching = false; _searchController.clear(); _searchQuery = ''; });

  List<GatheringModel> _filterAndMerge(List<GatheringModel> real) {
    final all = real.isEmpty ? [...real, ..._sampleGatherings] : real;
    if (_searchQuery.trim().isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((g) =>
      g.title.toLowerCase().contains(q) ||
      g.restaurantName.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final coords = ref.watch(nearbyCoordsProvider);
    final gatheringsAsync = coords != null
        ? ref.watch(nearbyGatheringsProvider)
        : _locationInit
            ? const AsyncData<List<GatheringModel>>([])
            : const AsyncValue<List<GatheringModel>>.loading();

    final timeStr = DateFormat('H:mm').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Hero Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD600), Color(0xFFFFC107)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '혼밥은 그만 🍚\n함께하는 한 끼',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const Spacer(),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: coords != null,
                            onChanged: (_) {},
                            activeThumbColor: const Color(0xFF03C75A),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 모임 목록 header (normal) or Search bar
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isSearching
                ? _SearchBar(
                    key: const ValueKey('search'),
                    controller: _searchController,
                    onClose: _stopSearch,
                  )
                : Padding(
                    key: const ValueKey('header'),
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                    child: Row(
                      children: [
                        const Text(
                          '모임 목록',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 22, color: Colors.black54),
                          onPressed: () => ref.invalidate(nearbyGatheringsProvider),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search, size: 22, color: Colors.black54),
                          onPressed: _startSearch,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_none, size: 22, color: Colors.black54),
                          onPressed: () {},
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
          ),

          // Gathering list
          Expanded(
            child: gatheringsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF03C75A))),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (gatherings) {
                final display = _filterAndMerge(gatherings);
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(nearbyGatheringsProvider),
                  color: const Color(0xFF03C75A),
                  child: display.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                _searchQuery.isNotEmpty
                                    ? '검색 결과가 없어요'
                                    : '근처에 모임이 없어요\n먼저 모임을 만들어보세요!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey, fontSize: 15),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: display.length,
                          itemBuilder: (ctx, i) => _GatheringCard(gathering: display[i]),
                        ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isSearching
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/gathering/create');
                ref.invalidate(nearbyGatheringsProvider);
              },
              backgroundColor: const Color(0xFF03C75A),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('모임 만들기', style: TextStyle(color: Colors.white)),
            ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClose;
  const _SearchBar({super.key, required this.controller, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black54),
            onPressed: onClose,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '모임 이름, 식당 이름으로 검색',
                hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (true)
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.black45),
              onPressed: () => controller.clear(),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class _GatheringCard extends StatelessWidget {
  final GatheringModel gathering;
  const _GatheringCard({required this.gathering});

  static const _categoryColor = {
    'KOREAN': Color(0xFFFF8C42),
    'CHINESE': Color(0xFFE53935),
    'JAPANESE': Color(0xFFEC407A),
    'WESTERN': Color(0xFF5C6BC0),
    'FAST_FOOD': Color(0xFFFFB300),
    'CAFE': Color(0xFF8D6E63),
    'OTHER': Color(0xFF26A69A),
  };

  static const _categoryEmoji = {
    'KOREAN': '🍲',
    'CHINESE': '🥟',
    'JAPANESE': '🍱',
    'WESTERN': '🍝',
    'FAST_FOOD': '🍔',
    'CAFE': '☕',
    'OTHER': '🍽️',
  };

  String _formatTime(DateTime dt) {
    final ampm = dt.hour < 12 ? '오전' : '오후';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}. ${dt.day}.  $ampm $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isRecruiting = gathering.isOpen && !gathering.isFull;
    final color = _categoryColor[gathering.category] ?? const Color(0xFF26A69A);
    final emoji = _categoryEmoji[gathering.category] ?? '🍽️';
    final isSample = gathering.id < 0;

    return GestureDetector(
      onTap: isSample
          ? () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('실제 모임을 만들어 참여해보세요!'), duration: Duration(seconds: 2)),
              )
          : () => context.push('/gathering/${gathering.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          gathering.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isRecruiting ? const Color(0xFFFFD600) : Colors.orange.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isRecruiting ? '모집중' : '마감',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(Icons.people_alt_outlined, '${gathering.currentParticipants}/${gathering.maxParticipants}'),
                  const SizedBox(height: 4),
                  _InfoRow(Icons.calendar_today_outlined, _formatTime(gathering.mealTime)),
                  const SizedBox(height: 4),
                  _InfoRow(Icons.place_outlined, gathering.restaurantName),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
