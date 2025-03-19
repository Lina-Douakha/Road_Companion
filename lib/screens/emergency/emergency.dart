import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

class EmergencyCallPage extends StatefulWidget {
  final int selectedIndex;

  const EmergencyCallPage({super.key, this.selectedIndex = 1});

  @override
  State<EmergencyCallPage> createState() => _EmergencyCallPageState();
}

class _EmergencyCallPageState extends State<EmergencyCallPage> {
  List<Map<String, dynamic>> emergencyNumbers = [];

  @override
  void initState() {
    super.initState();
    _loadEmergencyNumbers();
  }

  /// Charge les numéros d'urgence depuis le fichier JSON
  Future<void> _loadEmergencyNumbers() async {
    try {
      String jsonString = await rootBundle.loadString('assets/data/emergency_numbers.json');
      List<dynamic> jsonData = json.decode(jsonString);
      setState(() {
        emergencyNumbers = jsonData.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      print("Erreur de chargement des numéros d'urgence : $e");
    }
  }

  /// Ouvre l’application de téléphone avec le numéro sélectionné
  Future<void> _makePhoneCall(String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("error_phone".tr())),
      );

    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 70),
              Text(
                "emergency_title".tr(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B9169),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: emergencyNumbers.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  itemCount: emergencyNumbers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Card(
                        color: const Color(0xFFECFDF3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                          leading: Image.asset(
                            emergencyNumbers[index]['logo']!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                          title: Text(
                            tr(emergencyNumbers[index]['service']!),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          subtitle: Text(
                            emergencyNumbers[index]['number']!,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.phone_outlined, color: Color(0xFF00D47E), size: 32),
                            onPressed: () => _makePhoneCall(emergencyNumbers[index]['number']!),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
