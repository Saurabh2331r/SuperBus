
// ------------------------------------------------------------------------
// ride button logic updated orign and dest cant be same

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'nearest_stops.dart';
import 'everyday.dart';
import 'ride_map.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> busStops = [];
  String? selectedOrigin;
  String? selectedDestination;

  @override
  void initState() {
    super.initState();
    loadBusStops();
  }

  Future<void> loadBusStops() async {
    final String response = await rootBundle.loadString(
      'assets/home_bus_stops.json',
    );
    final data = json.decode(response) as List<dynamic>;

    setState(() {
      busStops = data.map((e) => e['name'].toString()).toList();
    });
    // final data = json.decode(response) as Map<String, dynamic>;

    // setState(() {
    //   busStops = data.keys.toList(); // just take the stop names
    // });
  }

  void _startRide() {
    if (selectedOrigin == selectedDestination) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Origin and Destination cannot be the same!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideMapPage(
          origin: selectedOrigin!,
          destination: selectedDestination!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bus Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NearestStopsPage()),
                );
              },
              child: const Text("Nearest Bus Stops"),
            ),
            // const SizedBox(height: 20),

            const SizedBox(height: 10), // spacing between buttons

            ElevatedButton(
              onPressed: () {
                // Navigate to Everyday Ride page (replace with your page)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EverydayRidePage()),
                );
              },
              child: const Text("Everyday Ride"),
            ),
            const SizedBox(height: 20),

            // Origin Dropdown
            const Text("Origin", style: TextStyle(fontSize: 18)),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedOrigin,
              hint: const Text("Select Origin Stop"),
              items: busStops.map((stop) {
                return DropdownMenuItem(value: stop, child: Text(stop));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedOrigin = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Destination Dropdown
            const Text("Destination", style: TextStyle(fontSize: 18)),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedDestination,
              hint: const Text("Select Destination Stop"),
              items: busStops.map((stop) {
                return DropdownMenuItem(value: stop, child: Text(stop));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDestination = value;
                });
              },
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: (selectedOrigin != null && selectedDestination != null)
                  ? _startRide
                  : null,
              child: const Text("Ride"),
            ),

            // Container(
            //   height: 200,
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(12),
            //     border: Border.all(color: Colors.grey),
            //   ),
            //   clipBehavior: Clip.hardEdge,
            //   child: Image.asset("assets/route_map.png", fit: BoxFit.cover),
            // ),
            GestureDetector(
              onTap: () {
                // Optional: action when image is tapped
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: InteractiveViewer(
                      panEnabled: true, // Allow panning
                      scaleEnabled: true, // Allow zooming
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.asset("assets/route_map.png", fit: BoxFit.contain),
                    ),
                  ),
                );
              },
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.asset("assets/route_map.png", fit: BoxFit.cover),
              ),
            )

          ],
        ),
      ),
    );
  }
}
