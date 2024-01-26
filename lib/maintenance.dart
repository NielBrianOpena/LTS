import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ltsalpha/dashboard.dart';
import 'add_maintenance.dart';
import 'constant.dart';
import 'container_widget.dart';
import 'delivery.dart';
import 'package:http/http.dart' as http;

class MaintenancePage extends StatefulWidget {
  final String driverId;
  final String driverUserName;

  const MaintenancePage({required this.driverId, required this.driverUserName});

  @override
  _MaintenancePageState createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  int _selectedIndex = 2;

  final List<Widget> _widgetOptions = <Widget>[
    ContainerWidget(icon: Icons.person, text: 'Profile'),
    ContainerWidget(icon: Icons.local_shipping, text: 'Deliveries'),
    ContainerWidget(icon: Icons.build, text: 'Maintenance'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DashboardPage(driverUserName: widget.driverUserName),
        ),
      );
    }
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryPage(
              driverUserName: widget.driverUserName,
              driverId: widget.driverId),
        ),
      );
    }
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MaintenancePage(
              driverUserName: widget.driverUserName,
              driverId: widget.driverId),
        ),
      );
    }
  }

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

  Future<List<Map<String, dynamic>>> fetchMaintenanceData() async {
    List<Map<String, dynamic>> truckingData = await fetchTruckingData();
    List<Map<String, dynamic>> truckData = await fetchTruckData();
    try {
      final response = await http.get(
        Uri.parse(
            '${Constants.apiUrl}/api/get-maintenance-data/${widget.driverId}'),
      );

      if (response.statusCode == 200) {
        dynamic responseData = json.decode(response.body);
        List<dynamic> maintenanceData = (responseData['maintenance'] is List)
            ? responseData['maintenance']
            : [];

        maintenanceData.forEach((maintenance) {
          Map<String, dynamic>? matchingTrucking = truckingData.firstWhere(
                (trucking) =>
            trucking['trucking_id'] == maintenance['trucking_id'],
            orElse: () => {},
          );
          maintenance['trucking_name'] = matchingTrucking['trucking_name'];
        });

        maintenanceData.forEach((maintenance) {
          Map<String, dynamic>? matchingTruck = truckData.firstWhere(
                (truck_unit) => truck_unit['truck_id'] == maintenance['truck_id'],
            orElse: () => {},
          );
          maintenance['truck_plateno'] = matchingTruck['truck_plateno'];
        });

        return maintenanceData.cast<Map<String, dynamic>>().toList();
      } else {
        throw Exception('Failed to load maintenance data');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }
  void showProofModal(String receiptProof) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Set to true to make the sheet take up the whole screen
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.network(
                  '${Constants.apiUrl}$receiptProof',
                  fit: BoxFit.contain, // Ensure the image fits within the container
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.lightGreen, // Set the background color to green
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white, // Set the text color to white
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void navigateToAddMaintenancePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMaintenancePage(
            driverUsername: widget.driverUserName,
            driverId: widget.driverId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            'Maintenance Dashboard',
            style: TextStyle(
              fontFamily: 'YourFontFamily', // Replace 'YourFontFamily' with your desired font family
              fontSize: 18.0, // Adjust the font size as needed
              fontWeight: FontWeight.bold, // Adjust the font weight as needed
              color: Colors.black, // Set the text color to white
            ),
          ),
        ),
        backgroundColor: Colors.lightGreen,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(Duration(seconds: 1)); // Simulate a delay for better visual feedback
          setState(() {}); // Trigger widget rebuild
          // Fetch maintenance data
          await fetchMaintenanceData();
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchMaintenanceData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('No recorded maintenance'));
            } else {
              List<dynamic> maintenanceData = snapshot.data!;
              return ListView.builder(
                itemCount: maintenanceData.length,
                itemBuilder: (context, index) {
                  var maintenance = maintenanceData[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Maintenance ID: ${maintenance['maintenance_id']}'),
                          Text('Truck ID: ${maintenance['truck_plateno']}'),
                          Text('Trucking ID: ${maintenance['trucking_name']}'),
                          SizedBox(
                            height: 8.0,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              showProofModal(maintenance['receipt_proof']);
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.lightGreen, // Set the background color to green
                            ),
                            child: Text(
                              'View Receipt',
                              style: TextStyle(
                                color: Colors.white, // Set the text color to white
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAddMaintenancePage,
        child: Icon(Icons.add),
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
    );
  }
}
