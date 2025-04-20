import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:road_companion/screens/roadside_assistance/handle_request.dart';

class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HandleRequestPage( providerID: "p001"),
    );
  }
}