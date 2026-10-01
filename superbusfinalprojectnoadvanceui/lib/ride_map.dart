// // ------------------------------------------------------------------------
// // interchnage icon corrected

// import 'dart:convert';
// import 'dart:collection';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class RideMapPage extends StatefulWidget {
//   final String origin;
//   final String destination;

//   const RideMapPage({
//     super.key,
//     required this.origin,
//     required this.destination,
//   });

//   @override
//   State<RideMapPage> createState() => _RideMapPageState();
// }

// class _RideMapPageState extends State<RideMapPage> {
//   Map<String, List<String>> routes = {}; // route name -> stops
//   Map<String, List<String>> adjacency = {}; // stop -> neighboring stops
//   Map<String, Map<String, List<String>>> edgeRoutes = {}; // stop1 -> stop2 -> routes
//   Map<String, LatLng> stopsMap = {}; // stop name -> LatLng

//   List<Map<String, dynamic>> routeSegments = [];
//   String errorText = '';

//   late GoogleMapController _mapController;
//   final Set<Marker> _markers = {};

//   final Map<String, Color> routeColors = {}; // color for each route

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//   try {
//     // Load stops with lat/lng
//     final stopsList =
//         json.decode(await rootBundle.loadString('assets/home_bus_stops.json'))
//             as List<dynamic>;

//     for (var stop in stopsList) {
//       final name = stop['name'];
//       final lat = stop['lat'];
//       final lng = stop['lng'];
//       if (name == null || lat == null || lng == null) continue;
//       stopsMap[name.toString()] = LatLng(lat.toDouble(), lng.toDouble());
//     }

//     // Load routes.json
//     final routesData =
//         json.decode(await rootBundle.loadString('assets/routes.json'))
//             as List<dynamic>;

//     final colors = [
//       Colors.pink,
//       Colors.blue,
//       Colors.green,
//       Colors.orange,
//       Colors.purple,
//       Colors.teal,
//       Colors.red,
//       Colors.brown,
//       Colors.indigo,
//       Colors.cyan,
//     ];
//     int colorIndex = 0;

//     for (var r in routesData) {
//       final name = r['route'];
//       final stopsList = r['stops'];
//       if (name == null || stopsList == null) continue;

//       final stops = <String>[];
//       for (var s in stopsList) {
//         if (s != null) stops.add(s.toString());
//       }

//       routes[name.toString()] = stops;
//       routeColors[name.toString()] = colors[colorIndex % colors.length];
//       colorIndex++;
//     }

//     _buildGraph();
//     _computeRoute(widget.origin, widget.destination);
//     _addMarkers();
//   } catch (e) {
//     setState(() {
//       errorText = 'Error loading data: $e';
//     });
//   }
// }

//   void _addMarkers() {
//     _markers.clear();

//     // Origin marker
//     if (stopsMap.containsKey(widget.origin)) {
//       _markers.add(Marker(
//         markerId: const MarkerId('origin'),
//         position: stopsMap[widget.origin]!,
//         infoWindow: InfoWindow(title: widget.origin),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//       ));
//     }

//     // Destination marker
//     if (stopsMap.containsKey(widget.destination)) {
//       _markers.add(Marker(
//         markerId: const MarkerId('destination'),
//         position: stopsMap[widget.destination]!,
//         infoWindow: InfoWindow(title: widget.destination),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       ));
//     }

//     // Intermediate stops
//     for (var segment in routeSegments) {
//       final stops = segment['stops'] as List<String>;
//       for (var stop in stops) {
//         if (stop != widget.origin && stop != widget.destination) {
//           final pos = stopsMap[stop];
//           if (pos != null) {
//             _markers.add(Marker(
//               markerId: MarkerId(stop),
//               position: pos,
//               infoWindow: InfoWindow(title: stop),
//               icon: BitmapDescriptor.defaultMarkerWithHue(
//                 BitmapDescriptor.hueAzure, // blue markers
//               ),
//             ));
//           }
//         }
//       }
//     }

//     setState(() {});
//   }

//   void _buildGraph() {
//     adjacency = {};
//     edgeRoutes = {};

//     for (var r in routes.entries) {
//       final routeName = r.key;
//       final stops = r.value;
//       for (int i = 0; i < stops.length - 1; i++) {
//         final a = stops[i];
//         final b = stops[i + 1];

//         adjacency[a] = (adjacency[a] ?? []);
//         adjacency[a]!.add(b);

//         adjacency[b] = (adjacency[b] ?? []);
//         adjacency[b]!.add(a);

//         edgeRoutes[a] = (edgeRoutes[a] ?? {});
//         edgeRoutes[a]![b] = (edgeRoutes[a]![b] ?? []);
//         edgeRoutes[a]![b]!.add(routeName);

//         edgeRoutes[b] = (edgeRoutes[b] ?? {});
//         edgeRoutes[b]![a] = (edgeRoutes[b]![a] ?? []);
//         edgeRoutes[b]![a]!.add(routeName);
//       }
//     }
//   }

//   void _computeRoute(String origin, String destination) {
//     if (!adjacency.containsKey(origin) || !adjacency.containsKey(destination)) {
//       setState(() {
//         errorText = 'Origin or destination not found';
//       });
//       return;
//     }

//     final parent = <String, String>{};
//     final visited = <String>{};
//     final queue = Queue<String>();
//     queue.add(origin);
//     visited.add(origin);

//     bool found = false;

//     while (queue.isNotEmpty) {
//       final current = queue.removeFirst();
//       if (current == destination) {
//         found = true;
//         break;
//       }
//       for (var neighbor in adjacency[current]!) {
//         if (!visited.contains(neighbor)) {
//           visited.add(neighbor);
//           parent[neighbor] = current;
//           queue.add(neighbor);
//         }
//       }
//     }

//     if (!found) {
//       setState(() {
//         errorText = 'No route found';
//       });
//       return;
//     }

//     final path = <String>[];
//     String cur = destination;
//     while (true) {
//       path.add(cur);
//       if (cur == origin) break;
//       cur = parent[cur]!;
//     }
//     final pathStops = path.reversed.toList();

//     routeSegments = [];
//     String? currentRoute;
//     List<String> currentSegment = [];

//     for (int i = 0; i < pathStops.length - 1; i++) {
//       final a = pathStops[i];
//       final b = pathStops[i + 1];
//       final possibleRoutes = edgeRoutes[a]![b]!;

//       String chosenRoute;
//       if (currentRoute != null && possibleRoutes.contains(currentRoute)) {
//         chosenRoute = currentRoute;
//       } else {
//         chosenRoute = possibleRoutes.first;
//       }

//       if (currentRoute == null) {
//         currentRoute = chosenRoute;
//         currentSegment.add(a);
//         currentSegment.add(b);
//       } else if (chosenRoute == currentRoute) {
//         if (currentSegment.last != a) currentSegment.add(a);
//         currentSegment.add(b);
//       } else {
//         routeSegments.add({
//           'route': currentRoute,
//           'stops': List<String>.from(currentSegment),
//         });
//         currentRoute = chosenRoute;
//         currentSegment = [a, b];
//       }
//     }

//     if (currentSegment.isNotEmpty) {
//       routeSegments.add({'route': currentRoute!, 'stops': currentSegment});
//     }

//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (errorText.isNotEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Ride Map')),
//         body: Center(child: Text(errorText)),
//       );
//     }

//     if (stopsMap.isEmpty || routeSegments.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Ride Map')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     final originLatLng = stopsMap[widget.origin]!;
//     final destLatLng = stopsMap[widget.destination]!;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Ride Map')),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition:
//                 CameraPosition(target: originLatLng, zoom: 14),
//             markers: _markers,
//             zoomControlsEnabled: true,
//             myLocationButtonEnabled: true,
//             onMapCreated: (controller) => _mapController = controller,
//           ),

//           // Draggable sheet
//           Positioned.fill(
//             child: Align(
//               alignment: Alignment.bottomCenter,
//               child: DraggableScrollableSheet(
//                 initialChildSize: 0.25,
//                 minChildSize: 0.1,
//                 maxChildSize: 0.6,
//                 builder: (context, scrollController) {
//                   return Container(
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius:
//                           BorderRadius.vertical(top: Radius.circular(16)),
//                       boxShadow: [
//                         BoxShadow(
//                             color: Colors.black26,
//                             blurRadius: 8,
//                             offset: Offset(0, -2))
//                       ],
//                     ),
//                     child: ListView.builder(
//                       controller: scrollController,
//                       itemCount: routeSegments.length,
//                       itemBuilder: (context, index) {
//                         final seg = routeSegments[index];
//                         final color = routeColors[seg['route']] ?? Colors.grey;
//                         return Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   Container(
//                                     width: 16,
//                                     height: 16,
//                                     decoration: BoxDecoration(
//                                       color: color,
//                                       shape: BoxShape.circle,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Text(
//                                     seg['route'],
//                                     style: const TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 16),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 4),
//                               ...List<Widget>.from(
//                                 (seg['stops'] as List<String>).map((stop) {
//                                   final isLastStopInSegment =
//                                       stop == seg['stops'].last;
//                                   final shouldShowInterchange =
//                                       isLastStopInSegment &&
//                                           index < routeSegments.length - 1;

//                                   return Padding(
//                                     padding: const EdgeInsets.only(
//                                         left: 24, top: 2, bottom: 2),
//                                     child: Row(
//                                       children: [
//                                         Icon(
//                                           shouldShowInterchange
//                                               ? Icons.swap_horiz
//                                               : Icons.circle,
//                                           size: shouldShowInterchange ? 18 : 10,
//                                           color: shouldShowInterchange
//                                               ? Colors.red
//                                               : color,
//                                         ),
//                                         const SizedBox(width: 6),
//                                         Text(
//                                           stop,
//                                           style: TextStyle(
//                                             fontWeight: shouldShowInterchange
//                                                 ? FontWeight.bold
//                                                 : FontWeight.normal,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 }),
//                               ),
//                               if (index < routeSegments.length - 1)
//                                 Padding(
//                                   padding:
//                                       const EdgeInsets.only(left: 24, top: 4),
//                                   child: Text(
//                                     'Interchange at ${seg['stops'].last}',
//                                     style: const TextStyle(
//                                         fontStyle: FontStyle.italic,
//                                         color: Colors.blue),
//                                   ),
//                                 ),
//                               const SizedBox(height: 12),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ------------------------------------------------------------------------
// supabse try 1

// import 'dart:convert';
// import 'dart:collection';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// // Supabase client (replace with your own URL + anon key)
// final supabase = SupabaseClient(
//   'https://ctocodgutltodufynrer.supabase.co',
//   'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0b2NvZGd1dGx0b2R1ZnlucmVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg0NzA3NDYsImV4cCI6MjA3NDA0Njc0Nn0.EYuUWfS3ARTbKbSM79AbZa9QGuidSiC5POwQ9ugDuEw',
// );

// class RideMapPage extends StatefulWidget {
//   final String origin;
//   final String destination;

//   const RideMapPage({
//     super.key,
//     required this.origin,
//     required this.destination,
//   });

//   @override
//   State<RideMapPage> createState() => _RideMapPageState();
// }

// class _RideMapPageState extends State<RideMapPage> {
//   Map<String, List<String>> routes = {}; // route name -> stops
//   Map<String, List<String>> adjacency = {}; // stop -> neighbors
//   Map<String, Map<String, List<String>>> edgeRoutes = {}; // stop1 -> stop2 -> routes
//   Map<String, LatLng> stopsMap = {}; // stop name -> LatLng

//   List<Map<String, dynamic>> routeSegments = [];
//   List<Map<String, dynamic>> buses = []; // from buses.json
//   String errorText = '';

//   late GoogleMapController _mapController;
//   final Set<Marker> _markers = {};
//   final Set<Marker> _busMarkers = {};

