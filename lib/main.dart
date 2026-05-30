import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'library_screen.dart';
import 'location_provider.dart';
import 'onboarding_screen.dart';
import 'photo_review_screen.dart';
import 'services/capture_backup.dart';
import 'services/config_storage.dart';
import 'services/image_orientation.dart';
import 'stamp_settings.dart';
import 'stamp_style.dart';
import 'widgets/outlined_stamp_text.dart';
import 'widgets/stamp_settings_sheet.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko');
  await initializeDateFormatting('en');
  _cameras = await availableCameras();
  // 스탬프용 폰트 미리 로드
  unawaited(
    GoogleFonts.pendingFonts([
      GoogleFonts.nanumPenScript(),
      GoogleFonts.notoSansKr(),
      GoogleFonts.ibmPlexSansKr(),
      GoogleFonts.amaticSc(),
      GoogleFonts.robotoSlab(),
      GoogleFonts.blackHanSans(),
      GoogleFonts.bebasNeue(),
      GoogleFonts.majorMonoDisplay(),
      GoogleFonts.orbitron(),
      GoogleFonts.spaceMono(),
      GoogleFonts.sourceCodePro(),
      GoogleFonts.dotGothic16(),
      GoogleFonts.gowunDodum(),
      GoogleFonts.gowunBatang(),
      GoogleFonts.gugi(),
      GoogleFonts.jua(),
      GoogleFonts.notoSerifKr(),
    ]),
  );
  runApp(const TimePlaceApp());
}

String currentSystemLanguageCode() =>
    WidgetsBinding.instance.platformDispatcher.locale.languageCode;

