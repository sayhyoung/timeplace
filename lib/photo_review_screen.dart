import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'main.dart' show currentSystemLanguageCode;
import 'services/capture_db.dart';
import 'services/capture_record.dart';
import 'services/share_service.dart';
import 'stamp_renderer.dart';
import 'stamp_settings.dart';
import 'stamp_style.dart';
import 'widgets/outlined_stamp_text.dart';
import 'widgets/stamp_settings_sheet.dart';
import 'widgets/timemark_stamp.dart';

enum _ReviewPanelMode { style, color }

class PhotoReviewScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final DateTime capturedAt;
  final LocalizedAddress address;
  final ({double lat, double lon})? coordinate;
  final StampConfiguration initialConfig;

  /// 촬영 시 이미 디코드된 픽셀 크기. 주어지면 리뷰에서 재디코드를 생략해
  /// 화면 진입 지연을 줄인다.
  final Size? initialImageSize;

  const PhotoReviewScreen({
    super.key,
    required this.imageBytes,
    required this.capturedAt,
    required this.address,
    required this.coordinate,
    required this.initialConfig,
    this.initialImageSize,
  });

  @override
  State<PhotoReviewScreen> createState() => _PhotoReviewScreenState();
}

class _PhotoReviewScreenState extends State<PhotoReviewScreen> {
  late StampConfiguration _config;
  Offset? _infoCenter;
  Offset? _memoCenter;
  bool _saving = false;
  bool _sharing = false;
  _ReviewPanelMode _panelMode = _ReviewPanelMode.style;
  late String _moodId;
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _config = StampConfiguration(
      timeMode: widget.initialConfig.timeMode,
      hourFormat: widget.initialConfig.hourFormat,
      placeMode: widget.initialConfig.placeMode,
      position: widget.initialConfig.position,
      memo: widget.initialConfig.memo,
      fontScale: widget.initialConfig.fontScale,
      language: widget.initialConfig.language,
      styleId: widget.initialConfig.styleId,
      stampColor: widget.initialConfig.stampColor,
      memoSize: widget.initialConfig.memoSize,
      memoOutlineColor: widget.initialConfig.memoOutlineColor,
      memoTextColor: widget.initialConfig.memoTextColor,
      memoFont: widget.initialConfig.memoFont,
      tapToCapture: widget.initialConfig.tapToCapture,
      shutterSound: widget.initialConfig.shutterSound,
    );
    _moodId = _moodIdForStyle(_config.styleId);
    final preSize = widget.initialImageSize;
    if (preSize != null && preSize.width > 0 && preSize.height > 0) {
      _imageSize = preSize;
    } else {
      _decodeImage();
    }
  }

  Future<void> _decodeImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(
      () => _imageSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      ),
    );
  }

  List<String> get _infoLines => _config.infoLines(
    widget.capturedAt,
    widget.address,
    widget.coordinate,
    systemLanguageCode: currentSystemLanguageCode(),
  );

  String? get _memoText => _config.memoText;

  Color get _effectiveStampColor {
    return _config.stampColor ?? StampStyle.byId(_config.styleId).textColor;
  }

  Color get _effectiveStrokeColor {
    final color = _effectiveStampColor;
    return _config.stampColor == null
        ? StampStyle.byId(_config.styleId).strokeColor
        : (color.computeLuminance() > 0.55
              ? const Color(0xAA000000)
              : const Color(0xCCFFFFFF));
  }

  Offset _anchorFor(StampPosition p) {
    switch (p) {
      case StampPosition.topLeft:
        return const Offset(0.20, 0.10);
      case StampPosition.topCenter:
        return const Offset(0.50, 0.10);
      case StampPosition.topRight:
        return const Offset(0.80, 0.10);
      case StampPosition.middleLeft:
        return const Offset(0.20, 0.50);
      case StampPosition.center:
        return const Offset(0.50, 0.50);
      case StampPosition.middleRight:
        return const Offset(0.80, 0.50);
      case StampPosition.bottomLeft:
        return const Offset(0.20, 0.90);
      case StampPosition.bottomCenter:
        return const Offset(0.50, 0.90);
      case StampPosition.bottomRight:
        return const Offset(0.80, 0.90);
    }
  }

  Offset get _resolvedInfoCenter => _infoCenter ?? _anchorFor(_config.position);
  Offset get _resolvedMemoCenter {
    if (_memoCenter != null) return _memoCenter!;
    // 기본은 info 위치 위쪽으로 약간 띄움 (없으면 가운데 살짝 위)
    final base = _anchorFor(_config.position);
    final dy = (base.dy - 0.12).clamp(0.05, 0.95);
    return Offset(base.dx, dy);
  }

  Future<void> _openEditSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StampSettingsSheet(
        config: _config,
        showPositionGrid: false,
        onChanged: (updated) => setState(() => _config = updated),
      ),
    );
  }

  Future<void> _save() async {
    final imageSize = _imageSize;
    if (_saving || imageSize == null) return;
    setState(() => _saving = true);
    try {
      final stamped = await _renderStamped();
      final saved = await _persistCapture(stamped);

      if (!mounted) return;
      Navigator.of(context).pop(saved.thumbnailBytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진 저장에 실패했습니다.')));
    }
  }

  Future<void> _share() async {
    final imageSize = _imageSize;
    if (_sharing || imageSize == null) return;
    setState(() => _sharing = true);
    try {
      final stamped = await _renderStamped();
      final sharePath = await CaptureFiles.saveForShare(stamped);
      await ShareService.shareImage(sharePath, text: '인증샷 카메라');
      if (!mounted) return;
      setState(() => _sharing = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sharing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공유를 시작하지 못했습니다.')));
    }
  }

  Future<Uint8List> _renderStamped() {
    final style = StampStyle.byId(_config.styleId);
    final items = <StampItem>[];
    if (_infoLines.isNotEmpty) {
      items.add(
        StampItem(
          lines: _infoLines,
          normalizedCenter: _resolvedInfoCenter,
          fontScale: _config.fontScale,
          fontFamily: style.baseStyle().fontFamily,
          fontWeight: style.fontWeight,
          letterSpacing: style.letterSpacing,
          lineHeight: style.lineHeight,
          strokeRatio: style.strokeRatio,
          textColor: _effectiveStampColor,
          strokeColor: _effectiveStrokeColor,
          fontSizeScale: style.fontSizeScale,
          lineScales: style.lineScales,
          backgroundColor: style.backgroundColor,
          borderColor: _config.stampColor ?? style.borderColor,
          borderWidth: style.borderWidth,
          cornerRadius: style.cornerRadius,
          padding: style.padding,
          shadowColor: style.shadowColor,
          shadowOffset: style.shadowOffset,
          shadowBlur: style.shadowBlur,
          frameColor: style.frameColor == null
              ? null
              : (_config.stampColor ?? style.frameColor),
          frameInsetRatio: style.frameInsetRatio,
          frameStrokeRatio: style.frameStrokeRatio,
          frameShape: style.frameShape.name,
          fullCanvasFrame: style.fullCanvasFrame,
          framePadding: style.framePadding,
          template: style.template.name,
        ),
      );
    }
    if (_memoText != null) {
      items.add(
        StampItem(
          lines: [_memoText!],
          normalizedCenter: _resolvedMemoCenter,
          fontScale: _config.fontScale * 1.25 * _config.memoSize.scale,
          fontFamily: _config.memoFont.fontFamily,
          fontWeight: _config.memoFont.fontWeight,
          letterSpacing: 0,
          lineHeight: _config.memoFont.lineHeight,
          strokeRatio: 0.14,
          textColor: _config.memoTextColor.color,
          strokeColor: _config.memoOutlineColor.color,
        ),
      );
    }
    return StampRenderer.render(imageBytes: widget.imageBytes, items: items);
  }

  Future<_SavedCapture> _persistCapture(Uint8List stamped) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await Gal.putImageBytes(stamped, name: 'timeplace_$stamp.png');

    final originalPath = await CaptureFiles.saveOriginal(widget.imageBytes);
    final stampedPath = await CaptureFiles.saveStamped(stamped);
    final thumbPath = await CaptureThumbnail.save(stamped);
    final addr = widget.address.forLocale(
      _config.resolvedLocale(currentSystemLanguageCode()),
    );
    final addrText =
        addr.fullAddress ?? addr.neighborhood ?? addr.district ?? addr.city;
    await CaptureDb.insert(
      CaptureRecord(
        capturedAt: widget.capturedAt,
        savedAt: DateTime.fromMillisecondsSinceEpoch(stamp),
        thumbnailPath: thumbPath,
        originalPath: originalPath,
        stampedPath: stampedPath,
        folderId: null,
        categoryId: inferCategoryId(_config.memo),
        memo: _config.memo,
        styleId: _config.styleId,
        address: addrText,
        latitude: widget.coordinate?.lat,
        longitude: widget.coordinate?.lon,
      ),
    );
    return _SavedCapture(
      thumbnailBytes: stamped,
      originalPath: originalPath,
      stampedPath: stampedPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageSize = _imageSize;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: imageSize == null
                  ? const ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  : ColoredBox(
                      color: Colors.black,
                      child: LayoutBuilder(
                        builder: (context, constraints) =>
                            _buildReviewImage(context, constraints, imageSize),
                      ),
                    ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewImage(
    BuildContext context,
    BoxConstraints constraints,
    Size imageSize,
  ) {
    final style = StampStyle.byId(_config.styleId);
    final imgAspect = imageSize.width / imageSize.height;
    final boxAspect = constraints.maxWidth / constraints.maxHeight;
    double displayW, displayH;
    if (imgAspect > boxAspect) {
      displayW = constraints.maxWidth;
      displayH = displayW / imgAspect;
    } else {
      displayH = constraints.maxHeight;
      displayW = displayH * imgAspect;
    }
    return Center(
      child: SizedBox(
        width: displayW,
        height: displayH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
            ),
            if (style.hasFrame && style.fullCanvasFrame)
              _StampFrameOverlay(style: style, stampColor: _config.stampColor),
            if (_infoLines.isNotEmpty)
              _buildDraggableStamp(
                displaySize: Size(displayW, displayH),
                center: _resolvedInfoCenter,
                onMove: (c) => setState(() => _infoCenter = c),
                child: style.template == StampTextTemplate.timeMark
                    ? TimeMarkStamp(
                        lines: _infoLines,
                        fontSize:
                            (MediaQuery.orientationOf(context) ==
                                    Orientation.portrait
                                ? 18.0
                                : 13.0) *
                            _config.fontScale,
                        style: style,
                        stampColor: _config.stampColor,
                      )
                    : _InfoBubble(
                        lines: _infoLines,
                        maxWidth: displayW * 0.84,
                        fontScale: _config.fontScale,
                        style: style,
                        stampColor: _config.stampColor,
                      ),
              ),
            if (_memoText != null)
              _buildDraggableStamp(
                displaySize: Size(displayW, displayH),
                center: _resolvedMemoCenter,
                onMove: (c) => setState(() => _memoCenter = c),
                child: _MemoBubble(
                  text: _memoText!,
                  maxWidth: displayW * 0.84,
                  fontScale: _config.fontScale,
                  sizeScale: _config.memoSize.scale,
                  outlineColor: _config.memoOutlineColor.color,
                  textColor: _config.memoTextColor.color,
                  memoFont: _config.memoFont,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableStamp({
    required Size displaySize,
    required Offset center,
    required ValueChanged<Offset> onMove,
    required Widget child,
  }) {
    return Positioned(
      left: center.dx * displaySize.width,
      top: center.dy * displaySize.height,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openEditSheet,
          onPanUpdate: (details) {
            final dx = details.delta.dx / displaySize.width;
            final dy = details.delta.dy / displaySize.height;
            onMove(
              Offset(
                (center.dx + dx).clamp(0.0, 1.0),
                (center.dy + dy).clamp(0.0, 1.0),
              ),
            );
          },
          child: child,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final compact = MediaQuery.orientationOf(context) == Orientation.landscape;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F5EF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReviewActions(compact: compact),
            _buildReviewToolTabs(compact: compact),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _panelMode == _ReviewPanelMode.style
                  ? _buildStyleStrip(compact: compact)
                  : _buildColorStrip(compact: compact),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewActions({required bool compact}) {
    return Container(
      height: compact ? 50 : 68,
      padding: compact
          ? const EdgeInsets.fromLTRB(12, 6, 12, 4)
          : const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _saving || _sharing
                ? null
                : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF30323A),
              side: const BorderSide(color: Color(0x2230323A)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.close, size: 18),
            label: Text(
              compact ? '' : '닫기',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          if (!compact)
            Expanded(
              child: Container(
                height: 44,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '끌어서 위치 조정',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF5A554E),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          SizedBox(width: compact ? 4 : 8),
          _roundActionButton(
            onPressed: _saving || _sharing ? null : _openEditSheet,
            icon: Icons.tune,
            tooltip: '상세 설정',
          ),
          const SizedBox(width: 6),
          _roundActionButton(
            onPressed: _saving || _sharing || _imageSize == null
                ? null
                : _share,
            tooltip: '공유',
            icon: Icons.ios_share,
            loading: _sharing,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _saving || _sharing || _imageSize == null ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F7A5C),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFB6C9C0),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 16,
                vertical: compact ? 10 : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle, size: 19),
            label: Text(
              _saving ? '저장 중' : (compact ? '저장' : '완료 저장'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String tooltip,
    bool loading = false,
  }) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.86),
        foregroundColor: const Color(0xFF30323A),
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 20),
    );
  }

  Widget _buildReviewToolTabs({required bool compact}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, compact ? 4 : 8),
      child: Row(
        children: [
          _toolTab(
            icon: Icons.auto_awesome_motion_outlined,
            label: '스타일',
            mode: _ReviewPanelMode.style,
            compact: compact,
          ),
          _toolTab(
            icon: Icons.format_color_text,
            label: '색상',
            mode: _ReviewPanelMode.color,
            compact: compact,
          ),
        ],
      ),
    );
  }

  Widget _toolTab({
    required IconData icon,
    required String label,
    required _ReviewPanelMode mode,
    required bool compact,
  }) {
    final selected = _panelMode == mode;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () => setState(() => _panelMode = mode),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: compact ? 34 : 44,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF30323A) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? const Color(0xFF30323A)
                    : const Color(0xFFE6DED3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : const Color(0xFF746D64),
                  size: compact ? 15 : 18,
                ),
                if (!compact) const SizedBox(height: 1),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF746D64),
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyleStrip({required bool compact}) {
    final lines = _infoLines.isEmpty ? const ['TIME'] : _infoLines;
    final mood = _moodCollections.firstWhere(
      (m) => m.id == _moodId,
      orElse: () => _moodCollections.first,
    );
    final styles = mood.styles;
    return SizedBox(
      key: const ValueKey('styles'),
      height: compact ? 108 : 176,
      child: Column(
        children: [
          SizedBox(
            height: compact ? 32 : 42,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(14, compact ? 2 : 4, 14, 6),
              scrollDirection: Axis.horizontal,
              itemCount: _moodCollections.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _moodCollections[index];
                final selected = item.id == _moodId;
                return _MoodChip(
                  mood: item,
                  selected: selected,
                  compact: compact,
                  onTap: () => setState(() {
                    _moodId = item.id;
                    final firstStyle = item.styles.first;
                    if (!item.styleIds.contains(_config.styleId)) {
                      _config.styleId = firstStyle.id;
                      _config.position = _defaultPositionFor(firstStyle);
                      _infoCenter = null;
                    }
                  }),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(14, 0, 14, compact ? 8 : 14),
              scrollDirection: Axis.horizontal,
              itemCount: styles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final style = styles[index];
                final selected = _config.styleId == style.id;
                return _StylePreviewCard(
                  imageBytes: widget.imageBytes,
                  style: style,
                  lines: lines,
                  stampColor: _config.stampColor,
                  selected: selected,
                  compact: compact,
                  onTap: () => setState(() {
                    _config.styleId = style.id;
                    _config.position = _defaultPositionFor(style);
                    _infoCenter = null;
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorStrip({required bool compact}) {
    return SizedBox(
      key: const ValueKey('colors'),
      height: compact ? 92 : 154,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          20,
          compact ? 22 : 42,
          20,
          compact ? 18 : 42,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: _stampPalette.length,
        separatorBuilder: (_, _) => SizedBox(width: compact ? 12 : 18),
        itemBuilder: (context, index) {
          final color = _stampPalette[index];
          final selected =
              _config.stampColor == color ||
              (_config.stampColor == null && color == null);
          return _ColorSwatch(
            color: color,
            selected: selected,
            size: compact ? 42 : 52,
            onTap: () => setState(() => _config.stampColor = color),
          );
        },
      ),
    );
  }

  StampPosition _defaultPositionFor(StampStyle style) {
    switch (style.id) {
      case 'tiny_corner':
        return StampPosition.bottomLeft;
      case 'bottom_band':
        return StampPosition.bottomCenter;
      case 'english_top':
        return StampPosition.topRight;
      case 'timemark':
        return StampPosition.bottomLeft;
      default:
        return style.template == StampTextTemplate.standard
            ? _config.position
            : StampPosition.center;
    }
  }
}

class _SavedCapture {
  final Uint8List thumbnailBytes;
  final String originalPath;
  final String stampedPath;

  const _SavedCapture({
    required this.thumbnailBytes,
    required this.originalPath,
    required this.stampedPath,
  });
}

String _moodIdForStyle(String styleId) {
  for (final mood in _moodCollections) {
    if (mood.styleIds.contains(styleId)) return mood.id;
  }
  return _moodCollections.first.id;
}

class _StyleMood {
  final String id;
  final String label;
  final IconData icon;
  final List<String> styleIds;

  const _StyleMood({
    required this.id,
    required this.label,
    required this.icon,
    required this.styleIds,
  });

  List<StampStyle> get styles => styleIds.map(StampStyle.byId).toList();
}

const List<_StyleMood> _moodCollections = [
  _StyleMood(
    id: 'proof',
    label: '인증',
    icon: Icons.verified_outlined,
    styleIds: ['timemark', 'minimal', 'report', 'compact', 'tiny_corner', 'bold'],
  ),
  _StyleMood(
    id: 'diary',
    label: '다이어리',
    icon: Icons.local_florist_outlined,
    styleIds: ['diary', 'elegant', 'label', 'notebook_lines', 'bottom_band'],
  ),
  _StyleMood(
    id: 'active',
    label: '활동',
    icon: Icons.directions_run,
    styleIds: ['workout_poster', 'workout', 'meal', 'diet_poster', 'study'],
  ),
  _StyleMood(
    id: 'minimal',
    label: '미니멀',
    icon: Icons.grid_3x3,
    styleIds: [
      'english_top',
      'ruled_classic',
      'framed_minimal',
      'circle_time',
      'calendar_mini',
    ],
  ),
  _StyleMood(
    id: 'retro',
    label: '레트로',
    icon: Icons.auto_awesome,
    styleIds: ['digital_large', 'film', 'morning_proof', 'study_poster'],
  ),
];

const List<Color?> _stampPalette = [
  null,
  Colors.white,
  Color(0xFFBFC3C8),
  Color(0xFF7C7F84),
  Colors.black,
  Color(0xFFF4A3B5),
  Color(0xFFFF5141),
  Color(0xFFFFF229),
  Color(0xFF3498DB),
  Color(0xFF31C48D),
  Color(0xFFFFA63D),
  Color(0xFFB98CFF),
];

class _MoodChip extends StatelessWidget {
  final _StyleMood mood;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _MoodChip({
    required this.mood,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: Icon(
        mood.icon,
        size: compact ? 13 : 15,
        color: selected ? Colors.white : const Color(0xFF746D64),
      ),
      label: Text(mood.label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      selectedColor: const Color(0xFF1F7A5C),
      backgroundColor: Colors.white.withValues(alpha: 0.76),
      side: BorderSide(
        color: selected ? const Color(0xFF1F7A5C) : const Color(0xFFE6DED3),
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF746D64),
        fontSize: compact ? 10 : 12,
        fontWeight: FontWeight.w900,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}

class _StylePreviewCard extends StatelessWidget {
  final Uint8List imageBytes;
  final StampStyle style;
  final List<String> lines;
  final Color? stampColor;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _StylePreviewCard({
    required this.imageBytes,
    required this.style,
    required this.lines,
    required this.stampColor,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: compact ? 106 : 132,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              style.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? const Color(0xFF252A33) : Colors.grey[700],
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: compact ? 3 : 6),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF252A33)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(imageBytes, fit: BoxFit.cover),
                      if (style.hasFrame && style.fullCanvasFrame)
                        _StampFrameOverlay(
                          style: style,
                          stampColor: stampColor,
                        ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: style.template == StampTextTemplate.timeMark
                              ? TimeMarkStamp(
                                  lines: lines,
                                  fontSize: compact ? 4.5 : 6,
                                  style: style,
                                  stampColor: stampColor,
                                )
                              : OutlinedStampText(
                                  text: _previewTextFor(style, lines),
                                  fontSize: compact ? 7.5 : 10,
                                  textAlign: TextAlign.center,
                                  style: style,
                                  stampColor: stampColor,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _previewTextFor(StampStyle style, List<String> lines) {
    if (lines.length <= 3) return lines.join('\n');
    return lines.take(3).join('\n');
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color? color;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fill = color ?? const Color(0xFFFFFFFF);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: selected ? size + 6 : size,
        height: selected ? size + 6 : size,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFF252A33) : Colors.transparent,
            width: 3,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(color: const Color(0x22000000)),
          ),
          child: color == null
              ? const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: Color(0xFF252A33),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _StampFrameOverlay extends StatelessWidget {
  final StampStyle style;
  final Color? stampColor;
  const _StampFrameOverlay({required this.style, this.stampColor});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return CustomPaint(
              painter: _StampFramePainter(style, stampColor: stampColor),
              size: constraints.biggest,
            );
          },
        ),
      ),
    );
  }
}

class _StampFramePainter extends CustomPainter {
  final StampStyle style;
  final Color? stampColor;
  const _StampFramePainter(this.style, {this.stampColor});

  @override
  void paint(Canvas canvas, Size size) {
    final color = stampColor ?? style.frameColor;
    if (color == null) return;
    final short = size.shortestSide;
    final inset = short * style.frameInsetRatio;
    final strokeWidth = short * style.frameStrokeRatio;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    switch (style.frameShape) {
      case StampFrameShape.rectangle:
        canvas.drawRect(rect, paint);
      case StampFrameShape.circle:
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          short * 0.19,
          paint,
        );
      case StampFrameShape.horizontalRules:
        final y1 = size.height / 2 - short * 0.055;
        final y2 = size.height / 2 + short * 0.055;
        canvas.drawLine(
          Offset(inset, y1),
          Offset(size.width - inset, y1),
          paint,
        );
        canvas.drawLine(
          Offset(inset, y2),
          Offset(size.width - inset, y2),
          paint,
        );
      case StampFrameShape.notebook:
        final gap = short * 0.075;
        final startY = size.height / 2 - gap * 1.6;
        for (var i = 0; i < 5; i += 1) {
          final y = startY + gap * i;
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        canvas.drawLine(
          Offset(short * 0.12, startY - gap * 0.55),
          Offset(short * 0.12, startY + gap * 4.2),
          paint,
        );
      case StampFrameShape.bottomBar:
        final barHeight = short * style.frameStrokeRatio;
        canvas.drawRect(
          Rect.fromLTWH(
            0,
            size.height - barHeight - inset,
            size.width,
            barHeight,
          ),
          Paint()..color = color,
        );
      case StampFrameShape.splitBoxes:
        final box = short * 0.16;
        final gap = short * 0.025;
        final top = size.height / 2 - box / 2;
        final left = size.width / 2 - box - gap / 2;
        canvas.drawRect(Rect.fromLTWH(left, top, box, box), paint);
        canvas.drawRect(Rect.fromLTWH(left + box + gap, top, box, box), paint);
      case StampFrameShape.calendar:
        final w = short * 0.22;
        final h = short * 0.18;
        final left = size.width / 2 - w / 2;
        final top = size.height / 2 - h / 2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, w, h),
            Radius.circular(short * 0.01),
          ),
          paint,
        );
        canvas.drawLine(
          Offset(left, top + h * 0.36),
          Offset(left + w, top + h * 0.36),
          paint,
        );
      case StampFrameShape.none:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _StampFramePainter oldDelegate) {
    return oldDelegate.style != style || oldDelegate.stampColor != stampColor;
  }
}

class _InfoBubble extends StatelessWidget {
  final List<String> lines;
  final double maxWidth;
  final double fontScale;
  final StampStyle? style;
  final Color? stampColor;
  const _InfoBubble({
    required this.lines,
    required this.maxWidth,
    required this.fontScale,
    this.style,
    this.stampColor,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Builder(
        builder: (context) {
          final isPortrait =
              MediaQuery.orientationOf(context) == Orientation.portrait;
          final base = isPortrait ? 18.0 : 13.0;
          return OutlinedStampText(
            text: lines.join('\n'),
            fontSize: base * fontScale,
            textAlign: TextAlign.center,
            style: style,
            stampColor: stampColor,
          );
        },
      ),
    );
  }
}

class _MemoBubble extends StatelessWidget {
  final String text;
  final double maxWidth;
  final double fontScale;
  final double sizeScale;
  final Color outlineColor;
  final Color textColor;
  final MemoFont memoFont;
  const _MemoBubble({
    required this.text,
    required this.maxWidth,
    required this.fontScale,
    required this.sizeScale,
    required this.outlineColor,
    required this.textColor,
    required this.memoFont,
  });

  @override
  Widget build(BuildContext context) {
    final size = 22 * fontScale * sizeScale;
    final base = memoFont.style(fontSize: size);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Stack(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: base.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = size * 0.28
                ..strokeJoin = StrokeJoin.round
                ..color = outlineColor,
            ),
          ),
          Text(
            text,
            textAlign: TextAlign.center,
            style: base.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