//   final Map<String, Color> routeColors = {}; // color for each route

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     try {
//       // Load stops
//       final stopsList = json.decode(
//         await rootBundle.loadString('assets/home_bus_stops.json'),
//       ) as List<dynamic>;

//       for (var stop in stopsList) {
//         final name = stop['name'];
//         final lat = stop['lat'];
//         final lng = stop['lng'];
//         if (name == null || lat == null || lng == null) continue;
//         stopsMap[name.toString()] = LatLng(lat.toDouble(), lng.toDouble());
//       }

//       // Load routes.json
//       final routesData = json.decode(
//         await rootBundle.loadString('assets/routes.json'),
//       ) as List<dynamic>;

//       final colors = [
//         Colors.pink,
//         Colors.blue,
//         Colors.green,
//         Colors.orange,
//         Colors.purple,
//         Colors.teal,
//         Colors.red,
//         Colors.brown,
//         Colors.indigo,
//         Colors.cyan,
//       ];
//       int colorIndex = 0;

//       for (var r in routesData) {
//         final name = r['route'];
//         final stopsList = r['stops'];
//         if (name == null || stopsList == null) continue;

//         final stops = <String>[];
//         for (var s in stopsList) {
//           if (s != null) stops.add(s.toString());
//         }

//         routes[name.toString()] = stops;
//         routeColors[name.toString()] = colors[colorIndex % colors.length];
//         colorIndex++;
//       }

//       // Load buses.json
//       final busesData = json.decode(
//         await rootBundle.loadString('assets/buses.json'),
//       ) as List<dynamic>;
//       buses = busesData.cast<Map<String, dynamic>>();

//       _buildGraph();
//       _computeRoute(widget.origin, widget.destination);
//       _addMarkers();
//       await _fetchBusLocationsForOrigin();
//     } catch (e) {
//       setState(() {
//         errorText = 'Error loading data: $e';
//       });
//     }
//   }

//   void _addMarkers() {
//     _markers.clear();

//     // Origin marker
//     if (stopsMap.containsKey(widget.origin)) {
//       _markers.add(Marker(
//         markerId: const MarkerId('origin'),
//         position: stopsMap[widget.origin]!,
//         infoWindow: InfoWindow(title: widget.origin),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//       ));
//     }

//     // Destination marker
//     if (stopsMap.containsKey(widget.destination)) {
//       _markers.add(Marker(
//         markerId: const MarkerId('destination'),
//         position: stopsMap[widget.destination]!,
//         infoWindow: InfoWindow(title: widget.destination),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       ));
//     }

//     // Intermediate stops
//     for (var segment in routeSegments) {
//       final stops = segment['stops'] as List<String>;
//       for (var stop in stops) {
//         if (stop != widget.origin && stop != widget.destination) {
//           final pos = stopsMap[stop];
//           if (pos != null) {
//             _markers.add(Marker(
//               markerId: MarkerId(stop),
//               position: pos,
//               infoWindow: InfoWindow(title: stop),
//               icon: BitmapDescriptor.defaultMarkerWithHue(
//                 BitmapDescriptor.hueAzure,
//               ),
//             ));
//           }
//         }
//       }
//     }

//     setState(() {});
//   }

//   void _buildGraph() {
//     adjacency = {};
//     edgeRoutes = {};

//     for (var r in routes.entries) {
//       final routeName = r.key;
//       final stops = r.value;
//       for (int i = 0; i < stops.length - 1; i++) {
//         final a = stops[i];
//         final b = stops[i + 1];

//         adjacency[a] = (adjacency[a] ?? []);
//         adjacency[a]!.add(b);

//         adjacency[b] = (adjacency[b] ?? []);
//         adjacency[b]!.add(a);

//         edgeRoutes[a] = (edgeRoutes[a] ?? {});
//         edgeRoutes[a]![b] = (edgeRoutes[a]![b] ?? []);
//         edgeRoutes[a]![b]!.add(routeName);

//         edgeRoutes[b] = (edgeRoutes[b] ?? {});
//         edgeRoutes[b]![a] = (edgeRoutes[b]![a] ?? []);
//         edgeRoutes[b]![a]!.add(routeName);
//       }
//     }
//   }

//   void _computeRoute(String origin, String destination) {
//     if (!adjacency.containsKey(origin) || !adjacency.containsKey(destination)) {
//       setState(() {
//         errorText = 'Origin or destination not found';
//       });
//       return;
//     }

//     final parent = <String, String>{};
//     final visited = <String>{};
//     final queue = Queue<String>();
//     queue.add(origin);
//     visited.add(origin);

//     bool found = false;

//     while (queue.isNotEmpty) {
//       final current = queue.removeFirst();
//       if (current == destination) {
//         found = true;
//         break;
//       }
//       for (var neighbor in adjacency[current]!) {
//         if (!visited.contains(neighbor)) {
//           visited.add(neighbor);
//           parent[neighbor] = current;
//           queue.add(neighbor);
//         }
//       }
//     }

//     if (!found) {
//       setState(() {
//         errorText = 'No route found';
//       });
//       return;
//     }

//     final path = <String>[];
//     String cur = destination;
//     while (true) {
//       path.add(cur);
//       if (cur == origin) break;
//       cur = parent[cur]!;
//     }
//     final pathStops = path.reversed.toList();

//     routeSegments = [];
//     String? currentRoute;
//     List<String> currentSegment = [];

//     for (int i = 0; i < pathStops.length - 1; i++) {
//       final a = pathStops[i];
//       final b = pathStops[i + 1];
//       final possibleRoutes = edgeRoutes[a]![b]!;

//       String chosenRoute;
//       if (currentRoute != null && possibleRoutes.contains(currentRoute)) {
//         chosenRoute = currentRoute;
//       } else {
//         chosenRoute = possibleRoutes.first;
//       }

//       if (currentRoute == null) {
//         currentRoute = chosenRoute;
//         currentSegment.add(a);
//         currentSegment.add(b);
//       } else if (chosenRoute == currentRoute) {
//         if (currentSegment.last != a) currentSegment.add(a);
//         currentSegment.add(b);
//       } else {
//         routeSegments.add({
//           'route': currentRoute,
//           'stops': List<String>.from(currentSegment),
//         });
//         currentRoute = chosenRoute;
//         currentSegment = [a, b];
//       }
//     }

//     if (currentSegment.isNotEmpty) {
//       routeSegments.add({'route': currentRoute!, 'stops': currentSegment});
//     }

//     setState(() {});
//   }

//   Future<void> _fetchBusLocationsForOrigin() async {
//     // Find routes that include origin
//     final relevantRoutes = routes.entries
//         .where((entry) => entry.value.contains(widget.origin))
//         .map((entry) => entry.key)
//         .toList();

//     // Find buses that run on those routes
//     final relevantBuses =
//         buses.where((bus) => relevantRoutes.contains(bus['route'])).toList();

//     _busMarkers.clear();

//     for (var bus in relevantBuses) {
//       final busId = bus['busId'];

//       final response = await supabase
//           .from('driver_locations')
//           .select()
//           .eq('busId', busId)
//           .maybeSingle();

//       if (response != null && response['latitude'] != null) {
//         final lat = (response['latitude'] as num).toDouble();
//         final lng = (response['longitude'] as num).toDouble();

//         _busMarkers.add(Marker(
//           markerId: MarkerId('bus_$busId'),
//           position: LatLng(lat, lng),
//           infoWindow: InfoWindow(
//             title: 'Bus ${bus['numberPlate']}',
//             snippet: 'Route: ${bus['route']}',
//           ),
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//             BitmapDescriptor.hueYellow,
//           ),
//         ));
//       }
//     }

//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (errorText.isNotEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Ride Map')),
//         body: Center(child: Text(errorText)),
//       );
//     }

//     if (stopsMap.isEmpty || routeSegments.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Ride Map')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     final originLatLng = stopsMap[widget.origin]!;
//     final destLatLng = stopsMap[widget.destination]!;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Ride Map')),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition:
//                 CameraPosition(target: originLatLng, zoom: 14),
//             markers: {..._markers, ..._busMarkers},
//             zoomControlsEnabled: true,
//             myLocationButtonEnabled: true,
//             onMapCreated: (controller) => _mapController = controller,
//           ),

//           // Draggable sheet with route info
//           Positioned.fill(
//             child: Align(
//               alignment: Alignment.bottomCenter,
//               child: DraggableScrollableSheet(
//                 initialChildSize: 0.25,
//                 minChildSize: 0.1,
//                 maxChildSize: 0.6,
//                 builder: (context, scrollController) {
//                   return Container(
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius:
//                           BorderRadius.vertical(top: Radius.circular(16)),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black26,
//                           blurRadius: 8,
//                           offset: Offset(0, -2),
//                         )
//                       ],
//                     ),
//                     child: ListView.builder(
//                       controller: scrollController,
//                       itemCount: routeSegments.length,
//                       itemBuilder: (context, index) {
//                         final seg = routeSegments[index];
//                         final color = routeColors[seg['route']] ?? Colors.grey;
//                         return Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   Container(
//                                     width: 16,
//                                     height: 16,
//                                     decoration: BoxDecoration(
//                                       color: color,
//                                       shape: BoxShape.circle,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Text(
//                                     seg['route'],
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 4),
//                               ...List<Widget>.from(
//                                 (seg['stops'] as List<String>).map((stop) {
//                                   final isLastStopInSegment =
//                                       stop == seg['stops'].last;
//                                   final shouldShowInterchange =
//                                       isLastStopInSegment &&
//                                           index < routeSegments.length - 1;

//                                   return Padding(
//                                     padding: const EdgeInsets.only(
//                                         left: 24, top: 2, bottom: 2),
//                                     child: Row(
//                                       children: [
//                                         Icon(
//                                           shouldShowInterchange
//                                               ? Icons.swap_horiz
//                                               : Icons.circle,
//                                           size: shouldShowInterchange ? 18 : 10,
//                                           color: shouldShowInterchange
//                                               ? Colors.red
//                                               : color,
//                                         ),
//                                         const SizedBox(width: 6),
//                                         Text(
//                                           stop,
//                                           style: TextStyle(
//                                             fontWeight: shouldShowInterchange
//                                                 ? FontWeight.bold
//                                                 : FontWeight.normal,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 }),
//                               ),
//                               if (index < routeSegments.length - 1)
//                                 Padding(
//                                   padding: const EdgeInsets.only(
//                                       left: 24, top: 4),
//                                   child: Text(
//                                     'Interchange at ${seg['stops'].last}',
//                                     style: const TextStyle(
//                                       fontStyle: FontStyle.italic,
//                                       color: Colors.blue,
//                                     ),
//                                   ),
//                                 ),
//                               const SizedBox(height: 12),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ------------------------------------------------------------------------
// try 2

// import 'dart:convert';
// import 'dart:collection';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class RideMapPage extends StatefulWidget {
//   final String origin;
//   final String destination;

//   const RideMapPage({
//     super.key,
//     required this.origin,
//     required this.destination,
//   });

//   @override
//   State<RideMapPage> createState() => _RideMapPageState();
// }

// class _RideMapPageState extends State<RideMapPage> {
//   final supabase = SupabaseClient(
//     'https://ctocodgutltodufynrer.supabase.co',
//     'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0b2NvZGd1dGx0b2R1ZnlucmVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg0NzA3NDYsImV4cCI6MjA3NDA0Njc0Nn0.EYuUWfS3ARTbKbSM79AbZa9QGuidSiC5POwQ9ugDuEw',
//   );

//   Map<String, List<String>> routes = {};
//   Map<String, List<String>> adjacency = {};
//   Map<String, Map<String, List<String>>> edgeRoutes = {};
//   Map<String, LatLng> stopsMap = {};
//   List<Map<String, dynamic>> routeSegments = [];
//   Map<String, String> busRouteMap = {}; // busId -> route
//   String errorText = '';

//   late GoogleMapController _mapController;
//   final Set<Marker> _markers = {};
//   final Map<String, Color> routeColors = {};

//   @override
//   void initState() {
//     super.initState();
//     _loadData().then((_) => _loadBusData().then((_) => _loadDriverLocations()));
//   }

//   /// Load stops and routes
//   Future<void> _loadData() async {
//     try {
//       // Load stops
//       final stopsList = json.decode(
//         await rootBundle.loadString('assets/home_bus_stops.json'),
//       ) as List<dynamic>;

//       for (var stop in stopsList) {
//         final name = stop['name'];
//         final lat = stop['lat'];
//         final lng = stop['lng'];
//         if (name != null && lat != null && lng != null) {
//           stopsMap[name] = LatLng(lat.toDouble(), lng.toDouble());
//         }
//       }

//       // Load routes
//       final routesData = json.decode(
//         await rootBundle.loadString('assets/routes.json'),
//       ) as List<dynamic>;

//       final colors = [
//         Colors.pink,
//         Colors.blue,
//         Colors.green,
//         Colors.orange,
//         Colors.purple,
//         Colors.teal,
//         Colors.red,
//         Colors.brown,
//         Colors.indigo,
//         Colors.cyan,
//       ];
//       int colorIndex = 0;

//       for (var r in routesData) {
//         final name = r['route'];
//         final stopsList = r['stops'];
//         if (name == null || stopsList == null) continue;
//         routes[name.toString()] = List<String>.from(stopsList);
//         routeColors[name.toString()] = colors[colorIndex % colors.length];
//         colorIndex++;
//       }

//       _buildGraph();
//       _computeRoute(widget.origin, widget.destination);
//       _addMarkers();
//     } catch (e) {
//       setState(() => errorText = 'Error loading data: $e');
//     }
//   }

//   /// Load buses.json to know which bus is on which route
//   Future<void> _loadBusData() async {
//     try {
//       final busesData = json.decode(
//         await rootBundle.loadString('assets/buses.json'),
//       ) as List<dynamic>;

//       for (var b in busesData) {
//         final busId = b['busId'];
//         final route = b['route'];
//         if (busId != null && route != null) {
//           busRouteMap[busId] = route;
//         }
//       }
//     } catch (e) {
//       print("Error loading buses.json: $e");
//     }
//   }

//   /// Load driver locations from Supabase
//   // Future<void> _loadDriverLocations() async {
//   //   try {
//   //     final response = await supabase.from('driver_locations').select();
//   //     print("DEBUG Supabase response: $response");

//   //     if (response is List) {
//   //       for (var row in response) {
//   //         final busId = row['busId'] ?? 'Unknown';
//   //         final lat = row['lat'];
//   //         final lng = row['lng'];

//   //         // Only show buses that include origin stop
//   //         final routeName = busRouteMap[busId];
//   //         if (routeName == null) continue;
//   //         final stopsInRoute = routes[routeName] ?? [];
//   //         if (!stopsInRoute.contains(widget.origin)) continue;

//   //         if (lat != null && lng != null) {
//   //           final position = LatLng(lat.toDouble(), lng.toDouble());
//   //           _markers.add(Marker(
//   //             markerId: MarkerId('driver_$busId'),
//   //             position: position,
//   //             icon: BitmapDescriptor.defaultMarkerWithHue(
//   //                 BitmapDescriptor.hueYellow),
//   //             infoWindow: InfoWindow(title: 'Bus $busId'),
//   //           ));
//   //         }
//   //       }
//   //     }

