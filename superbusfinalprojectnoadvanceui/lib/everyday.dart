// import 'dart:convert';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:awesome_notifications/awesome_notifications.dart';

// class EverydayRidePage extends StatefulWidget {
//   const EverydayRidePage({super.key});

//   @override
//   State<EverydayRidePage> createState() => _EverydayRidePageState();
// }

// class _EverydayRidePageState extends State<EverydayRidePage> {
//   List<String> busStops = [];
//   String? selectedOrigin;
//   String? selectedDestination;
//   TimeOfDay? selectedTime;

//   List<dynamic> busLocations = [];
//   List<dynamic> buses = [];
//   List<dynamic> routes = [];

//   @override
//   void initState() {
//     super.initState();
//     initNotifications();
//     loadBusStops();
//     loadBusData();
//     loadSavedData();
//   }

//   void initNotifications() {
//     AwesomeNotifications().initialize(
//       null,
//       [
//         NotificationChannel(
//           channelKey: 'everyday_ride_channel',
//           channelName: 'Everyday Ride Notifications',
//           channelDescription: 'Notifications for your everyday ride',
//           defaultColor: Colors.blue,
//           importance: NotificationImportance.Max,
//           channelShowBadge: true,
//         ),
//       ],
//     );

//     AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
//   if (!isAllowed) {
//     // Show a dialog to ask user for permission
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Allow Notifications'),
//         content: const Text('We need your permission to send bus alerts.'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             child: const Text('Deny'),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               await AwesomeNotifications().requestPermissionToSendNotifications();
//             },
//             child: const Text('Allow'),
//           ),
//         ],
//       ),
//     );
//   }
// });

//   }

//   Future<void> showNotification(String message) async {
//     await AwesomeNotifications().createNotification(
//       content: NotificationContent(
//         id: 1,
//         channelKey: 'everyday_ride_channel',
//         title: 'Bus Alert',
//         body: message,
//       ),
//     );
//   }

//   Future<void> loadBusStops() async {
//     final String response = await rootBundle.loadString('assets/home_bus_stops.json');
//     final data = json.decode(response) as List<dynamic>;
//     setState(() {
//       busStops = data.map((e) => e['name'].toString()).toList();
//     });
//   }

//   Future<void> loadBusData() async {
//     final busLocationString = await rootBundle.loadString('assets/bus_location.json');
//     final busesString = await rootBundle.loadString('assets/buses.json');
//     final routesString = await rootBundle.loadString('assets/routes.json');

//     setState(() {
//       busLocations = json.decode(busLocationString);
//       buses = json.decode(busesString);
//       routes = json.decode(routesString);
//     });
//   }

//   Future<void> loadSavedData() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       selectedOrigin = prefs.getString('everyday_origin');
//       selectedDestination = prefs.getString('everyday_destination');
//       final hour = prefs.getInt('everyday_hour');
//       final minute = prefs.getInt('everyday_minute');
//       if (hour != null && minute != null) selectedTime = TimeOfDay(hour: hour, minute: minute);
//     });
//   }

//   Future<void> saveData() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (selectedOrigin != null) await prefs.setString('everyday_origin', selectedOrigin!);
//     if (selectedDestination != null) await prefs.setString('everyday_destination', selectedDestination!);
//     if (selectedTime != null) {
//       await prefs.setInt('everyday_hour', selectedTime!.hour);
//       await prefs.setInt('everyday_minute', selectedTime!.minute);
//     }
//   }

//   double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
//     const p = 0.017453292519943295;
//     final a = 0.5 -
//         cos((lat2 - lat1) * p) / 2 +
//         cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
//     return 12742 * asin(sqrt(a));
//   }

//   List<double> getLatLngForStop(String stop) {
//     final map = {
//       'bennett': [28.445, 77.583],
//       'omicron 1': [28.446, 77.584],
//       'gnida': [28.436, 77.576],
//       'delta 1': [28.437, 77.578],
//       'alpha 1': [28.438, 77.580],
//       'pari chowk': [28.439, 77.581],
//       'knowledge park': [28.440, 77.582],
//       'sector 146': [28.441, 77.583],
//       'sector 142': [28.442, 77.584],
//       'gn expressway': [28.443, 77.585],
//     };
//     return map[stop] ?? [28.445, 77.583];
//   }

//   void checkBusArrival() {
//     if (selectedOrigin == null || selectedDestination == null) return;

//     final matchingRoutes = routes.where((r) {
//       final stops = List<String>.from(r['stops']);
//       return stops.contains(selectedOrigin!) &&
//           stops.contains(selectedDestination!) &&
//           stops.indexOf(selectedOrigin!) < stops.indexOf(selectedDestination!);
//     }).toList();

