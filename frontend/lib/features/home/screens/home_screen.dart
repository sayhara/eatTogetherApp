import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../models/gathering_model.dart';
import '../providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  KakaoMapController? _mapController;
  Position? _currentPosition;
  bool _locationDone = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  void _setLocationDone([Position? pos]) {
    if (!mounted) return;
    setState(() {
      _currentPosition = pos;
      _locationDone = true;
    });
    if (pos != null) {
      ref.read(nearbyCoordsProvider.notifier).set(pos.latitude, pos.longitude);
    }
  }

  Future<void> _initLocation() async {
    debugPrint('[LOC] serviceEnabled check');
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('[LOC] serviceEnabled=$serviceEnabled');
    if (!serviceEnabled) { _setLocationDone(); return; }
    if (!mounted) return;

    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('[LOC] permission=$permission');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      debugPrint('[LOC] after request permission=$permission');
      if (permission == LocationPermission.denied) { _setLocationDone(); return; }
    }
    if (!mounted) return;
    if (permission == LocationPermission.deniedForever) { _setLocationDone(); return; }

    debugPrint('[LOC] getLastKnownPosition start');
    Position? position = await Geolocator.getLastKnownPosition();
    debugPrint('[LOC] lastKnown=${position?.latitude}');
    if (position == null) {
      debugPrint('[LOC] getCurrentPosition start (10s timeout)');
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
        debugPrint('[LOC] getCurrentPosition success: ${position.latitude}');
      } catch (e) {
        debugPrint('[LOC] getCurrentPosition error: $e');
        _setLocationDone();
        return;
      }
    }
    debugPrint('[LOC] setLocationDone with position');
    _setLocationDone(position);

    await ref.read(authProvider.notifier).updateLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
  }

  void _updateMarkers(List<GatheringModel> gatherings) {
    setState(() {
      _markers = gatherings
          .map((g) => Marker(
                markerId: g.id.toString(),
                latLng: LatLng(g.latitude, g.longitude),
                markerImageSrc:
                    'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/markerStar.png',
              ))
          .toSet();
    });

    for (final g in gatherings) {
      _mapController?.addMarker(
        markers: [
          Marker(
            markerId: g.id.toString(),
            latLng: LatLng(g.latitude, g.longitude),
          )
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final coords = ref.watch(nearbyCoordsProvider);

    ref.listen(nearbyGatheringsProvider, (_, next) {
      next.whenData(_updateMarkers);
    });

    final gatheringsAsync = coords != null
        ? ref.watch(nearbyGatheringsProvider)
        : _locationDone
            ? const AsyncData<List<GatheringModel>>([])
            : const AsyncValue<List<GatheringModel>>.loading();

    final defaultLat = _currentPosition?.latitude ?? 37.5665;
    final defaultLng = _currentPosition?.longitude ?? 126.9780;

    return Scaffold(
      appBar: AppBar(
        title: const Text('잇투게더', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF03C75A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/mypage'),
          ),
        ],
      ),
      body: Stack(
        children: [
          KakaoMap(
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                controller.panTo(LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ));
              }
            },
            center: LatLng(defaultLat, defaultLng),
            markers: _markers.toList(),
            onMarkerTap: (markerId, latLng, zoomLevel) {
              final gathering = gatheringsAsync.value?.firstWhere(
                (g) => g.id.toString() == markerId,
                orElse: () => gatheringsAsync.value!.first,
              );
              if (gathering != null) {
                ref.read(selectedGatheringProvider.notifier).select(gathering);
              }
            },
          ),
          _GatheringBottomSheet(
            gatheringsAsync: gatheringsAsync,
            userId: user?.id,
            onRefresh: () async {
              ref.invalidate(nearbyGatheringsProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/gathering/create');
          debugPrint('[HOME] returned from create, invalidating nearby');
          ref.invalidate(nearbyGatheringsProvider);
        },
        backgroundColor: const Color(0xFF03C75A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('모임 만들기', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _GatheringBottomSheet extends ConsumerWidget {
  final AsyncValue<List<GatheringModel>> gatheringsAsync;
  final int? userId;
  final Future<void> Function() onRefresh;

  const _GatheringBottomSheet({
    required this.gatheringsAsync,
    required this.userId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedGatheringProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.1,
      maxChildSize: 0.75,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      '근처 모임',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    gatheringsAsync.when(
                      data: (list) => Text(
                        '${list.length}개',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (e, st) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: gatheringsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('오류: $e')),
                  data: (gatherings) => RefreshIndicator(
                    onRefresh: onRefresh,
                    color: const Color(0xFF03C75A),
                    child: gatherings.isEmpty
                        ? ListView(
                            controller: scrollController,
                            children: const [
                              SizedBox(height: 60),
                              Center(
                                child: Text(
                                  '근처에 모임이 없어요\n먼저 모임을 만들어보세요!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: gatherings.length,
                            separatorBuilder: (context, i) => const Divider(height: 1),
                            itemBuilder: (context, i) => _GatheringTile(
                              gathering: gatherings[i],
                              isSelected: selected?.id == gatherings[i].id,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GatheringTile extends StatelessWidget {
  final GatheringModel gathering;
  final bool isSelected;

  const _GatheringTile({
    required this.gathering,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: const Color(0xFFE8FFF2),
      onTap: () => context.push('/gathering/${gathering.id}'),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF03C75A),
        child: Text(
          gathering.category?.substring(0, 1) ?? '식',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        gathering.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${gathering.restaurantName} · ${gathering.currentParticipants}/${gathering.maxParticipants}명',
        style: const TextStyle(fontSize: 13),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: gathering.isOpen && !gathering.isFull
              ? const Color(0xFF03C75A)
              : Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          gathering.isOpen && !gathering.isFull ? '참여 가능' : '마감',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}
