import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import '../models/gathering_model.dart';
import '../providers/home_provider.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  NaverMapController? _mapController;
  GatheringModel? _selectedGathering;
  NLatLng _mapCenter = const NLatLng(37.5665, 126.9780);
  bool _centerMoved = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      ref.read(nearbyCoordsProvider.notifier).set(pos.latitude, pos.longitude, radius: 5.0);
      setState(() => _mapCenter = NLatLng(pos.latitude, pos.longitude));
      _mapController?.updateCamera(
        NCameraUpdate.scrollAndZoomTo(target: NLatLng(pos.latitude, pos.longitude)),
      );
    } catch (_) {}
  }

  Future<void> _resetToMyLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      ref.read(nearbyCoordsProvider.notifier).set(pos.latitude, pos.longitude, radius: 5.0);
      setState(() {
        _mapCenter = NLatLng(pos.latitude, pos.longitude);
        _centerMoved = false;
        _selectedGathering = null;
      });
      _mapController?.updateCamera(
        NCameraUpdate.scrollAndZoomTo(target: NLatLng(pos.latitude, pos.longitude)),
      );
    } catch (_) {}
  }

  Future<void> _updateMarkers(List<GatheringModel> gatherings) async {
    if (!mounted || _mapController == null) return;
    await _mapController!.clearOverlays();
    final newMarkers = gatherings.map((g) {
      final marker = NMarker(
        id: g.id.toString(),
        position: NLatLng(g.latitude, g.longitude),
      );
      marker.setOnTapListener((m) {
        setState(() => _selectedGathering = g);
      });
      return marker;
    }).toList();
    await _mapController!.addOverlayAll(newMarkers.toSet());
  }

  Future<void> _onCameraIdle() async {
    if (_mapController == null) return;
    final position = await _mapController!.getCameraPosition();
    final coords = ref.read(nearbyCoordsProvider);
    if (coords == null) return;
    final dist = (position.target.latitude - coords.lat).abs() +
        (position.target.longitude - coords.lng).abs();
    if (mounted) {
      setState(() {
        _mapCenter = position.target;
        _centerMoved = dist > 0.005;
      });
    }
  }

  void _researchHere() {
    ref.read(nearbyCoordsProvider.notifier).set(_mapCenter.latitude, _mapCenter.longitude, radius: 5.0);
    setState(() => _centerMoved = false);
  }

  void _showSearchModal() {
    final coords = ref.read(nearbyCoordsProvider);
    final controller = TextEditingController(text: coords?.keyword ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('모임 검색', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('식당명 또는 모임 제목으로 진행중인 모임을 찾아보세요',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '예: 삼겹살, 파스타, 혼밥',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF03C75A)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF03C75A), width: 2),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => _doSearch(value, ctx),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _doSearch(controller.text, ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF03C75A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('검색', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _doSearch(String value, BuildContext sheetContext) {
    Navigator.of(sheetContext).pop();
    final coords = ref.read(nearbyCoordsProvider);
    if (coords == null) return;
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      ref.read(nearbyCoordsProvider.notifier).set(coords.lat, coords.lng, radius: coords.radius);
    } else {
      ref.read(nearbyCoordsProvider.notifier).setWithKeyword(coords.lat, coords.lng, trimmed, radius: coords.radius);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final coords = ref.read(nearbyCoordsProvider);
    if (coords != null && _mapCenter.latitude == 37.5665 && _mapCenter.longitude == 126.9780) {
      _mapCenter = NLatLng(coords.lat, coords.lng);
    }
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
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
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                const Text(
                  '모임 탐색',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (coords?.keyword != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF03C75A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          coords!.keyword!,
                          style: const TextStyle(
                              color: Color(0xFF03C75A), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => ref.read(nearbyCoordsProvider.notifier)
                              .set(coords.lat, coords.lng, radius: coords.radius),
                          child: const Icon(Icons.close, size: 14, color: Color(0xFF03C75A)),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                gatheringsAsync.when(
                  data: (list) => Text('${list.length}개', style: const TextStyle(color: Colors.grey)),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.search, size: 22, color: Colors.black54),
                  onPressed: _showSearchModal,
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

          Expanded(
            child: Stack(
              children: [
                NaverMap(
                  options: NaverMapViewOptions(
                    initialCameraPosition: NCameraPosition(
                      target: _mapCenter,
                      zoom: 14,
                    ),
                    mapType: NMapType.basic,
                    activeLayerGroups: const [NLayerGroup.building, NLayerGroup.transit],
                    locationButtonEnable: false,
                  ),
                  onMapReady: (controller) async {
                    _mapController = controller;
                    final coords = ref.read(nearbyCoordsProvider);
                    if (coords != null) {
                      await controller.updateCamera(
                        NCameraUpdate.scrollAndZoomTo(
                          target: NLatLng(coords.lat, coords.lng),
                        ),
                      );
                    }
                    final gatherings = ref.read(nearbyGatheringsProvider).value ?? [];
                    if (gatherings.isNotEmpty) _updateMarkers(gatherings);
                  },
                  onCameraIdle: () => _onCameraIdle(),
                ),

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

                Positioned(
                  right: 12,
                  bottom: _selectedGathering != null ? 220 : 76,
                  child: FloatingActionButton.small(
                    heroTag: 'myLocation',
                    backgroundColor: Colors.white,
                    onPressed: () {
                      if (coords != null) {
                        _mapController?.updateCamera(
                          NCameraUpdate.scrollAndZoomTo(
                            target: NLatLng(coords.lat, coords.lng),
                          ),
                        );
                      }
                      setState(() {
                        _centerMoved = false;
                        _selectedGathering = null;
                      });
                    },
                    child: const Icon(Icons.my_location, color: Color(0xFF03C75A)),
                  ),
                ),

                if (_selectedGathering == null)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _resetToMyLocation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF03C75A),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF03C75A).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.my_location, size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                '현재 위치로 재설정',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                if (_selectedGathering != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _GatheringBottomCard(
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

class _GatheringBottomCard extends StatelessWidget {
  final GatheringModel gathering;
  final VoidCallback onClose;

  const _GatheringBottomCard({required this.gathering, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  gathering.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            gathering.restaurantName,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.people, size: 16, color: Color(0xFF03C75A)),
              const SizedBox(width: 4),
              Text(
                '${gathering.currentParticipants}/${gathering.maxParticipants}명',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${gathering.mealTime.hour.toString().padLeft(2, '0')}:${gathering.mealTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
