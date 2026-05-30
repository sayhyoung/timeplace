import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../onboarding_screen.dart';
import '../stamp_settings.dart';
import 'topper_picker_sheet.dart';

const _sheetBg = Color(0xFFF8F5EF);
const _ink = Color(0xFF30323A);
const _muted = Color(0xFF746D64);
const _line = Color(0xFFE6DED3);
const _accent = Color(0xFF1F7A5C);

class StampSettingsSheet extends StatefulWidget {
  final StampConfiguration config;
  final ValueChanged<StampConfiguration> onChanged;
  final bool showPositionGrid;

  const StampSettingsSheet({
    super.key,
    required this.config,
    required this.onChanged,
    this.showPositionGrid = true,
  });

  @override
  State<StampSettingsSheet> createState() => _StampSettingsSheetState();
}

class _StampSettingsSheetState extends State<StampSettingsSheet> {
  static const _actionsChannel = MethodChannel('timeplace/actions');
  late StampConfiguration _config;
  late final TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _config = StampConfiguration(
      timeMode: widget.config.timeMode,
      hourFormat: widget.config.hourFormat,
      placeMode: widget.config.placeMode,
      position: widget.config.position,
      memo: widget.config.memo,
      fontScale: widget.config.fontScale,
      language: widget.config.language,
      styleId: widget.config.styleId,
      stampColor: widget.config.stampColor,
      memoSize: widget.config.memoSize,
      memoOutlineColor: widget.config.memoOutlineColor,
      memoTextColor: widget.config.memoTextColor,
      memoFont: widget.config.memoFont,
      tapToCapture: widget.config.tapToCapture,
      shutterSound: widget.config.shutterSound,
    );
    _memoController = TextEditingController(text: _config.memo);
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  void _update(void Function() fn) {
    setState(fn);
    widget.onChanged(_config);
  }

