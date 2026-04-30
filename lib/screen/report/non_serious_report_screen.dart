import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'report_submitted_screen.dart';
import '../services/api_service.dart';
import '../models/report.dart';
import '../map/location_picker_screen.dart';

class NonSeriousReportScreen extends StatefulWidget {
  const NonSeriousReportScreen({super.key});

  @override
  State<NonSeriousReportScreen> createState() => _NonSeriousReportScreenState();
}

class _NonSeriousReportScreenState extends State<NonSeriousReportScreen> {
  String selectedCrime = "";
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

  List<String> crimeTypes = [
    "Snatching",
    "Theft",
    "Harassment",
    "Assault",
    "Robbery",
    "Vandalism",
    "Other"
  ];

  void pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot select future time")));
          return;
        }
      }
      setState(() => selectedTime = time);
    }
  }

  void onSubmit() async {
    if (selectedCrime.isEmpty ||
        locationController.text.isEmpty ||
        _pickedLatLng == null ||
        selectedDate == null ||
        selectedTime == null ||
        descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields."), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final report = Report(
        type: 'non-serious',
        title: selectedCrime,
        description: descriptionController.text,
        location: locationController.text,
        area: _pickedLocationLabel.isNotEmpty ? _pickedLocationLabel : locationController.text,
        latitude: _pickedLatLng!.latitude,
        longitude: _pickedLatLng!.longitude,
        witnesses: witnessController.text.isEmpty ? null : witnessController.text,
        date: selectedDate,
        time: selectedTime,
      );

      await ApiService.submitReport(report, imageFile: _pickedImage);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ReportSubmittedScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Observational Report", style: AppTextStyles.sectionTitle),
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
            _buildSectionHeader("Crime Category", "What did you observe?"),
            const SizedBox(height: 16),
            _buildCrimeTypeGrid(),
            
            const SizedBox(height: 32),
            _buildSectionHeader("Incident details", "Where and when?"),
            const SizedBox(height: 16),
            _buildLocationAndDateTime(),
            
            const SizedBox(height: 32),
            _buildSectionHeader("Additional info", "Provide more context"),
            const SizedBox(height: 16),
            _buildDescriptionAndEvidence(),
            
            const SizedBox(height: 48),
            CustomButton(
              text: "Submit Report",
              isLoading: _isLoading,
              onPressed: onSubmit,
            ),
            const SizedBox(height: 40),
          ],
        ),
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
      children: crimeTypes.map((crime) {
        final bool isSelected = selectedCrime == crime;
        return GestureDetector(
          onTap: () => setState(() => selectedCrime = crime),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
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

  Widget _buildLocationAndDateTime() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTextStyles.premiumCard,
      child: Column(
        children: [
          CustomTextField(
            label: "Location Details",
            hint: "Building, shop, or landmark name",
            controller: locationController,
          ),
          const SizedBox(height: 16),
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
                      _pickedLatLng == null ? 'Pin incident on map*' : 'Location Pinned: $_pickedLocationLabel',
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

  Widget _buildDescriptionAndEvidence() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTextStyles.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: "Incident description",
            hint: "What happened specifically? Mention suspects, vehicles...",
            controller: descriptionController,
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: "Potential witnesses",
            hint: "Optional name or contact info",
            controller: witnessController,
          ),
          const SizedBox(height: 24),
          const Text("Evidence Upload", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                child: _btnIcon(
                  label: "Gallery",
                  icon: Icons.photo_library_outlined,
                  onPressed: () => _handleImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _btnIcon(
                  label: "Camera",
                  icon: Icons.camera_alt_outlined,
                  onPressed: () => _handleImage(ImageSource.camera),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btnIcon({required String label, required IconData icon, required VoidCallback onPressed}) {
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

  Future<void> _handleImage(ImageSource src) async {
    final x = await _imagePicker.pickImage(source: src, imageQuality: 70);
    if (x != null) {
      final b = await x.readAsBytes();
      if (b.length > 2 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 2MB file limit.')));
        return;
      }
      setState(() { _pickedImage = x; _pickedImageBytes = b; });
    }
  }
}
