import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;

  const LocationResult({
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
  });
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  String? _searchError;

  NaverMapController? _mapController;
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  double _lat = 37.5665;
  double _lng = 126.9780;

  // 행정안전부 도로명주소 API 키 (juso.go.kr 에서 발급)
  static const _jusoKey = 'devU01TX0FVVEgyMDE3MDcxOTE0MDkxMTExNDYzMTI=';
  static const _orange = Color(0xFFF5A623);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentPosition();
  }

  Future<void> _loadCurrentPosition() async {
    try {
      final pos = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 5),
            ),
          );
      if (mounted) setState(() { _lat = pos.latitude; _lng = pos.longitude; });
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final kw = _searchCtrl.text.trim();
    if (kw.isEmpty) return;
    setState(() { _searching = true; _searchError = null; _results = []; });
    try {
      final res = await Dio().get(
        'https://business.juso.go.kr/addrlink/addrLinkApi.do',
        queryParameters: {
          'currentPage': 1,
          'countPerPage': 20,
          'keyword': kw,
          'confmKey': _jusoKey,
          'resultType': 'json',
        },
      );
      final raw = res.data['results']['juso'];
      setState(() {
        _results = (raw as List?)?.cast<Map<String, dynamic>>() ?? [];
      });
    } catch (_) {
      setState(() { _searchError = '검색 중 오류가 발생했습니다'; });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _pick(String name, String address, [double? lat, double? lng]) {
    Navigator.of(context).pop(
      LocationResult(name: name, address: address, latitude: lat, longitude: lng),
    );
  }

  void _confirmDirect() {
    final name = _nameCtrl.text.trim();
    final addr = _addrCtrl.text.trim();
    if (name.isEmpty || addr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장소명과 주소를 입력해주세요')),
      );
      return;
    }
    _pick(name, addr, _lat, _lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('장소 선택'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _orange,
          tabs: const [
            Tab(text: '주변 검색'),
            Tab(text: '직접 입력'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSearchTab(), _buildDirectTab()],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '장소명을 입력하세요',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onSubmitted: (_) => _doSearch(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _searching ? null : _doSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('검색'),
          ),
        ]),
      ),
      if (_searching)
        const Expanded(child: Center(child: CircularProgressIndicator(color: _orange)))
      else if (_searchError != null)
        Expanded(
          child: Center(
            child: Text(_searchError!, style: const TextStyle(color: Colors.red)),
          ),
        )
      else
        Expanded(
          child: ListView.separated(
            itemCount: _results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final j = _results[i];
              final bdNm = (j['bdNm'] as String?)?.trim() ?? '';
              final road = (j['roadAddr'] as String?) ?? '';
              final title = bdNm.isNotEmpty ? bdNm : road;
              final sub = bdNm.isNotEmpty ? road : '';
              return ListTile(
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: sub.isNotEmpty
                    ? Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))
                    : null,
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _pick(title, road),
              );
            },
          ),
        ),
    ]);
  }

  Widget _buildDirectTab() {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            '지도를 움직여서 장소를 선택해주세요.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        SizedBox(
          height: 240,
          child: Stack(alignment: Alignment.center, children: [
            NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: NLatLng(_lat, _lng),
                  zoom: 16,
                ),
              ),
              onMapReady: (ctrl) => _mapController = ctrl,
              onCameraIdle: () async {
                if (_mapController == null) return;
                final pos = await _mapController!.getCameraPosition();
                if (!mounted) return;
                setState(() {
                  _lat = pos.target.latitude;
                  _lng = pos.target.longitude;
                });
              },
            ),
            const IgnorePointer(
              child: Icon(Icons.location_pin, size: 44, color: Colors.red),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('장소명 *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              maxLength: 30,
              decoration: InputDecoration(
                hintText: '장소명을 입력해주세요 (최대 30자)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            const Text('주소 *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _addrCtrl,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: '주소를 입력해주세요 (최대 100자)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _confirmDirect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('선택 완료', style: TextStyle(fontSize: 16)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
