import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/screens/admin/admin_load_reviews.dart';
import 'package:road_companion/screens/admin/UserDetailsScreen.dart';

class AdminReviewManager extends StatefulWidget {
  @override
  _AdminReviewManagerState createState() => _AdminReviewManagerState();
}

class _AdminReviewManagerState extends State<AdminReviewManager> {

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> reviews = [];
  String status = 'Loading...';
  List<String> providers = [];
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchReviews();
  }
  Future<void> fetchReviews() async {
    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await _db.collection('Reviews').get();

      setState(() {
        providers = snapshot.docs.map((doc) => doc.id).toList();
        status    = providers.isEmpty
            ? '❌ No providers found.'
            : '✅ Providers loaded (${providers.length})';
      });
    } catch (e) {
      setState(() {
        status = '❌ Error fetching providers: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  Widget buildIconCircle({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
        ),

        child: Icon(
          icon,
          size: 16,
          color: color, // white icon
        ),

      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth  = MediaQuery.of(context).size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: screenHeight * 0.12,
                floating: false,
                pinned: false,
                backgroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(bottom: screenHeight * 0.03),
                  title: Text(
                    'Manage Reviews',
                    style: TextStyle(
                      color: Color(0xFF1B9169),
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),

              // ← here’s the ONLY change:
              if (isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00D47E),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final providerNum = index + 1;
                      final id          = providers[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                  onTap: () async {
                                    try {

                                      final snapshot = await firestore.collection('users').doc(id).get();

                                      if (snapshot.exists) {

                                        Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>? ?? {};

                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => UserDetailsScreen(user: userData),
                                          ),
                                        );
                                      } else {

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('User profile not found')),
                                        );
                                      }
                                    } catch (e) {

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error loading user profile: ${e.toString()}')),
                                      );
                                      print('Error navigating to user profile: $e');
                                    }
                                  },

                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Color(0xFF00D47E).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$providerNum',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1B9169),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Provider $providerNum',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[900],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AdminLoadReviews(providerId: id),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: Color(0xFF00D47E).withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.rate_review,
                                              size: 16,
                                              color: Color(0xFF00D47E),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Check Reviews',
                                              style: TextStyle(
                                                color: Color(0xFF00D47E),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: providers.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}