//   //     // Move camera to first bus if exists
//   //     if (_markers.isNotEmpty) {
//   //       final firstBus = _markers.first.position;
//   //       _mapController.animateCamera(
//   //         CameraUpdate.newLatLngZoom(firstBus, 14),
//   //       );
//   //     }

//   //     setState(() {});
//   //   } catch (e) {
//   //     print("Error fetching driver locations: $e");
//   //   }
//   // }

//   Future<void> _loadDriverLocations() async {
//   try {
//     final response = await supabase.from('driver_locations').select();
//     print("DEBUG Supabase raw response: $response");

//     if (response is! List) {
//       print("ERROR: Supabase response is not a list");
//       return;
//     }

//     for (var row in response) {
//       // Safe type casting
//       final busId = row['busId']?.toString() ?? 'Unknown';
//       final latRaw = row['lat'];
//       final lngRaw = row['lng'];

//       if (latRaw == null || lngRaw == null) {
//         print('Skipping bus $busId: lat/lng null');
//         continue;
//       }

//       final lat = latRaw is double ? latRaw : double.tryParse(latRaw.toString());
//       final lng = lngRaw is double ? lngRaw : double.tryParse(lngRaw.toString());

//       if (lat == null || lng == null) {
//         print('Skipping bus $busId: lat/lng could not be parsed');
//         continue;
//       }

//       final position = LatLng(lat, lng);

//       // Get route of this bus
//       final routeName = busRouteMap[busId];
//       if (routeName == null) {
//         print('Skipping bus $busId: route not found in buses.json');
//         continue;
//       }

//       final stopsInRoute = routes[routeName] ?? [];
//       print('Bus $busId route: $routeName, stops: $stopsInRoute');

//       // Check if this bus passes through rider's origin
//       if (!stopsInRoute.contains(widget.origin)) {
//         print('Skipping bus $busId: origin ${widget.origin} not in route');
//         continue;
//       }

//       print('Adding marker for bus $busId at ${position.latitude}, ${position.longitude}');
//       _markers.add(Marker(
//         markerId: MarkerId('driver_$busId'),
//         position: position,
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
//         infoWindow: InfoWindow(title: 'Bus $busId'),
//       ));
//     }

//     // Move camera to first bus if exists
//     if (_markers.isNotEmpty) {
//       final firstBus = _markers.first.position;
//       _mapController.animateCamera(
//         CameraUpdate.newLatLngZoom(firstBus, 14),
//       );
//     }

//     setState(() {});
//   } catch (e) {
//     print("Error fetching driver locations: $e");
//   }
// }


//   void _addMarkers() {
//     // Clear previous route markers (keep drivers)
//     _markers.removeWhere((m) => !m.markerId.value.startsWith('driver_'));

//     if (stopsMap.containsKey(widget.origin)) {
//       _markers.add(Marker(
//         markerId: const MarkerId('origin'),
//         position: stopsMap[widget.origin]!,
//         infoWindow: InfoWindow(title: widget.origin),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//       ));
//     }

//     if (stopsMap.containsKey(widget.destination)) {
//       _markers.add(Marker(
//         markerId: const MarkerId('destination'),
//         position: stopsMap[widget.destination]!,
//         infoWindow: InfoWindow(title: widget.destination),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       ));
//     }

//     for (var segment in routeSegments) {
//       final stops = segment['stops'] as List<String>;
//       for (var stop in stops) {
//         if (stop != widget.origin && stop != widget.destination) {
//           final pos = stopsMap[stop];
//           if (pos != null) {
//             _markers.add(Marker(
//               markerId: MarkerId(stop),
//               position: pos,
//               infoWindow: InfoWindow(title: stop),
//               icon: BitmapDescriptor.defaultMarkerWithHue(
//                 BitmapDescriptor.hueAzure,
//               ),
//             ));
//           }
//         }
//       }
//     }

//     setState(() {});
//   }

//   void _buildGraph() {
//     adjacency = {};
//     edgeRoutes = {};

//     for (var r in routes.entries) {
//       final routeName = r.key;
//       final stops = r.value;
//       for (int i = 0; i < stops.length - 1; i++) {
//         final a = stops[i];
//         final b = stops[i + 1];

//         adjacency[a] = (adjacency[a] ?? []);
//         adjacency[a]!.add(b);

//         adjacency[b] = (adjacency[b] ?? []);
//         adjacency[b]!.add(a);

//         edgeRoutes[a] = (edgeRoutes[a] ?? {});
//         edgeRoutes[a]![b] = (edgeRoutes[a]![b] ?? []);
//         edgeRoutes[a]![b]!.add(routeName);

//         edgeRoutes[b] = (edgeRoutes[b] ?? {});
//         edgeRoutes[b]![a] = (edgeRoutes[b]![a] ?? []);
//         edgeRoutes[b]![a]!.add(routeName);
//       }
//     }
//   }

//   void _computeRoute(String origin, String destination) {
//     if (!adjacency.containsKey(origin) || !adjacency.containsKey(destination)) {
//       setState(() => errorText = 'Origin or destination not found');
//       return;
//     }

//     final parent = <String, String>{};
//     final visited = <String>{};
//     final queue = Queue<String>();
//     queue.add(origin);
//     visited.add(origin);

//     bool found = false;

//     while (queue.isNotEmpty) {
//       final current = queue.removeFirst();
//       if (current == destination) {
//         found = true;
//         break;
//       }
//       for (var neighbor in adjacency[current]!) {
//         if (!visited.contains(neighbor)) {
//           visited.add(neighbor);
//           parent[neighbor] = current;
//           queue.add(neighbor);
//         }
//       }
//     }

//     if (!found) {
//       setState(() => errorText = 'No route found');
//       return;
//     }

//     final path = <String>[];
//     String cur = destination;
//     while (true) {
//       path.add(cur);
//       if (cur == origin) break;
//       cur = parent[cur]!;
//     }

//     final pathStops = path.reversed.toList();
//     routeSegments = [];
//     String? currentRoute;
//     List<String> currentSegment = [];

//     for (int i = 0; i < pathStops.length - 1; i++) {
//       final a = pathStops[i];
//       final b = pathStops[i + 1];
//       final possibleRoutes = edgeRoutes[a]![b]!;

//       String chosenRoute;
//       if (currentRoute != null && possibleRoutes.contains(currentRoute)) {
//         chosenRoute = currentRoute;
//       } else {
//         chosenRoute = possibleRoutes.first;
//       }

//       if (currentRoute == null) {
//         currentRoute = chosenRoute;
//         currentSegment.add(a);
//         currentSegment.add(b);
//       } else if (chosenRoute == currentRoute) {
//         if (currentSegment.last != a) currentSegment.add(a);
//         currentSegment.add(b);
//       } else {
//         routeSegments.add({'route': currentRoute!, 'stops': List.from(currentSegment)});
//         currentRoute = chosenRoute;
//         currentSegment = [a, b];
//       }
//     }

//     if (currentSegment.isNotEmpty) {
//       routeSegments.add({'route': currentRoute!, 'stops': currentSegment});
//     }

//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (errorText.isNotEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Ride Map')),
//         body: Center(child: Text(errorText)),
//       );
//     }

//     if (stopsMap.isEmpty || routeSegments.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Ride Map')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     final originLatLng = stopsMap[widget.origin]!;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Ride Map')),
//       body: GoogleMap(
//         initialCameraPosition:
//             CameraPosition(target: originLatLng, zoom: 14),
//         markers: _markers,
//         zoomControlsEnabled: true,
//         myLocationButtonEnabled: true,
//         onMapCreated: (controller) => _mapController = controller,
//       ),
//     );
//   }
// }



//  -------------------------------------------------------------------------


// import 'dart:convert';
// import 'dart:collection';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class RideMapPage extends StatefulWidget {
//   final String origin;
//   final String destination;

//   const RideMapPage({
//     super.key,
//     required this.origin,
//     required this.destination,
//   });

//   @override
//   State<RideMapPage> createState() => _RideMapPageState();
// }

// class _RideMapPageState extends State<RideMapPage> {
//   final supabase = SupabaseClient(
//     'https://ctocodgutltodufynrer.supabase.co',
//     'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0b2NvZGd1dGx0b2R1ZnlucmVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg0NzA3NDYsImV4cCI6MjA3NDA0Njc0Nn0.EYuUWfS3ARTbKbSM79AbZa9QGuidSiC5POwQ9ugDuEw',
//   );

//   Map<String, List<String>> routes = {};
//   Map<String, List<String>> adjacency = {};
//   Map<String, Map<String, List<String>>> edgeRoutes = {};
//   Map<String, LatLng> stopsMap = {};
//   List<Map<String, dynamic>> routeSegments = [];
//   Map<String, String> busRouteMap = {};
//   String errorText = '';

//   late GoogleMapController _mapController;
//   final Set<Marker> _markers = {};
//   final Map<String, Color> routeColors = {};

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   /// Load stops and routes
//   Future<void> _loadData() async {
//     try {
//       // Load stops
//       final stopsList = json.decode(
//         await rootBundle.loadString('assets/home_bus_stops.json'),
//       ) as List<dynamic>;
//       for (var stop in stopsList) {
//         final mapStop = stop as Map<String, dynamic>;
//         final name = mapStop['name'];
//         final lat = mapStop['lat'];
//         final lng = mapStop['lng'];
//         if (name != null && lat != null && lng != null) {
//           stopsMap[name] = LatLng(lat.toDouble(), lng.toDouble());
//         }
//       }

//       // Load routes
//       final routesData = json.decode(
//         await rootBundle.loadString('assets/routes.json'),
//       ) as List<dynamic>;
//       final colors = [
//         Colors.pink,
//         Colors.blue,
//         Colors.green,
//         Colors.orange,
//         Colors.purple,
//         Colors.teal,
//         Colors.red,
//         Colors.brown,
//         Colors.indigo,
//         Colors.cyan,
//       ];
//       int colorIndex = 0;
//       for (var r in routesData) {
//         final mapR = r as Map<String, dynamic>;
//         final name = mapR['route'];
//         final stopsList = mapR['stops'];
//         if (name == null || stopsList == null) continue;
//         routes[name.toString()] = List<String>.from(stopsList);
//         routeColors[name.toString()] = colors[colorIndex % colors.length];
//         colorIndex++;
//       }

//       _buildGraph();
//       _computeRoute(widget.origin, widget.destination);
//       _addMarkers();

//       // Load buses.json after routes
//       await _loadBusData();
//     } catch (e) {
//       setState(() => errorText = 'Error loading data: $e');
//     }
//   }

//   /// Load buses.json
//   Future<void> _loadBusData() async {
//     try {
//       final busesData = json.decode(
//         await rootBundle.loadString('assets/buses.json'),
//       ) as List<dynamic>;
//       for (var b in busesData) {
//         final mapB = b as Map<String, dynamic>;
//         final busId = mapB['busId'];
//         final route = mapB['route'];
//         if (busId != null && route != null) {
//           busRouteMap[busId] = route;
//         }
//       }
//     } catch (e) {
//       print("Error loading buses.json: $e");
//     }
//   }

//   /// Load driver locations from Supabase
//   Future<void> _loadDriverLocations() async {
//     try {
//       final response = await supabase.from('driver_locations').select();
//       print("DEBUG Supabase raw response: $response");

//       if (response is! List) return;

//       for (var row in response) {
//         final busId = row['busId']?.toString() ?? 'Unknown';
//         final latRaw = row['lat'];
//         final lngRaw = row['lng'];

//         if (latRaw == null || lngRaw == null) {
//           print('Skipping bus $busId: lat/lng null');
//           continue;
//         }

//         final lat = latRaw is double ? latRaw : double.tryParse(latRaw.toString());
//         final lng = lngRaw is double ? lngRaw : double.tryParse(lngRaw.toString());
//         if (lat == null || lng == null) continue;

//         final position = LatLng(lat, lng);

//         final routeName = busRouteMap[busId];
//         if (routeName == null) continue;

//         final stopsInRoute = routes[routeName] ?? [];
//         if (!stopsInRoute.contains(widget.origin)) continue;

//         print('Adding marker for bus $busId at $lat, $lng');
//         _markers.add(Marker(
//           markerId: MarkerId('driver_$busId'),
//           position: position,
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
//           infoWindow: InfoWindow(title: 'Bus $busId'),
//         ));
//       }

//       setState(() {});
//     } catch (e) {
//       print("Error fetching driver locations: $e");
//     }
//   }

//   void _addMarkers() {
//     _markers.removeWhere((m) => !m.markerId.value.startsWith('driver_'));

//     if (stopsMap.containsKey(widget.origin)) {
//       _markers.add(Marker(
//         markerId: const MarkerId('origin'),
//         position: stopsMap[widget.origin]!,
//         infoWindow: InfoWindow(title: widget.origin),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//       ));
//     }
//     if (stopsMap.containsKey(widget.destination)) {
//       _markers.add(Marker(
//         markerId: const MarkerId('destination'),
//         position: stopsMap[widget.destination]!,
//         infoWindow: InfoWindow(title: widget.destination),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       ));
//     }

