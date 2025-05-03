import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:easy_localization/easy_localization.dart';

class TermsConditionsPage extends StatefulWidget {
  @override
  _TermsConditionsPageState createState() => _TermsConditionsPageState();
}

class _TermsConditionsPageState extends State<TermsConditionsPage> {
  Map<String, dynamic> termsData = {};

  @override
  void initState() {
    super.initState();
    loadTerms();
  }

  Future<void> loadTerms() async {
    final frJson = await rootBundle.loadString('assets/lang/fr.json');
    final enJson = await rootBundle.loadString('assets/lang/en.json');
    final arJson = await rootBundle.loadString('assets/lang/ar.json');

    setState(() {
      termsData = {
        'fr': json.decode(frJson)['fr'],
        'en': json.decode(enJson)['en'],
        'ar': json.decode(arJson)['ar'],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final localeCode = context.locale.languageCode;
    final currentTerms = termsData[localeCode] ?? {};

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body:
          termsData.isEmpty
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // ✅ Barre verte qui couvre aussi la zone de statut
                  Container(
                    height: MediaQuery.of(context).padding.top,
                    color: Color(0xFF1B9169),
                  ),


                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView(
                        children: [
                          Text(
                            currentTerms["titre"] ?? 'terms.title'.tr(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B9169),
                            ),
                            textAlign:
                                localeCode == 'ar'
                                    ? TextAlign.right
                                    : TextAlign.left,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currentTerms["introduction"] ?? 'terms.intro'.tr(),
                            style: TextStyle(fontSize: 16),
                            textAlign:
                                localeCode == 'ar'
                                    ? TextAlign.right
                                    : TextAlign.left,
                          ),
                          const SizedBox(height: 20),
                          ...List.generate(
                            (currentTerms["conditions"] as List<dynamic>)
                                .length,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${index + 1}. ",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      currentTerms["conditions"][index],
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: const Color.fromARGB(
                                          255,
                                          0,
                                          0,
                                          0,
                                        ),
                                      ),
                                      textAlign:
                                          localeCode == 'ar'
                                              ? TextAlign.right
                                              : TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}