import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../data/repository.dart';
import '../models/academic.dart';

/// الإعداد الأكاديمي — خمس خطوات بترتيب الهيكل نفسه
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final Future<void> Function() onDone;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final repo = TalibRepo();
  int step = 0;
  bool loading = true;
  bool saving = false;
  String? selected;
  String? error;
  List<AcademicNode> options = [];
  final Map<int, AcademicNode> chosen = {};

  static const _titles = [
    'اختر مؤسستك', 'اختر تخصصك', 'اختر الملمح', 'اختر مستواك', 'اختر السداسي'
  ];
  static const _subs = [
    'حتى نعرض لك المقررات والمحتوى الخاصّين بمؤسستك',
    'التخصص الذي تدرسه',
    'الطور الذي تتكوّن لتدريسه',
    'السنة الدراسية الحالية',
    'نصف السنة الدراسية الحالي',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      List<AcademicNode> rows;
      switch (step) {
        case 0:
          rows = await repo.institutions();
          break;
        case 1:
          rows = await repo.specializations(chosen[0]!.id);
          break;
        case 2:
          rows = await repo.tracks(chosen[1]!.id);
          break;
        case 3:
          rows = await repo.levels(chosen[2]!.id);
          break;
        default:
          rows = await repo.semesters(chosen[3]!.id);
      }
      if (!mounted) return;
      setState(() {
        options = rows;
        selected = null;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'تعذّر جلب البيانات — تأكد من تنفيذ ملف SQL ومن الاتصال';
        loading = false;
      });
    }
  }

  Future<void> _next() async {
    if (selected == null) return;
    chosen[step] = options.firstWhere((o) => o.id == selected);
    if (step < 4) {
      setState(() => step++);
      _load();
      return;
    }
    setState(() => saving = true);
    try {
      await repo.saveOnboarding(
        institutionId: chosen[0]!.id,
        specializationId: chosen[1]!.id,
        trackId: chosen[2]!.id,
        levelId: chosen[3]!.id,
        semesterId: chosen[4]!.id,
      );
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذّر الحفظ — حاول مجددًا')));
      }
      return;
    }
    await widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(17)),
                        child: Icon(PhosphorIcons.fill.bookOpenText,
                            color: cs.onPrimary, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text('طالب',
                          style: tt.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: List.generate(5, (i) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= step
                                ? cs.primary
                                : cs.primary.withOpacity(.15),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text('الخطوة ${['١', '٢', '٣', '٤', '٥'][step]} من ٥',
                      style: tt.labelSmall),
                  const SizedBox(height: 14),
                  Text(_titles[step],
                      style: tt.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(_subs[step], style: tt.bodySmall),
                ],
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? _ErrorView(message: error!, onRetry: _load)
                      : options.isEmpty
                          ? _ErrorView(
                              message: 'لا توجد خيارات متاحة لهذه الخطوة',
                              onRetry: _load)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
                              itemCount: options.length,
                              itemBuilder: (_, i) {
                                final o = options[i];
                                final sel = selected == o.id;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Material(
                                    color: sel
                                        ? cs.primary.withOpacity(.08)
                                        : cs.surface,
                                    borderRadius: BorderRadius.circular(18),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () =>
                                          setState(() => selected = o.id),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border: Border.all(
                                            color: sel
                                                ? cs.primary
                                                : Colors.transparent,
                                            width: 1.6,
                                          ),
                                        ),
                                        child: Row(children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: sel
                                                  ? cs.primary
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: sel
                                                    ? cs.primary
                                                    : cs.onSurface
                                                        .withOpacity(.2),
                                                width: 1.6,
                                              ),
                                            ),
                                            child: sel
                                                ? Icon(Icons.check,
                                                    size: 14,
                                                    color: cs.onPrimary)
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                              child: Text(o.name,
                                                  style: tt.titleSmall)),
                                        ]),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                    top: BorderSide(color: cs.onSurface.withOpacity(.08))),
              ),
              child: Row(children: [
                if (step > 0)
                  IconButton.outlined(
                    onPressed: () {
                      setState(() => step--);
                      _load();
                    },
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'رجوع',
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: (selected == null || saving) ? null : _next,
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(step == 4 ? 'ابدأ استخدام طالب' : 'متابعة'),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.regular.warningCircle,
              size: 44,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.4)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: Icon(PhosphorIcons.regular.arrowClockwise),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}