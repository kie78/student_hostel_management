// add_hostel_screen.dart
// Creates a new hostel via POST /landlord/hostels (multipart/form-data).
// API fields: hostel_name, location, description, whatsapp_number, images[].
// After the hostel is created, rooms are created one-by-one via
// POST /landlord/hostels/:hostelId/rooms.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'add_room_screen.dart';
import 'landlord_models.dart';

class AddHostelScreen extends StatefulWidget {
  const AddHostelScreen({super.key});

  @override
  State<AddHostelScreen> createState() => _AddHostelScreenState();
}

class _AddHostelScreenState extends State<AddHostelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostelNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _whatsappController = TextEditingController();

  final List<XFile> _images = [];
  final List<LandlordRoom> _rooms = [];
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _hostelNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  // ── Image Picker ─────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty && mounted) {
      setState(() {
        final remaining = 5 - _images.length;
        _images.addAll(picked.take(remaining));
      });
    }
  }

  void _removeImage(int index) => setState(() => _images.removeAt(index));

  // ── Rooms ─────────────────────────────────────────────────────────────────

  Future<void> _openAddRoom(RoomTypeEnum type) async {
    final room = await Navigator.push<LandlordRoom>(
      context,
      MaterialPageRoute(
        builder: (_) => AddRoomScreen(hostelId: 'new', type: type),
      ),
    );
    if (room != null && mounted) {
      setState(() => _rooms.add(room));
    }
  }

  void _removeRoom(int index) => setState(() => _rooms.removeAt(index));

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add at least one room before submitting.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final createdHostel = await ApiService.createHostel(
        hostelName: _hostelNameController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        imagePaths: _images.map((x) => x.path).toList(),
      );

      final createdRooms = <LandlordRoom>[];
      for (final room in _rooms) {
        final created = await ApiService.createRoom(
          hostelId: createdHostel.id,
          room: LandlordRoom(
            id: room.id,
            hostelId: createdHostel.id,
            type: room.type,
            pricePerMonth: room.pricePerMonth,
            totalSlots: room.totalSlots,
          ),
        );
        createdRooms.add(created);
      }

      final hydrated = LandlordHostel(
        id: createdHostel.id,
        name: createdHostel.name,
        location: createdHostel.location,
        district: createdHostel.district,
        description: createdHostel.description,
        whatsappNumber: createdHostel.whatsappNumber,
        imageUrls: createdHostel.imageUrls,
        rooms: createdRooms,
        createdAt: createdHostel.createdAt,
        isActive: createdHostel.isActive,
      );

      LandlordStore.addHostel(hydrated);

      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final message = e.response?.data?['message']?.toString() ??
          'Failed to create hostel. Please try again.';
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unexpected error while creating hostel.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            elevation: 0,
            backgroundColor: const Color(0xFF006B4F),
            systemOverlayStyle: SystemUiOverlayStyle.light,
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
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF006B4F), Color(0xFF00A876)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text('Add Hostel',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text(
                            'Fill in the details below to list your property',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              // ── Hostel Info ──────────────────────────────────────────
              const _SectionHeader(
                  icon: Icons.apartment_rounded, label: 'Hostel Details'),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  children: [
                    _Field(
                      controller: _hostelNameController,
                      label: 'Hostel Name',
                      hint: 'e.g. Green Towers Hostel',
                      icon: Icons.apartment_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Hostel name is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      controller: _locationController,
                      label: 'Location / Address',
                      hint: 'e.g. Kikoni, Kampala',
                      icon: Icons.location_on_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Location is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      controller: _whatsappController,
                      label: 'WhatsApp Number',
                      hint: 'e.g. 256701234567',
                      icon: Icons.chat_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'WhatsApp number is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      controller: _descriptionController,
                      label: 'Description',
                      hint:
                          'Describe your hostel — location details, nearby landmarks, special features…',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Description is required'
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Photos ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionHeader(
                      icon: Icons.photo_library_outlined,
                      label: 'Photos'),
                  Text('${_images.length}/5',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_images.isNotEmpty) ...[
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(_images[i].path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(i),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_images.length < 5)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006B4F)
                                .withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF006B4F)
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  color: const Color(0xFF006B4F)
                                      .withValues(alpha: 0.6),
                                  size: 32),
                              const SizedBox(height: 6),
                              Text(
                                _images.isEmpty
                                    ? 'Tap to add photos'
                                    : 'Add more photos',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: const Color(0xFF006B4F)
                                        .withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text('Up to 5 images',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade400)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Rooms ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionHeader(
                      icon: Icons.bed_rounded, label: 'Capacity'),
                  if (_rooms.isNotEmpty)
                    Text('${_rooms.length} added',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF006B4F))),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _AddRoomButton(
                      label: 'Single S/C',
                      icon: Icons.single_bed_rounded,
                      onTap: () =>
                          _openAddRoom(RoomTypeEnum.singleSelfContained),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AddRoomButton(
                      label: 'Double S/C',
                      icon: Icons.bedroom_parent_rounded,
                      onTap: () =>
                          _openAddRoom(RoomTypeEnum.doubleSelfContained),
                    ),
                  ),
                ],
              ),

              if (_rooms.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._rooms.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RoomTile(
                        room: e.value,
                        onRemove: () => _removeRoom(e.key),
                      ),
                    )),
              ],

              const SizedBox(height: 32),

              // ── Submit ───────────────────────────────────────────────
              GestureDetector(
                onTap: _isSubmitting ? null : _submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isSubmitting
                          ? [Colors.grey.shade400, Colors.grey.shade400]
                          : const [Color(0xFF006B4F), Color(0xFF00A876)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isSubmitting
                        ? []
                        : [
                            BoxShadow(
                              color: const Color(0xFF006B4F)
                                  .withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white)),
                          )
                        : const Text(
                            'Create Hostel',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Local Widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF006B4F)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D1147))),
        ],
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0D1147)),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon:
              Icon(icon, color: const Color(0xFF006B4F), size: 20),
          filled: true,
          fillColor: const Color(0xFFF8F9FE),
          labelStyle:
              TextStyle(color: Colors.grey.shade500, fontSize: 13),
          hintStyle:
              TextStyle(color: Colors.grey.shade300, fontSize: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF006B4F), width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.red, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

class _AddRoomButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _AddRoomButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF006B4F).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF006B4F).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    color: const Color(0xFF006B4F), size: 20),
              ),
              const SizedBox(height: 6),
              Text('+ $label',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF006B4F))),
            ],
          ),
        ),
      );
}

class _RoomTile extends StatelessWidget {
  final LandlordRoom room;
  final VoidCallback onRemove;
  const _RoomTile({required this.room, required this.onRemove});

  String _formatUGX(double v) {
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF006B4F).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                room.type == RoomTypeEnum.singleSelfContained
                    ? Icons.single_bed_rounded
                    : Icons.bedroom_parent_rounded,
                color: const Color(0xFF006B4F),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.typeShort,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF0D1147))),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatUGX(room.pricePerMonth)} / sem  ·  '
                    '${room.totalSlots} slot${room.totalSlots != 1 ? 's' : ''}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 16),
              ),
            ),
          ],
        ),
      );
}
