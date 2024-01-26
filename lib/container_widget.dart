import 'package:flutter/material.dart';

class ContainerWidget extends StatelessWidget {
  final IconData icon;
  final String text;

  ContainerWidget({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36),
          SizedBox(height: 8),
          Text(text),
        ],
      ),
    );
  }
}