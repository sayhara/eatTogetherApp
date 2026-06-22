import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import 'location_picker_screen.dart';

class GatheringEditScreen extends ConsumerStatefulWidget {
  final int gatheringId;
  const GatheringEditScreen({super.key, required this.gatheringId});

  @override
  ConsumerState<GatheringEditScreen> createState() => _GatheringEditScreenState();
}

class _GatheringEditScreenState extends ConsumerState<GatheringEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  LocationResult? _selectedLocation;
  DateTime? _mealTime;
  int _maxParticipants = 4;
  String? _category;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _categories = ['한식', '중식', '일식', '양식', '분식', '카페', '기타'];
  static const _categoryEnum = {
    '한식': 'KOREAN', '중식': 'CHINESE', '일식': 'JAPANESE',
    '양식': 'WESTERN', '분식': 'FAST_FOOD', '카페': 'CAFE', '기타': 'OTHER',
  };
  static const _enumCategory = {
    'KOREAN': '한식', 'CHINESE': '중식', 'JAPANESE': '일식',
    'WESTERN': '양식', 'FAST_FOOD': '분식', 'CAFE': '카페', 'OTHER': '기타',
  };

  @override
  void initState() {
    super.initState();
    _loadGathering();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadGathering() async {
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.dio.get('/api/gatherings/${widget.gatheringId}');
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      setState(() {
        _titleController.text = data['title'] as String? ?? '';
        _descriptionController.text = data['description'] as String? ?? '';
        _maxParticipants = data['maxParticipants'] as int? ?? 4;
        _category = _enumCategory[data['category'] as String? ?? ''];
        final mealTimeStr = data['mealTime'] as String?;
        if (mealTimeStr != null) _mealTime = DateTime.parse(mealTimeStr);

        final name = data['restaurantName'] as String? ?? '';
        final address = data['address'] as String? ?? '';
        if (name.isNotEmpty) {
          _selectedLocation = LocationResult(
            name: name,
            address: address,
            latitude: (data['latitude'] as num?)?.toDouble(),
            longitude: (data['longitude'] as num?)?.toDouble(),
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('불러오기 실패: $e')),
        );
        context.pop();
      }
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _mealTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _mealTime != null
          ? TimeOfDay(hour: _mealTime!.hour, minute: _mealTime!.minute)
          : TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _mealTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (result != null) setState(() => _selectedLocation = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모임 장소를 선택해주세요')),
      );
      return;
    }
    if (_mealTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('식사 시간을 선택해주세요')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.dio.put('/api/gatherings/${widget.gatheringId}', data: {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null : _descriptionController.text.trim(),
        'restaurantName': _selectedLocation!.name,
        'address': _selectedLocation!.address.isEmpty ? null : _selectedLocation!.address,
        'category': _category != null ? _categoryEnum[_category] : null,
        'maxParticipants': _maxParticipants,
        'mealTime': _mealTime!.toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수정 완료!')),
        );
        context.pop();
      }
    } catch (e) {
      String msg = e.toString();
      if (e is DioException) msg = '${e.response?.statusCode}: ${e.response?.data}';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('오류: $msg'), duration: const Duration(seconds: 8)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MM월 dd일 HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('모임 수정'),
        backgroundColor: const Color(0xFF03C75A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF03C75A)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionLabel('모임 제목 *'),
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration('제목을 입력하세요'),
                    maxLength: 50,
                    validator: (v) => v == null || v.trim().isEmpty ? '제목을 입력하세요' : null,
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('모임 장소 *'),
                  GestureDetector(
                    onTap: _openLocationPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _selectedLocation == null
                          ? Row(children: [
                              Icon(Icons.location_on_outlined, color: Colors.grey.shade500),
                              const SizedBox(width: 8),
                              Text('위치 선택', style: TextStyle(color: Colors.grey.shade500)),
                              const Spacer(),
                              Icon(Icons.chevron_right, color: Colors.grey.shade400),
                            ])
                          : Row(children: [
                              const Icon(Icons.location_on, color: Color(0xFF03C75A)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedLocation!.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    if (_selectedLocation!.address.isNotEmpty)
                                      Text(
                                        _selectedLocation!.address,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.grey.shade400),
                            ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('카테고리'),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: _inputDecoration('카테고리 선택'),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _category = v),
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('식사 시간 *'),
                  InkWell(
                    onTap: _pickDateTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Color(0xFF03C75A)),
                          const SizedBox(width: 8),
                          Text(
                            _mealTime != null ? fmt.format(_mealTime!) : '식사 시간을 선택하세요',
                            style: TextStyle(color: _mealTime != null ? Colors.black : Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('최대 인원 *'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _maxParticipants > 2 ? () => setState(() => _maxParticipants--) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF03C75A),
                      ),
                      Text('$_maxParticipants명', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      IconButton(
                        onPressed: _maxParticipants < 10 ? () => setState(() => _maxParticipants++) : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF03C75A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('모임 소개'),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: _inputDecoration('모임에 대해 소개해주세요 (선택)'),
                    maxLines: 3,
                    maxLength: 200,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF03C75A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('수정 완료', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }
}
