import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/Theming/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:road_companion/screens/chat.dart';

class MechanicProfilePage extends StatefulWidget {
  final String providerId;

  const MechanicProfilePage({super.key, required this.providerId});

  @override
  State<MechanicProfilePage> createState() => _MechanicProfilePageState();
}

class ReviewCard extends StatefulWidget {
  final String name;
  final String comment;
  final double rating;
  final String date;
  final String? image;

  const ReviewCard({
    required this.name,
    required this.comment,
    required this.rating,
    required this.date,
    required this.image,
    Key? key,
  }) : super(key: key);

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool isExpanded = false;
  final int commentLimit = 100;

  @override
  Widget build(BuildContext context) {
    final displayedComment = isExpanded || widget.comment.length <= commentLimit
        ? widget.comment
        : '${widget.comment.substring(0, commentLimit)}...';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[400],
                  child: widget.image != null &&
                         widget.image!.isNotEmpty &&
                         widget.image!.startsWith('assets/')
                      ? ClipOval(
                          child: SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: Image.asset(widget.image!),
                            ),
                          ),
                        )
                      : Text(
                          widget.name.isNotEmpty
                              ? widget.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStars(widget.rating),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              displayedComment,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
              ),
            ),
            if (widget.comment.length > commentLimit)
              GestureDetector(
                onTap: () => setState(() => isExpanded = !isExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isExpanded ? 'Read Less' : 'Read More',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }
}

class _MechanicProfilePageState extends State<MechanicProfilePage> {
  int _selectedIndex = 3;
  Map<String, dynamic> _providerData = {};
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  double _averageRating = 0.0;
  final TextEditingController _reviewController = TextEditingController();
  double _newRating = 0;

  @override
  void initState() {
    super.initState();
    _fetchProviderData();
    _fetchReviews();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _fetchProviderData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.providerId)
          .get();

      if (doc.exists) {
        setState(() {
          _providerData = doc.data() ?? {};
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load provider data: $e')),
      );
    }
  }

  Future<void> _fetchReviews() async {
    try {
      final reviewDoc = await FirebaseFirestore.instance
          .collection('Reviews')
          .doc(widget.providerId)
          .get();

      if (reviewDoc.exists) {
        final reviewData = reviewDoc.data() as Map<String, dynamic>;
        final reviewsMap = reviewData['reviews'] as Map<String, dynamic>? ?? {};

        final loadedReviews = <Map<String, dynamic>>[];
        double totalRating = 0.0;
        int reviewCount = 0;

        await Future.wait(reviewsMap.entries.map((entry) async {
          if (entry.key.startsWith('review')) {
            final review = entry.value as Map<String, dynamic>;
            final senderId = review['senderID'] as String?;

            if (senderId != null) {
              final senderDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(senderId)
                  .get();

              if (senderDoc.exists) {
                final senderData = senderDoc.data() as Map<String, dynamic>;
                loadedReviews.add({
                  'name': senderData['Name'] ?? 'Anonymous',
                  'comment': review['comment'] ?? '',
                  'rating': (review['rating'] as num?)?.toDouble() ?? 0.0,
                  'date': review['date'] ?? '',
                  'image': senderData['ProfilePhoto'] ?? '',
                });

                totalRating += (review['rating'] as num?)?.toDouble() ?? 0.0;
                reviewCount++;
              }
            }
          }
        }));

        loadedReviews.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

        setState(() {
          _reviews = loadedReviews;
          _averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _reviews = [];
          _averageRating = 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reviews: $e')),
      );
    }
  }

  String _formatWorkingHours() {
    try {
      final workingHours = _providerData['Working_hours'] as String? ?? '';

      if (workingHours.isEmpty) {
        return 'No Specific Working time';
      }

      final parts = workingHours.split('|');

      if (parts.length != 3) {
        return 'No Specific Working time';
      }

      final daysStr = parts[0].trim();
      final startTime = parts[1].trim().replaceAll(':', 'h');
      final endTime = parts[2].trim().replaceAll(':', 'h');

      if (daysStr.isEmpty) {
        return 'No Specific Working time';
      }

      final dayNumbers = daysStr.split(' ')
          .map((d) => d.trim())
          .where((d) => d.isNotEmpty)
          .map((d) => int.tryParse(d) ?? 0)
          .where((d) => d >= 1 && d <= 7)
          .toList();

      if (dayNumbers.isEmpty) {
        return '';
      }

      final dayNames = {
        1: 'Dimanche',
        2: 'Lundi',
        3: 'Mardi',
        4: 'Mercredi',
        5: 'Jeudi',
        6: 'Vendredi',
        7: 'Samedi',
      };
      if (dayNumbers.contains(1) &&
          dayNumbers.contains(2) &&
          dayNumbers.contains(3) &&
          dayNumbers.contains(4) &&
          dayNumbers.contains(5) &&
          dayNumbers.length == 5) {
        return 'Dimanche - Jeudi : ${startTime} - ${endTime}';
      } else if (dayNumbers.length == 7) {
        return 'Tous les jours : ${startTime} - ${endTime}';
      } else if (dayNumbers.length == 2 &&
                 dayNumbers.contains(6) &&
                 dayNumbers.contains(7)) {
        return 'Week-end : ${startTime} - ${endTime}';
      } else {
        if (dayNumbers.length > 1 &&
            dayNumbers.every((d) => d == dayNumbers.first + dayNumbers.indexOf(d))) {
          final firstDay = dayNames[dayNumbers.first] ?? 'Jour';
          final lastDay = dayNames[dayNumbers.last] ?? 'Jour';
          return '$firstDay - $lastDay : ${startTime} - ${endTime}';
        } else {
          final dayList = dayNumbers.map((d) => dayNames[d] ?? 'Jour').join(', ');
          return '$dayList : ${startTime} - ${endTime}';
        }
      }
    } catch (e) {
      debugPrint('Error formatting working hours: $e');
      return 'No Specific Working time';
    }
  }

  Widget _buildProfileImage() {
    final profilePhoto = _providerData['ProfilePhoto'] as String?;
    final name = _providerData['Name'] as String? ?? '';

    if (profilePhoto != null && profilePhoto.isNotEmpty) {
        if (profilePhoto.startsWith('assets/')) {
          return CircleAvatar(
            radius: 48,
            backgroundImage: AssetImage(profilePhoto),
          );
        } else {
          return CircleAvatar(
           radius: 48,
           backgroundImage: NetworkImage(profilePhoto),
          );
        }
    } else {
      return CircleAvatar(
        radius: 48,
        backgroundColor: Colors.grey[400],
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 36, color: Colors.white),
        ),
      );
    }
  }

