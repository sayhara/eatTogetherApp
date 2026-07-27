import 'package:geolocator/geolocator.dart';

Future<LocationPermission>? _pendingRequest;

/// Checks and, if needed, requests location permission.
///
/// Multiple widgets (list/explore tabs) can call this concurrently on
/// startup since they're all mounted via IndexedStack; Android only allows
/// one native permission request in flight at a time, so concurrent callers
/// share the same pending request instead of each firing their own.
Future<LocationPermission> ensureLocationPermission() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    _pendingRequest ??=
        Geolocator.requestPermission().whenComplete(() => _pendingRequest = null);
    permission = await _pendingRequest!;
  }
  return permission;
}
