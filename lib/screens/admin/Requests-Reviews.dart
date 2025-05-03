import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'historiques_requests.dart';

class RequestReviewsScreen extends StatefulWidget {
  final String UserID;

  const RequestReviewsScreen({Key? key, required this.UserID}) : super(key: key);

  @override
  _RequestReviewsScreenState createState() => _RequestReviewsScreenState();
}

class _RequestReviewsScreenState extends State<RequestReviewsScreen> {
  List<Map<String, String>> rawNotifications = [];
  List<Map<String, dynamic>> reviews = [];
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String ratingStatus = 'Loading...';
  String historyStatus = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {

    await loadReviews();
  }


  Future<void> loadReviews() async {
    try {
      DocumentReference providerRef = _db.collection('Reviews').doc(widget.UserID);
      DocumentSnapshot providerDoc = await providerRef.get();

      if (providerDoc.exists) {
        Map<String, dynamic> data = providerDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> reviewsMap = data['reviews'] ?? {};

        if (reviewsMap.isNotEmpty) {
          setState(() {
            reviews = reviewsMap.entries.map((entry) {
              var value = entry.value as Map<String, dynamic>;
              double rating = value['rating'] is num ? value['rating'].toDouble() : 0.0;
              return {
                'name': value['name'] ?? 'No Name',
                'image': value['image'] ?? '',
                'rating': rating,
                'comment': value['comment'] ?? 'No comment',
                'date': value['date'] ?? 'No date',
              };
            }).toList();
            ratingStatus = '✅ Reviews loaded!';
          });
        } else {
          setState(() {
            ratingStatus = '❌ No reviews yet.';
          });
        }
      } else {
        setState(() {
          ratingStatus = '❌ No reviews yet.';
        });
      }
    } catch (e) {
      setState(() {
        ratingStatus = '❌ Error loading reviews: $e';
      });
      debugPrint('Error loading reviews: $e');
    }
  }

  Widget _buildRatingSummary(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int totalReviews = reviews.length;
    if (totalReviews == 0) return const SizedBox();

    double averageRating = reviews.fold(0.0, (sum, item) => sum + item["rating"]) / totalReviews;

    Map<int, int> ratingCount = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in reviews) {
      int rate = review["rating"].round();
      if (ratingCount.containsKey(rate)) {
        ratingCount[rate] = ratingCount[rate]! + 1;
      }
    }

    Widget ratingRow(String label, int count) {
      double barWidth = screenWidth * 0.45;
      double filledWidth = (count / totalReviews) * barWidth;

      return Padding(
        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: screenWidth * 0.2,
              child: Text(
                label.tr(),
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Stack(
              children: [
                Container(
                  width: barWidth,
                  height: screenWidth * 0.015,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  width: filledWidth,
                  height: screenWidth * 0.015,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D47E),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenWidth * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            averageRating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: screenWidth * 0.1,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenWidth * 0.015),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < averageRating.round() ? Icons.star : Icons.star_border,
                color: const Color(0xFFFFC107),
                size: screenWidth * 0.06,
              );
            }),
          ),
          SizedBox(height: screenWidth * 0.015),
          Text(
            '${'review.summary.based_on'.tr()} $totalReviews ${'review.summary.reviews'.tr()}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: screenWidth * 0.035,
            ),
          ),
          SizedBox(height: screenWidth * 0.03),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ratingRow('review.summary.excellent'.tr(), reviews.where((r) => r['rating'] >= 5).length),
                  ratingRow('review.summary.good'.tr(), reviews.where((r) => r['rating'] >= 4 && r['rating'] < 5).length),
                  ratingRow('review.summary.average'.tr(), reviews.where((r) => r['rating'] >= 3 && r['rating'] < 4).length),
                  ratingRow('review.summary.poor'.tr(), reviews.where((r) => r['rating'] < 3).length),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    await _loadData();
  }
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF00D47E),
      backgroundColor: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Service Provider Reviews'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B9169)),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildRatingSummary(context)),
          SliverToBoxAdapter(child: const Divider()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Request History'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B9169)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: NotificationHistoryScreen(
              UserID: widget.UserID,
              embedInParent: true,
            ),
          )
        ],
      ),
    );
  }

}