//     for (var segment in routeSegments) {
//       final stops = segment['stops'] as List<String>;
//       for (var stop in stops) {
//         if (stop != widget.origin && stop != widget.destination) {
//           final pos = stopsMap[stop];
//           if (pos != null) {
//             _markers.add(Marker(
//               markerId: MarkerId(stop),
//               position: pos,
//               infoWindow: InfoWindow(title: stop),
//               icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
//             ));
//           }
//         }
//       }
//     }

//     setState(() {});
//   }

//   void _buildGraph() {
//     adjacency = {};
//     edgeRoutes = {};
//     for (var r in routes.entries) {
//       final routeName = r.key;
//       final stops = r.value;
//       for (int i = 0; i < stops.length - 1; i++) {
//         final a = stops[i];
//         final b = stops[i + 1];

//         adjacency[a] = (adjacency[a] ?? [])..add(b);
//         adjacency[b] = (adjacency[b] ?? [])..add(a);

//         edgeRoutes[a] = (edgeRoutes[a] ?? {});
//         edgeRoutes[a]![b] = (edgeRoutes[a]![b] ?? [])..add(routeName);

//         edgeRoutes[b] = (edgeRoutes[b] ?? {});
//         edgeRoutes[b]![a] = (edgeRoutes[b]![a] ?? [])..add(routeName);
//       }
//     }
//   }

//   void _computeRoute(String origin, String destination) {
//     if (!adjacency.containsKey(origin) || !adjacency.containsKey(destination)) {
//       setState(() => errorText = 'Origin or destination not found');
//       return;
//     }

//     final parent = <String, String>{};
//     final visited = <String>{};
//     final queue = Queue<String>()..add(origin);
//     visited.add(origin);
//     bool found = false;

//     while (queue.isNotEmpty) {
//       final current = queue.removeFirst();
//       if (current == destination) {
//         found = true;
//         break;
//       }
//       for (var neighbor in adjacency[current]!) {
//         if (!visited.contains(neighbor)) {
//           visited.add(neighbor);
//           parent[neighbor] = current;
//           queue.add(neighbor);
//         }
//       }
//     }

//     if (!found) {
//       setState(() => errorText = 'No route found');
//       return;
//     }

//     final path = <String>[];
//     String cur = destination;
//     while (true) {
//       path.add(cur);
//       if (cur == origin) break;
//       cur = parent[cur]!;
//     }

//     final pathStops = path.reversed.toList();
//     routeSegments = [];
//     String? currentRoute;
//     List<String> currentSegment = [];

//     for (int i = 0; i < pathStops.length - 1; i++) {
//       final a = pathStops[i];
//       final b = pathStops[i + 1];
//       final possibleRoutes = edgeRoutes[a]![b]!;

//       String chosenRoute;
//       if (currentRoute != null && possibleRoutes.contains(currentRoute)) {
//         chosenRoute = currentRoute;
//       } else {
//         chosenRoute = possibleRoutes.first;
//       }

//       if (currentRoute == null) {
//         currentRoute = chosenRoute;
//         currentSegment.add(a);
//         currentSegment.add(b);
//       } else if (chosenRoute == currentRoute) {
//         if (currentSegment.last != a) currentSegment.add(a);
//         currentSegment.add(b);
//       } else {
//         routeSegments.add({'route': currentRoute!, 'stops': List.from(currentSegment)});
//         currentRoute = chosenRoute;
//         currentSegment = [a, b];
//       }
//     }

//     if (currentSegment.isNotEmpty) {
//       routeSegments.add({'route': currentRoute!, 'stops': currentSegment});
//     }

//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (errorText.isNotEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Ride Map')),
//         body: Center(child: Text(errorText)),
//       );
//     }

//     if (stopsMap.isEmpty || routeSegments.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Ride Map')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     final originLatLng = stopsMap[widget.origin]!;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Ride Map')),
//       body: GoogleMap(
//         initialCameraPosition: CameraPosition(target: originLatLng, zoom: 14),
//         markers: _markers,
//         zoomControlsEnabled: true,
//         myLocationButtonEnabled: true,
//         onMapCreated: (controller) {
//           _mapController = controller;
//           _loadDriverLocations(); // load buses after map ready
//         },
//       ),
//     );
//   }
// }









// --------------------------------------------------------------------------------






// import 'dart:convert';
// import 'dart:collection';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class RideMapPage extends StatefulWidget {
//   final String origin;
//   final String destination;

//   const RideMapPage({
//     super.key,
//     required this.origin,
//     required this.destination,
//   });

//   @override
//   State<RideMapPage> createState() => _RideMapPageState();
// }

// class _RideMapPageState extends State<RideMapPage> {
//   final supabase = SupabaseClient(
//     'https://ctocodgutltodufynrer.supabase.co',
//     'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0b2NvZGd1dGx0b2R1ZnlucmVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg0NzA3NDYsImV4cCI6MjA3NDA0Njc0Nn0.EYuUWfS3ARTbKbSM79AbZa9QGuidSiC5POwQ9ugDuEw',
//   );

//   Map<String, List<String>> routes = {};
//   Map<String, List<String>> adjacency = {};
//   Map<String, Map<String, List<String>>> edgeRoutes = {};
//   Map<String, LatLng> stopsMap = {};
//   List<Map<String, dynamic>> routeSegments = [];
//   Map<String, String> busRouteMap = {};
//   String errorText = '';

//   late GoogleMapController _mapController;
//   final Set<Marker> _markers = {};
//   final Map<String, Color> routeColors = {};

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   /// Load stops, routes, and bus info
//   Future<void> _loadData() async {
//     try {
//       // Load stops
//       final stopsList = json.decode(
//         await rootBundle.loadString('assets/home_bus_stops.json'),
//       ) as List<dynamic>;
//       for (var stop in stopsList) {
//         final mapStop = stop as Map<String, dynamic>;
//         final name = mapStop['name'];
//         final lat = mapStop['lat'];
//         final lng = mapStop['lng'];
//         if (name != null && lat != null && lng != null) {
//           stopsMap[name] = LatLng(lat.toDouble(), lng.toDouble());
//         }
//       }

//       // Load routes
//       final routesData = json.decode(
//         await rootBundle.loadString('assets/routes.json'),
//       ) as List<dynamic>;
//       final colors = [
//         Colors.pink,
//         Colors.blue,
//         Colors.green,
//         Colors.orange,
//         Colors.purple,
//         Colors.teal,
//         Colors.red,
//         Colors.brown,
//         Colors.indigo,
//         Colors.cyan,
//       ];
//       int colorIndex = 0;
//       for (var r in routesData) {
//         final mapR = r as Map<String, dynamic>;
//         final name = mapR['route'];
//         final stopsList = mapR['stops'];
//         if (name == null || stopsList == null) continue;
//         routes[name.toString()] = List<String>.from(stopsList);
//         routeColors[name.toString()] = colors[colorIndex % colors.length];
//         colorIndex++;
//       }

//       _buildGraph();
//       _computeRoute(widget.origin, widget.destination);
//       _addMarkers();

//       // Load buses.json
//       final busesData = json.decode(
//         await rootBundle.loadString('assets/buses.json'),
//       ) as List<dynamic>;
//       for (var b in busesData) {
//         final mapB = b as Map<String, dynamic>;
//         final busId = mapB['busId'];
//         final route = mapB['route'];
//         if (busId != null && route != null) {
//           busRouteMap[busId] = route;
//         }
//       }
//     } catch (e) {
//       setState(() => errorText = 'Error loading data: $e');
//     }
//   }

//   /// Load driver locations from Supabase
//   // Future<void> _loadDriverLocations() async {
//   //   try {
//   //     final response = await supabase.from('driver_locations').select();
//   //     print("DEBUG Supabase raw response: $response");

//   //     if (response is! List) return;

//   //     for (var row in response) {
//   //       final busId = row['busId']?.toString() ?? 'Unknown';
//   //       final latRaw = row['lat'];
//   //       final lngRaw = row['lng'];

//   //       if (latRaw == null || lngRaw == null) continue;

//   //       final lat = latRaw is double ? latRaw : double.tryParse(latRaw.toString());
//   //       final lng = lngRaw is double ? lngRaw : double.tryParse(lngRaw.toString());
//   //       if (lat == null || lng == null) continue;

//   //       final position = LatLng(lat, lng);

//   //       final routeName = busRouteMap[busId];
//   //       if (routeName == null) continue;

//   //       final stopsInRoute = routes[routeName] ?? [];
//   //       if (!stopsInRoute.contains(widget.origin)) continue;

//   //       print('Adding marker for bus $busId at $lat, $lng');
//   //       _markers.add(Marker(
//   //         markerId: MarkerId('driver_$busId'),
//   //         position: position,
//   //         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
//   //         infoWindow: InfoWindow(title: 'Bus $busId'),
//   //       ));
//   //     }

//   //     setState(() {});
//   //   } catch (e) {
//   //     print("Error fetching driver locations: $e");
//   //   }
//   // }
// Future<void> _loadDriverLocations() async {
//   if (routeSegments.isEmpty) return; // nothing to filter yet

//   try {
//     final response = await supabase.from('driver_locations').select();
//     print("DEBUG Supabase raw response: $response");
//     if (response is! List) return;

//     final allRouteStops = <String>{};
//     for (var seg in routeSegments) {
//       final stops = seg['stops'] as List<String>;
//       allRouteStops.addAll(stops);
//     }

//     for (var row in response) {
//       final busId = row['busId']?.toString() ?? '';
//       final routeName = busRouteMap[busId];
//       if (routeName == null) continue;

//       // Only show bus if it has at least one stop in path
//       final busStops = routes[routeName] ?? [];
//       if (!busStops.any((s) => allRouteStops.contains(s))) continue;

//       final latRaw = row['lat'];
//       final lngRaw = row['lng'];
//       if (latRaw == null || lngRaw == null) continue;

//       final lat = latRaw is double ? latRaw : double.tryParse(latRaw.toString());
//       final lng = lngRaw is double ? lngRaw : double.tryParse(lngRaw.toString());
//       if (lat == null || lng == null) continue;

//       _markers.add(Marker(
//         markerId: MarkerId('driver_$busId'),
//         position: LatLng(lat, lng),
//         infoWindow: InfoWindow(title: 'Bus $busId'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
//       ));
//     }

//     setState(() {});
//   } catch (e) {
//     print("Error fetching driver locations: $e");
//   }
// }



//   void _addMarkers() {
//     _markers.removeWhere((m) => !m.markerId.value.startsWith('driver_'));

//     if (stopsMap.containsKey(widget.origin)) {
//       _markers.add(Marker(
//         markerId: const MarkerId('origin'),
//         position: stopsMap[widget.origin]!,
//         infoWindow: InfoWindow(title: widget.origin),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//       ));
//     }
//     if (stopsMap.containsKey(widget.destination)) {
//       _markers.add(Marker(
//         markerId: const MarkerId('destination'),
//         position: stopsMap[widget.destination]!,
//         infoWindow: InfoWindow(title: widget.destination),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       ));
//     }

//     for (var segment in routeSegments) {
//       final stops = segment['stops'] as List<String>;
//       for (var stop in stops) {
//         if (stop != widget.origin && stop != widget.destination) {
//           final pos = stopsMap[stop];
//           if (pos != null) {
//             _markers.add(Marker(
//               markerId: MarkerId(stop),
//               position: pos,
//               infoWindow: InfoWindow(title: stop),
//               icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
//             ));
//           }
//         }
//       }
//     }

//     setState(() {});
//   }

//   void _buildGraph() {
//     adjacency = {};
//     edgeRoutes = {};
//     for (var r in routes.entries) {
//       final routeName = r.key;
//       final stops = r.value;
//       for (int i = 0; i < stops.length - 1; i++) {
//         final a = stops[i];
//         final b = stops[i + 1];

//         adjacency[a] = (adjacency[a] ?? [])..add(b);
//         adjacency[b] = (adjacency[b] ?? [])..add(a);

//         edgeRoutes[a] = (edgeRoutes[a] ?? {});
//         edgeRoutes[a]![b] = (edgeRoutes[a]![b] ?? [])..add(routeName);

//         edgeRoutes[b] = (edgeRoutes[b] ?? {});
//         edgeRoutes[b]![a] = (edgeRoutes[b]![a] ?? [])..add(routeName);
//       }
//     }
//   }

//   void _computeRoute(String origin, String destination) {
//     if (!adjacency.containsKey(origin) || !adjacency.containsKey(destination)) {
//       setState(() => errorText = 'Origin or destination not found');
//       return;
//     }

//     final parent = <String, String>{};
//     final visited = <String>{};
//     final queue = Queue<String>()..add(origin);
//     visited.add(origin);
//     bool found = false;

//     while (queue.isNotEmpty) {
//       final current = queue.removeFirst();
//       if (current == destination) {
//         found = true;
//         break;
//       }
//       for (var neighbor in adjacency[current]!) {
//         if (!visited.contains(neighbor)) {
//           visited.add(neighbor);
//           parent[neighbor] = current;
//           queue.add(neighbor);
//         }
//       }
//     }

//     if (!found) {
//       setState(() => errorText = 'No route found');
//       return;
//     }

//     final path = <String>[];
//     String cur = destination;
//     while (true) {
//       path.add(cur);
//       if (cur == origin) break;
//       cur = parent[cur]!;
//     }

//     final pathStops = path.reversed.toList();
//     routeSegments = [];
//     String? currentRoute;
//     List<String> currentSegment = [];

//     for (int i = 0; i < pathStops.length - 1; i++) {
//       final a = pathStops[i];
//       final b = pathStops[i + 1];
//       final possibleRoutes = edgeRoutes[a]![b]!;

