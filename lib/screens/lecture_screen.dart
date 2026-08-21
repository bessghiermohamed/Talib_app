import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../core/ui.dart';
import '../data/repository.dart';
import '../models/academic.dart';
import '../models/content.dart';

/// شاشة المحاضرة — عرض النص + قاعدة سريعة + وسم مقروء — v0.2
class LectureScreen extends StatefulWidget {
  const LectureScreen({
    super.key,
    required this.course,
    required this.week,
    required this.lecture,
    required this.totalLectures,
  });
  final Course course;
  final Week week;
  final Lecture lecture;
  final int totalLectures;

  @override
  State<LectureScreen> createState() => _LectureScreenState();
}

class _LectureScreenState extends State<LectureScreen> {
  final repo = TalibRepo();
  bool isRead = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _checkRead();
  }

  Future<void> _checkRead() async {
    final ids = await repo.readLectureIds(widget.course.id);
    if (!mounted) return;
    setState(() {
      isRead = ids.contains(widget.lecture.id);
      loading = false;
    });
  }

  Future<void> _toggleRead() async {
    final next = !isRead;
    setState(() => isRead = next);
    await repo.setLectureRead(
      widget.course.id,
      widget.lecture.id,
      next,
      widget.totalLectures,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bodyText = widget.lecture.body ?? '';
    final nlIndex = bodyText.indexOf('\n');
    final quickRuleText = nlIndex > 0
        ? bodyText.substring(0, nlIndex).trim()
        : bodyText.length > 120
            ? '${bodyText.substring(0, 120).trim()}...'
            : bodyText.trim();
    final remainingBody = nlIndex > 0
        ? bodyText.substring(nlIndex + 1).trim()
        : '';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
          children: [
            Row(children: [
              IconButton.outlined(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_forward),
              ),
              const Spacer(),
              Text(
                'الأسبوع ${widget.week.orderIndex}',
                style: tt.labelMedium
                    ?.copyWith(color: cs.onSurface.withOpacity(.5)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              widget.lecture.title,
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (widget.lecture.minutesRead != null) ...[
              const SizedBox(height: 4),
              Text(
                '${widget.lecture.minutesRead} دقيقة للقراءة',
                style: tt.bodySmall,
              ),
            ],
            const SizedBox(height: 20),
            if (quickRuleText.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.primary.withOpacity(.16)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        PhosphorIconsRegular.lightbulb,
                        size: 20,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'قاعدة سريعة',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quickRuleText,
                            style: tt.bodyMedium?.copyWith(
                              height: 1.8,
                              color: cs.onSurface.withOpacity(.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (remainingBody.isNotEmpty)
              Text(remainingBody,
                  style: tt.bodyMedium?.copyWith(height: 2))
            else if (bodyText.trim().isNotEmpty && nlIndex <= 0)
              Text(bodyText,
                  style: tt.bodyMedium?.copyWith(height: 2)),
          ],
        ),
      ),
      bottomSheet: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _toggleRead,
              icon: Icon(
                isRead
                    ? PhosphorIconsFill.checkCircle
                    : PhosphorIconsRegular.checkCircle,
                size: 20,
              ),
              label: Text(
                isRead ? 'تمت القراءة' : 'وسم كمقروء',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isRead ? cs.primary.withOpacity(.12) : cs.primary,
                foregroundColor: isRead ? cs.primary : cs.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
