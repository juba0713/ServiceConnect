import 'dart:async';
import 'dart:math'; // Import math library for distance calculation
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/service_response.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/main.dart';


import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSample extends StatefulWidget {
  final double latitude;
  final double longitude;
  final List<ServiceLocationResponse> serviceLocations;

  const MapSample({super.key, required this.latitude, required this.longitude, required this.serviceLocations});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  late CameraPosition _initialPosition;
  String? _selectedCategory;
  String? _selectedServiceName; // New variable for the selected service name
  ServiceLocationResponse? _nearestService; // To store the nearest service

  bool? isInitial = true;

  @override
  void initState() {
    super.initState();
    _initialPosition = CameraPosition(
      target: LatLng(widget.latitude, widget.longitude),
      zoom: 14.4746,
    );

    // Default filters
    _selectedCategory = "All Categories";
    _selectedServiceName = "All Services";
  }


  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371; // Earth's radius in kilometers
  final double dLat = _degToRad(lat2 - lat1);
  final double dLon = _degToRad(lon2 - lon1);
  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  final double distance = earthRadius * c;

  // Log calculated distance for debugging
  print("Haversine Distance: ${distance.toStringAsFixed(2)} km");
  return distance;
}


  double _degToRad(double degree) {
    return degree * pi / 180;
  }

  // Define _goToTheLake method before the build method
  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;

    // Print current location to debug
    print("Moving camera to: Lat: ${widget.latitude}, Lng: ${widget.longitude}");

    // Move the camera to the current location
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(widget.latitude, widget.longitude),
      zoom: 19.151926040649414,
    )));
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {};
    Set<Circle> circles = {};

    // Extract category names from the serviceLocations
    List<String> categoryNames = widget.serviceLocations
        .map((service) => service.categoryName ?? "Unknown Category")
        .toSet()  // Remove duplicates
        .toList();

    // Add a "All Categories" option
    categoryNames.insert(0, "All Categories");

    // Filtered service names based on selected category
    List<String> serviceNames = widget.serviceLocations
        .where((service) => _selectedCategory == "All Categories" || service.categoryName == _selectedCategory)
        .map((service) => service.serviceName ?? "Unknown Service")
        .toSet() // Remove duplicates
        .toList();

        

    // Add a "All Services" option
    serviceNames.insert(0, "All Services");

    double minDistance = double.infinity;
    ServiceLocationResponse? nearestService;

    // Define a radius around the current location (e.g., 5 kilometers)
  const double radiusInKm = 5.0;

  // Create a list to hold sorted services with distances
List<Map<String, dynamic>> servicesWithDistances = [];

for (var service in widget.serviceLocations) {
  if ((_selectedCategory == "All Categories" || service.categoryName == _selectedCategory) &&
      (_selectedServiceName == "All Services" || service.serviceName == _selectedServiceName) || isInitial == true) {
    if (service.serviceAddressMapping != null) {
      for (var mapping in service.serviceAddressMapping!) {
        try {
          double? latitude = double.tryParse(mapping.providerAddressMapping!.latitude ?? "");
          double? longitude = double.tryParse(mapping.providerAddressMapping!.longitude ?? "");

          if (latitude != null && longitude != null) {
            // Validate latitude and longitude
            if (latitude.abs() > 90 || longitude.abs() > 180) {
              print("Invalid coordinates for service: ${service.serviceName}");
              continue; // Skip invalid coordinates
            }

            // Calculate distance from user location
            double distance = _calculateDistance(widget.latitude, widget.longitude, latitude, longitude);

            servicesWithDistances.add({
              'service': service,
              'distance': distance,
              'latitude': latitude,
              'longitude': longitude,
            });

            // Determine marker color
            BitmapDescriptor markerColor = BitmapDescriptor.defaultMarkerWithHue(
                distance <= radiusInKm ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed);

            // Add marker
            markers.add(Marker(
              markerId: MarkerId('${service.serviceId}-${markers.length}'),
              position: LatLng(latitude, longitude),
              icon: markerColor,
              infoWindow: InfoWindow(
                title: service.serviceName,
                snippet: "${distance.toStringAsFixed(2)} km away",
              ),
            ));

            isInitial = false;
          } else {
            print("Null or unparsable coordinates for service: ${service.serviceName}");
          }
        } catch (e) {
          print("Error processing service location for service: ${service.serviceName}. Error: $e");
        }
      }
    } else {
      print("serviceAddressMapping is null for service: ${service.serviceName}");
    }
  }
}