  Future<void> _pickTopper() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const TopperPickerSheet(),
    );
    if (picked != null && picked.isNotEmpty) {
      _memoController.text = picked;
      _memoController.selection = TextSelection.collapsed(
        offset: picked.length,
      );
      _update(() => _config.memo = picked);
    }
  }

  Future<void> _sendFeedback() async {
    try {
      await _actionsChannel.invokeMethod<void>('sendFeedback');
    } catch (_) {
      await Clipboard.setData(
        const ClipboardData(text: 'yoonsam2017@gmail.com'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('메일 주소를 클립보드에 복사했습니다.')));
    }
  }

  Future<void> _openReview() async {
    try {
      await _actionsChannel.invokeMethod<void>('openReview');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('스토어 페이지를 열지 못했습니다.')));
    }
  }

  Future<void> _openPrivacyPolicy() async {
    try {
      await _actionsChannel.invokeMethod<void>('openPrivacyPolicy');
    } catch (_) {
      await Clipboard.setData(
        const ClipboardData(
          text: 'https://sites.google.com/view/timestampcam/%ED%99%88',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('개인정보처리방침 URL을 복사했습니다.')));
    }
  }

  Future<void> _openTutorial() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Material(
        color: _sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8D0C6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                _sheetHeader(),
                const SizedBox(height: 16),
                _settingsCard(
                  icon: Icons.schedule,
                  title: '시간과 장소',
                  children: [
                    _sectionTitle('시간 스탬프'),
                    _dropdown<TimeStampMode>(
                      value: _config.timeMode,
                      items: TimeStampMode.values,
                      label: (m) => m.title,
                      onChanged: (v) => _update(() => _config.timeMode = v),
                    ),
                    if (_config.timeMode != TimeStampMode.off &&
                        _config.timeMode != TimeStampMode.date) ...[
                      const SizedBox(height: 12),
                      _sectionTitle('시간 표기'),
                      _choiceChips<TimeHourFormat>(
                        values: TimeHourFormat.values,
                        selected: _config.hourFormat,
                        label: (v) => v.title,
                        onSelected: (v) =>
                            _update(() => _config.hourFormat = v),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _sectionTitle('장소 스탬프'),
                    _dropdown<PlaceStampMode>(
                      value: _config.placeMode,
                      items: PlaceStampMode.values,
                      label: (m) => m.title,
                      onChanged: (v) => _update(() => _config.placeMode = v),
                    ),
                    if (_config.placeMode != PlaceStampMode.off) ...[
                      const SizedBox(height: 12),
                      _sectionTitle('주소 언어'),
                      _dropdown<StampLanguage>(
                        value: _config.language,
                        items: StampLanguage.values,
                        label: (l) => l.title,
                        onChanged: (v) => _update(() => _config.language = v),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _settingsCard(
                  icon: Icons.auto_awesome,
                  title: '메모 꾸미기',
                  trailing: FilledButton.icon(
                    onPressed: _pickTopper,
                    icon: const Icon(Icons.style_outlined, size: 16),
                    label: const Text('템플릿'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  children: [
                    TextFormField(
                      controller: _memoController,
                      onChanged: (v) => _update(() => _config.memo = v),
                      minLines: 1,
                      maxLines: 3,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                      decoration: _inputDecoration('예: 우리 지금 힐링중'),
                    ),
                    const SizedBox(height: 12),
                    _memoPreview(),
                    const SizedBox(height: 14),
                    _sectionTitle('폰트'),
                    _memoFontPicker(),
                    const SizedBox(height: 14),
                    _sectionTitle('글자색'),
                    _memoColorPicker(),
                    const SizedBox(height: 14),
                    _sectionTitle('크기'),
                    _choiceChips<MemoSize>(
                      values: MemoSize.values,
                      selected: _config.memoSize,
                      label: (v) => v.title,
                      onSelected: (v) => _update(() => _config.memoSize = v),
                    ),
                    const SizedBox(height: 14),
                    _sectionTitle('윤곽선'),
                    _choiceChips<MemoOutlineColor>(
                      values: MemoOutlineColor.values,
                      selected: _config.memoOutlineColor,
                      label: (v) => v.title,
                      onSelected: (v) =>
                          _update(() => _config.memoOutlineColor = v),
                    ),
                    const SizedBox(height: 14),
                    _sectionTitle(
                      '전체 글자 크기 ${(_config.fontScale * 100).round()}%',
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _accent,
                        inactiveTrackColor: const Color(0xFFDCD4CA),
                        thumbColor: _accent,
                        overlayColor: _accent.withValues(alpha: 0.14),
                        valueIndicatorColor: _ink,
                      ),
                      child: Slider(
                        value: _config.fontScale.clamp(
                          StampConfiguration.minFontScale,
                          StampConfiguration.maxFontScale,
                        ),
                        min: StampConfiguration.minFontScale,
                        max: StampConfiguration.maxFontScale,
                        divisions: 14,
                        label: '${(_config.fontScale * 100).round()}%',
                        onChanged: (v) => _update(() => _config.fontScale = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _settingsCard(
                  icon: Icons.camera_alt_outlined,
                  title: '촬영 동작',
                  children: [
                    _settingSwitch(
                      title: '화면 탭으로 촬영',
                      icon: Icons.touch_app_outlined,
                      value: _config.tapToCapture,
                      onChanged: (v) => _update(() => _config.tapToCapture = v),
                    ),
                    const SizedBox(height: 8),
                    _settingSwitch(
                      title: '셔터 효과음 / 진동',
                      icon: Icons.vibration,
                      value: _config.shutterSound,
                      onChanged: (v) => _update(() => _config.shutterSound = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _supportCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.tune, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            '스탬프 설정',
            style: TextStyle(
              color: _ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingsCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFECE5DA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _ink, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: _muted,
      ),
    ),
  );

  Widget _memoPreview() {
    final text = _config.memo.trim().isEmpty ? '우리 지금\n힐링중' : _config.memo;
    final size = 30 * _config.memoSize.scale;
    final base = _config.memoFont.style(fontSize: size);
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF34333B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x225A554E)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Icon(
              Icons.favorite,
              color: _config.memoTextColor.color.withValues(alpha: 0.22),
              size: 22,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(
              Icons.local_florist,
              color: _config.memoTextColor.color.withValues(alpha: 0.20),
              size: 24,
            ),
          ),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: base.copyWith(
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = size * 0.22
                      ..strokeJoin = StrokeJoin.round
                      ..color = _config.memoOutlineColor.color,
                  ),
                ),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: base.copyWith(color: _config.memoTextColor.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0x99817A70)),
      filled: true,
      fillColor: const Color(0xFFFDFBF7),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _settingSwitch({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Icon(icon, color: _muted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: _accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _supportCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline, color: _muted, size: 18),
              SizedBox(width: 8),
              Text(
                '도움말',
                style: TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _supportTile(
            icon: Icons.mail_outline,
            title: '제안/건의하기',
            subtitle: 'yoonsam2017@gmail.com',
            onTap: _sendFeedback,
          ),
          const Divider(color: _line, height: 18),
          _supportTile(
            icon: Icons.school_outlined,
            title: '튜토리얼 다시보기',
            subtitle: '처음 사용하는 흐름을 다시 확인합니다.',
            onTap: _openTutorial,
          ),
          const Divider(color: _line, height: 18),
          _supportTile(
            icon: Icons.star_border_rounded,
            title: '앱 리뷰하기',
            subtitle: '출시 후 스토어 리뷰로 연결됩니다.',
            onTap: _openReview,
          ),
          const Divider(color: _line, height: 18),
          _supportTile(
            icon: Icons.privacy_tip_outlined,
            title: '개인정보처리방침',
            subtitle: 'sites.google.com/view/timestampcam',
            onTap: _openPrivacyPolicy,
          ),
          const Divider(color: _line, height: 18),
          const Row(
            children: [
              Icon(Icons.info_outline, color: _muted, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '인증샷 카메라  1.1.2',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _supportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFECE5DA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _accent, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _memoFontPicker() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MemoFont.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final font = MemoFont.values[index];
          final selected = _config.memoFont == font;
          return GestureDetector(
            onTap: () => _update(() => _config.memoFont = font),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 112,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? _ink : const Color(0xFFFDFBF7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? _ink : _line, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '힐링',
                    maxLines: 1,
                    style: font.style(
                      fontSize: 24,
                      color: selected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    font.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white70 : Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _memoColorPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: MemoTextColor.values.map((value) {
        final selected = _config.memoTextColor == value;
        return GestureDetector(
          onTap: () => _update(() => _config.memoTextColor = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? _ink : Colors.transparent,
                width: 3,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value.color,
                border: Border.all(color: const Color(0x22000000)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) label,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      // ignore: deprecated_member_use
      value: value,
      dropdownColor: const Color(0xFFFFFCF7),
      borderRadius: BorderRadius.circular(14),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
      decoration: _inputDecoration(''),
      style: const TextStyle(
        color: _ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(value: item, child: Text(label(item))),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _choiceChips<T>({
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required ValueChanged<T> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final isSelected = value == selected;
        return ChoiceChip(
          label: Text(label(value)),
          selected: isSelected,
          onSelected: (_) => onSelected(value),
          selectedColor: _ink,
          backgroundColor: const Color(0xFFFDFBF7),
          side: BorderSide(color: isSelected ? _ink : _line),
          showCheckmark: false,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : _muted,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        );
      }).toList(),
    );
  }
}
