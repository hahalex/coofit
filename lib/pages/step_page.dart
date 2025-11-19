// lib/pages/step_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';
import '../services/routing_service.dart';
import '../services/weather_service.dart';
import 'package:http/http.dart' as http;

class StepPage extends StatefulWidget {
  const StepPage({super.key});

  @override
  State<StepPage> createState() => _StepPageState();
}

class _StepPageState extends State<StepPage> {
  final DBService _db = DBService();

  bool _loading = true;
  int _todaySteps = 0;
  int _goalSteps = 5000;

  StreamSubscription<StepCount>? _stepSub;
  int? _lastSensorValue;
  bool _hasPermission = false;

  // map & routing state
  LatLng? _mapCenter;
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<LatLng> _routeCoords = [];
  double? _routeDistanceMeters;

  // weather state (for current location)
  double? _currentTempC;
  String? _currentWeatherIcon; // 'sun','cloud','rain','snow'

  String get _today {
    final now = DateTime.now();
    return now.toIso8601String().split('T')[0];
  }

  @override
  void initState() {
    super.initState();
    // init step data and permissions after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initPermissionAndLoad();
      await _initLocationAndWeather();
    });
  }

  // --- STEP logic (unchanged functionality) ---
  Future<void> _initPermissionAndLoad() async {
    await _loadProfileAndToday();
    await _requestStepPermission();
    if (_hasPermission) _startListening();
  }

  Future<void> _loadProfileAndToday() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) {
      setState(() {
        _loading = false;
        _todaySteps = 0;
      });
      return;
    }

    final profile = await _db.getProfileByUserId(user.id!);
    if (profile != null) _goalSteps = profile['target_steps'] ?? 5000;

    final metrics = await _db.getDailyMetrics(user.id!, _today);
    if (metrics != null) {
      _todaySteps = metrics['steps'] ?? 0;
    } else {
      await _db.insertDailyMetrics(
        user.id!,
        _today,
        calories: 0,
        waterGlasses: 0,
        steps: 0,
      );
      _todaySteps = 0;
    }

    if (mounted)
      setState(() {
        _loading = false;
      });
  }

  Future<void> _requestStepPermission() async {
    // activity recognition permission (Android)
    PermissionStatus status;
    try {
      status = await Permission.activityRecognition.status;
      if (status != PermissionStatus.granted) {
        status = await Permission.activityRecognition.request();
      }
    } catch (e) {
      status = PermissionStatus.denied;
    }
    setState(() => _hasPermission = status == PermissionStatus.granted);
  }

  void _startListening() {
    _stepSub?.cancel();
    _stepSub = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (e) {},
      cancelOnError: true,
    );
  }

  void _onStepCount(StepCount event) async {
    final sensorValue = event.steps;
    if (_lastSensorValue == null) {
      _lastSensorValue = sensorValue;
      return;
    }

    int delta = sensorValue - _lastSensorValue!;
    if (delta < 0) delta = sensorValue;

    if (delta > 0) await _addSteps(delta);

    _lastSensorValue = sensorValue;
  }

  Future<void> _addSteps(int delta) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;

    final metrics = await _db.getDailyMetrics(user.id!, _today);
    if (metrics == null) {
      await _db.insertDailyMetrics(
        user.id!,
        _today,
        calories: 0,
        waterGlasses: 0,
        steps: delta,
      );
    } else {
      final current = metrics['steps'] ?? 0;
      await _db.upsertDailyMetrics(user.id!, _today, steps: current + delta);
    }

    final updated = await _db.getDailyMetrics(user.id!, _today);
    if (mounted)
      setState(() => _todaySteps = updated?['steps'] ?? _todaySteps + delta);
  }

  Future<void> _manualAddStep() async {
    await _modifySteps(1);
  }

  Future<void> _modifySteps(int delta) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;
    final metrics = await _db.getDailyMetrics(user.id!, _today);
    if (metrics == null) {
      await _db.insertDailyMetrics(
        user.id!,
        _today,
        calories: 0,
        waterGlasses: 0,
        steps: delta,
      );
    } else {
      final current = metrics['steps'] ?? 0;
      final newVal = (current + delta) < 0 ? 0 : (current + delta);
      await _db.upsertDailyMetrics(user.id!, _today, steps: newVal);
    }
    final updated = await _db.getDailyMetrics(user.id!, _today);
    if (mounted) setState(() => _todaySteps = updated?['steps'] ?? 0);
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    super.dispose();
  }

  // --- LOCATION + MAP + WEATHER initialization ---
  Future<void> _initLocationAndWeather() async {
    // Request location permission and set initial map center
    LocationPermission perm;
    try {
      perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
    } catch (e) {
      perm = LocationPermission.denied;
    }

    if (perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        _mapCenter = LatLng(pos.latitude, pos.longitude);
        // fetch weather
        final weather = await WeatherService.fetchCurrentWeather(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
        if (weather != null) {
          _currentTempC = weather['temp'] as double;
          _currentWeatherIcon = WeatherService.codeToIcon(
            weather['weathercode'] as int,
          );
        }

        // try to move map controller to user location (may throw if controller not ready)
        try {
          if (_mapCenter != null) {
            _mapController.move(_mapCenter!, 13.0);
          }
        } catch (_) {
          // controller might not be ready yet — safe to ignore
        }
      } catch (e) {
        // ignore
      }
    } else {
      // fallback center
      _mapCenter = LatLng(55.751244, 37.618423); // Moscow center as fallback
      try {
        if (_mapCenter != null) _mapController.move(_mapCenter!, 13.0);
      } catch (_) {}
    }

    if (mounted) setState(() {});
  }

  // --- HELPERS for map bounds/center ---
  LatLng _centerFromPoints(List<LatLng> points) {
    if (points.isEmpty) return _mapCenter ?? LatLng(55.751244, 37.618423);
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
    }
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    return LatLng(centerLat, centerLng);
  }

  // --- MAP interactions ---
  void _onMapTap(TapPosition tapPos, LatLng latlng) async {
    // update stored center to tapped point
    _mapCenter = latlng;

    // add marker; keep max 2 markers
    if (_markers.length >= 2) {
      _markers.clear();
      _routeCoords.clear();
      _routeDistanceMeters = null;
    }
    final marker = Marker(
      point: latlng,
      width: 36,
      height: 36,
      // new API: use `child` instead of `builder`
      child: const Icon(Icons.location_on, size: 36, color: Colors.red),
    );
    setState(() {
      _markers.add(marker);
    });

    // if two markers present -> compute route
    if (_markers.length == 2) {
      final a = _markers[0].point;
      final b = _markers[1].point;
      final res = await RoutingService.getRoute(a, b);
      if (res != null) {
        setState(() {
          _routeCoords = (res['coords'] as List<LatLng>);
          _routeDistanceMeters = (res['distance'] as double);
        });

        // try to fit map to route: compute bounds center and move camera there
        try {
          final center = _centerFromPoints(_routeCoords);
          // set a reasonable zoom (you can adjust or compute zoom to fit bounds more precisely)
          const double zoom = 13.0;
          _mapCenter = center;
          // Use move() to relocate map; this avoids calling non-existent fitBounds methods
          _mapController.move(center, zoom);
        } catch (e) {
          // ignore map fit errors
        }
      } else {
        // route failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось построить маршрут')),
        );
      }
    }
  }

  // --- WEATHER refresh (optional) ---
  Future<void> _refreshWeatherFor(LatLng pos) async {
    final weather = await WeatherService.fetchCurrentWeather(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
    if (weather != null && mounted) {
      setState(() {
        _currentTempC = weather['temp'] as double;
        _currentWeatherIcon = WeatherService.codeToIcon(
          weather['weathercode'] as int,
        );
      });
    }
  }

  Widget _buildWeatherCard() {
    final temp = _currentTempC;
    final icon = _currentWeatherIcon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (icon != null)
            Icon(
              icon == 'sun'
                  ? Icons.wb_sunny
                  : icon == 'rain'
                  ? Icons
                        .grain // rain icon substitute
                  : icon == 'snow'
                  ? Icons.ac_unit
                  : Icons.cloud,
              color: const Color(0xFFFFC700),
            ),
          const SizedBox(width: 8),
          Text(
            temp != null ? '${temp.toStringAsFixed(1)}°C' : '--',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    // if map center unknown, show placeholder
    final center = _mapCenter ?? LatLng(55.751244, 37.618423);
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        // new API uses initialCenter / initialZoom
        initialCenter: center,
        initialZoom: 13.0,
        onTap: _onMapTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.coolfit',
        ),
        if (_routeCoords.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routeCoords,
                strokeWidth: 4.0,
                color: const Color(0xFF00FFCC),
              ),
            ],
          ),
        MarkerLayer(markers: _markers),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build UI:
    // - top: шагомер (меньше места — flex: 3)
    // - bottom: карта в окошке (flex: 7)
    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Steps menu',
          style: TextStyle(color: Color(0xFFDB0058), fontSize: 28),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // TOP: centered counter — уменьшил занимаемое место
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Today's Steps",
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFFFFC700),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_todaySteps',
                          style: const TextStyle(
                            fontFamily: 'AllertaStencil',
                            fontSize: 56,
                            color: Color(0xFFFFC700),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Goal: $_goalSteps steps',
                          style: TextStyle(
                            fontSize: 18,
                            color: const Color(0xFFFFC700).withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // BOTTOM: карта в прямоугольном окне с отступами и скруглениями
                Expanded(
                  flex: 7,
                  child: Stack(
                    children: [
                      // padding + rounded rectangle so map doesn't touch screen edges
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 12.0,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(14),
                                // <-- added outer border
                                border: Border.all(
                                  color: const Color(0xFF009999),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _buildMap(),
                            ),
                          ),
                        ),
                      ),

                      // weather card: positioned relative to the overall bottom area.
                      // we offset it a bit inward so it sits above the rounded corners.
                      Positioned(
                        top: 20,
                        left: 24,
                        child: GestureDetector(
                          onTap: () async {
                            final center =
                                _mapCenter ?? LatLng(55.751244, 37.618423);
                            await _refreshWeatherFor(center);
                          },
                          child: _buildWeatherCard(),
                        ),
                      ),

                      // route distance centered at bottom of map area
                      if (_routeDistanceMeters != null)
                        Positioned(
                          bottom: 28,
                          left: 24,
                          right: 24,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Distance: ${(_routeDistanceMeters! / 1000).toStringAsFixed(2)} km',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),

                      // small hint overlay for map tap
                      Positioned(
                        top: 20,
                        right: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Tap to place markers',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
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
