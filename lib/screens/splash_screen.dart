import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pageone.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();

    // Auto navigate after 2.8 seconds
    _navigationTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, animation, __) => const PageOne(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topHalfHeight = size.height * 0.53;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      body: Stack(
        children: [
          Column(
            children: [
              // --- 1. Top Section: Layered Curved Image ---
              SizedBox(
                height: topHalfHeight + 15,
                width: double.infinity,
                child: Stack(
                  children: [
                    // Background Shadow Curve Accent
                    Positioned.fill(
                      child: ClipPath(
                        clipper: BottomCurvedClipper(curveOffset: 12),
                        child: Container(
                          color: const Color(0xFF003830).withValues(alpha: 0.35),
                        ),
                      ),
                    ),

                    // Main Image with Smooth Bottom Curve
                    Positioned.fill(
                      child: ClipPath(
                        clipper: BottomCurvedClipper(curveOffset: 0),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/images/platano_splash.jpg',
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                            // Vignette / subtle gradient overlay at bottom of image
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.4),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- 2. Bottom Section: Stylish Brand Content ---
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),

                          // Luxury Brand Prefix Header with Deep Teal Bars
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 1.5,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Color(0xFF004D40),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'P L A T A N O',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4.5,
                                  color: Color(0xFF00332C),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 28,
                                height: 1.5,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF004D40),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Main Brand Typography with Deep Midnight Teal Gradient
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF00241E),
                                Color(0xFF003D34),
                                Color(0xFF002B24),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'Avil Milk',
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle Ribbon
                          const Text(
                            'The Authentic Malabar Taste',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF003830),
                              letterSpacing: 0.8,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Aesthetic Ingredient Chips
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPillTag('🥛 Fresh Milk'),
                              const SizedBox(width: 6),
                              _buildPillTag('🍌 Banana'),
                              const SizedBox(width: 6),
                              _buildPillTag('🥜 Roasted Nuts'),
                            ],
                          ),

                          const Spacer(),

                          // Modern Capsule Loading Indicator
                          Container(
                            width: 130,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const ClipRRect(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF003830)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Loading store & menu...',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF004D40),
                              letterSpacing: 0.2,
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // --- 3. Floating Emblem on the Apex of the Curve ---
          Positioned(
            top: topHalfHeight - 24,
            left: (size.width / 2) - 24,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF002B24).withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.teal.shade300,
                    width: 2.5,
                  ),
                ),
                child: const Icon(
                  Icons.local_cafe_rounded,
                  size: 24,
                  color: Color(0xFF003830),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.shade300),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF00332C),
        ),
      ),
    );
  }
}

/// Dynamic Curved Clipper with adjustable curve depth
class BottomCurvedClipper extends CustomClipper<Path> {
  final double curveOffset;
  BottomCurvedClipper({this.curveOffset = 0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40 + curveOffset);

    final controlPoint = Offset(size.width / 2, size.height + 25 + curveOffset);
    final endPoint = Offset(size.width, size.height - 40 + curveOffset);

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant BottomCurvedClipper oldClipper) =>
      oldClipper.curveOffset != curveOffset;
}