//       String chosenRoute;
//       if (currentRoute != null && possibleRoutes.contains(currentRoute)) {
//         chosenRoute = currentRoute;
//       } else {
//         chosenRoute = possibleRoutes.first;
//       }

//       if (currentRoute == null) {
//         currentRoute = chosenRoute;
//         currentSegment.add(a);
//         currentSegment.add(b);
//       } else if (chosenRoute == currentRoute) {
//         if (currentSegment.last != a) currentSegment.add(a);
//         currentSegment.add(b);
//       } else {
//         routeSegments.add({'route': currentRoute!, 'stops': List.from(currentSegment)});
//         currentRoute = chosenRoute;
//         currentSegment = [a, b];
//       }
//     }

//     if (currentSegment.isNotEmpty) {
//       routeSegments.add({'route': currentRoute!, 'stops': currentSegment});
//     }

//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (errorText.isNotEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Ride Map')),
//         body: Center(child: Text(errorText)),
//       );
//     }

//     if (stopsMap.isEmpty || routeSegments.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Ride Map')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     final originLatLng = stopsMap[widget.origin]!;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Ride Map')),
//       body: Stack(
//         children: [
//           // Google Map
//           GoogleMap(
//             initialCameraPosition: CameraPosition(target: originLatLng, zoom: 14),
//             markers: _markers,
//             zoomControlsEnabled: true,
//             myLocationButtonEnabled: true,
//             onMapCreated: (controller) {
//               _mapController = controller;
//               _loadDriverLocations();
//             },
//           ),

//           // Draggable Sheet
//           Positioned.fill(
//             child: Align(
//               alignment: Alignment.bottomCenter,
//               child: DraggableScrollableSheet(
//                 initialChildSize: 0.25,
//                 minChildSize: 0.1,
//                 maxChildSize: 0.6,
//                 builder: (context, scrollController) {
//                   return Container(
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//                       boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))],
//                     ),
//                     child: ListView.builder(
//                       controller: scrollController,
//                       itemCount: routeSegments.length,
//                       itemBuilder: (context, index) {
//                         final seg = routeSegments[index];
//                         final color = routeColors[seg['route']] ?? Colors.grey;
//                         return Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
//                                   const SizedBox(width: 8),
//                                   Text(seg['route'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                                 ],
//                               ),
//                               const SizedBox(height: 4),
//                               ...List<Widget>.from(
//                                 (seg['stops'] as List<String>).map((stop) {
//                                   final isLastStopInSegment = stop == seg['stops'].last;
//                                   final shouldShowInterchange = isLastStopInSegment && index < routeSegments.length - 1;

//                                   return Padding(
//                                     padding: const EdgeInsets.only(left: 24, top: 2, bottom: 2),
//                                     child: Row(
//                                       children: [
//                                         Icon(
//                                           shouldShowInterchange ? Icons.swap_horiz : Icons.circle,
//                                           size: shouldShowInterchange ? 18 : 10,
//                                           color: shouldShowInterchange ? Colors.red : color,
//                                         ),
//                                         const SizedBox(width: 6),
//                                         Text(
//                                           stop,
//                                           style: TextStyle(
//                                             fontWeight: shouldShowInterchange ? FontWeight.bold : FontWeight.normal,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 }),
//                               ),
//                               if (index < routeSegments.length - 1)
//                                 Padding(
//                                   padding: const EdgeInsets.only(left: 24, top: 4),
//                                   child: Text(
//                                     'Interchange at ${seg['stops'].last}',
//                                     style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
//                                   ),
//                                 ),
//                               const SizedBox(height: 12),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// --------------------------------------------------------------------------------
// bus showing version no eta
// import 'dart:convert';
// import 'dart:collection';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class RideMapPage extends StatefulWidget {
//   final String origin;
//   final String destination;

//   const RideMapPage({
//     super.key,
//     required this.origin,
//     required this.destination,
//   });

//   @override
//   State<RideMapPage> createState() => _RideMapPageState();
// }

// class _RideMapPageState extends State<RideMapPage> {
//   final supabase = SupabaseClient(
//     "https://ctocodgutltodufynrer.supabase.co", // replace with your Supabase URL
//     "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0b2NvZGd1dGx0b2R1ZnlucmVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg0NzA3NDYsImV4cCI6MjA3NDA0Njc0Nn0.EYuUWfS3ARTbKbSM79AbZa9QGuidSiC5POwQ9ugDuEw", // replace with your anon key
//   );

//   Map<String, List<String>> routes = {};
//   Map<String, List<String>> adjacency = {};
//   Map<String, Map<String, List<String>>> edgeRoutes = {};
//   Map<String, LatLng> stopsMap = {};
//   List<Map<String, dynamic>> routeSegments = [];
//   Map<String, String> busRouteMap = {};
//   String errorText = '';

//   late GoogleMapController _mapController;
//   final Set<Marker> _markers = {};
//   final Map<String, Color> routeColors = {};

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   /// Load stops, routes, and bus info
//   Future<void> _loadData() async {
//     try {
//       // Load stops
//       final stopsList = json.decode(
//         await rootBundle.loadString('assets/home_bus_stops.json'),
//       ) as List<dynamic>;
//       for (var stop in stopsList) {
//         final mapStop = stop as Map<String, dynamic>;
//         final name = mapStop['name'];
//         final lat = mapStop['lat'];
//         final lng = mapStop['lng'];
//         if (name != null && lat != null && lng != null) {
//           stopsMap[name] = LatLng(lat.toDouble(), lng.toDouble());
//         }
//       }

//       // Load routes
//       final routesData = json.decode(
//         await rootBundle.loadString('assets/routes.json'),
//       ) as List<dynamic>;
//       final colors = [
//         Colors.pink,
//         Colors.blue,
//         Colors.green,
//         Colors.orange,
//         Colors.purple,
//         Colors.teal,
//         Colors.red,
//         Colors.brown,
//         Colors.indigo,
//         Colors.cyan,
//       ];
//       int colorIndex = 0;
//       for (var r in routesData) {
//         final mapR = r as Map<String, dynamic>;
//         final name = mapR['route'];
//         final stopsList = mapR['stops'];
//         if (name == null || stopsList == null) continue;
//         routes[name.toString()] = List<String>.from(stopsList);
//         routeColors[name.toString()] = colors[colorIndex % colors.length];
//         colorIndex++;
//       }

//       _buildGraph();
//       _computeRoute(widget.origin, widget.destination);
//       _addMarkers();

//       // Load buses.json
//       final busesData = json.decode(
//         await rootBundle.loadString('assets/buses.json'),
//       ) as List<dynamic>;
//       for (var b in busesData) {
//         final mapB = b as Map<String, dynamic>;
//         final busId = mapB['busId'];
//         final route = mapB['route'];
//         if (busId != null && route != null) {
//           busRouteMap[busId] = route;
//         }
//       }

//       // Load driver markers after everything is ready
//       await _loadDriverLocations();
//     } catch (e) {
//       setState(() => errorText = 'Error loading data: $e');
//     }
//   }

//   /// Load driver locations from Supabase
//   Future<void> _loadDriverLocations() async {
//     if (routeSegments.isEmpty) return;

//     try {
//       final response = await supabase.from('driver_locations').select();
//       print("DEBUG Supabase raw response: $response");
//       if (response is! List) return;

//       final allRouteStops = <String>{};
//       for (var seg in routeSegments) {
//         final stops = List<String>.from(seg['stops']);
//         allRouteStops.addAll(stops);
//       }

//       for (var row in response) {
//         final busId = row['busId']?.toString() ?? '';
//         final routeName = busRouteMap[busId];
//         if (routeName == null) continue;

//         // Only show bus if it has any stop in the computed path
//         final busStops = routes[routeName] ?? [];
//         if (!busStops.any((s) => allRouteStops.contains(s))) continue;

//         final latRaw = row['lat'];
//         final lngRaw = row['lng'];
//         if (latRaw == null || lngRaw == null) continue;

//         final lat = latRaw is double ? latRaw : double.tryParse(latRaw.toString());
//         final lng = lngRaw is double ? lngRaw : double.tryParse(lngRaw.toString());
//         if (lat == null || lng == null) continue;

//         _markers.add(Marker(
//           markerId: MarkerId('driver_$busId'),
//           position: LatLng(lat, lng),
//           infoWindow: InfoWindow(title: 'Bus $busId'),
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
//         ));
//       }

//       setState(() {});
//     } catch (e) {
//       print("Error fetching driver locations: $e");
//     }
//   }

//   void _addMarkers() {
//     _markers.removeWhere((m) => !m.markerId.value.startsWith('driver_'));

//     if (stopsMap.containsKey(widget.origin)) {
//       _markers.add(Marker(
//         markerId: const MarkerId('origin'),
//         position: stopsMap[widget.origin]!,
//         infoWindow: InfoWindow(title: widget.origin),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//       ));
//     }
//     if (stopsMap.containsKey(widget.destination)) {
//       _markers.add(Marker(
//         markerId: const MarkerId('destination'),
//         position: stopsMap[widget.destination]!,
//         infoWindow: InfoWindow(title: widget.destination),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       ));
//     }

//     for (var segment in routeSegments) {
//       final stops = List<String>.from(segment['stops']);
//       for (var stop in stops) {
//         if (stop != widget.origin && stop != widget.destination) {
//           final pos = stopsMap[stop];
//           if (pos != null) {
//             _markers.add(Marker(
//               markerId: MarkerId(stop),
//               position: pos,
//               infoWindow: InfoWindow(title: stop),
//               icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
//             ));
//           }
//         }
//       }
//     }

//     setState(() {});
//   }

//   void _buildGraph() {
//     adjacency = {};
//     edgeRoutes = {};
//     for (var r in routes.entries) {
//       final routeName = r.key;
//       final stops = r.value;
//       for (int i = 0; i < stops.length - 1; i++) {
//         final a = stops[i];
//         final b = stops[i + 1];

//         adjacency[a] = (adjacency[a] ?? [])..add(b);
//         adjacency[b] = (adjacency[b] ?? [])..add(a);

//         edgeRoutes[a] = (edgeRoutes[a] ?? {});
//         edgeRoutes[a]![b] = (edgeRoutes[a]![b] ?? [])..add(routeName);

//         edgeRoutes[b] = (edgeRoutes[b] ?? {});
//         edgeRoutes[b]![a] = (edgeRoutes[b]![a] ?? [])..add(routeName);
//       }
//     }
//   }

//   void _computeRoute(String origin, String destination) {
//     if (!adjacency.containsKey(origin) || !adjacency.containsKey(destination)) {
//       setState(() => errorText = 'Origin or destination not found');
//       return;
//     }

//     final parent = <String, String>{};
//     final visited = <String>{};
//     final queue = Queue<String>()..add(origin);
//     visited.add(origin);
//     bool found = false;

//     while (queue.isNotEmpty) {
//       final current = queue.removeFirst();
//       if (current == destination) {
//         found = true;
//         break;
//       }
//       for (var neighbor in adjacency[current]!) {
//         if (!visited.contains(neighbor)) {
//           visited.add(neighbor);
//           parent[neighbor] = current;
//           queue.add(neighbor);
//         }
//       }
//     }

//     if (!found) {
//       setState(() => errorText = 'No route found');
//       return;
//     }

//     final path = <String>[];
//     String cur = destination;
//     while (true) {
//       path.add(cur);
//       if (cur == origin) break;
//       cur = parent[cur]!;
//     }

//     final pathStops = path.reversed.toList();
//     routeSegments = [];
//     String? currentRoute;
//     List<String> currentSegment = [];

//     for (int i = 0; i < pathStops.length - 1; i++) {
//       final a = pathStops[i];
//       final b = pathStops[i + 1];
//       final possibleRoutes = edgeRoutes[a]![b]!;

//       String chosenRoute;
//       if (currentRoute != null && possibleRoutes.contains(currentRoute)) {
//         chosenRoute = currentRoute;
//       } else {
//         chosenRoute = possibleRoutes.first;
//       }

//       if (currentRoute == null) {
//         currentRoute = chosenRoute;
//         currentSegment.add(a);
//         currentSegment.add(b);
//       } else if (chosenRoute == currentRoute) {
//         if (currentSegment.last != a) currentSegment.add(a);
//         currentSegment.add(b);
//       } else {
//         routeSegments.add({'route': currentRoute!, 'stops': List<String>.from(currentSegment)});
//         currentRoute = chosenRoute;
//         currentSegment = [a, b];
//       }
//     }

//     if (currentSegment.isNotEmpty) {
//       routeSegments.add({'route': currentRoute!, 'stops': List<String>.from(currentSegment)});
//     }

//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (errorText.isNotEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Ride Map')),
//         body: Center(child: Text(errorText)),
//       );
//     }

//     if (stopsMap.isEmpty || routeSegments.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Ride Map')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     final originLatLng = stopsMap[widget.origin]!;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Ride Map')),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: CameraPosition(target: originLatLng, zoom: 14),
//             markers: _markers,
//             zoomControlsEnabled: true,
//             myLocationButtonEnabled: true,
//             onMapCreated: (controller) {
//               _mapController = controller;
//             },
//           ),

