import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../services/api_service.dart';
import '../models/report.dart';
import 'report_submitted_screen.dart';
import '../map/location_picker_screen.dart';

class SeriousReportScreen extends StatefulWidget {
  const SeriousReportScreen({super.key});

  @override
  State<SeriousReportScreen> createState() => _SeriousReportScreenState();
}

class _SeriousReportScreenState extends State<SeriousReportScreen> {
  // Form State
  String selectedCrime = "";
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  final witnessController = TextEditingController();

  LatLng? _pickedLatLng;
  String _pickedLocationLabel = '';
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  final _imagePicker = ImagePicker();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    selectedTime = TimeOfDay.now();
    _initCurrentLocation();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    try {
      final profile = await ApiService.fetchUserProfile();
      if (profile != null && profile['phoneNumber'] != null) {
        setState(() {
          phoneController.text = profile['phoneNumber'] ?? '';
        });
      }
    } catch (e) {
      print("Error loading user phone: $e");
    }
  }

  Future<void> _initCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDialog();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return;
    } 

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _pickedLatLng = LatLng(position.latitude, position.longitude);
        _pickedLocationLabel = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        locationController.text = "GPS Coordinates: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
      });
    } catch (e) {
      print("Error getting position: $e");
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Location Services Disabled"),
        content: const Text("Please enable location services to automatically tag your incident's coordinates."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  final List<String> seriousCrimeTypes = [
    "Kidnapping",
    "Attempted Murder",
    "Sexual Assault",
    "Armed Robbery",
    "Homicide",
    "Severe Violence",
    "Terror Threat",
    "Other Serious"
  ];

  void pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) setState(() => selectedDate = date);
  }

  void pickTime() async {
    final now = DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      if (selectedDate != null &&
          selectedDate!.year == now.year &&
          selectedDate!.month == now.month &&
          selectedDate!.day == now.day) {
        final selectedDateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        if (selectedDateTime.isAfter(now)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cannot select future time for today's date")),
          );
          return;
        }
      }
      setState(() => selectedTime = time);
    }
  }


  void onSubmit() async {
    if (selectedCrime.isEmpty ||
        phoneController.text.length != 11 ||
        locationController.text.isEmpty ||
        _pickedLatLng == null ||
        selectedDate == null ||
        selectedTime == null ||
        (selectedCrime == 'Other Serious' && descriptionController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields and confirm the location."), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final report = Report(
        type: 'serious',
        title: selectedCrime,
        description: descriptionController.text,
        location: locationController.text,
        area: _pickedLocationLabel.isNotEmpty ? _pickedLocationLabel : locationController.text,
        latitude: _pickedLatLng!.latitude,
        longitude: _pickedLatLng!.longitude,
        witnesses: witnessController.text.isNotEmpty ? witnessController.text : null,
        date: selectedDate,
        time: selectedTime,
      );

      final crimeId = await ApiService.submitReport(report, imageFile: _pickedImage);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ReportSubmittedScreen(crimeId: crimeId)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Street Crime Report", style: AppTextStyles.sectionTitle),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWarningHeader(),
            const SizedBox(height: 32),
            
            _buildSectionHeader("Incident Category", "Select the type of crime"),
            const SizedBox(height: 16),
            _buildCrimeTypeGrid(),
            
            const SizedBox(height: 32),
            _buildSectionHeader("Reporter Identity", "Verification is mandatory"),
            const SizedBox(height: 16),
            _buildIdentityFields(),
            
            const SizedBox(height: 32),
            _buildSectionHeader("Occurrence Details", "Where and when did it happen?"),
            const SizedBox(height: 16),
            _buildOccurrenceFields(),
            
            const SizedBox(height: 32),
            _buildSectionHeader("Evidence & Testimony", "Photos and detailed description"),
            const SizedBox(height: 16),
            _buildEvidenceFields(),
            
            const SizedBox(height: 48),
            CustomButton(
              text: "Submit Official Report",
              isLoading: _isLoading,
              color: AppColors.danger,
              onPressed: onSubmit,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.gavel_rounded, color: AppColors.danger, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Legal Compliance Required", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  "Providing false information to law enforcement is a punishable offense. Ensure all details are accurate.",
                  style: TextStyle(color: AppColors.danger.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        const SizedBox(height: 2),
        Text(subtitle, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildCrimeTypeGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: seriousCrimeTypes.map((crime) {
        final bool isSelected = selectedCrime == crime;
        return GestureDetector(
          onTap: () => setState(() => selectedCrime = crime),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.danger : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.danger : AppColors.border,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppColors.danger.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                  : [],
            ),
            child: Text(
              crime,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.primary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIdentityFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTextStyles.premiumCard,
      child: Column(
        children: [
          CustomTextField(
            label: "Contact Mobile",
            hint: "03XXXXXXXXX",
            controller: phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 11,
          ),
        ],
      ),
    );
  }

  Widget _buildOccurrenceFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTextStyles.premiumCard,
      child: Column(
        children: [
          CustomTextField(
            label: "Incident Location / Landmark",
            hint: "e.g. Near Model Town Entrance",
            controller: locationController,
          ),
          const SizedBox(height: 16),
          // MAP PICKER BUTTON
          InkWell(
            onTap: () async {
              final picked = await Navigator.push<LatLng>(
                context,
                MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
              );
              if (picked != null) {
                setState(() {
                  _pickedLatLng = picked;
                  _pickedLocationLabel = '${picked.latitude.toStringAsFixed(4)}, ${picked.longitude.toStringAsFixed(4)}';
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: _pickedLatLng == null ? AppColors.accent.withOpacity(0.05) : AppColors.success.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _pickedLatLng == null ? AppColors.accent : AppColors.success,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _pickedLatLng == null ? Icons.add_location_alt_outlined : Icons.check_circle_rounded,
                    color: _pickedLatLng == null ? AppColors.accent : AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _pickedLatLng == null ? 'Pin exact location on map*' : 'Location Pinned: $_pickedLocationLabel',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _pickedLatLng == null ? AppColors.accent : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildPickerTile(
                  title: "Date",
                  value: selectedDate == null ? "Select" : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                  icon: Icons.calendar_today_rounded,
                  onTap: pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPickerTile(
                  title: "Time",
                  value: selectedTime == null ? "Select" : selectedTime!.format(context),
                  icon: Icons.access_time_rounded,
                  onTap: pickTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickerTile({required String title, required String value, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTextStyles.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedCrime == 'Other Serious') ...[
            CustomTextField(
              label: "Detailed Description",
              hint: "Provide suspect descriptions, vehicle numbers, or injury details...",
              controller: descriptionController,
              maxLines: 5,
            ),
            const SizedBox(height: 20),
          ],
          CustomTextField(
            label: "Witness Contact Info (Optional)",
            hint: "Name - Phone number",
            controller: witnessController,
          ),
          const SizedBox(height: 24),
          const Text("Visual Evidence", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          if (_pickedImageBytes != null) ...[
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_pickedImageBytes!, height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
                IconButton(
                  onPressed: () => setState(() { _pickedImage = null; _pickedImageBytes = null; }),
                  icon: const CircleAvatar(backgroundColor: Colors.white, radius: 14, child: Icon(Icons.close, color: AppColors.danger, size: 18)),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _imageSourceBtn(
                  label: "Gallery",
                  icon: Icons.photo_library_outlined,
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _imageSourceBtn(
                  label: "Camera",
                  icon: Icons.camera_alt_outlined,
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imageSourceBtn({required String label, required IconData icon, required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _imagePicker.pickImage(source: source, imageQuality: 70);
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image too large (> 2MB)')));
        return;
      }
      setState(() { _pickedImage = xfile; _pickedImageBytes = bytes; });
    }
  }
}
