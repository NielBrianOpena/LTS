import 'package:flutter/material.dart';
import 'completed_delivery.dart';
import 'constant.dart';
import 'container_widget.dart';
import 'dashboard.dart';
import 'maintenance.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ongoing_delivery.dart';

class DeliveryPage extends StatefulWidget {
  final String driverId;
  final String driverUserName;

  DeliveryPage({Key? key, required this.driverId, required this.driverUserName}) : super(key: key);

  @override
  _DeliveryPageState createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  int _selectedIndex = 1;

  final List<Widget> _widgetOptions = <Widget>[
    ContainerWidget(icon: Icons.person, text: 'Profile'),
    ContainerWidget(icon: Icons.local_shipping, text: 'Deliveries'),
    ContainerWidget(icon: Icons.build, text: 'Maintenance'),
  ];

  Future<List<Map<String, dynamic>>> fetchTruckingData() async {
    final response = await http.get(
      Uri.parse('${Constants.apiUrl}/api/get-trucking-data'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>().toList();
    } else {
      throw Exception('Failed to load trucking data');
    }
  }

  Future<List<Map<String, dynamic>>> fetchTruckData() async {
    final response = await http.get(
      Uri.parse('${Constants.apiUrl}/api/get-truck-data'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>().toList();
    } else {
      throw Exception('Failed to load truck data');
    }
  }

  Future<List<dynamic>> fetchDeliveries() async {
    try {
      List<Map<String, dynamic>> truckingData = await fetchTruckingData();
      List<Map<String, dynamic>> truckData = await fetchTruckData();

      final response = await http.get(
        Uri.parse('${Constants.apiUrl}/api/get-deliveries-data/${widget.driverId}'),
      );

      if (response.statusCode == 200) {
        dynamic responseData = json.decode(response.body);

        List<dynamic> deliveries = (responseData['deliveries'] is List) ? responseData['deliveries'] : [];

        List<dynamic> filteredDeliveries = deliveries.where((delivery) => delivery['status_id'] == 0).toList();

        filteredDeliveries.forEach((delivery) {
          Map<String, dynamic>? matchingTrucking = truckingData.firstWhere(
                (trucking) => trucking['trucking_id'] == delivery['trucking_id'],
            orElse: () => {},
          );
          delivery['trucking_name'] = matchingTrucking['trucking_name'];
        });

        filteredDeliveries.forEach((delivery) {
          Map<String, dynamic>? matchingTruck = truckData.firstWhere(
                (truck_unit) => truck_unit['truck_id'] == delivery['truck_id'],
            orElse: () => {},
          );
          delivery['truck_plateno'] = matchingTruck['truck_plateno'];
        });

        return filteredDeliveries;
      } else {
        throw Exception('Failed to load deliveries data');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<List<dynamic>> fetchDeliveriesCom() async {
    try {
      List<Map<String, dynamic>> truckingData = await fetchTruckingData();
      List<Map<String, dynamic>> truckData = await fetchTruckData();

      final response = await http.get(
        Uri.parse('${Constants.apiUrl}/api/get-deliveries-data/${widget.driverId}'),
      );

      if (response.statusCode == 200) {
        dynamic responseData = json.decode(response.body);

        List<dynamic> deliveries = (responseData['deliveries'] is List) ? responseData['deliveries'] : [];

        List<dynamic> filteredDeliveriesCom = deliveries.where((delivery) => delivery['status_id'] == 1).toList();

        filteredDeliveriesCom.forEach((delivery) {
          Map<String, dynamic>? matchingTruckingCom = truckingData.firstWhere(
                (trucking) => trucking['trucking_id'] == delivery['trucking_id'],
            orElse: () => {},
          );

          filteredDeliveriesCom.forEach((delivery) {
            Map<String, dynamic>? matchingTruck = truckData.firstWhere(
                  (truck_unit) => truck_unit['truck_id'] == delivery['truck_id'],
              orElse: () => {},
            );
            delivery['truck_plateno'] = matchingTruck['truck_plateno'];
          });

          delivery['trucking_name'] = matchingTruckingCom['trucking_name'];
        });

        return filteredDeliveriesCom;
      } else {
        throw Exception('Failed to load deliveries data');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<void> _refreshData() async {
    try {
      List<dynamic> ongoingDeliveries = await fetchDeliveries();
      List<dynamic> ComDeliveries = await fetchDeliveriesCom();
      setState(() {
        // Update the state variables with the new data
        // For example, if you have a variable called 'ongoingDeliveries', update it with the new list
        // ongoingDeliveries = fetchedOngoingDeliveries;
        // Same for 'ComDeliveries'
      });
    } catch (error) {
      print('Error refreshing data: $error');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(driverUserName: widget.driverUserName),
        ),
      );
    }
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryPage(driverUserName: widget.driverUserName, driverId: widget.driverId),
        ),
      );
    }
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MaintenancePage(driverUserName: widget.driverUserName, driverId: widget.driverId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Center(
            child: Text(
              'Delivery Dashboard',
              style: TextStyle(
                fontFamily: 'YourFontFamily', // Replace 'YourFontFamily' with your desired font family
                fontSize: 18.0, // Adjust the font size as needed
                fontWeight: FontWeight.bold, // Adjust the font weight as needed
              ),
            ),
          ),
          backgroundColor: Colors.lightGreen,
          bottom: TabBar(
            tabs: [
              Tab(
                text: 'Ongoing Deliveries',
              ),
              Tab(
                text: 'Completed Deliveries',
              ),
            ],
            indicatorColor: Colors.white, // Set the indicator color to white
            labelColor: Colors.white, // Set the text color of the selected tab to white
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            // Handle the refresh action here (e.g., refetch data)
            await fetchDeliveries();
            await fetchDeliveriesCom();
          },
          child: TabBarView(
            children: [
              RefreshIndicator(
                onRefresh: _refreshData,
                child: FutureBuilder<List<dynamic>>(
                  future: fetchDeliveries(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('No Ongoing Deliveries'));
                    } else {
                      List<dynamic> ongoingDeliveries = snapshot.data!;

                      if (ongoingDeliveries.isEmpty) {
                        return Center(child: Text('No ongoing Deliveries'));
                      } else {
                        return ListView.builder(
                          itemCount: ongoingDeliveries.length,
                          itemBuilder: (context, index) {
                            var delivery = ongoingDeliveries[index];
                            return Card(
                              elevation: 3,
                              margin: EdgeInsets.all(8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Has No: ${delivery['hasno']}',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Business Name: ${delivery['bussiness_name']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'Trucker Name: ${delivery['trucking_name']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'Truck Plate No: ${delivery['truck_plateno']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'Delivery Address: ${delivery['delivery_address']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'Contact Person: ${delivery['contact_person']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'Dispatched By: ${delivery['dispatch_by']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => OngoingDeliveryInfoPage(
                                              deliveryId: delivery['delivery_id'].toString(),
                                              driverId: widget.driverId,
                                              driverUserName: widget.driverUserName,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        primary: Colors.lightGreen,
                                        onPrimary: Colors.white,
                                      ),
                                      child: Text('More Info'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    }
                  },
                ),
              ),
              RefreshIndicator(
                onRefresh: _refreshData,
                child: FutureBuilder<List<dynamic>>(
                  future: fetchDeliveriesCom(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('No Completed Deliveries'));
                    } else {
                      List<dynamic> ComDeliveries = snapshot.data!;

                      if (ComDeliveries.isEmpty) {
                        return Center(child: Text('No Completed Deliveries'));
                      } else {
                        return ListView.builder(
                          itemCount: ComDeliveries.length,
                          itemBuilder: (context, index) {
                            var delivery = ComDeliveries[index];
                            return Card(
                              elevation: 3,
                              margin: EdgeInsets.all(8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Has No: ${delivery['hasno']}',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Business Name: ${delivery['bussiness_name']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'Trucker Name: ${delivery['trucking_name']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'Truck Plate No: ${delivery['truck_plateno']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'Delivery Address: ${delivery['delivery_address']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'Contact Person: ${delivery['contact_person']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'Dispatched By: ${delivery['dispatch_by']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'Received By: ${delivery['receive_by']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CompletedDeliveryInfoPage(deliveryId: delivery['delivery_id'].toString()),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        primary: Colors.lightGreen,
                                        onPrimary: Colors.white,
                                      ),
                                      child: Text('More Info'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping),
              label: 'Deliveries',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build),
              label: 'Maintenance',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.lightGreen,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