//           // Draggable sheet
//           Positioned.fill(
//             child: Align(
//               alignment: Alignment.bottomCenter,
//               child: DraggableScrollableSheet(
//                 initialChildSize: 0.25,
//                 minChildSize: 0.1,
//                 maxChildSize: 0.6,
//                 builder: (context, scrollController) {
//                   return Container(
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//                       boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))],
//                     ),
//                     child: ListView.builder(
//                       controller: scrollController,
//                       itemCount: routeSegments.length,
//                       itemBuilder: (context, index) {
//                         final seg = routeSegments[index];
//                         final color = routeColors[seg['route']] ?? Colors.grey;
//                         final stops = List<String>.from(seg['stops']);
//                         return Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
//                                   const SizedBox(width: 8),
//                                   Text(seg['route'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                                 ],
//                               ),
//                               const SizedBox(height: 4),
//                               ...stops.map((stop) {
//                                 final isLastStopInSegment = stop == stops.last;
//                                 final shouldShowInterchange = isLastStopInSegment && index < routeSegments.length - 1;
//                                 return Padding(
//                                   padding: const EdgeInsets.only(left: 24, top: 2, bottom: 2),
//                                   child: Row(
//                                     children: [
//                                       Icon(
//                                         shouldShowInterchange ? Icons.swap_horiz : Icons.circle,
//                                         size: shouldShowInterchange ? 18 : 10,
//                                         color: shouldShowInterchange ? Colors.red : color,
//                                       ),
//                                       const SizedBox(width: 6),
//                                       Text(
//                                         stop,
//                                         style: TextStyle(fontWeight: shouldShowInterchange ? FontWeight.bold : FontWeight.normal),
//                                       ),
//                                     ],
//                                   ),
//                                 );
//                               }).toList(),
//                               if (index < routeSegments.length - 1)
//                                 Padding(
//                                   padding: const EdgeInsets.only(left: 24, top: 4),
//                                   child: Text(
//                                     'Interchange at ${stops.last}',
//                                     style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
//                                   ),
//                                 ),
//                               const SizedBox(height: 12),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



// --------------------------------------------------------------------------------
// bus marker bus icon with eta 1

// import 'dart:convert';
// import 'dart:collection';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'dart:math';

// class RideMapPage extends StatefulWidget {
//   final String origin;
//   final String destination;

//   const RideMapPage({
//     super.key,
//     required this.origin,
//     required this.destination,
//   });

//   @override
//   State<RideMapPage> createState() => _RideMapPageState();
// }

// class _RideMapPageState extends State<RideMapPage> {
//   final supabase = SupabaseClient(
//     "https://vwwnsxssuezenssvqvks.supabase.co", // replace with your Supabase URL
// "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3d25zeHNzdWV6ZW5zc3ZxdmtzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MTEwMzUsImV4cCI6MjA3NDA4NzAzNX0.ln-zc7m4ghiRZTI6hY8HBKtbSZrCD7AtQVbc8Utt4Go", // replace with your anon key
//   );


//   Map<String, List<String>> routes = {};
//   Map<String, List<String>> adjacency = {};
//   Map<String, Map<String, List<String>>> edgeRoutes = {};
//   Map<String, LatLng> stopsMap = {};
//   List<Map<String, dynamic>> routeSegments = [];
//   Map<String, String> busRouteMap = {};
//   Map<String, String> busNumberMap = {};
//   Map<String, LatLng> busPositions = {};
//   String errorText = '';

//   late GoogleMapController _mapController;
//   final Set<Marker> _markers = {};
//   late BitmapDescriptor busIcon;

//   final Map<String, Color> routeColors = {};

//   @override
//   void initState() {
//     super.initState();
//     _createBusEmojiIcon();
//     _loadData();
//   }

//   /// Create 🚌 emoji as BitmapDescriptor
//   Future<void> _createBusEmojiIcon() async {
//   final int size = 100; // bigger canvas
//   final recorder = ui.PictureRecorder();
//   final canvas = Canvas(recorder);
//   final textPainter = TextPainter(
//     textDirection: TextDirection.ltr,
//     text: TextSpan(
//       text: '🚌',
//       style: TextStyle(fontSize: 80), // bigger font
//     ),
//   );
//   textPainter.layout();
//   textPainter.paint(canvas, Offset(0, 0));
//   final picture = recorder.endRecording();
//   final img = await picture.toImage(size, size);
//   final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
//   final bitmap = bytes!.buffer.asUint8List();
//   busIcon = BitmapDescriptor.fromBytes(bitmap);
// }

//   Future<void> _loadData() async {
//     try {
//       // Load stops
//       final stopsList = json.decode(
//         await rootBundle.loadString('assets/home_bus_stops.json'),
//       ) as List<dynamic>;
//       for (var stop in stopsList) {
//         final mapStop = stop as Map<String, dynamic>;
//         final name = mapStop['name'];
//         final lat = mapStop['lat'];
//         final lng = mapStop['lng'];
//         if (name != null && lat != null && lng != null) {
//           stopsMap[name] = LatLng(lat.toDouble(), lng.toDouble());
//         }
//       }

//       // Load routes
//       final routesData = json.decode(
//         await rootBundle.loadString('assets/routes.json'),
//       ) as List<dynamic>;
//       final colors = [
//         Colors.pink,
//         Colors.blue,
//         Colors.green,
//         Colors.orange,
//         Colors.purple,
//         Colors.teal,
//         Colors.red,
//         Colors.brown,
//         Colors.indigo,
//         Colors.cyan,
//       ];
//       int colorIndex = 0;
//       for (var r in routesData) {
//         final mapR = r as Map<String, dynamic>;
//         final name = mapR['route'];
//         final stopsList = mapR['stops'];
//         if (name == null || stopsList == null) continue;
//         routes[name.toString()] = List<String>.from(stopsList);
//         routeColors[name.toString()] = colors[colorIndex % colors.length];
//         colorIndex++;
//       }

//       _buildGraph();
//       _computeRoute(widget.origin, widget.destination);
//       _addMarkers();

//       // Load buses.json
//       final busesData = json.decode(
//         await rootBundle.loadString('assets/buses.json'),
//       ) as List<dynamic>;
//       for (var b in busesData) {
//         final mapB = b as Map<String, dynamic>;
//         final busId = mapB['busId'];
//         final route = mapB['route'];
//         final numberPlate = mapB['numberPlate'];
//         if (busId != null && route != null) {
//           busRouteMap[busId] = route;
//         }
//         if (busId != null && numberPlate != null) {
//           busNumberMap[busId] = numberPlate;
//         }
//       }

//       // Load bus positions from Supabase
//       await _loadDriverLocations();
//     } catch (e) {
//       setState(() => errorText = 'Error loading data: $e');
//     }
//   }

//   Future<void> _loadDriverLocations() async {
//     if (routeSegments.isEmpty) return;

//     try {
//       final response = await supabase.from('driver_locations').select();
//       print("DEBUG Supabase raw response: $response");
//       if (response is! List) return;

//       final allRouteStops = <String>{};
//       for (var seg in routeSegments) {
//         final stops = List<String>.from(seg['stops']);
//         allRouteStops.addAll(stops);
//       }

//       for (var row in response) {
//         final busId = row['busId']?.toString() ?? '';
//         final routeName = busRouteMap[busId];
//         if (routeName == null) continue;

//         final busStops = routes[routeName] ?? [];
//         if (!busStops.any((s) => allRouteStops.contains(s))) continue;

//         final latRaw = row['lat'];
//         final lngRaw = row['lng'];
//         if (latRaw == null || lngRaw == null) continue;

//         final lat = latRaw is double ? latRaw : double.tryParse(latRaw.toString());
//         final lng = lngRaw is double ? lngRaw : double.tryParse(lngRaw.toString());
//         if (lat == null || lng == null) continue;

//         busPositions[busId] = LatLng(lat, lng);

//         final eta = _computeETA(busId, widget.origin);

//         _markers.add(Marker(
//           markerId: MarkerId('driver_$busId'),
//           position: LatLng(lat, lng),
//           infoWindow: InfoWindow(
//             title: 'Bus ${busNumberMap[busId] ?? busId}',
//             snippet: 'ETA: $eta min',
//           ),
//           icon: busIcon,
//         ));
//       }

//       setState(() {});
//     } catch (e) {
//       print("Error fetching driver locations: $e");
//     }
//   }

//   void _addMarkers() {
//     _markers.removeWhere((m) => !m.markerId.value.startsWith('driver_'));

//     if (stopsMap.containsKey(widget.origin)) {
//       _markers.add(Marker(
//         markerId: const MarkerId('origin'),
//         position: stopsMap[widget.origin]!,
//         infoWindow: InfoWindow(title: widget.origin),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//       ));
//     }

//     if (stopsMap.containsKey(widget.destination)) {
//       _markers.add(Marker(
//         markerId: const MarkerId('destination'),
//         position: stopsMap[widget.destination]!,
//         infoWindow: InfoWindow(title: widget.destination),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       ));
//     }

//     for (var segment in routeSegments) {
//       final stops = List<String>.from(segment['stops']);
//       for (var stop in stops) {
//         if (stop != widget.origin && stop != widget.destination) {
//           final pos = stopsMap[stop];
//           if (pos != null) {
//             _markers.add(Marker(
//               markerId: MarkerId(stop),
//               position: pos,
//               infoWindow: InfoWindow(title: stop),
//               icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
//             ));
//           }
//         }
//       }
//     }

//     setState(() {});
//   }

//   void _buildGraph() {
//     adjacency = {};
//     edgeRoutes = {};
//     for (var r in routes.entries) {
//       final routeName = r.key;
//       final stops = r.value;
//       for (int i = 0; i < stops.length - 1; i++) {
//         final a = stops[i];
//         final b = stops[i + 1];

//         adjacency[a] = (adjacency[a] ?? [])..add(b);
//         adjacency[b] = (adjacency[b] ?? [])..add(a);

//         edgeRoutes[a] = (edgeRoutes[a] ?? {});
//         edgeRoutes[a]![b] = (edgeRoutes[a]![b] ?? [])..add(routeName);

//         edgeRoutes[b] = (edgeRoutes[b] ?? {});
//         edgeRoutes[b]![a] = (edgeRoutes[b]![a] ?? [])..add(routeName);
//       }
//     }
//   }

//   void _computeRoute(String origin, String destination) {
//     if (!adjacency.containsKey(origin) || !adjacency.containsKey(destination)) {
//       setState(() => errorText = 'Origin or destination not found');
//       return;
//     }

//     final parent = <String, String>{};
//     final visited = <String>{};
//     final queue = Queue<String>()..add(origin);
//     visited.add(origin);
//     bool found = false;

//     while (queue.isNotEmpty) {
//       final current = queue.removeFirst();
//       if (current == destination) {
//         found = true;
//         break;
//       }
//       for (var neighbor in adjacency[current]!) {
//         if (!visited.contains(neighbor)) {
//           visited.add(neighbor);
//           parent[neighbor] = current;
//           queue.add(neighbor);
//         }
//       }
//     }

//     if (!found) {
//       setState(() => errorText = 'No route found');
//       return;
//     }

//     final path = <String>[];
//     String cur = destination;
//     while (true) {
//       path.add(cur);
//       if (cur == origin) break;
//       cur = parent[cur]!;
//     }

//     final pathStops = path.reversed.toList();
//     routeSegments = [];
//     String? currentRoute;
//     List<String> currentSegment = [];

//     for (int i = 0; i < pathStops.length - 1; i++) {
//       final a = pathStops[i];
//       final b = pathStops[i + 1];
//       final possibleRoutes = edgeRoutes[a]![b]!;

//       String chosenRoute;
//       if (currentRoute != null && possibleRoutes.contains(currentRoute)) {
//         chosenRoute = currentRoute;
//       } else {
//         chosenRoute = possibleRoutes.first;
//       }

//       if (currentRoute == null) {
//         currentRoute = chosenRoute;
//         currentSegment.add(a);
//         currentSegment.add(b);
//       } else if (chosenRoute == currentRoute) {
//         if (currentSegment.last != a) currentSegment.add(a);
//         currentSegment.add(b);
//       } else {
//         routeSegments.add({'route': currentRoute!, 'stops': currentSegment});
//         currentRoute = chosenRoute;
//         currentSegment = [a, b];
//       }
//     }

//     if (currentSegment.isNotEmpty) {
//       routeSegments.add({'route': currentRoute!, 'stops': currentSegment});
//     }

//     setState(() {});
//   }

//   int _computeETA(String busId, String originStop) {
//     final busLatLng = busPositions[busId];
//     final originLatLng = stopsMap[originStop];
//     if (busLatLng == null || originLatLng == null) return 0;

//     final distanceKm = _calculateDistance(busLatLng, originLatLng);
//     const speedKmH = 30.0;
//     return (distanceKm / speedKmH * 60).ceil();
//   }

//   double _calculateDistance(LatLng from, LatLng to) {
//     const R = 6371;
//     final dLat = _deg2rad(to.latitude - from.latitude);
//     final dLng = _deg2rad(to.longitude - from.longitude);
//     final a = sin(dLat / 2) * sin(dLat / 2) +
//         cos(_deg2rad(from.latitude)) *
//             cos(_deg2rad(to.latitude)) *
//             sin(dLng / 2) *
//             sin(dLng / 2);
//     final c = 2 * atan2(sqrt(a), sqrt(1 - a));
//     return R * c;
//   }

//   double _deg2rad(double deg) => deg * (pi / 180);

//   @override
//   Widget build(BuildContext context) {
//     if (errorText.isNotEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Ride Map')),
//         body: Center(child: Text(errorText)),
//       );
//     }

