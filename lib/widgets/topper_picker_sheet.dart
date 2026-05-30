import 'package:flutter/material.dart';
import '../topper_template.dart';

/// 카테고리별 메모 토퍼 템플릿을 고르는 바텀시트.
/// 선택 시 해당 텍스트가 [Navigator.pop]으로 반환된다.
class TopperPickerSheet extends StatefulWidget {
  const TopperPickerSheet({super.key});

  @override
  State<TopperPickerSheet> createState() => _TopperPickerSheetState();
}

class _TopperPickerSheetState extends State<TopperPickerSheet> {
  TopperCategory _selected = TopperCategory.daily;

  @override
  Widget build(BuildContext context) {
    final templates = TopperTemplates.byCategory(_selected);
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFFFFCF8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3D8CF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '토퍼 템플릿',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2A211B),
                      ),
                    ),
                  ),
                  Text(
                    '${templates.length}개',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF8B7D73),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: TopperCategory.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final category = TopperCategory.values[i];
                  final selected = category == _selected;
                  return _CategoryPill(
                    category: category,
                    selected: selected,
                    onTap: () => setState(() => _selected = category),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.75,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: templates.length,
                itemBuilder: (context, i) {
                  final template = templates[i];
                  return _TemplateCard(
                    template: template,
                    onTap: () => Navigator.of(context).pop(template.text),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final TopperCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2A211B) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFF2A211B) : const Color(0xFFE8DDD5),
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x292A211B),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 5),
            Text(
              category.title,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF3A2E27),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final TopperTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final parts = _splitFirstEmoji(template.text);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9DED6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(parts.emoji, style: const TextStyle(fontSize: 17)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                parts.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF2A211B),
                  fontSize: 13,
                  height: 1.16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({String emoji, String label}) _splitFirstEmoji(String text) {
    final pieces = text.trim().split(RegExp(r'\s+'));
    if (pieces.length <= 1) return (emoji: '✨', label: text);
    final first = pieces.first;
    if (RegExp(r'[가-힣A-Za-z0-9]').hasMatch(first)) {
      return (emoji: '✨', label: text);
    }
    return (emoji: first, label: pieces.skip(1).join(' '));
  }
}
