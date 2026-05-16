import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:intl/intl.dart';
import '../models/gathering_model.dart';
import '../providers/home_provider.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  KakaoMapController? _mapController;
  GatheringModel? _selectedGathering;
  LatLng _mapCenter = LatLng(37.5665, 126.9780);
  bool _centerMoved = false;
  Set<Marker> _markers = {};

  void _updateMarkers(List<GatheringModel> gatherings) {
    if (!mounted) return;
    setState(() {
      _markers = gatherings.map((g) => Marker(
        markerId: g.id.toString(),
        latLng: LatLng(g.latitude, g.longitude),
      )).toSet();
    });
  }

  void _onCameraIdle(LatLng center, int zoom) {
    final coords = ref.read(nearbyCoordsProvider);
    if (coords == null) return;
    final dist = (center.latitude - coords.lat).abs() + (center.longitude - coords.lng).abs();
    setState(() => _centerMoved = dist > 0.005);
    _mapCenter = center;
  }

  void _researchHere() {
    ref.read(nearbyCoordsProvider.notifier).set(_mapCenter.latitude, _mapCenter.longitude);
    setState(() => _centerMoved = false);
  }

  @override
  Widget build(BuildContext context) {
    final coords = ref.watch(nearbyCoordsProvider);
    final gatheringsAsync = coords != null
        ? ref.watch(nearbyGatheringsProvider)
        : const AsyncData<List<GatheringModel>>([]);

    ref.listen(nearbyGatheringsProvider, (_, next) {
      next.whenData(_updateMarkers);
    });

    if (coords != null && _mapCenter.latitude == 37.5665 && _mapCenter.longitude == 126.9780) {
      _mapCenter = LatLng(coords.lat, coords.lng);
    }

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
                      '내 주변 모임 📍\n지도로 간편하게 확인',
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

          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                const Text(
                  '모임 탐색',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                gatheringsAsync.when(
                  data: (list) => Text('${list.length}개', style: const TextStyle(color: Colors.grey)),
                  loading: () => const SizedBox.shrink(),
                  error: (_, s) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.search, size: 22, color: Colors.black54),
                  onPressed: () {},
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

          // Map area
          Expanded(
            child: coords == null
                ? const _LocationLoadingView()
                : Stack(
                    children: [
                      KakaoMap(
                        center: _mapCenter,
                        markers: _markers.toList(),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          controller.panTo(LatLng(coords.lat, coords.lng));
                        },
                        onCameraIdle: _onCameraIdle,
                        onMarkerTap: (markerId, latLng, zoom) {
                          final gatherings = ref.read(nearbyGatheringsProvider).value ?? [];
                          final gathering = gatherings.firstWhere(
                            (g) => g.id.toString() == markerId,
                            orElse: () => gatherings.first,
                          );
                          setState(() => _selectedGathering = gathering);
                        },
                      ),

                      // 이 위치로 재검색 button
                      if (_centerMoved)
                        Positioned(
                          top: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: _researchHere,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh, size: 16, color: Colors.black54),
                                    SizedBox(width: 6),
                                    Text(
                                      '이 위치로 재검색',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // 내 위치로 이동 버튼
                      Positioned(
                        right: 12,
                        bottom: _selectedGathering != null ? 220 : 16,
                        child: FloatingActionButton.small(
                          heroTag: 'myLocation',
                          backgroundColor: Colors.white,
                          onPressed: () {
                            _mapController?.panTo(LatLng(coords.lat, coords.lng));
                            setState(() { _centerMoved = false; _selectedGathering = null; });
                          },
                          child: const Icon(Icons.my_location, color: Color(0xFF03C75A)),
                        ),
                      ),

                      // Gathering popup card
                      if (_selectedGathering != null)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _GatheringPopupCard(
                            gathering: _selectedGathering!,
                            onClose: () => setState(() => _selectedGathering = null),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LocationLoadingView extends StatelessWidget {
  const _LocationLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF03C75A)),
          SizedBox(height: 16),
          Text(
            '내 위치를 확인하는 중...',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _GatheringPopupCard extends StatelessWidget {
  final GatheringModel gathering;
  final VoidCallback onClose;
  const _GatheringPopupCard({required this.gathering, required this.onClose});

  String _formatTime(DateTime dt) {
    final ampm = dt.hour < 12 ? '오전' : '오후';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}월 ${dt.day}일 $ampm $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  gathering.title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF5C6BC0)),
              const SizedBox(width: 8),
              Text(
                _formatTime(gathering.mealTime),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.place, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  gathering.restaurantName,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/gathering/${gathering.id}'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                '모임 상세보기 →',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