//     if (stopsMap.isEmpty || routeSegments.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Ride Map')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     final originLatLng = stopsMap[widget.origin]!;
//     final destLatLng = stopsMap[widget.destination]!;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Ride Map')),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: CameraPosition(target: originLatLng, zoom: 14),
//             markers: _markers,
//             zoomControlsEnabled: true,
//             myLocationButtonEnabled: true,
//             onMapCreated: (controller) => _mapController = controller,
//           ),
//           Positioned.fill(
//             child: Align(
//               alignment: Alignment.bottomCenter,
//               child: DraggableScrollableSheet(
//                 initialChildSize: 0.25,
//                 minChildSize: 0.1,
//                 maxChildSize: 0.6,
//                 builder: (context, scrollController) {
//                   return Container(
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//                       boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))],
//                     ),
//                     child: ListView.builder(
//                       controller: scrollController,
//                       itemCount: routeSegments.length,
//                       itemBuilder: (context, index) {
//                         final seg = routeSegments[index];
//                         final color = routeColors[seg['route']] ?? Colors.grey;
//                         final stops = List<String>.from(seg['stops']);
//                         return Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
//                                   const SizedBox(width: 8),
//                                   Text(seg['route'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                                 ],
//                               ),
//                               const SizedBox(height: 4),
//                               ...stops.map((stop) {
//                                 final isLastStopInSegment = stop == stops.last;
//                                 final shouldShowInterchange = isLastStopInSegment && index < routeSegments.length - 1;
//                                 return Padding(
//                                   padding: const EdgeInsets.only(left: 24, top: 2, bottom: 2),
//                                   child: Row(
//                                     children: [
//                                       Icon(
//                                         shouldShowInterchange ? Icons.swap_horiz : Icons.circle,
//                                         size: shouldShowInterchange ? 18 : 10,
//                                         color: shouldShowInterchange ? Colors.red : color,
//                                       ),
//                                       const SizedBox(width: 6),
//                                       Text(stop, style: TextStyle(fontWeight: shouldShowInterchange ? FontWeight.bold : FontWeight.normal)),
//                                     ],
//                                   ),
//                                 );
//                               }).toList(),
//                               if (index < routeSegments.length - 1)
//                                 Padding(
//                                   padding: const EdgeInsets.only(left: 24, top: 4),
//                                   child: Text('Interchange at ${stops.last}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue)),
//                                 ),
//                               const SizedBox(height: 12),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


// import 'dart:convert';
// import 'dart:collection';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'dart:math';

// class RideMapPage extends StatefulWidget {
//   final String origin;
//   final String destination;

//   const RideMapPage({
//     super.key,
//     required this.origin,
//     required this.destination,
//   });

//   @override
//   State<RideMapPage> createState() => _RideMapPageState();
// }

// class _RideMapPageState extends State<RideMapPage> {
//   Map<String, List<String>> routes = {};
//   Map<String, List<String>> adjacency = {};
//   Map<String, Map<String, List<String>>> edgeRoutes = {};
//   Map<String, LatLng> stopsMap = {};
//   List<Map<String, dynamic>> routeSegments = [];
//   Map<String, String> busRouteMap = {};
//   Map<String, String> busNumberMap = {};
//   Map<String, LatLng> busPositions = {};
//   String errorText = '';

//   late GoogleMapController _mapController;
//   final Set<Marker> _markers = {};
//   late BitmapDescriptor busIcon;

//   final Map<String, Color> routeColors = {};

//   @override
//   void initState() {
//     super.initState();
//     _createBusEmojiIcon();
//     _loadData();
//   }

//   /// Create 🚌 emoji as BitmapDescriptor
//   Future<void> _createBusEmojiIcon() async {
//     final int size = 100; // bigger canvas
//     final recorder = ui.PictureRecorder();
//     final canvas = Canvas(recorder);
//     final textPainter = TextPainter(
//       textDirection: TextDirection.ltr,
//       text: const TextSpan(
//         text: '🚌',
//         style: TextStyle(fontSize: 80), // bigger font
//       ),
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, const Offset(0, 0));
//     final picture = recorder.endRecording();
//     final img = await picture.toImage(size, size);
//     final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
//     final bitmap = bytes!.buffer.asUint8List();
//     busIcon = BitmapDescriptor.fromBytes(bitmap);
//   }

//   Future<void> _loadData() async {
//     try {
//       // Load stops
//       final stopsList = json.decode(
//         await rootBundle.loadString('assets/home_bus_stops.json'),
//       ) as List<dynamic>;
//       for (var stop in stopsList) {
//         final mapStop = stop as Map<String, dynamic>;
//         final name = mapStop['name'];
//         final lat = mapStop['lat'];
//         final lng = mapStop['lng'];
//         if (name != null && lat != null && lng != null) {
//           stopsMap[name] = LatLng(lat.toDouble(), lng.toDouble());
//         }
//       }

//       // Load routes
//       final routesData = json.decode(
//         await rootBundle.loadString('assets/routes.json'),
//       ) as List<dynamic>;
//       final colors = [
//         Colors.pink,
//         Colors.blue,
//         Colors.green,
//         Colors.orange,
//         Colors.purple,
//         Colors.teal,
//         Colors.red,
//         Colors.brown,
//         Colors.indigo,
//         Colors.cyan,
//       ];
//       int colorIndex = 0;
//       for (var r in routesData) {
//         final mapR = r as Map<String, dynamic>;
//         final name = mapR['route'];
//         final stopsList = mapR['stops'];
//         if (name == null || stopsList == null) continue;
//         routes[name.toString()] = List<String>.from(stopsList);
//         routeColors[name.toString()] = colors[colorIndex % colors.length];
//         colorIndex++;
//       }

//       // Build graph only after routes loaded
//       _buildGraph();

//       // Compute route only if origin and destination exist
//       if (stopsMap.containsKey(widget.origin) &&
//           stopsMap.containsKey(widget.destination)) {
//         _computeRoute(widget.origin, widget.destination);
//       } else {
//         setState(() {
//           errorText = "Origin or destination not found in stops.";
//         });
//         return;
//       }

//       // Add markers after route is computed
//       _addMarkers();

//       // Load buses.json
//       final busesData = json.decode(
//         await rootBundle.loadString('assets/buses.json'),
//       ) as List<dynamic>;
//       for (var b in busesData) {
//         final mapB = b as Map<String, dynamic>;
//         final busId = mapB['busId'];
//         final route = mapB['route'];
//         final numberPlate = mapB['numberPlate'];
//         if (busId != null && route != null) {
//           busRouteMap[busId] = route;
//         }
//         if (busId != null && numberPlate != null) {
//           busNumberMap[busId] = numberPlate;
//         }
//       }

//       // Load bus locations from local JSON
//       await _loadBusLocations();
//     } catch (e) {
//       setState(() => errorText = 'Error loading data: $e');
//     }
//   }

//   Future<void> _loadBusLocations() async {
//     if (routeSegments.isEmpty) return;

//     try {
//       final response = json.decode(
//         await rootBundle.loadString('assets/bus_location.json'),
//       ) as List<dynamic>;

//       final allRouteStops = <String>{};
//       for (var seg in routeSegments) {
//         final stops = List<String>.from(seg['stops']);
//         allRouteStops.addAll(stops);
//       }

//       for (var row in response) {
//         final busId = row['busId']?.toString() ?? '';
//         final routeName = busRouteMap[busId];
//         if (routeName == null) continue;

//         final busStops = routes[routeName] ?? [];
//         if (!busStops.any((s) => allRouteStops.contains(s))) continue;

//         final latRaw = row['lat'];
//         final lngRaw = row['lng'];
//         if (latRaw == null || lngRaw == null) continue;

//         final lat = latRaw is double ? latRaw : double.tryParse(latRaw.toString());
//         final lng = lngRaw is double ? lngRaw : double.tryParse(lngRaw.toString());
//         if (lat == null || lng == null) continue;

//         busPositions[busId] = LatLng(lat, lng);

//         final eta = _computeETA(busId, widget.origin);

//         _markers.add(Marker(
//           markerId: MarkerId('driver_$busId'),
//           position: LatLng(lat, lng),
//           infoWindow: InfoWindow(
//             title: 'Bus ${busNumberMap[busId] ?? busId}',
//             snippet: 'ETA: $eta min',
//           ),
//           icon: busIcon,
//         ));
//       }

//       setState(() {});
//     } catch (e) {
//       print("Error loading bus locations: $e");
//     }
//   }

//   void _addMarkers() {
//     _markers.removeWhere((m) => !m.markerId.value.startsWith('driver_'));

//     if (stopsMap.containsKey(widget.origin)) {
//       _markers.add(Marker(
//         markerId: const MarkerId('origin'),
//         position: stopsMap[widget.origin]!,
//         infoWindow: InfoWindow(title: widget.origin),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//       ));
//     }

//     if (stopsMap.containsKey(widget.destination)) {
//       _markers.add(Marker(
//         markerId: const MarkerId('destination'),
//         position: stopsMap[widget.destination]!,
//         infoWindow: InfoWindow(title: widget.destination),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       ));
//     }

//     for (var segment in routeSegments) {
//       final stops = List<String>.from(segment['stops']);
//       for (var stop in stops) {
//         if (stop != widget.origin && stop != widget.destination) {
//           final pos = stopsMap[stop];
//           if (pos != null) {
//             _markers.add(Marker(
//               markerId: MarkerId(stop),
//               position: pos,
//               infoWindow: InfoWindow(title: stop),
//               icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
//             ));
//           }
//         }
//       }
//     }

//     setState(() {});
//   }

//   void _buildGraph() {
//     adjacency = {};
//     edgeRoutes = {};
//     for (var r in routes.entries) {
//       final routeName = r.key;
//       final stops = r.value;
//       for (int i = 0; i < stops.length - 1; i++) {
//         final a = stops[i];
//         final b = stops[i + 1];

//         adjacency[a] = (adjacency[a] ?? [])..add(b);
//         adjacency[b] = (adjacency[b] ?? [])..add(a);

//         edgeRoutes[a] = (edgeRoutes[a] ?? {});
//         edgeRoutes[a]![b] = (edgeRoutes[a]![b] ?? [])..add(routeName);

//         edgeRoutes[b] = (edgeRoutes[b] ?? {});
//         edgeRoutes[b]![a] = (edgeRoutes[b]![a] ?? [])..add(routeName);
//       }
//     }
//   }

//   void _computeRoute(String origin, String destination) {
//     if (!adjacency.containsKey(origin) || !adjacency.containsKey(destination)) {
//       setState(() => errorText = 'Origin or destination not found');
//       return;
//     }

//     final parent = <String, String>{};
//     final visited = <String>{};
//     final queue = Queue<String>()..add(origin);
//     visited.add(origin);
//     bool found = false;

//     while (queue.isNotEmpty) {
//       final current = queue.removeFirst();
//       if (current == destination) {
//         found = true;
//         break;
//       }
//       for (var neighbor in adjacency[current]!) {
//         if (!visited.contains(neighbor)) {
//           visited.add(neighbor);
//           parent[neighbor] = current;
//           queue.add(neighbor);
//         }
//       }
//     }

//     if (!found) {
//       setState(() => errorText = 'No route found');
//       return;
//     }

//     final path = <String>[];
//     String cur = destination;
//     while (true) {
//       path.add(cur);
//       if (cur == origin) break;
//       cur = parent[cur]!;
//     }

//     final pathStops = path.reversed.toList();
//     routeSegments = [];
//     String? currentRoute;
//     List<String> currentSegment = [];

//     for (int i = 0; i < pathStops.length - 1; i++) {
//       final a = pathStops[i];
//       final b = pathStops[i + 1];
//       final possibleRoutes = edgeRoutes[a]![b]!;

//       String chosenRoute;
//       if (currentRoute != null && possibleRoutes.contains(currentRoute)) {
//         chosenRoute = currentRoute;
//       } else {
//         chosenRoute = possibleRoutes.first;
//       }

//       if (currentRoute == null) {
//         currentRoute = chosenRoute;
//         currentSegment.add(a);
//         currentSegment.add(b);
//       } else if (chosenRoute == currentRoute) {
//         if (currentSegment.last != a) currentSegment.add(a);
//         currentSegment.add(b);
//       } else {
//         routeSegments.add({'route': currentRoute!, 'stops': currentSegment});
//         currentRoute = chosenRoute;
//         currentSegment = [a, b];
//       }
//     }

//     if (currentSegment.isNotEmpty) {
//       routeSegments.add({'route': currentRoute!, 'stops': currentSegment});
//     }

//     setState(() {});
//   }

//   int _computeETA(String busId, String originStop) {
//     final busLatLng = busPositions[busId];
//     final originLatLng = stopsMap[originStop];
//     if (busLatLng == null || originLatLng == null) return 0;

//     final distanceKm = _calculateDistance(busLatLng, originLatLng);
//     const speedKmH = 30.0;
//     return (distanceKm / speedKmH * 60).ceil();
//   }

//   double _calculateDistance(LatLng from, LatLng to) {
//     const R = 6371;
//     final dLat = _deg2rad(to.latitude - from.latitude);
//     final dLng = _deg2rad(to.longitude - from.longitude);
//     final a = sin(dLat / 2) * sin(dLat / 2) +
//         cos(_deg2rad(from.latitude)) *
//             cos(_deg2rad(to.latitude)) *
//             sin(dLng / 2) *
//             sin(dLng / 2);
//     final c = 2 * atan2(sqrt(a), sqrt(1 - a));
//     return R * c;
//   }

