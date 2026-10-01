


// ------------------------------------------------------------------------
// nearesst bus stops show only 3


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;

class NearestStopsPage extends StatefulWidget {
  const NearestStopsPage({super.key});

  @override
  State<NearestStopsPage> createState() => _RiderMapPageState();
}

class _RiderMapPageState extends State<NearestStopsPage> {
  LatLng? _currentLocation;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentLocation = LatLng(pos.latitude, pos.longitude);
    });

    _loadNearestBusStops(pos.latitude, pos.longitude);
  }

  Future<void> _loadNearestBusStops(double userLat, double userLng) async {
    final data = await rootBundle.loadString("assets/home_bus_stops.json");
    final List<dynamic> stops = json.decode(data);

    // Calculate distance for each stop
    List<Map<String, dynamic>> stopsWithDistance = stops.map((stop) {
      double distance = Geolocator.distanceBetween(
        userLat,
        userLng,
        stop['lat'],
        stop['lng'],
      );
      return {
        "name": stop['name'],
        "lat": stop['lat'],
        "lng": stop['lng'],
        "distance": distance,
      };
    }).toList();

    // Sort by distance and take nearest 3
    stopsWithDistance.sort((a, b) => a['distance'].compareTo(b['distance']));
    var nearestStops = stopsWithDistance.take(3);

    // Convert to markers
    Set<Marker> markers = nearestStops.map((stop) {
      return Marker(
        markerId: MarkerId(stop['name']),
        position: LatLng(stop['lat'], stop['lng']),
        infoWindow: InfoWindow(
          title: stop['name'],
          snippet: "${(stop['distance'] / 1000).toStringAsFixed(2)} km away",
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    }).toSet();

    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Nearest Bus Stops")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation!,
          zoom: 14,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
      ),
    );
  }
}
