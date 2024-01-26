import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:ltsalpha/maintenance.dart';
import 'constant.dart';
import 'delivery.dart';

class AddMaintenancePage extends StatefulWidget {
  final String driverId;
  final String driverUsername;

  AddMaintenancePage({required this.driverId, required this.driverUsername});

  @override
  _AddMaintenancePageState createState() => _AddMaintenancePageState();
}

class _AddMaintenancePageState extends State<AddMaintenancePage> {
  List<dynamic> truckUnits = [];
  List<dynamic> truckings = [];
  Set<String> truckUnitValues = Set();
  Set<String> truckingValues = Set();
  String? selectedTrucking;
  String? selectedTruckUnit;
  File? _receiveProofImage;

  List<Map<String, dynamic>> truckUnitItems = [];
  List<Map<String, dynamic>> truckingItems = [];
  TextEditingController _amountController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _fetchTruckUnits();
    _fetchTrucking();
  }

  // Function to handle form submission
  void submitForm() {
    // Access the entered values using the controller
    // Perform actions with the form data, e.g., send to the server
  }

  Future<String> _uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('${Constants.apiUrl}/api/upload_maintenance');
      var request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        // Successfully uploaded, get the file path from the response
        String filePath = await response.stream.bytesToString();
        // Now you can proceed with the delivery completion post query using filePath
        print('Image uploaded successfully. File path: $filePath');
        return filePath;
      } else {
        throw Exception('Failed to complete maintenance. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error completing maintenance: $error');
      throw Exception('Error completing delivery');
    }
  }

  Future<void> _getImage(ImageSource source, {int targetSizeKB = 100}) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
    );

    if (pickedFile != null) {
      File? compressedImage = await compressImage(File(pickedFile.path), targetSizeKB);

      if (compressedImage != null) {
        setState(() {
          _receiveProofImage = compressedImage;
        });
      }
    }
  }

  Future<File?> compressImage(File imageFile, int targetSizeKB) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(Uint8List.fromList(bytes));

    if (image != null) {
      final resizedImage = img.copyResize(image, width: 800);
      final compressedBytes = img.encodeJpg(resizedImage, quality: 70);
      final compressedFile = File('${imageFile.path}_compressed.jpg');
      await compressedFile.writeAsBytes(compressedBytes);
      return compressedFile;
    }

    return null;
  }

  Future<void> _fetchTrucking() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.apiUrl}/api/get-trucking-data'),
      );

      if (response.statusCode == 200) {
        setState(() {
          truckings = List<Map<String, dynamic>>.from(json.decode(response.body));
          for (var trucking in truckings) {
            truckingItems.add({
              'displayValue': trucking['trucking_name'].toString(),
              'value': trucking['trucking_id'].toString(),
            });
          }
          if (truckings.isNotEmpty) {
            selectedTrucking = truckingItems.first['value'];
          }
        });
      } else {
        print('Failed to fetch trucking information. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching truck unit information: $e');
    }
  }

  Future<void> _fetchTruckUnits() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.apiUrl}/api/get-truck-data'),
      );

      if (response.statusCode == 200) {
        setState(() {
          truckUnits = List<Map<String, dynamic>>.from(json.decode(response.body));
          for (var truckUnit in truckUnits) {
            truckUnitItems.add({
              'displayValue': truckUnit['truck_plateno'].toString(),
              'value': truckUnit['truck_id'].toString(),
            });
          }
          if (truckUnits.isNotEmpty) {
            selectedTruckUnit = truckUnitItems.first['value'];
          }
        });
      } else {
        print('Failed to fetch truck unit information. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching truck unit information: $e');
    }
  }

  Future<void> _completeMaintenance() async {
    try {
      // Check if an image is selected
      if (_receiveProofImage != null) {
        // Upload the image and get the file path
        String filePath = await _uploadImage(_receiveProofImage!);

        if (filePath.isNotEmpty) {
          // Now you can proceed with the put query to update the delivery data
          String driverId = widget.driverId;
          String? truckingId = selectedTrucking;
          String? truckUnitId = selectedTruckUnit;
          String amount = _amountController.text;

          final response = await http.post(
            Uri.parse('${Constants.apiUrl}/api/completeMaintenance'), // Replace with your API endpoint
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'driverId': driverId,
              'truckingId': truckingId,
              'truckUnitId': truckUnitId,
              'amount': amount,
              'filePath': filePath
            }),
          );

          if (response.statusCode == 200) {
            // Successfully completed delivery, navigate back
            Navigator.pop(context);
          } else {
            print('Failed to complete maintenance. Status code: ${response.statusCode}');
          }
        } else {
          print('Please upload an image before completing the maintenance.');
        }
      } else {
        throw Exception('Failed to upload image.');
      }
    } catch (error) {
      print('Error uploading image: $error');
      throw Exception('Error uploading image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Maintenance'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Trucking Company DropdownButton
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTruckUnit,
                  items: truckUnitItems.map((truckUnit) {
                    return DropdownMenuItem<String>(
                      value: truckUnit['value'],
                      child: Text(truckUnit['displayValue']),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedTruckUnit = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Select A Truck Unit',
                  ),
                  hint: Text('Select a Truck Unit'),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTrucking,
                  items: truckingItems.map((trucking) {
                    return DropdownMenuItem<String>(
                      value: trucking['value'],
                      child: Text(trucking['displayValue']),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedTrucking = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Select A Trucking Company',
                  ),
                  hint: Text('Select a Trucking Company'),
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: 'Amount'),
                ),
                SizedBox(height: 32),
                if (_receiveProofImage != null)
                  Column(
                    children: [
                      Image.file(_receiveProofImage!),
                      SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _receiveProofImage = null;
                              });
                            },
                            child: Text('Remove Image'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return Card(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                title: Text('Select an image source'),
                              ),
                              ListTile(
                                leading: Icon(Icons.photo),
                                title: Text('Gallery'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _getImage(
                                      ImageSource.gallery, targetSizeKB: 100);
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.camera),
                                title: Text('Camera'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _getImage(
                                      ImageSource.camera, targetSizeKB: 100);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Text('Upload Picture of Receipt'),
                ),
                // Submit Button
                ElevatedButton(
                  onPressed: () async {
                    // Show confirmation dialog before submitting
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Confirmation'),
                          content: Text("Once you submit, you can't edit this anymore!"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await _completeMaintenance();
                                Navigator.pop(context);
                              },
                              child: Text('Submit'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
