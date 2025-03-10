import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:road_companion/widgets/navigation_bar_widget.dart';
import 'package:flutter/services.dart';

class EmergencyCallPage extends StatefulWidget {
  final int selectedIndex;

  const EmergencyCallPage({super.key, this.selectedIndex = 1});

  @override
  State<EmergencyCallPage> createState() => _EmergencyCallPageState();
}

class _EmergencyCallPageState extends State<EmergencyCallPage> {
  int _selectedIndex = 1;

  final List<Map<String, String>> emergencyNumbers = [
    {'service': 'Police Nationale', 'number': '1548', 'logo': 'assets/images/Police.png'},
    {'service': 'Gendarmerie Nationale', 'number': '1055', 'logo': 'assets/images/Gendarmerie.png'},
    {'service': 'Protection Civile', 'number': '1021', 'logo': 'assets/images/Protection_civile.png'},
    {'service': 'Service des forêts', 'number': '1070', 'logo': 'assets/images/Direction_generale_des_forets.png'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  Future<void> _makePhoneCall(String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’ouvrir l’application Téléphone')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/map');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/emergency');
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
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
             SizedBox(height: 70),
            const Text(
              'Appel d’urgence',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B9169),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
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
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                        leading: Image.asset(
                          emergencyNumbers[index]['logo']!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                        title: Text(
                          emergencyNumbers[index]['service']!,
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        subtitle: Text(
                          emergencyNumbers[index]['number']!,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.phone_outlined, color: const Color(0xFF00D47E), size: 32),
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
      /*bottomNavigationBar: NavigationBarWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),*/
    ),
    );
  }
}
