import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/gathering_model.dart';

typedef NearbyCoords = ({double lat, double lng, double radius, String? keyword});

class NearbyCoordsNotifier extends Notifier<NearbyCoords?> {
  @override
  NearbyCoords? build() => null;

  void set(double lat, double lng, {double radius = 5.0}) {
    state = (lat: lat, lng: lng, radius: radius, keyword: null);
  }

  void setWithKeyword(double lat, double lng, String keyword, {double radius = 5.0}) {
    state = (lat: lat, lng: lng, radius: radius, keyword: keyword.isEmpty ? null : keyword);
  }
}

final nearbyCoordsProvider =
    NotifierProvider<NearbyCoordsNotifier, NearbyCoords?>(NearbyCoordsNotifier.new);

final nearbyGatheringsProvider = FutureProvider.autoDispose<List<GatheringModel>>((ref) async {
  final coords = ref.watch(nearbyCoordsProvider);
  if (coords == null) return [];
  debugPrint('[NEARBY] fetching lat=${coords.lat}, lng=${coords.lng}, keyword=${coords.keyword}');
  final client = ref.read(apiClientProvider);
  final queryParams = <String, dynamic>{
    'latitude': coords.lat,
    'longitude': coords.lng,
    'radius': coords.radius,
  };
  if (coords.keyword != null && coords.keyword!.isNotEmpty) {
    queryParams['keyword'] = coords.keyword;
  }
  final res = await client.dio.get('/api/gatherings/nearby', queryParameters: queryParams);
  debugPrint('[NEARBY] status=${res.statusCode}, data=${res.data}');
  final list = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
  debugPrint('[NEARBY] parsed ${list.length} gatherings');
  return list
      .map((e) => GatheringModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

final selectedGatheringProvider =
    NotifierProvider<SelectedGatheringNotifier, GatheringModel?>(
  SelectedGatheringNotifier.new,
);

class SelectedGatheringNotifier extends Notifier<GatheringModel?> {
  @override
  GatheringModel? build() => null;

  void select(GatheringModel? gathering) => state = gathering;
}