//   double _deg2rad(double deg) => deg * (pi / 180);

//   @override
//   Widget build(BuildContext context) {
//     if (errorText.isNotEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Ride Map')),
//         body: Center(child: Text(errorText)),
//       );
//     }

//     if (stopsMap.isEmpty || routeSegments.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Ride Map')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     final originLatLng = stopsMap[widget.origin]!;
//     final destLatLng = stopsMap[widget.destination]!;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Ride Map')),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: CameraPosition(target: originLatLng, zoom: 14),
//             markers: _markers,
//             zoomControlsEnabled: true,
//             myLocationButtonEnabled: true,
//             onMapCreated: (controller) => _mapController = controller,
//           ),
//           Positioned.fill(
//             child: Align(
//               alignment: Alignment.bottomCenter,
//               child: DraggableScrollableSheet(
//                 initialChildSize: 0.25,
//                 minChildSize: 0.1,
//                 maxChildSize: 0.6,
//                 builder: (context, scrollController) {
//                   return Container(
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//                       boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))],
//                     ),
//                     child: ListView.builder(
//                       controller: scrollController,
//                       itemCount: routeSegments.length,
//                       itemBuilder: (context, index) {
//                         final seg = routeSegments[index];
//                         final color = routeColors[seg['route']] ?? Colors.grey;
//                         final stops = List<String>.from(seg['stops']);
//                         return Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
//                                   const SizedBox(width: 8),
//                                   Text(seg['route'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                                 ],
//                               ),
//                               const SizedBox(height: 4),
//                               ...stops.map((stop) {
//                                 final isLastStopInSegment = stop == stops.last;
//                                 final shouldShowInterchange = isLastStopInSegment && index < routeSegments.length - 1;
//                                 return Padding(
//                                   padding: const EdgeInsets.only(left: 24, top: 2, bottom: 2),
//                                   child: Row(
//                                     children: [
//                                       Icon(
//                                         shouldShowInterchange ? Icons.swap_horiz : Icons.circle,
//                                         size: shouldShowInterchange ? 18 : 10,
//                                         color: shouldShowInterchange ? Colors.red : color,
//                                       ),
//                                       const SizedBox(width: 6),
//                                       Text(stop, style: TextStyle(fontWeight: shouldShowInterchange ? FontWeight.bold : FontWeight.normal)),
//                                     ],
//                                   ),
//                                 );
//                               }).toList(),
//                               if (index < routeSegments.length - 1)
//                                 Padding(
//                                   padding: const EdgeInsets.only(left: 24, top: 4),
//                                   child: Text('Interchange at ${stops.last}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue)),
//                                 ),
//                               const SizedBox(height: 12),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }




import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class RideMapPage extends StatefulWidget {
  final String origin;
  final String destination;

  const RideMapPage({
    super.key,
    required this.origin,
    required this.destination,
  });

  @override
  State<RideMapPage> createState() => _RideMapPageState();
}

class _RideMapPageState extends State<RideMapPage> {
  Map<String, List<String>> routes = {};
  Map<String, List<String>> adjacency = {};
  Map<String, Map<String, List<String>>> edgeRoutes = {};
  Map<String, LatLng> stopsMap = {};
  List<Map<String, dynamic>> routeSegments = [];
  Map<String, String> busRouteMap = {};
  Map<String, String> busNumberMap = {};
  Map<String, LatLng> busPositions = {};
  String errorText = '';

  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  late BitmapDescriptor busIcon;

  final Map<String, Color> routeColors = {};

  @override
  void initState() {
    super.initState();
    _initSetup();
  }

  Future<void> _initSetup() async {
    await _createBusEmojiIcon(); // Ensure 🚌 icon is ready first
    await _loadData();           // Then load routes, stops, buses, bus locations
  }

  /// Create 🚌 emoji as BitmapDescriptor
  Future<void> _createBusEmojiIcon() async {
    final int size = 100; // bigger canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: const TextSpan(
        text: '🚌',
        style: TextStyle(fontSize: 80),
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(0, 0));
    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final bitmap = bytes!.buffer.asUint8List();
    busIcon = BitmapDescriptor.fromBytes(bitmap);
  }

  Future<void> _loadData() async {
    try {
      // Load stops
      final stopsList = json.decode(
        await rootBundle.loadString('assets/home_bus_stops.json'),
      ) as List<dynamic>;
      for (var stop in stopsList) {
        final mapStop = stop as Map<String, dynamic>;
        final name = mapStop['name'];
        final lat = mapStop['lat'];
        final lng = mapStop['lng'];
        if (name != null && lat != null && lng != null) {
          stopsMap[name] = LatLng(lat.toDouble(), lng.toDouble());
        }
      }

      // Load routes
      final routesData = json.decode(
        await rootBundle.loadString('assets/routes.json'),
      ) as List<dynamic>;
      final colors = [
        Colors.pink,
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.teal,
        Colors.red,
        Colors.brown,
        Colors.indigo,
        Colors.cyan,
      ];
      int colorIndex = 0;
      for (var r in routesData) {
        final mapR = r as Map<String, dynamic>;
        final name = mapR['route'];
        final stopsList = mapR['stops'];
        if (name == null || stopsList == null) continue;
        routes[name.toString()] = List<String>.from(stopsList);
        routeColors[name.toString()] = colors[colorIndex % colors.length];
        colorIndex++;
      }

      // Build graph and compute route
      _buildGraph();
      _computeRoute(widget.origin, widget.destination);
      _addMarkers();

      // Load buses.json
      final busesData = json.decode(
        await rootBundle.loadString('assets/buses.json'),
      ) as List<dynamic>;
      for (var b in busesData) {
        final mapB = b as Map<String, dynamic>;
        final busId = mapB['busId'];
        final route = mapB['route'];
        final numberPlate = mapB['numberPlate'];
        if (busId != null && route != null) {
          busRouteMap[busId] = route;
        }
        if (busId != null && numberPlate != null) {
          busNumberMap[busId] = numberPlate;
        }
      }

      // Load bus positions
      await _loadBusLocations();
    } catch (e) {
      setState(() => errorText = 'Error loading data: $e');
    }
  }

  Future<void> _loadBusLocations() async {
    if (routeSegments.isEmpty) return;

    try {
      final response = json.decode(
        await rootBundle.loadString('assets/bus_location.json'),
      ) as List<dynamic>;

      print("Loaded ${response.length} bus locations"); // 🔍 debug

      for (var row in response) {
        final busId = row['busId']?.toString() ?? '';
        final routeName = busRouteMap[busId];
        if (routeName == null) continue;

        final lat = (row['lat'] as num).toDouble();
        final lng = (row['lng'] as num).toDouble();

        final pos = LatLng(lat, lng);
        busPositions[busId] = pos;

        final eta = _computeETA(busId, widget.origin);

        final marker = Marker(
          markerId: MarkerId('driver_$busId'),
          position: pos,
          infoWindow: InfoWindow(
            title: 'Bus ${busNumberMap[busId] ?? busId}',
            snippet: 'ETA: $eta min',
          ),
          icon: busIcon,
        );

        // Update bus markers safely
        _markers.removeWhere((m) => m.markerId.value == 'driver_$busId');
        _markers.add(marker);

        print("Added bus $busId at $pos"); // 🔍 debug
      }

      setState(() {});
    } catch (e) {
      print("Error loading bus locations: $e");
    }
  }

  void _addMarkers() {
    // Keep bus markers, only re-add stops and origin/destination
    _markers.removeWhere((m) =>
        !m.markerId.value.startsWith('driver_')); // preserve buses

    if (stopsMap.containsKey(widget.origin)) {
      _markers.add(Marker(
        markerId: const MarkerId('origin'),
        position: stopsMap[widget.origin]!,
        infoWindow: InfoWindow(title: widget.origin),
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    if (stopsMap.containsKey(widget.destination)) {
      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: stopsMap[widget.destination]!,
        infoWindow: InfoWindow(title: widget.destination),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    for (var segment in routeSegments) {
      final stops = List<String>.from(segment['stops']);
      for (var stop in stops) {
        if (stop != widget.origin && stop != widget.destination) {
          final pos = stopsMap[stop];
          if (pos != null) {
            _markers.add(Marker(
              markerId: MarkerId(stop),
              position: pos,
              infoWindow: InfoWindow(title: stop),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
            ));
          }
        }
      }
    }

    setState(() {});
  }

  void _buildGraph() {
    adjacency = {};
    edgeRoutes = {};
    for (var r in routes.entries) {
      final routeName = r.key;
      final stops = r.value;
      for (int i = 0; i < stops.length - 1; i++) {
        final a = stops[i];
        final b = stops[i + 1];

        adjacency[a] = (adjacency[a] ?? [])..add(b);
        adjacency[b] = (adjacency[b] ?? [])..add(a);

        edgeRoutes[a] = (edgeRoutes[a] ?? {});
        edgeRoutes[a]![b] = (edgeRoutes[a]![b] ?? [])..add(routeName);

        edgeRoutes[b] = (edgeRoutes[b] ?? {});
        edgeRoutes[b]![a] = (edgeRoutes[b]![a] ?? [])..add(routeName);
      }
    }
  }

  void _computeRoute(String origin, String destination) {
    if (!adjacency.containsKey(origin) || !adjacency.containsKey(destination)) {
      setState(() => errorText = 'Origin or destination not found');
      return;
    }

    final parent = <String, String>{};
    final visited = <String>{};
    final queue = Queue<String>()..add(origin);
    visited.add(origin);
    bool found = false;

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current == destination) {
        found = true;
        break;
      }
      for (var neighbor in adjacency[current]!) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          parent[neighbor] = current;
          queue.add(neighbor);
        }
      }
    }

    if (!found) {
      setState(() => errorText = 'No route found');
      return;
    }

    final path = <String>[];
    String cur = destination;
    while (true) {
      path.add(cur);
      if (cur == origin) break;
      cur = parent[cur]!;
    }

    final pathStops = path.reversed.toList();
    routeSegments = [];
    String? currentRoute;
    List<String> currentSegment = [];

    for (int i = 0; i < pathStops.length - 1; i++) {
      final a = pathStops[i];
      final b = pathStops[i + 1];
      final possibleRoutes = edgeRoutes[a]![b]!;

      String chosenRoute;
      if (currentRoute != null && possibleRoutes.contains(currentRoute)) {
        chosenRoute = currentRoute;
      } else {
        chosenRoute = possibleRoutes.first;
      }

      if (currentRoute == null) {
        currentRoute = chosenRoute;
        currentSegment.add(a);
        currentSegment.add(b);
      } else if (chosenRoute == currentRoute) {
        if (currentSegment.last != a) currentSegment.add(a);
        currentSegment.add(b);
      } else {
        routeSegments.add({'route': currentRoute!, 'stops': currentSegment});
        currentRoute = chosenRoute;
        currentSegment = [a, b];
      }
    }

    if (currentSegment.isNotEmpty) {
      routeSegments.add({'route': currentRoute!, 'stops': currentSegment});
    }

    setState(() {});
  }

  int _computeETA(String busId, String originStop) {
    final busLatLng = busPositions[busId];
    final originLatLng = stopsMap[originStop];
    if (busLatLng == null || originLatLng == null) return 0;

    final distanceKm = _calculateDistance(busLatLng, originLatLng);
    const speedKmH = 30.0;
    return (distanceKm / speedKmH * 60).ceil();
  }

  double _calculateDistance(LatLng from, LatLng to) {
    const R = 6371;
    final dLat = _deg2rad(to.latitude - from.latitude);
    final dLng = _deg2rad(to.longitude - from.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(from.latitude)) *
            cos(_deg2rad(to.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    if (errorText.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ride Map')),
        body: Center(child: Text(errorText)),
      );
    }

    if (stopsMap.isEmpty || routeSegments.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ride Map')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final originLatLng = stopsMap[widget.origin]!;
    final destLatLng = stopsMap[widget.destination]!;

    return Scaffold(
      appBar: AppBar(title: const Text('Ride Map')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: originLatLng, zoom: 14),
            markers: _markers,
            zoomControlsEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DraggableScrollableSheet(
                initialChildSize: 0.25,
                minChildSize: 0.1,
                maxChildSize: 0.6,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))],
                    ),
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: routeSegments.length,
                      itemBuilder: (context, index) {
                        final seg = routeSegments[index];
                        final color = routeColors[seg['route']] ?? Colors.grey;
                        final stops = List<String>.from(seg['stops']);
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Text(seg['route'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ...stops.map((stop) {
                                final isLastStopInSegment = stop == stops.last;
                                final shouldShowInterchange = isLastStopInSegment && index < routeSegments.length - 1;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 24, top: 2, bottom: 2),
                                  child: Row(
                                    children: [
                                      Icon(
                                        shouldShowInterchange ? Icons.swap_horiz : Icons.circle,
                                        size: shouldShowInterchange ? 18 : 10,
                                        color: shouldShowInterchange ? Colors.red : color,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(stop, style: TextStyle(fontWeight: shouldShowInterchange ? FontWeight.bold : FontWeight.normal)),
                                    ],
                                  ),
                                );
                              }).toList(),
                              if (index < routeSegments.length - 1)
                                Padding(
                                  padding: const EdgeInsets.only(left: 24, top: 4),
                                  child: Text('Interchange at ${stops.last}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue)),
                                ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