  Future<void> _launchUniversalUrl(String url) async {
    if (url.isEmpty) return;

    try {
      // Handle @username for Instagram
      if (url.startsWith('@')) {
        url = 'https://instagram.com/${url.substring(1)}';
      }
      // Add https:// if missing for websites
      else if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("error opening link"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Center(
                        child: Text(
                          'Laisser un avis',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Notez le service'),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              index < _newRating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 28,
                            ),
                            onPressed: () {
                              setState(() {
                                _newRating = index + 1.0;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 80,
                        child: TextField(
                          controller: _reviewController,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            hintText: 'Votre commentaire',
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: const OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: ColorsManager.Bgreen),
                            ),
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(color: Color(0xFF00D47E)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D47E),
                            ),
                            onPressed: () async {
                              if (_newRating > 0 || _reviewController.text.isNotEmpty) {
                                try {
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "You must be logged in to submit a review",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final newReviewId =
                                      'review${DateTime.now().millisecondsSinceEpoch}';

                                  await FirebaseFirestore.instance
                                      .collection('Reviews')
                                      .doc(widget.providerId)
                                      .set(
                                    {
                                      'reviews': {
                                        newReviewId: {
                                          'comment': _reviewController.text,
                                          'rating': _newRating,
                                          'date':
                                              '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}',
                                          'senderID': user.uid,
                                        }
                                      }
                                    },
                                    SetOptions(merge: true),
                                  );

                                  await _fetchReviews();
                                  _reviewController.clear();
                                  _newRating = 0;

                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Merci pour votre avis !"),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error submitting review: $e"),
                                    ),
                                  );
                                }
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            child: const Text(
                              'Envoyer',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      // Check if location permissions are granted
      final status = await Permission.location.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission is required")),
        );
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
      return null;
    }
  }

  Future<void> _sendServiceRequest(String problemDescription) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must be logged in to send a request")),
        );
        return;
      }

