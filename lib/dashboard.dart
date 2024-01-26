import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:ltsalpha/login.dart';
import 'package:permission_handler/permission_handler.dart';
import 'container_widget.dart';
import 'constant.dart';
import 'delivery.dart';
import 'edit_profile_pic.png.dart';
import 'maintenance.dart';

class DashboardPage extends StatefulWidget {
  final String driverUserName;

  DashboardPage({required this.driverUserName});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Map<String, dynamic>> driverDataFuture = fetchData();
  late Future<
      List<Map<String, dynamic>>> truckingDataFuture = fetchTruckingData();
  late File _image;
  var driverId = '';
  int _selectedIndex = 0;
  late Map<String, dynamic> driverData;

  final List<Widget> _widgetOptions = <Widget>[
    ContainerWidget(icon: Icons.person, text: 'Profile'),
    ContainerWidget(icon: Icons.local_shipping, text: 'Deliveries'),
    ContainerWidget(icon: Icons.build, text: 'Maintenance'),
  ];

  Future<Map<String, dynamic>> fetchData() async {
    final response = await http.get(
      Uri.parse(
          '${Constants.apiUrl}/api/get-driver-row/${widget.driverUserName}'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      driverId = data['driver_id'].toString();
      print('Driver ID: $driverId');
      return data;
    } else {
      throw Exception('Failed to load driver data');
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DashboardPage(driverUserName: widget.driverUserName),
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DeliveryPage(
                  driverUserName: widget.driverUserName, driverId: driverId),
        ),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MaintenancePage(
                  driverUserName: widget.driverUserName, driverId: driverId),
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

  void logout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }

  void toggleDriverStatus(bool newValue) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.apiUrl}/api/update-driver-status/$driverId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'driver_status_id': newValue ? 1 : 0}),
      );

      if (response.statusCode == 200) {
        setState(() {
          driverData['driver_status_id'] = newValue ? 1 : 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                newValue ? 'Switched to Active' : 'Switched to Inactive'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        print('Failed to update driver status');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    _image = File('assets/profilepic.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            'Profile Dashboard',
            style: TextStyle(
              fontFamily: 'YourFontFamily', // Replace 'YourFontFamily' with your desired font family
              fontSize: 18.0, // Adjust the font size as needed
              fontWeight: FontWeight.bold, // Adjust the font weight as needed
            ),
          ),
        ),
        backgroundColor: Colors.lightGreen,
      ),
      body: Stack(
        children: [
          Container(
            height: 200,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<Map<String, dynamic>>(
              future: driverDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return Center(child: Text('No data available'));
                } else {
                  driverData = snapshot.data!;
                  var profilePic = '${Constants.apiUrl}${driverData['profile_pic'] ?? '/upload_mobile/profilepic.png'}?${DateTime.now().millisecondsSinceEpoch}';
                  var profPic = '${Constants
                      .apiUrl}${driverData['profile_pic']}';

                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: truckingDataFuture,
                    builder: (context, truckingSnapshot) {
                      if (truckingSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (truckingSnapshot.hasError) {
                        return Center(
                            child: Text('Error: ${truckingSnapshot.error}'));
                      } else if (!truckingSnapshot.hasData) {
                        return Center(
                            child: Text('No trucking data available'));
                      } else {
                        final List<Map<String,
                            dynamic>> truckingData = truckingSnapshot.data!;
                        final matchingTrucking = truckingData.firstWhere(
                              (trucking) =>
                          trucking['trucking_id'] == driverData['trucking_id'],
                          orElse: () => {'trucking_name': 'Unknown'},
                        );

                        return RefreshIndicator(
                          onRefresh: () async {
                            setState(() {
                              driverDataFuture = fetchData();
                              ImageCache imageCache = PaintingBinding.instance.imageCache!;
                              imageCache.clear();
                              profilePic =
                              '${Constants.apiUrl}${driverData['profile_pic']}';
                            });
                            await driverDataFuture;
                          },
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Column(
                                  children: [
                                    // Add a container for the cover photo
                                    Container(
                                      height: 150,
                                      child: Stack(
                                        alignment: Alignment.centerRight,
                                        children: [
                                          // Circular profile picture with background cover photo
                                          Positioned(
                                            left: 95,
                                            // Adjust the right position
                                            child: Container(
                                              width: 150,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                              ),
                                              child: CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                    profilePic),
                                                radius: 75,
                                              ),
                                            ),
                                          ),
                                          // Circular profile picture
                                          Positioned(
                                            left: 200,
                                            bottom: 5,
                                            child: CircleAvatar(
                                              backgroundColor: Colors
                                                  .white,
                                              child: IconButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditProfilePicPage(
                                                              driverId: driverData['driver_id']
                                                                  .toString(),
                                                              driverProfile: profPic),
                                                    ),
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.camera_alt_rounded,
                                                  size: 30, // Set the icon color
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  ],
                                ),
                                Center(
                                  child: ListTile(
                                    subtitle: Row(
                                      mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                      children: [
                                        Text(
                                          'Status:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Switch(
                                          value: driverData['driver_status_id'] == 1,
                                          onChanged: (value) {
                                            // Call the function to show the confirmation dialog
                                            showConfirmationDialog(value);
                                          },
                                          activeColor: Colors.green,
                                          inactiveTrackColor: Colors.red,
                                        ),
                                        Text(
                                          driverData['driver_status_id'] == 1 ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: driverData['driver_status_id'] == 1 ? Colors.green : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                buildCard('Driver Name',
                                    driverData['driver_name'].toString(),
                                    Icons.person),
                                buildCard('Age', driverData['age'].toString(),
                                    Icons.calendar_month),
                                buildCard('Address',
                                    driverData['driver_address'].toString(),
                                    Icons.location_on),
                                buildCard('Phone Number',
                                    driverData['driver_phone'].toString(),
                                    Icons.phone),
                                buildCard('License Number',
                                    driverData['licence_no'].toString(),
                                    Icons.credit_card),
                                buildCard('Trucking Company',
                                    matchingTrucking['trucking_name']
                                        .toString(), Icons.business),
                          ElevatedButton(
                            onPressed: logout,
                            child: Text(
                              'Logout',
                              style: TextStyle(color: Colors.white), // Set text color to white
                            ),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(Colors.lightGreen),
                            ),
                          ),
                            ]),
                          ),
                        );
                      }
                    },
                  );
                }
              },
            ),
          ),
        ],
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

  Widget buildCard(String title, String subtitle, IconData iconData) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: Icon(
          iconData,
          color: Colors.green, // Set the color to green
        ), // Add this line to display the icon
      ),
    );
  }


  void showConfirmationDialog(bool newStatus) {
    showDialog(
      context: context, // Make sure to have access to the context variable
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Status Change'),
          content: Text('Are you sure you want to switch the status?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                toggleDriverStatus(newStatus);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

}