// Sort services by distance
servicesWithDistances.sort((a, b) => a['distance'].compareTo(b['distance']));

    // Store the nearest service to display below the dropdown
    if (_selectedCategory != "All Categories") {
      _nearestService = nearestService;
    } else {
      _nearestService = null;
    }

    // Add a marker for the current location
    markers.add(Marker(
      markerId: MarkerId("current_location"),
      position: LatLng(widget.latitude, widget.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Current location marker (blue)
      infoWindow: const InfoWindow(title: "Your Location"),
    ));

    // Define a radius around the current location (e.g., 5 kilometers)
    const double radiusInMeters = 10000; // Radius in meters

    // Add a circle around the current location
    circles.add(Circle(
      circleId: CircleId("current_location_radius"),
      center: LatLng(widget.latitude, widget.longitude),
      radius: radiusInMeters,
      strokeColor: Colors.blue.withOpacity(0.5), // Circle border color
      strokeWidth: 2, // Border width
      fillColor: Colors.blue.withOpacity(0.2), // Circle fill color
    ));
    

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: Colors.blueAccent,
      ),
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          // Google Map widget
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: markers,
            circles: circles,
            padding: EdgeInsets.only(
              right: 10, // Adjust this value to move the zoom controls closer to the center horizontally
              bottom: 135, // Adjust this value to move the zoom controls higher vertically
            ),
          ),
          // Positioned Category Dropdown (absolute position)
          Positioned(
            top: 20,
            left: 30,
            right: 30,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: DropdownButton<String>(
                hint: const Text('Select Category'),
                value: _selectedCategory,
                isExpanded: true,
                items: categoryNames.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category,
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                    _selectedServiceName = "All Services";
                  });
                },
                underline: SizedBox(),
              ),
            ),
          ),
          // Positioned Service Name Dropdown (below the category dropdown)
          Positioned(
            top: 80,
            left: 30,
            right: 30,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: DropdownButton<String>(
                hint: const Text('Select Service'),
                value: _selectedServiceName,
                isExpanded: true,
                items: serviceNames.map((serviceName) {
                  return DropdownMenuItem<String>(
                    value: serviceName,
                    child: Text(
                      serviceName,
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedServiceName = newValue;
                  });
                },
                underline: SizedBox(),
              ),
            ),
          ),
          // FloatingActionButton
          Positioned(
            bottom: 150,
            left: 16.0,
            child: FloatingActionButton.extended(
              onPressed: _goToTheLake,
              label: const Text('Go to My Location'),
              icon: const Icon(Icons.location_searching),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (() {
                  // Calculate distances and sort the service locations directly
                  final sortedServices = widget.serviceLocations
                      .where((service) {
                        // Filter by category and service name
                        bool matchesCategory = _selectedCategory == "All Categories" || service.categoryName == _selectedCategory;
                        bool matchesService = _selectedServiceName == "All Services" || service.serviceName == _selectedServiceName;
                        return matchesCategory && matchesService;
                      })
                      .toList();

                  // Attach distances and sort by distance
                  sortedServices.sort((a, b) {
                    double distanceA = _calculateServiceDistance(a);
                    double distanceB = _calculateServiceDistance(b);
                    return distanceA.compareTo(distanceB);
                  });

                  return sortedServices.map<Widget>((service) {
  double distance = _calculateServiceDistance(service);
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: GestureDetector(
      onTap: () {
        appStore.setLoading(true);
        // Add your onTap functionality here
        print('Service clicked: ${service.serviceName}');
        hideKeyboard(context);
        ServiceDetailScreen(serviceId: service.serviceId!).launch(context).then((value) {
          setStatusBarColor(context.primaryColor);
        });
      },
      child: IntrinsicWidth(
        child: Container(
          padding: EdgeInsets.all(16),
          constraints: BoxConstraints(
            minWidth: 150,
            maxWidth: 350,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (service.categoryImage != null && service.categoryImage!.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(right: 10),
                  width: 120,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(service.categoryImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.categoryName ?? "Unknown Category",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      service.serviceName ?? "Unknown Service",
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "${distance.toStringAsFixed(2)} km away",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}).toList();

                })(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  double _calculateServiceDistance(ServiceLocationResponse service) {
  try {
    if (service.serviceAddressMapping != null && service.serviceAddressMapping!.isNotEmpty) {
      var firstMapping = service.serviceAddressMapping!.first;
      double? latitude = double.tryParse(firstMapping.providerAddressMapping!.latitude ?? "");
      double? longitude = double.tryParse(firstMapping.providerAddressMapping!.longitude ?? "");

      if (latitude != null && longitude != null) {
        // Debug log to verify lat/lon values
        print("Calculating distance: User(${widget.latitude}, ${widget.longitude}) -> Service($latitude, $longitude)");

        double distance = _calculateDistance(widget.latitude, widget.longitude, latitude, longitude);

        // Log the calculated distance for verification
        print("Distance calculated: ${distance.toStringAsFixed(2)} km");

        return distance;
      } else {
        print("Invalid latitude or longitude for service: ${service.serviceName}");
      }
    } else {
      print("serviceAddressMapping is empty for service: ${service.serviceName}");
    }
  } catch (e) {
    print("Error calculating distance for service: ${service.serviceName}. Error: $e");
  }
  return double.infinity; // Return a large distance if unable to calculate
}

}


