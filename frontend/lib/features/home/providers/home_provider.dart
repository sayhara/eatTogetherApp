import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/gathering_model.dart';

typedef NearbyCoords = ({double lat, double lng, double radius});

class NearbyCoordsNotifier extends Notifier<NearbyCoords?> {
  @override
  NearbyCoords? build() => null;

  void set(double lat, double lng, {double radius = 2.0}) {
    state = (lat: lat, lng: lng, radius: radius);
  }
}

final nearbyCoordsProvider =
    NotifierProvider<NearbyCoordsNotifier, NearbyCoords?>(NearbyCoordsNotifier.new);

final nearbyGatheringsProvider = FutureProvider.autoDispose<List<GatheringModel>>((ref) async {
  final coords = ref.watch(nearbyCoordsProvider);
  if (coords == null) return [];
  debugPrint('[NEARBY] fetching lat=${coords.lat}, lng=${coords.lng}');
  final client = ref.read(apiClientProvider);
  final res = await client.dio.get('/api/gatherings/nearby', queryParameters: {
    'latitude': coords.lat,
    'longitude': coords.lng,
    'radius': coords.radius,
  });
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
