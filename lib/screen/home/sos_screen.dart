import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../services/api_service.dart';
import 'sos_tracker_screen.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  bool _isSilent = false;
  bool _isHolding = false;
  double _holdProgress = 0.0; // 0.0 to 1.0
  Timer? _timer;
  int _secondsLeft = 3;
  
  late AnimationController _pulsingController;
  late Animation<double> _pulsingAnimation;

  @override
  void initState() {
    super.initState();
    _pulsingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulsingAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulsingController, curve: Curves.easeInOut),
    );

    // Proactively ask for location permissions so they are ready
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _pulsingController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  void _startHolding() {
    setState(() {
      _isHolding = true;
      _holdProgress = 0.0;
      _secondsLeft = 3;
    });

    const tickDuration = Duration(milliseconds: 100);
    int ticks = 0;

    _timer = Timer.periodic(tickDuration, (timer) {
      ticks++;
      setState(() {
        _holdProgress = ticks / 30.0; // 3 seconds = 30 ticks of 100ms
        _secondsLeft = 3 - (ticks ~/ 10);
      });

      // Provide vibration feedback if not silent
      if (!_isSilent) {
        if (ticks % 5 == 0) {
          HapticFeedback.mediumImpact();
        }
      }

      if (ticks >= 30) {
        _timer?.cancel();
        _triggerSos();
      }
    });
  }

  void _stopHolding() {
    _timer?.cancel();
    if (_isHolding) {
      setState(() {
        _isHolding = false;
        _holdProgress = 0.0;
        _secondsLeft = 3;
      });
      if (!_isSilent) {
        HapticFeedback.lightImpact();
      }
    }
  }

  Future<void> _triggerSos() async {
    // Show quick triggering sheet
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.danger),
                SizedBox(height: 20),
                Text(
                  "Sending Emergency Alert...",
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
        ),
      ),
    );

    double latitude = 34.1688;
    double longitude = 73.2215;

    try {
      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        latitude = pos.latitude;
        longitude = pos.longitude;
      }
    } catch (e) {
      print("Location error on SOS: $e");
    }

    // Call API
    final crime = await ApiService.submitSosAlert(latitude, longitude, _isSilent);
    
    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading dialog

    if (crime != null) {
      // Success, open Tracker
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SosTrackerScreen(
            crimeId: crime['id'],
            isSilent: _isSilent,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to submit SOS. Attempting local alert..."),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Background color shifts to dark red if holding
    final backgroundColor = _isHolding && !_isSilent
        ? Colors.red.shade900
        : AppColors.background;

    final textColor = _isHolding && !_isSilent ? Colors.white : AppColors.primary;
    final subtitleColor = _isHolding && !_isSilent ? Colors.white70 : AppColors.secondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Header
              Text(
                'Emergency SOS Link',
                style: AppTextStyles.title.copyWith(color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                _isHolding
                    ? 'KEEP HOLDING FOR $_secondsLeft SECONDS'
                    : 'Press and hold the button below for 3 seconds to alert emergency units.',
                style: AppTextStyles.subtitle.copyWith(color: subtitleColor),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Animated SOS Button
              GestureDetector(
                onTapDown: (_) => _startHolding(),
                onTapUp: (_) => _stopHolding(),
                onTapCancel: () => _stopHolding(),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing Alarm ring (hidden in silent mode or if holding)
                      if (!_isSilent && !_isHolding)
                        ScaleTransition(
                          scale: _pulsingAnimation,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.danger.withOpacity(0.15),
                            ),
                          ),
                        ),

                      // Outer circular progress ring showing hold duration
                      SizedBox(
                        width: 210,
                        height: 210,
                        child: CircularProgressIndicator(
                          value: _holdProgress,
                          strokeWidth: 8,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isSilent ? Colors.grey : AppColors.danger,
                          ),
                        ),
                      ),

                      // Actual Button Circle
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isSilent ? Colors.black87 : AppColors.danger,
                          boxShadow: [
                            BoxShadow(
                              color: (_isSilent ? Colors.black : AppColors.danger).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.offline_bolt_rounded,
                                color: Colors.white,
                                size: _isHolding ? 48 : 54,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isHolding ? 'HOLDING' : 'SOS',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
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

              const Spacer(),

              // Silent SOS Option card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _isHolding && !_isSilent ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _isHolding && !_isSilent
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSilent ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: _isSilent ? Colors.grey : AppColors.accent,
                      size: 26,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send SOS Silently',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _isHolding && !_isSilent ? Colors.white : AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bypasses sound, alarms, and dims the screen for stealth.',
                            style: TextStyle(
                              fontSize: 11,
                              color: _isHolding && !_isSilent ? Colors.white60 : AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isSilent,
                      onChanged: (val) {
                        setState(() => _isSilent = val);
                        HapticFeedback.lightImpact();
                      },
                      activeColor: AppColors.accent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