//     if (matchingRoutes.isEmpty) {
//       showNotification("No buses found for your route!");
//       return;
//     }

//     for (var route in matchingRoutes) {
//       final routeName = route['route'];
//       final stops = List<String>.from(route['stops']);
//       final busesOnRoute = buses.where((b) => b['route'] == routeName).toList();

//       for (var bus in busesOnRoute) {
//         final busLoc = busLocations.firstWhere(
//           (bl) => bl['busId'] == bus['busId'],
//           orElse: () => null,
//         );

//         if (busLoc != null) {
//           final originLatLng = getLatLngForStop(selectedOrigin!);
//           final distance = calculateDistance(busLoc['lat'], busLoc['lng'], originLatLng[0], originLatLng[1]);
//           final eta = (distance * 3 * 60).toInt();
//           showNotification("Bus ${bus['numberPlate']} is arriving at $selectedOrigin in $eta minutes");
//         }
//       }
//     }
//   }

//   Future<void> pickTime() async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: selectedTime ?? TimeOfDay.now(),
//     );
//     if (picked != null) setState(() => selectedTime = picked);
//   }

//   void startEverydayRide() async {
//     if (selectedOrigin == null || selectedDestination == null || selectedTime == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select origin, destination, and time')),
//       );
//       return;
//     }
//     if (selectedOrigin == selectedDestination) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Origin and destination cannot be the same!')),
//       );
//       return;
//     }

//     await saveData();
//     checkBusArrival();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Everyday ride saved! Notifications enabled.')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Everyday Ride')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const Text('Origin', style: TextStyle(fontSize: 18)),
//             DropdownButton<String>(
//               isExpanded: true,
//               value: selectedOrigin,
//               hint: const Text('Select Origin Stop'),
//               items: busStops.map((stop) => DropdownMenuItem(value: stop, child: Text(stop))).toList(),
//               onChanged: (value) => setState(() => selectedOrigin = value),
//             ),
//             const SizedBox(height: 20),
//             const Text('Destination', style: TextStyle(fontSize: 18)),
//             DropdownButton<String>(
//               isExpanded: true,
//               value: selectedDestination,
//               hint: const Text('Select Destination Stop'),
//               items: busStops.map((stop) => DropdownMenuItem(value: stop, child: Text(stop))).toList(),
//               onChanged: (value) => setState(() => selectedDestination = value),
//             ),
//             const SizedBox(height: 20),
//             const Text('Time', style: TextStyle(fontSize: 18)),
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     selectedTime != null
//                         ? selectedTime!.format(context)
//                         : 'Select your preferred time',
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                 ),
//                 ElevatedButton(onPressed: pickTime, child: const Text('Pick Time')),
//               ],
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton(onPressed: startEverydayRide, child: const Text('Save & Notify')),
//           ],
//         ),
//       ),
//     );
//   }
// }






//    -----------------------------------------


import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class EverydayRidePage extends StatefulWidget {
  const EverydayRidePage({super.key});

  @override
  State<EverydayRidePage> createState() => _EverydayRidePageState();
}

class _EverydayRidePageState extends State<EverydayRidePage> {
  List<String> busStops = [];
  String? selectedOrigin;
  String? selectedDestination;
  TimeOfDay? selectedTime;

  List<dynamic> busLocations = [];
  List<dynamic> buses = [];
  List<dynamic> routes = [];

  Timer? etaTimer;

  @override
  void initState() {
    super.initState();
    initNotifications();
    loadBusStops();
    loadBusData();
    loadSavedData();
  }

  @override
  void dispose() {
    etaTimer?.cancel();
    super.dispose();
  }

