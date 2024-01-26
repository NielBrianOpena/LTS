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
import 'constant.dart';
import 'delivery.dart';

class CompletionFormPage extends StatefulWidget {
  final String deliveryId;
  final String driverId;
  final String driverUserName;

  CompletionFormPage({required this.deliveryId, required this.driverId, required this.driverUserName});

  @override
  _CompletionFormPageState createState() => _CompletionFormPageState();
}

class _CompletionFormPageState extends State<CompletionFormPage> {
  File? _receiveProofImage;

  // Controllers for TextFormField
  TextEditingController _receiveByController = TextEditingController();
  TextEditingController _receiveDateController = TextEditingController();
  TextEditingController _remarkController = TextEditingController();
  DateTime now = DateTime.now();
  String formattedDate = '';

  @override
  void initState() {
    super.initState();
    // Initialize _receiveDateController with formatted date
    formattedDate = DateFormat('MMMM d, y hh:mm a').format(now);
    _receiveDateController.text = formattedDate;
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

  Future<String> _uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('${Constants.apiUrl}/api/upload_delivery');
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
        throw Exception('Failed to complete delivery. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error completing delivery: $error');
      throw Exception('Error completing delivery');
    }
  }

  Future<void> _completeDelivery() async {
    try {
      // Check if an image is selected
      if (_receiveProofImage != null) {
        // Upload the image and get the file path
        String filePath = await _uploadImage(_receiveProofImage!);

        if (filePath.isNotEmpty) {
          // Now you can proceed with the put query to update the delivery data
          String deliveryId = widget.deliveryId;
          String receiveBy = _receiveByController.text;
          String receiveDate = _receiveDateController.text;
          String remark = _remarkController.text;
          int statusId = 1;

          final response = await http.put(
            Uri.parse('${Constants.apiUrl}/api/completeDelivery/$deliveryId'), // Replace with your API endpoint
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'receiveBy': receiveBy,
              'receiveDate': receiveDate,
              'remark': remark,
              'filePath': filePath,
              'statusId': statusId
            }),
          );

          if (response.statusCode == 200) {
            // Successfully completed delivery, navigate back
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DeliveryPage(driverUserName: widget.driverUserName, driverId:widget.driverId),
              ),
            );
          } else {
            print('Failed to complete delivery. Status code: ${response.statusCode}');
          }
        } else {
          print('Please upload an image before completing the delivery.');
        }
      } else {
        throw Exception('Failed to upload image.');
      }
    } catch (error) {
      print('Error uploading image: $error');
      throw Exception('Error uploading image');
    }
  }
  Future<List<Map<String, dynamic>>> fetchTruckingData() async {
    final response = await http.get(
      Uri.parse('${Constants.apiUrl}/api/get-trucking-data'),
    );

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>().toList();
    } else {
      // If the server did not return a 200 OK response,
      // throw an exception or display an error message.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Completion Form'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 16.0),
              TextFormField(
                controller: _receiveByController,
                decoration: InputDecoration(labelText: 'Received By'),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                readOnly: true,
                controller: _receiveDateController,
                decoration: InputDecoration(labelText: 'Received Date and Time'),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _remarkController,
                decoration: InputDecoration(labelText: 'Delivery Remarks'),
              ),
              SizedBox(height: 16.0),
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
                child: Text('Upload Picture'),
              ),
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
                              // Dismiss the dialog
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await _completeDelivery();
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
    );
  }
}