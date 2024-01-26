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

import 'completion_form.dart';
import 'constant.dart';

class OngoingDeliveryInfoPage extends StatefulWidget {
  final String deliveryId;
  final String driverId;
  final String driverUserName;

  OngoingDeliveryInfoPage({
    required this.deliveryId,
    required this.driverId,
    required this.driverUserName,
  });

  @override
  _OngoingDeliveryInfoPageState createState() => _OngoingDeliveryInfoPageState();
}

class _OngoingDeliveryInfoPageState extends State<OngoingDeliveryInfoPage> {
  late Future<Map<String, dynamic>> _deliveryDetails;

  @override
  void initState() {
    super.initState();
    _deliveryDetails = fetchDeliveryDetails(widget.deliveryId);
  }

  Future<Map<String, dynamic>> fetchDeliveryDetails(String deliveryId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.apiUrl}/api/get-delivery-details/$deliveryId'),
      );

      if (response.statusCode == 200) {
        dynamic responseData = json.decode(response.body);
        print(responseData);
        return responseData;
      } else {
        throw Exception('Failed to load delivery details');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  TableRow buildKeyValue(String key, dynamic value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            key,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '$value',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Information'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _deliveryDetails = fetchDeliveryDetails(widget.deliveryId);
          });
        },
        child: FutureBuilder<Map<String, dynamic>>(
          future: _deliveryDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              Map<String, dynamic> deliveryDetails = snapshot.data!;
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(13.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Table(
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          buildKeyValue('Delivery ID:', deliveryDetails['delivery_id']),
                          buildKeyValue('Has No:', deliveryDetails['hasno']),
                          buildKeyValue('Trucking ID:', deliveryDetails['trucking_id']),
                          buildKeyValue('Truck ID:', deliveryDetails['truck_id']),
                          buildKeyValue('Helper:', deliveryDetails['helper']),
                          buildKeyValue('Business Name:', deliveryDetails['bussiness_name']),
                          buildKeyValue('Delivery Address:', deliveryDetails['delivery_address']),
                          buildKeyValue('Contact Person:', deliveryDetails['contact_person']),
                          buildKeyValue('Contact No:', deliveryDetails['contactno']),
                          buildKeyValue('Delivery Date:', deliveryDetails['delivery_date']),
                          buildKeyValue('Dispatched By:', deliveryDetails['dispatch_by']),
                        ],
                      ),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CompletionFormPage(
                                deliveryId: widget.deliveryId,
                                driverId: widget.driverId,
                                driverUserName: widget.driverUserName,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.lightGreen, // Set the background color to green
                        ),
                        child: const Text(
                          'Complete Delivery',
                          style: TextStyle(
                            color: Colors.white, // Set the text color to white
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