  void initNotifications() {
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'everyday_ride_channel',
          channelName: 'Everyday Ride Notifications',
          channelDescription: 'Notifications for your everyday ride',
          defaultColor: Colors.blue,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
        ),
      ],
    );

    // Request permission
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Allow Notifications'),
            content: const Text('We need your permission to send bus alerts.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: const Text('Deny')),
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await AwesomeNotifications().requestPermissionToSendNotifications();
                  },
                  child: const Text('Allow')),
            ],
          ),
        );
      }
    });
  }

  Future<void> showNotification(String message) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'everyday_ride_channel',
        title: 'Bus Alert',
        body: message,
      ),
    );
  }

  Future<void> loadBusStops() async {
    final String response = await rootBundle.loadString('assets/home_bus_stops.json');
    final data = json.decode(response) as List<dynamic>;
    setState(() {
      busStops = data.map((e) => e['name'].toString()).toList();
    });
  }

  Future<void> loadBusData() async {
    final busLocationString = await rootBundle.loadString('assets/bus_location.json');
    final busesString = await rootBundle.loadString('assets/buses.json');
    final routesString = await rootBundle.loadString('assets/routes.json');

    setState(() {
      busLocations = json.decode(busLocationString);
      buses = json.decode(busesString);
      routes = json.decode(routesString);
    });
  }

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedOrigin = prefs.getString('everyday_origin');
      selectedDestination = prefs.getString('everyday_destination');
      final hour = prefs.getInt('everyday_hour');
      final minute = prefs.getInt('everyday_minute');
      if (hour != null && minute != null) selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    if (selectedOrigin != null) await prefs.setString('everyday_origin', selectedOrigin!);
    if (selectedDestination != null) await prefs.setString('everyday_destination', selectedDestination!);
    if (selectedTime != null) {
      await prefs.setInt('everyday_hour', selectedTime!.hour);
      await prefs.setInt('everyday_minute', selectedTime!.minute);
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // distance in km
  }

  List<double> getLatLngForStop(String stop) {
    final map = {
      'bennett': [28.445, 77.583],
      'omicron 1': [28.446, 77.584],
      'gnida': [28.436, 77.576],
      'delta 1': [28.437, 77.578],
      'alpha 1': [28.438, 77.580],
      'pari chowk': [28.439, 77.581],
      'knowledge park': [28.440, 77.582],
      'sector 146': [28.441, 77.583],
      'sector 142': [28.442, 77.584],
      'gn expressway': [28.443, 77.585],
    };
    return map[stop] ?? [28.445, 77.583];
  }

  void startEverydayRide() async {
    if (selectedOrigin == null || selectedDestination == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select origin, destination, and time')),
      );
      return;
    }
    if (selectedOrigin == selectedDestination) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Origin and destination cannot be the same!')),
      );
      return;
    }

    await saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Everyday ride saved! Notifications enabled.')),
    );

    // Start periodic bus check
    etaTimer?.cancel();
    etaTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      checkBusArrival();
    });

    // Also check immediately
    checkBusArrival();
  }

  void checkBusArrival() {
    if (selectedOrigin == null || selectedDestination == null) return;

    final matchingRoutes = routes.where((r) {
      final stops = List<String>.from(r['stops']);
      return stops.contains(selectedOrigin!) &&
          stops.contains(selectedDestination!) &&
          stops.indexOf(selectedOrigin!) < stops.indexOf(selectedDestination!);
    }).toList();

    if (matchingRoutes.isEmpty) {
      showNotification("No buses found for your route!");
      return;
    }

    for (var route in matchingRoutes) {
      final routeName = route['route'];
      final busesOnRoute = buses.where((b) => b['route'] == routeName).toList();

      for (var bus in busesOnRoute) {
        final busLoc = busLocations.firstWhere(
          (bl) => bl['busId'] == bus['busId'],
          orElse: () => null,
        );

        if (busLoc != null) {
          final originLatLng = getLatLngForStop(selectedOrigin!);
          final distance = calculateDistance(busLoc['lat'], busLoc['lng'], originLatLng[0], originLatLng[1]);
          const busSpeedKmph = 20; // realistic average speed
          final eta = (distance / busSpeedKmph * 60).toInt(); // in minutes

          if (eta <= 0) {
            showNotification("Bus ${bus['numberPlate']} has arrived at $selectedOrigin!");
          } else {
            showNotification("Bus ${bus['numberPlate']} is arriving at $selectedOrigin in $eta minutes");
          }
        }
      }
    }
  }

  Future<void> pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Everyday Ride')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Origin', style: TextStyle(fontSize: 18)),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedOrigin,
              hint: const Text('Select Origin Stop'),
              items: busStops.map((stop) => DropdownMenuItem(value: stop, child: Text(stop))).toList(),
              onChanged: (value) => setState(() => selectedOrigin = value),
            ),
            const SizedBox(height: 20),
            const Text('Destination', style: TextStyle(fontSize: 18)),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedDestination,
              hint: const Text('Select Destination Stop'),
              items: busStops.map((stop) => DropdownMenuItem(value: stop, child: Text(stop))).toList(),
              onChanged: (value) => setState(() => selectedDestination = value),
            ),
            const SizedBox(height: 20),
            const Text('Time', style: TextStyle(fontSize: 18)),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedTime != null
                        ? selectedTime!.format(context)
                        : 'Select your preferred time',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(onPressed: pickTime, child: const Text('Pick Time')),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: startEverydayRide, child: const Text('Save & Notify')),
          ],
        ),
      ),
    );
  }
}
