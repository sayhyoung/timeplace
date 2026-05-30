import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const _pages = [
    (
      illustration: _OnboardingIllustrationType.camera,
      title: '찍고 바로 꾸미기',
      body: '사진을 찍은 뒤 하단 패널에서 사진에 어울리는 스탬프 스타일과 색상을 고를 수 있어요.',
    ),
    (
      illustration: _OnboardingIllustrationType.memo,
      title: '메모는 토퍼처럼',
      body: '템플릿을 고르고 폰트, 색상, 윤곽선을 바꿔 인증샷에 어울리는 문구를 얹어보세요.',
    ),
    (
      illustration: _OnboardingIllustrationType.library,
      title: '저장하고 모아보기',
      body: '완성한 사진은 라이브러리에 저장되고, 폴더와 공유 기능으로 기록을 정리할 수 있어요.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => Navigator.of(context).pop();

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    '인증샷 카메라',
                    style: TextStyle(
                      color: Color(0xFF30323A),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: const Text(
                      '건너뛰기',
                      style: TextStyle(
                        color: Color(0xFF746D64),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _OnboardingIllustration(type: page.illustration),
                        const SizedBox(height: 30),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF30323A),
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF746D64),
                            fontSize: 15,
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: _index == i ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _index == i
                          ? const Color(0xFF1F7A5C)
                          : const Color(0xFFD8D0C6),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1F7A5C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    _index == _pages.length - 1 ? '시작하기' : '다음',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
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

enum _OnboardingIllustrationType { camera, memo, library }

class _OnboardingIllustration extends StatelessWidget {
  final _OnboardingIllustrationType type;

  const _OnboardingIllustration({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      height: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE6DED3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: switch (type) {
        _OnboardingIllustrationType.camera => const _CameraMock(),
        _OnboardingIllustrationType.memo => const _MemoMock(),
        _OnboardingIllustrationType.library => const _LibraryMock(),
      },
    );
  }
}

class _CameraMock extends StatelessWidget {
  const _CameraMock();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/onboarding/onboarding_court.jpg',
                fit: BoxFit.cover,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.04),
                      Colors.black.withValues(alpha: 0.38),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 18,
          top: 18,
          child: _FloatingIcon(
            icon: Icons.camera_alt,
            color: Color(0xFF30323A),
          ),
        ),
        Positioned(
          right: 18,
          top: 22,
          child: _StampChip(text: 'STYLE', icon: Icons.auto_awesome),
        ),
        Positioned(
          left: 24,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '현재 코트 상태',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
              SizedBox(height: 2),
              Text(
                '2026.05.09   14:30',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 13,
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _TinyDot(color: Color(0xFFFFFFFF)),
                _TinyDot(color: Color(0xFF30323A)),
                _TinyDot(color: Color(0xFFFF5141)),
                _TinyDot(color: Color(0xFFFFE75A)),
                _TinyDot(color: Color(0xFF1F7A5C)),
              ],
            ),
          ),
        ),
        Positioned(
          right: 22,
          bottom: 34,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE6DED3), width: 5),
            ),
          ),
        ),
      ],
    );
  }
}

class _MemoMock extends StatelessWidget {
  const _MemoMock();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.rotate(
                angle: -0.035,
                child: Transform.scale(
                  scale: 1.18,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      const Color(0xFFDCF5E6).withValues(alpha: 0.22),
                      BlendMode.screen,
                    ),
                    child: Image.asset(
                      'assets/onboarding/onboarding_topper.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      const Color(0xFF30323A).withValues(alpha: 0.46),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 28,
          right: 28,
          top: 54,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF30323A).withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.38),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '오늘의',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                  ),
                ),
                Text(
                  '힐링 기록',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 36,
          top: 70,
          child: Icon(Icons.favorite, color: Color(0xFFFF6B80), size: 20),
        ),
        Positioned(
          right: 38,
          top: 118,
          child: Icon(Icons.favorite, color: Color(0xFFFF6B80), size: 18),
        ),
        Positioned(
          right: 14,
          top: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: Color(0xFF1F7A5C),
                  size: 14,
                ),
                SizedBox(width: 5),
                Text(
                  'FONT',
                  style: TextStyle(
                    color: Color(0xFF30323A),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 14,
          bottom: 14,
          child: Row(
            children: const [
              _TemplateSwatch(color: Color(0xFFFF6B80), icon: Icons.favorite),
              SizedBox(width: 7),
              _TemplateSwatch(
                color: Color(0xFFFFD166),
                icon: Icons.local_florist,
              ),
              SizedBox(width: 7),
              _TemplateSwatch(
                color: Color(0xFF70B7FF),
                icon: Icons.auto_awesome,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LibraryMock extends StatelessWidget {
  const _LibraryMock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/onboarding/onboarding_library.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.02),
                        Colors.white.withValues(alpha: 0.60),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 14,
                  child: Row(
                    children: const [
                      _FolderPill(label: '운동'),
                      SizedBox(width: 8),
                      _FolderPill(label: '회사'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: const [
            Expanded(
              child: _ActionPill(icon: Icons.ios_share, label: '공유'),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _ActionPill(icon: Icons.folder_outlined, label: '폴더'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TinyDot extends StatelessWidget {
  final Color color;

  const _TinyDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x22000000)),
      ),
    );
  }
}

class _TemplateSwatch extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _TemplateSwatch({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _FloatingIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _StampChip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _StampChip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF1F7A5C), size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF30323A),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderPill extends StatelessWidget {
  final String label;

  const _FolderPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF30323A),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6DED3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF746D64), size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF746D64),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
