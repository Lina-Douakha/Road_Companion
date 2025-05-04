import 'package:flutter/material.dart';
import 'login.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math' as math;

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _controller = PageController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _currentPage = 0;
  final int _totalPages = 5;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      _controller.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateToLogin();
    }
  }

  void goToPreviousPage() {
    if (_currentPage > 0) {
      _controller.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final Size screenSize = MediaQuery.of(context).size;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // Calculate responsive dimensions
    final double headerHeight = screenSize.height * 0.08;
    final double footerHeight = screenSize.height * 0.15;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background elements - made responsive with screen percentage
            Positioned(
              top: -screenSize.width * 0.25,
              right: -screenSize.width * 0.25,
              child: Container(
                width: screenSize.width * 0.5,
                height: screenSize.width * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x1200D47E),
                ),
              ),
            ),
            Positioned(
              bottom: -screenSize.width * 0.375,
              left: -screenSize.width * 0.125,
              child: Container(
                width: screenSize.width * 0.75,
                height: screenSize.width * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x1200D47E),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Header with navigation dots and skip button
                  Container(
                    height: headerHeight,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.05,
                      vertical: headerHeight * 0.2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        SizedBox(
                          width: headerHeight * 0.8,
                          height: headerHeight * 0.8,
                          child: _currentPage > 0
                              ? GestureDetector(
                            onTap: goToPreviousPage,
                            child: Container(
                              padding: EdgeInsets.all(headerHeight * 0.15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(headerHeight * 0.25),
                              ),
                              child: Icon(Icons.arrow_back_ios_new,
                                  size: headerHeight * 0.4,
                                  color: Color(0xFF1B9169)),
                            ),
                          )
                              : Container(),
                        ),

                        // Page indicators
                        Container(
                          height: headerHeight * 0.15,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              _totalPages,
                                  (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: EdgeInsets.symmetric(horizontal: headerHeight * 0.05),
                                height: headerHeight * 0.15,
                                width: _currentPage == index ? headerHeight * 0.4 : headerHeight * 0.15,
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? Color(0xFF00D47E)
                                      : Color(0xFFE0E0E0),
                                  borderRadius: BorderRadius.circular(headerHeight * 0.075),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Skip button
                        Container(
                          width: screenSize.width * 0.15,
                          height: headerHeight * 0.8,
                          alignment: Alignment.centerRight,
                          child: _currentPage < _totalPages - 1
                              ? GestureDetector(
                            onTap: _navigateToLogin,
                            child: Text(
                              "onboarding.skip".tr(),
                              style: TextStyle(
                                color: Color(0xFF1B9169),
                                fontSize: screenSize.width * 0.04,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                              : Container(),
                        ),
                      ],
                    ),
                  ),

                  // Main content with PageView
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        _buildOnboardingPage(
                          imagePath: 'Car_driving_bro.png',
                          title: "onboarding.title1".tr(),
                          screenSize: screenSize,
                        ),
                        _buildOnboardingPage(
                          imagePath: 'City_driver_bro.png',
                          title: "onboarding.title2".tr(),
                          screenSize: screenSize,
                        ),
                        _buildOnboardingPage(
                          imagePath: 'City_driver_pana.png',
                          title: "onboarding.title3".tr(),
                          screenSize: screenSize,
                        ),
                        _buildOnboardingPage(
                          imagePath: 'ORHG1K0_1.png',
                          title: "onboarding.title4".tr(),
                          screenSize: screenSize,
                        ),
                        _buildOnboardingPage(
                          imagePath: 'Car_driving_pana_1.png',
                          title: "Let's get started!",
                          isLastPage: true,
                          screenSize: screenSize,
                        ),
                      ],
                    ),
                  ),

                  // Navigation buttons
                  Container(
                    height: footerHeight,
                    padding: EdgeInsets.only(
                      bottom: math.max(bottomPadding, screenSize.height * 0.03),
                      top: screenSize.height * 0.02,
                    ),
                    child: _currentPage < _totalPages - 1
                        ? _buildNavigationButton(screenSize)
                        : _buildGetStartedButton(screenSize),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage({
    required String imagePath,
    required String title,
    required Size screenSize,
    bool isLastPage = false,
  }) {
    final double imageHeight = screenSize.height * 0.3;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Image container
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  height: imageHeight,
                  margin: EdgeInsets.symmetric(horizontal: screenSize.width * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenSize.width * 0.06),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenSize.width * 0.06),
                    child: Container(
                      color: Colors.white,
                      child: Hero(
                        tag: imagePath,
                        child: Image.asset(
                          'assets/images/$imagePath',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: screenSize.height * 0.05),

        // Title text
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.075),
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, double value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: screenSize.width * 0.055,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButton(Size screenSize) {
    final double buttonSize = screenSize.width * 0.175;

    return InkWell(
      onTap: goToNextPage,
      borderRadius: BorderRadius.circular(buttonSize),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: Color(0xFF00D47E),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFF00D47E).withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.arrow_forward,
            color: Colors.white,
            size: buttonSize * 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildGetStartedButton(Size screenSize) {
    // Fixed thin height for button
    final double buttonHeight = screenSize.height * 0.04;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: _navigateToLogin,
              child: Container(
                width: screenSize.width * 0.55,
                height: buttonHeight, // Fixed thin height
                decoration: BoxDecoration(
                  color: Color(0xFF00D47E),
                  borderRadius: BorderRadius.circular(buttonHeight / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00D47E).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "onboarding.start_button".tr(),
                        style: TextStyle(
                          fontSize: screenSize.width * 0.038,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: screenSize.width * 0.02),
                      AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(5 * _animation.value, 0),
                              child: Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: buttonHeight * 0.6,
                              ),
                            );
                          }
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}