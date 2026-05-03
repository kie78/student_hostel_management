// add_room_screen.dart
// Collects room configuration locally.
// The actual API call (POST /landlord/hostels/:hostelId/rooms) is made
// in AddHostelScreen._submit() after the hostel has been created, so that
// we have the real hostelId from the server.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'landlord_models.dart';

class AddRoomScreen extends StatefulWidget {
  final String hostelId;
  final RoomTypeEnum type;

  const AddRoomScreen({
    super.key,
    required this.hostelId,
    required this.type,
  });

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  int _roomCount = 1;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  String get _typeLabel =>
      widget.type == RoomTypeEnum.singleSelfContained
          ? 'Single Self-Contained'
          : 'Double Self-Contained';

  String get _typeEmoji =>
      widget.type == RoomTypeEnum.singleSelfContained ? '🛏️' : '🛏️🛏️';

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Build a local LandlordRoom object.
    // If hostelId is 'new' (called from AddHostelScreen before creation),
    // the real hostelId will be filled in by AddHostelScreen._submit().
    final room = LandlordRoom(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      hostelId: widget.hostelId,
      type: widget.type,
      pricePerMonth:
          double.parse(_priceController.text.replaceAll(',', '')),
      totalSlots:
          widget.type == RoomTypeEnum.singleSelfContained ? 1 : 2,
      roomCount: _roomCount,
    );

    Navigator.pop(context, room);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006B4F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Add $_typeLabel',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF006B4F), Color(0xFF00A876)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(_typeEmoji,
                        style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_typeLabel,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                          Text(
                            widget.type ==
                                    RoomTypeEnum.singleSelfContained
                                ? 'Private room with personal bathroom'
                                : 'Shared room for 2 students with bathroom',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _SectionLabel2(
                  icon: Icons.bed_rounded, label: 'Capacity'),
              const SizedBox(height: 10),

              // Read-only capacity display (hardcoded by room type)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people_outline,
                        color: const Color(0xFF006B4F), size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Accommodates',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        Text(
                          widget.type ==
                                  RoomTypeEnum.singleSelfContained
                              ? '1 student per room'
                              : '2 students per room',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF0D1147)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _SectionLabel2(
                  icon: Icons.meeting_room_outlined,
                  label: 'Number of Rooms'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _roomCount > 1
                          ? () => setState(() => _roomCount--)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _roomCount > 1
                              ? const Color(0xFF006B4F).withValues(alpha: 0.08)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.remove_rounded,
                          color: _roomCount > 1
                              ? const Color(0xFF006B4F)
                              : Colors.grey.shade400,
                          size: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$_roomCount',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D1147),
                            ),
                          ),
                          Text(
                            _roomCount == 1 ? 'room' : 'rooms',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _roomCount++),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006B4F).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Color(0xFF006B4F),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _SectionLabel2(
                  icon: Icons.payments_outlined, label: 'Pricing'),
              const SizedBox(height: 14),

              // Price field — API field: price (UGX per semester)
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Price is required';
                  }
                  final price = double.tryParse(v);
                  if (price == null || price <= 0) {
                    return 'Enter a valid price';
                  }
                  if (price < 50000) {
                    return 'Minimum price is UGX 50,000';
                  }
                  return null;
                },
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1147)),
                decoration: _inputDeco(
                  label: 'Price per Semester (UGX)',
                  hint: 'e.g. 350000',
                  icon: Icons.payments_outlined,
                ),
              ),

              const SizedBox(height: 8),
              Text(
                'Suggested: Single S/C: UGX 250K–450K | Double S/C: UGX 180K–300K',
                style:
                    TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
              ),

              const SizedBox(height: 32),

              // Save button
              GestureDetector(
                onTap: _submit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF006B4F), Color(0xFF00A876)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFF006B4F).withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Save Room Type ✓',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco({
    required String label,
    required String hint,
    required IconData icon,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon:
            Icon(icon, color: const Color(0xFF006B4F), size: 20),
        filled: true,
        fillColor: Colors.white,
        labelStyle:
            TextStyle(color: Colors.grey.shade500, fontSize: 13),
        hintStyle:
            TextStyle(color: Colors.grey.shade300, fontSize: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFF006B4F), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 15),
      );
}

class _SectionLabel2 extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel2({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF006B4F)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF006B4F))),
        ],
      );
}