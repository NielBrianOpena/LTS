import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'constant.dart';
import 'package:flutter/cupertino.dart';

class CompletedDeliveryInfoPage extends StatefulWidget {
  final String deliveryId;

  CompletedDeliveryInfoPage({required this.deliveryId});

  @override
  _CompletedDeliveryInfoPageState createState() => _CompletedDeliveryInfoPageState();
}

class _CompletedDeliveryInfoPageState extends State<CompletedDeliveryInfoPage> {
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
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              key,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '$value',
            ),
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
                      Container(
                        padding: EdgeInsets.all(8.0),
                        width: 370,
                        height: 300,
                        color: Colors.black12,
                        child: Image.network(
                          '${Constants.apiUrl}${deliveryDetails['receive_proof']}',
                          fit: BoxFit.fill,
                        ),
                      ),
                      SizedBox(height: 8.0),
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
                          buildKeyValue('Delivery Date:', deliveryDetails['delivery_date']),
                          buildKeyValue('Received By:', deliveryDetails['receive_by']),
                          buildKeyValue('Received Date:', deliveryDetails['receive_date']),
                          // Add more key-value pairs as needed
                        ],
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