      // Get user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User data not found")),
        );
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final clientName = userData['Name'] as String? ?? 'Unknown';
      final clientPhone = userData['Phone'] as String? ?? '';

      // Get current location
      final position = await _getCurrentLocation();
      if (position == null) return;

      String addressString = 'Location';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          addressString = [
            if (place.street != null) place.street,
            if (place.subLocality != null) place.subLocality,
            if (place.locality != null) place.locality,
            if (place.administrativeArea != null) place.administrativeArea,
            if (place.country != null) place.country,
          ].where((part) => part != null && part.isNotEmpty).join(', ');
        }
      } catch (e) {
        debugPrint('Error getting address from coordinates: $e');
        // Fallback to coordinates if geocoding fails
        addressString = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      }

      // Create request data
      final requestData = {
        'address': addressString,
        'clientID': user.uid,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'description': problemDescription,
        'location': GeoPoint(position.latitude, position.longitude),
        'providerID': widget.providerId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add to Firestore
      await FirebaseFirestore.instance
          .collection('Service_requests')
          .add(requestData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Request sent successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send request: $e")),
      );
    }
  }

  void _showRequestDialog() {
    final TextEditingController problemController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              title: const Text(
                'Décrire votre problème',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              content: SizedBox(
                height: 100,
                child: TextField(
                  controller: problemController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Description (optionnelle)',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: ColorsManager.Bgreen),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: ColorsManager.Bgreen),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: ColorsManager.Bgreen),
                  onPressed: isSending
                      ? null
                      : () async {
                          setState(() => isSending = true);
                          await _sendServiceRequest(problemController.text.trim());
                          setState(() => isSending = false);

                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Envoyer', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  Widget _buildReview({
    required String name,
    required String comment,
    required double rating,
    required String date,
    required String? image,
  }) {
    return ReviewCard(
      name: name,
      comment: comment,
      rating: rating,
      date: date,
      image: image,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final address = _providerData['Address'] as String? ?? 'Adresse non disponible';
    final name = _providerData['Name'] as String? ?? 'Nom inconnu';
    final phoneNumber = _providerData['Phone'] as String? ?? '';
    final link = _providerData['Link'] as String? ?? '';
    final workingHours = _formatWorkingHours();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: const Color(0xFF1B9169),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B9169)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
                icon: const Icon(Icons.chat_outlined, color: Color(0xFF1B9169)),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(receiverId: widget.providerId),
                  ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ColorsManager.Green1, width: 2),
                    ),
                    child: _buildProfileImage(),
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          address,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStars(_averageRating),
                  Text(
                    "${_averageRating.toStringAsFixed(1)} (${_reviews.length} avis)",
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.Bgreen,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _showRequestDialog,
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.build, color: Colors.white),
                    ),
                    label: const Text('Demander', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const SizedBox(height: 16),

                  // Added rating button here - better position in the UI flow
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: ColorsManager.Green1,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: ColorsManager.Green1.withOpacity(0.5), width: 1),
                      ),
                    ),
                    onPressed: _showRatingDialog,
                    icon: const Icon(Icons.star_border, size: 20),
                    label: const Text(
                      'Noter & Commenter',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(thickness: 0.5, height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    horizontalTitleGap: 8,
                    leading: const Icon(Icons.calendar_today, color: ColorsManager.Green1, size: 20),
                    title: Text(workingHours, style: const TextStyle(fontSize: 13)),
                  ),
                  const Divider(thickness: 0.5, height: 10),

                  if (link.isNotEmpty) ...[
                    InkWell(
                      onTap: () => _launchUniversalUrl(link),
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 50,
                        child: const Center(
                          child: Row(
                            children: [
                              Icon(Icons.link, size: 20, color: ColorsManager.Green1),
                              SizedBox(width: 8),
                              Text("Open Link for more information"),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(thickness: 0.5, height: 10),
                  ],
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Avis des clients",
                        style: TextStyle(fontWeight: FontWeight.bold, color: ColorsManager.Green1, fontSize: 14)),
                  ),
                  const SizedBox(height: 8),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _reviews.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text("Aucun avis pour le moment.",
                                  style: TextStyle(fontSize: 13, color: Colors.grey)),
                            )
                          : Column(
                              children: _reviews.map((review) {
                                return ReviewCard(
                                  name: review['name'],
                                  comment: review['comment'],
                                  rating: review['rating'],
                                  date: review['date'],
                                  image: review['image'],
                                );
                              }).toList(),
                            ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}