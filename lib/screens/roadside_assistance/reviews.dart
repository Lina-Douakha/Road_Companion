import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lottie/lottie.dart';

class ForumScreen extends StatefulWidget {
  @override
  _ForumScreenState createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  List<Map<String, dynamic>> reviews = [];
  String status = 'Loading...'; // Added status variable for user feedback

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    loadReviews();
  }

  Future<void> loadReviews() async {
    try {
      DocumentReference providerRef = _db.collection('Reviews').doc('p001');
      DocumentSnapshot providerDoc = await providerRef.get();

      if (providerDoc.exists) {
        Map<String, dynamic> data = providerDoc.data() as Map<String, dynamic>;

        debugPrint('Top-level keys in document: ${data.keys}');
        debugPrint('Data fetched: $data');

        // 🔥 FIX: Access the "reviews" map inside the document
        Map<String, dynamic> reviewsMap = data['reviews'] ?? {};
        debugPrint('Reviews map: $reviewsMap');

        if (reviewsMap.isNotEmpty) {
          setState(() {
            reviews = reviewsMap.entries.map((entry) {
              var value = entry.value as Map<String, dynamic>;
              debugPrint('Review data: $value');

              double rating = value['rating'] is num ? value['rating']
                  .toDouble() : 0.0;

              return {
                'name': value['name'] ?? 'No Name',
                'image': value['image'] ?? '',
                'rating': rating,
                'comment': value['comment'] ?? 'No comment',
                'date': value['date'] ?? 'No date',
              };
            }).toList();
            status = '✅ Reviews loaded!';
          });
        } else {
          setState(() {
            status = '❌ No reviews found.';
          });
        }
      } else {
        setState(() {
          status = '❌ Document does not exist!';
        });
      }
    } catch (e) {
      setState(() {
        status = '❌ Error: $e';
      });
      debugPrint('Error loading reviews: $e');
    }
  }


  Widget buildRatingSummary(double screenWidth) {
    int totalReviews = reviews.length;
    if (totalReviews == 0) return SizedBox();

    double averageRating = reviews.fold(
        0.0, (sum, item) => sum + item["rating"]) / totalReviews;

    Map<int, int> ratingCount = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in reviews) {
      int rate = review["rating"].round(); // Round to nearest integer
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
                label,
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
                    color: Color(0xFF00D47E),
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
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05, vertical: screenWidth * 0.03),
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
                color: Color(0xFFFFC107),
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
            // centers the entire column of rows
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ratingRow('review.summary.excellent'.tr(), ratingCount[5]!),
                  ratingRow('review.summary.good'.tr(), ratingCount[4]!),
                  ratingRow('review.summary.average'.tr(), ratingCount[3]!),
                  ratingRow('review.summary.poor'.tr(), ratingCount[2]! + ratingCount[1]!),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  Future<void> _refreshData() async {
    await loadReviews();
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
    statusBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: Colors.white,
    body: RefreshIndicator(
    onRefresh: _refreshData,
      color: Color(0xFF00D47E),
      backgroundColor: Colors.white,
      child: CustomScrollView(
        slivers: [
         if (reviews.isNotEmpty)
          SliverAppBar(
            expandedHeight: screenHeight * 0.12,
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: false,
            floating: false,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: EdgeInsets.only(bottom: screenHeight * 0.03),
              title: Text(
                "review.title".tr(),
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B9169),
                ),
              ),

            ),
          ),
          // Check if reviews are empty or not
          reviews.isEmpty
              ? SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animation/empty.json',
                    width: screenWidth * 0.6,
                    height: screenWidth * 0.6,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'results.no_results'.tr(),
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.008),
                  Text(
                    'review.no_reviews'.tr(),
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
              : SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.015,
              ),
              child: buildRatingSummary(screenWidth),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final review = reviews[index];
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.005,
                  ),
                  child: ReviewCard(
                    name: review["name"],
                    imageUrl: review["image"],
                    rating: review["rating"].toInt(),
                    comment: review["comment"],
                    date: review["date"],
                    screenWidth: screenWidth,
                  ),
                );
              },
              childCount: reviews.length,
            ),
          ),
        ],
      ),
    ),
    ),
    );
  }
}
class ReviewCard extends StatefulWidget {
  final String name;
  final String comment;
  final String imageUrl;
  final String date;
  final int rating;
  final double screenWidth; // This is passed from the parent widget

  const ReviewCard({
    Key? key,
    required this.name,
    required this.comment,
    required this.imageUrl,
    required this.date,
    required this.rating,
    required this.screenWidth, // Ensure the screenWidth is passed here
  }) : super(key: key);

  @override
  _ReviewCardState createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool isExpanded = false; // Track whether the comment is expanded or not
  final int commentLimit = 100; // Maximum number of characters before "Read More"

  @override
  Widget build(BuildContext context) {
    // Use the screenWidth that was passed into the widget
    final double screenWidth = widget.screenWidth; // Access it directly from widget

    final double padding = screenWidth * 0.03;
    final double avatarSize = screenWidth * 0.10;
    final double iconSize = screenWidth * 0.045;
    final double nameFontSize = screenWidth * 0.035;
    final double commentFontSize = screenWidth * 0.032;
    final double dateFontSize = screenWidth * 0.030;

    // Shortened comment if it exceeds the limit
    String displayedComment = widget.comment;
    if (widget.comment.length > commentLimit && !isExpanded) {
      displayedComment = widget.comment.substring(0, commentLimit) + '...';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name/Stars and Date
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: avatarSize / 2,
                  backgroundImage: widget.imageUrl.startsWith('http')
                      ? NetworkImage(widget.imageUrl)
                      : AssetImage(widget.imageUrl) as ImageProvider,
                ),
                SizedBox(width: screenWidth * 0.03), // Space between avatar and name/rating

                // Name, Stars, and Date aligned next to avatar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and date in a row, aligned well
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.name,
                            style: TextStyle(
                              fontSize: nameFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.date,
                            style: TextStyle(
                              fontSize: dateFontSize,
                              color: Colors.grey[500], // Lighter date color
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenWidth * 0.01),
                      // Rating stars aligned perfectly under the name/date row
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < widget.rating ? Icons.star : Icons.star_border,
                            color: Color(0xFFFFC107),
                            size: iconSize,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: screenWidth * 0.02), // Space between name and comment

            // Comment Text (Aligned with the left edge)
            Text(
              displayedComment,
              style: TextStyle(
                fontSize: commentFontSize,
                color: Colors.grey[800],
              ),
            ),

            // "Read More" / "Read Less" Button
            if (widget.comment.length > commentLimit)

              InkWell(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded; // Toggle expanded state
                  });
                },
                child: Text(
                  isExpanded ? 'read.read_less'.tr() : 'read.read_more'.tr(),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}