class TimePlaceApp extends StatelessWidget {
  const TimePlaceApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '인증샷 카메라 - 시간 장소 스탬프',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  final LocationProvider _location = LocationProvider();
  StampConfiguration _config = StampConfiguration();
  DateTime _now = DateTime.now();
  Timer? _timer;
  Timer? _savedBadgeTimer;
  bool _isCapturing = false;
  bool _useFrontCamera = false;
  Uint8List? _lastSavedThumb;
  String _statusMessage = '카메라 준비 중';
  int _timerSeconds = 0; // 0/3/5/10
  int? _countdown; // 진행 중인 카운트다운 표시값
  Timer? _idleTimer;
  bool _isIdle = false;
  static const _idleSeconds = 600; // 10분 무입력 → 카메라 정지
  late final AnimationController _flashController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final AnimationController _shutterScaleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 130),
    lowerBound: 0.85,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _location.requestAndFetch();
    _restoreConfig();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _resetIdleTimer();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (_isIdle) {
      _isIdle = false;
      _initCamera();
    }
    _idleTimer = Timer(const Duration(seconds: _idleSeconds), _enterIdle);
  }

  Future<void> _enterIdle() async {
    if (!mounted) return;
    final old = _controller;
    _controller = null;
    setState(() {
      _isIdle = true;
      _statusMessage = '절전 모드 — 화면을 탭해 다시 시작';
    });
    try {
      await old?.dispose();
    } catch (_) {}
  }

  Future<void> _restoreConfig() async {
    final loaded = await ConfigStorage.load();
    if (!mounted) return;
    setState(() => _config = loaded);
    unawaited(_checkOrphanCaptures());
    unawaited(_showOnboardingIfNeeded());
  }

  Future<void> _showOnboardingIfNeeded() async {
    final shouldShow = await ConfigStorage.shouldShowOnboarding();
    if (!shouldShow || !mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const OnboardingScreen(),
      ),
    );
    await ConfigStorage.markOnboardingSeen();
  }

  Future<void> _checkOrphanCaptures() async {
    final orphans = await CaptureBackup.orphans();
    if (orphans.isEmpty || !mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('미저장 사진 발견'),
        content: Text(
          '이전 촬영 중 정상 종료되지 못한 사진 ${orphans.length}장이 있습니다.\n사진 보관함에 저장할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('삭제'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (result == true) {
      for (final f in orphans) {
        try {
          final bytes = await f.readAsBytes();
          await Gal.putImageBytes(
            bytes,
            name:
                'timeplace_recovered_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        } catch (_) {}
        await CaptureBackup.discard(f.path);
      }
    } else if (result == false) {
      for (final f in orphans) {
        await CaptureBackup.discard(f.path);
      }
    }
  }

  void _updateConfig(StampConfiguration updated) {
    setState(() => _config = updated);
    unawaited(ConfigStorage.save(updated));
  }

  Future<void> _initCamera() async {
    if (_cameras.isEmpty) {
      setState(() => _statusMessage = '시뮬레이터 미리보기 모드 (카메라 없음)');
      return;
    }
    // 기존 컨트롤러를 먼저 정리해서 동시 활성 충돌 방지
    final old = _controller;
    if (old != null) {
      _controller = null;
      if (mounted) setState(() {});
      try {
        await old.dispose();
      } catch (_) {}
    }

    final wantedLens = _useFrontCamera
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final selected = _cameras.firstWhere(
      (c) => c.lensDirection == wantedLens,
      orElse: () => _cameras.first,
    );
    // 전면 카메라는 max에서 실패하는 기기가 있어 보수적으로 veryHigh
    final preset = _useFrontCamera
        ? ResolutionPreset.veryHigh
        : ResolutionPreset.max;
    final ctrl = CameraController(selected, preset, enableAudio: false);
    try {
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _controller = ctrl;
        _statusMessage = '카메라 준비 완료';
      });
    } catch (e) {
      // 전면이 실패하면 high로 한 번 더 시도
      if (_useFrontCamera) {
        try {
          final retry = CameraController(
            selected,
            ResolutionPreset.high,
            enableAudio: false,
          );
          await retry.initialize();
          if (!mounted) {
            await retry.dispose();
            return;
          }
          setState(() {
            _controller = retry;
            _statusMessage = '카메라 준비 완료';
          });
          return;
        } catch (e2) {
          setState(() => _statusMessage = '전면 카메라 초기화 실패: $e2');
          return;
        }
      }
      setState(() => _statusMessage = '카메라 초기화 실패: $e');
    }
  }

  Future<void> _flipCamera() async {
    if (_isCapturing) return;
    final hasFront = _cameras.any(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    final hasBack = _cameras.any(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    if (!hasFront || !hasBack) return;
    setState(() {
      _useFrontCamera = !_useFrontCamera;
      _statusMessage = '카메라 전환 중…';
    });
    await _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _idleTimer?.cancel();
    _savedBadgeTimer?.cancel();
    _controller?.dispose();
    _location.dispose();
    _flashController.dispose();
    _shutterScaleController.dispose();
    super.dispose();
  }

  Future<void> _triggerShutterFx() async {
    // 스케일 다운 → 업 펄스
    _shutterScaleController.value = 0.85;
    _shutterScaleController.animateTo(1.0, curve: Curves.easeOut);
    // 플래시 (어둠→투명)
    _flashController.forward(from: 0).then((_) => _flashController.reverse());
    if (_config.shutterSound) {
      unawaited(SystemSound.play(SystemSoundType.click));
      unawaited(HapticFeedback.mediumImpact());
    }
  }

  Future<void> _capture() async {
    final ctrl = _controller;
    if (_isCapturing || ctrl == null || !ctrl.value.isInitialized) return;
    _resetIdleTimer();
    _triggerShutterFx();
    setState(() => _isCapturing = true);
    Future<String>? backupFuture;
    try {
      // 타이머 카운트다운
      if (_timerSeconds > 0) {
        for (int i = _timerSeconds; i > 0; i--) {
          if (!mounted) return;
          setState(() => _countdown = i);
          await Future.delayed(const Duration(seconds: 1));
        }
        if (mounted) setState(() => _countdown = null);
        // 실제 촬영 직전에 효과 한 번 더 (셔터 순간)
        _triggerShutterFx();
      }
      final file = await ctrl.takePicture();
      final rawBytes = await file.readAsBytes();
      final capturedAt = DateTime.now();
      // EXIF 회전을 픽셀에 반영해 스탬프-사진 방향 불일치 차단
      final bytes = bakeExifOrientation(rawBytes);

      // 비정상 종료 대비 임시 백업은 화면 전환을 막지 않도록 백그라운드에서 시작한다.
      backupFuture = CaptureBackup.stash(bytes);

      if (!mounted) return;
      final result = await Navigator.of(context).push<Uint8List?>(
        MaterialPageRoute(
          builder: (_) => PhotoReviewScreen(
            imageBytes: bytes,
            capturedAt: capturedAt,
            address: _location.address,
            coordinate: _location.coordinate,
            initialConfig: _config,
          ),
        ),
      );
      // 리뷰 정상 종료 — 저장됐든 사용자가 닫았든 백업은 정리
      try {
        final backupPath = await backupFuture;
        await CaptureBackup.discard(backupPath);
      } catch (_) {}
      backupFuture = null;
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        if (result != null) {
          _lastSavedThumb = result;
          _statusMessage = '사진 보관함에 저장했습니다.';
          _savedBadgeTimer?.cancel();
          _savedBadgeTimer = Timer(const Duration(milliseconds: 1500), () {
            if (!mounted) return;
            setState(() => _lastSavedThumb = null);
          });
        }
      });
    } catch (_) {
      // 실패해도 백업은 남겨 둬 다음 실행에서 복구 시도
      if (!mounted) return;
      setState(() {
        _statusMessage = '저장에 실패했습니다.';
        _isCapturing = false;
        _countdown = null;
      });
    }
  }

  Future<void> _openLibrary() async {
    _resetIdleTimer();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LibraryScreen()));
    _resetIdleTimer();
  }

  void _cycleTimer() {
    setState(() {
      _timerSeconds = switch (_timerSeconds) {
        0 => 3,
        3 => 5,
        5 => 10,
        _ => 0,
      };
    });
    _resetIdleTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 카메라 레이어 + 절전 해제/탭 촬영을 위한 GestureDetector
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onPreviewTap,
                child: _buildCameraLayer(),
              ),
            ),
            _buildGradientOverlay(),
            Positioned.fill(child: _buildStampPreview()),
            if (_countdown != null) _buildCountdownOverlay(),
            _buildFlashOverlay(),
            if (_isIdle) _buildIdleOverlay(),
            Positioned(left: 18, top: 14, right: 18, child: _buildHeader()),
            Positioned(
              left: 18,
              right: 18,
              bottom: 14,
              child: _buildControls(),
            ),
          ],
        ),
      ),
    );
  }

  void _onPreviewTap() {
    if (_isIdle) {
      _resetIdleTimer();
      return;
    }
    _resetIdleTimer();
    if (!_config.tapToCapture) return;
    _capture();
  }

  Widget _buildCountdownOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Text(
            '$_countdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 160,
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 12)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlashOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _flashController,
          builder: (_, _) => Container(
            color: Colors.white.withValues(
              alpha: _flashController.value * 0.85,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdleOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _resetIdleTimer,
        child: Container(
          color: Colors.black.withAlpha(180),
          alignment: Alignment.center,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bedtime_outlined, color: Colors.white70, size: 56),
              SizedBox(height: 12),
              Text(
                '절전 모드',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '화면을 탭해 다시 시작',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraLayer() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return Container(color: Colors.black);
    }
    final size = ctrl.value.previewSize!;
    // 카메라 센서는 항상 가로(긴 변이 width). 세로 모드일 때만 차원을 바꿔 화면을 채운다.
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final w = isPortrait ? size.height : size.width;
    final h = isPortrait ? size.width : size.height;
    final preview = ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(width: w, height: h, child: CameraPreview(ctrl)),
        ),
      ),
    );
    if (_useFrontCamera) {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scaleByDouble(-1.0, 1.0, 1.0, 1.0),
        child: preview,
      );
    }
    return preview;
  }

  Widget _buildGradientOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x8C000000), Colors.transparent, Color(0xB8000000)],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '인증샷 카메라',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildAccuracyBadge(),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: _location,
                builder: (context, _) {
                  final locationStatus = _location.statusMessage;
                  return Text(
                    locationStatus.isEmpty ? _statusMessage : locationStatus,
                    style: TextStyle(
                      color: Colors.white.withAlpha(184),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTimerButton(),
                const SizedBox(width: 8),
                _iconButton(
                  icon: Icons.photo_library_outlined,
                  onTap: _openLibrary,
                  semanticLabel: '라이브러리',
                ),
                const SizedBox(width: 8),
                _iconButton(
                  icon: Icons.location_on_outlined,
                  onTap: _location.refresh,
                  semanticLabel: '위치 새로고침',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerButton() {
    final on = _timerSeconds > 0;
    return Semantics(
      label: '셔터 타이머',
      child: GestureDetector(
        onTap: _cycleTimer,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(82),
            shape: BoxShape.circle,
            border: Border.all(
              color: on ? const Color(0xFFFFCC00) : Colors.transparent,
              width: 1.6,
            ),
          ),
          alignment: Alignment.center,
          child: on
              ? Text(
                  '${_timerSeconds}s',
                  style: const TextStyle(
                    color: Color(0xFFFFCC00),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : const Icon(Icons.timer_outlined, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildAccuracyBadge() {
    return ListenableBuilder(
      listenable: _location,
      builder: (context, _) {
        final acc = _location.accuracyMeters;
        if (acc == null) return const SizedBox.shrink();
        final Color color;
        final String label;
        if (acc <= 20) {
          color = const Color(0xFF34C759);
          label = '${acc.round()}m';
        } else if (acc <= 100) {
          color = const Color(0xFFFFCC00);
          label = '${acc.round()}m';
        } else {
          color = const Color(0xFFFF3B30);
          label = '${acc.round()}m 부정확';
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(120),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gps_fixed, color: color, size: 12),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStampPreview() {
    return ListenableBuilder(
      listenable: _location,
      builder: (context, _) {
        final style = StampStyle.byId(_config.styleId);
        final infoLines = _config.infoLines(
          _now,
          _location.address,
          _location.coordinate,
          systemLanguageCode: currentSystemLanguageCode(),
        );
        final memoText = _config.memoText;
        return Stack(
          children: [
            if (style.hasFrame && style.fullCanvasFrame)
              _StampFrameOverlay(style: style),
            if (infoLines.isNotEmpty && memoText != null)
              Align(
                alignment: _stampAlignment(_config.position),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _PreviewStampGroup(
                    position: _config.position,
                    stamp: _StampBubble(
                      lines: infoLines,
                      position: _config.position,
                      fontScale: _config.fontScale,
                      style: style,
                    ),
                    memo: _MemoBubble(
                      text: memoText,
                      fontScale: _config.fontScale,
                      sizeScale: _config.memoSize.scale,
                      outlineColor: _config.memoOutlineColor.color,
                      textColor: _config.memoTextColor.color,
                      memoFont: _config.memoFont,
                    ),
                  ),
                ),
              )
            else ...[
              if (infoLines.isNotEmpty)
                Align(
                  alignment: _stampAlignment(_config.position),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _StampBubble(
                      lines: infoLines,
                      position: _config.position,
                      fontScale: _config.fontScale,
                      style: style,
                    ),
                  ),
                ),
              if (memoText != null)
                Align(
                  alignment: _memoAlignment(_config.position),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _MemoBubble(
                      text: memoText,
                      fontScale: _config.fontScale,
                      sizeScale: _config.memoSize.scale,
                      outlineColor: _config.memoOutlineColor.color,
                      textColor: _config.memoTextColor.color,
                      memoFont: _config.memoFont,
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _iconButton(
              icon: Icons.cameraswitch_outlined,
              onTap: _flipCamera,
              semanticLabel: '카메라 전환',
            ),
            _buildShutterButton(),
            _iconButton(
              icon: Icons.tune,
              onTap: _showSettings,
              semanticLabel: '스탬프 설정 열기',
            ),
          ],
        ),
        if (_lastSavedThumb != null) ...[
          const SizedBox(height: 10),
          _buildSavedBadge(),
        ],
      ],
    );
  }

  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _capture,
      child: ScaleTransition(
        scale: _shutterScaleController,
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withAlpha(46), width: 4),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedBadge() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(87),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _lastSavedThumb!,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            '스탬프 사진 저장 완료',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(82),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) =>
          StampSettingsSheet(config: _config, onChanged: _updateConfig),
    );
  }

  Alignment _stampAlignment(StampPosition p) {
    switch (p) {
      case StampPosition.topLeft:
        return Alignment.topLeft;
      case StampPosition.topCenter:
        return Alignment.topCenter;
      case StampPosition.topRight:
        return Alignment.topRight;
      case StampPosition.middleLeft:
        return Alignment.centerLeft;
      case StampPosition.center:
        return Alignment.center;
      case StampPosition.middleRight:
        return Alignment.centerRight;
      case StampPosition.bottomLeft:
        return Alignment.bottomLeft;
      case StampPosition.bottomCenter:
        return Alignment.bottomCenter;
      case StampPosition.bottomRight:
        return Alignment.bottomRight;
    }
  }

  /// 메모는 정보 스탬프 바로 위로 살짝 띄워 미리보기.
  Alignment _memoAlignment(StampPosition p) {
    final base = _stampAlignment(p);
    return Alignment(base.x, (base.y - 0.25).clamp(-1.0, 1.0));
  }
}

class _PreviewStampGroup extends StatelessWidget {
  final StampPosition position;
  final Widget stamp;
  final Widget memo;

  const _PreviewStampGroup({
    required this.position,
    required this.stamp,
    required this.memo,
  });

  @override
  Widget build(BuildContext context) {
    final putMemoAbove = switch (position) {
      StampPosition.bottomLeft ||
      StampPosition.bottomCenter ||
      StampPosition.bottomRight => true,
      _ => false,
    };
    final children = putMemoAbove
        ? [memo, const SizedBox(height: 8), stamp]
        : [stamp, const SizedBox(height: 8), memo];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _crossAxisAlignment(position),
      children: children,
    );
  }

  CrossAxisAlignment _crossAxisAlignment(StampPosition p) {
    switch (p) {
      case StampPosition.topLeft:
      case StampPosition.middleLeft:
      case StampPosition.bottomLeft:
        return CrossAxisAlignment.start;
      case StampPosition.topCenter:
      case StampPosition.center:
      case StampPosition.bottomCenter:
        return CrossAxisAlignment.center;
      case StampPosition.topRight:
      case StampPosition.middleRight:
      case StampPosition.bottomRight:
        return CrossAxisAlignment.end;
    }
  }
}

class _StampFrameOverlay extends StatelessWidget {
  final StampStyle style;
  const _StampFrameOverlay({required this.style});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return CustomPaint(
              painter: _StampFramePainter(style),
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
  const _StampFramePainter(this.style);

  @override
  void paint(Canvas canvas, Size size) {
    final color = style.frameColor;
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
          canvas.drawLine(
            Offset.zero.translate(0, y),
            Offset(size.width, y),
            paint,
          );
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
    return oldDelegate.style != style;
  }
}

class _StampBubble extends StatelessWidget {
  final List<String> lines;
  final StampPosition position;
  final double fontScale;
  final StampStyle? style;
  const _StampBubble({
    required this.lines,
    required this.position,
    this.fontScale = 1.0,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.84,
      ),
      child: Builder(
        builder: (context) {
          final isPortrait =
              MediaQuery.orientationOf(context) == Orientation.portrait;
          final base = isPortrait ? 18.0 : 13.0;
          return OutlinedStampText(
            text: lines.join('\n'),
            fontSize: base * fontScale,
            textAlign: style?.template == StampTextTemplate.standard
                ? _textAlign(position)
                : TextAlign.center,
            style: style,
          );
        },
      ),
    );
  }

  TextAlign _textAlign(StampPosition p) {
    switch (p) {
      case StampPosition.topLeft:
      case StampPosition.middleLeft:
      case StampPosition.bottomLeft:
        return TextAlign.left;
      case StampPosition.topCenter:
      case StampPosition.center:
      case StampPosition.bottomCenter:
        return TextAlign.center;
      case StampPosition.topRight:
      case StampPosition.middleRight:
      case StampPosition.bottomRight:
        return TextAlign.right;
    }
  }
}

class _MemoBubble extends StatelessWidget {
  final String text;
  final double fontScale;
  final double sizeScale;
  final Color outlineColor;
  final Color textColor;
  final MemoFont memoFont;
  const _MemoBubble({
    required this.text,
    required this.fontScale,
    required this.sizeScale,
    required this.outlineColor,
    required this.textColor,
    required this.memoFont,
  });

  @override
  Widget build(BuildContext context) {
    final size = 22.0 * fontScale * sizeScale;
    final base = memoFont.style(fontSize: size);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.84,
      ),
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
