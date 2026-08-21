import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/ui.dart';
import '../data/repository.dart';
import '../models/academic.dart';
import '../models/content.dart';
import 'lecture_screen.dart';
import 'pdf_viewer_screen.dart';

/// صفحة المقرر — أسابيع / ملفات / اختبارات / نظرة عامة (تصميم v0.2)
class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key, required this.course});
  final Course course;

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final repo = TalibRepo();
  bool loading = true;
  String? error;
  int tab = 0;
  bool saved = false;

  List<Week> weeks = [];
  List<FileItem> files = [];
  List<ExamItem> exams = [];
  Map<String, Lecture> lecturesByWeek = {};
  Set<String> readIds = {};

  static const _tabs = ['الأسابيع', 'الملفات', 'الاختبارات', 'نظرة عامة'];

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
      final cid = widget.course.id;
      final r = await Future.wait([
        repo.weeks(cid),
        repo.courseFiles(cid),
        repo.courseExams(cid),
        repo.lecturesByWeek(cid),
        repo.readLectureIds(cid),
      ]);
      if (!mounted) return;
      setState(() {
        weeks = r[0] as List<Week>;
        files = r[1] as List<FileItem>;
        exams = r[2] as List<ExamItem>;
        lecturesByWeek = r[3] as Map<String, Lecture>;
        readIds = r[4] as Set<String>;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'تعذّر تحميل المقرر — تحقق من الاتصال وأعد المحاولة';
        loading = false;
      });
    }
  }

  int get totalLectures => lecturesByWeek.length;
  int get percent =>
      totalLectures == 0 ? 0 : (readIds.length * 100 ~/ totalLectures);

  bool weekDone(Week w) {
    final l = lecturesByWeek[w.id];
    return l != null && readIds.contains(l.id);
  }

  bool isCurrent(Week w) {
    for (final k in weeks) {
      if (weekDone(k)) continue;
      return k.id == w.id;
    }
    return false;
  }

  String weekLabel(String? wid) {
    if (wid == null) return 'عام';
    for (final w in weeks) {
      if (w.id == wid) return 'الأسبوع ${w.orderIndex}';
    }
    return '';
  }

  Future<void> _openWeek(Week w) async {
    final l = lecturesByWeek[w.id];
    if (l == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('لم تُنشر محاضرة هذا الأسبوع بعد')));
      return;
    }
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => LectureScreen(
                course: widget.course,
                week: w,
                lecture: l,
                totalLectures: totalLectures)));
    _load();
  }

  void _openFile(FileItem f) {
    if (f.storagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'الملف لم يُرفع للمخزن بعد — يُرفع من لوحة الإدارة')));
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
                title: f.title,
                url: repo.fileUrl(f.storagePath!))));
  }

  IconData _fileIcon(String t) => switch (t) {
        'docx' => PhosphorIcons.regular.fileDoc,
        'ppt' || 'pptx' => PhosphorIcons.regular.projectorScreen,
        'image' => PhosphorIcons.regular.image,
        'link' => PhosphorIcons.regular.link,
        _ => PhosphorIcons.regular.filePdf,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(PhosphorIcons.regular.warningCircle,
                size: 44, color: cs.onSurface.withOpacity(.4)),
            const SizedBox(height: 12),
            Text(error!, style: tt.bodySmall),
            const SizedBox(height: 14),
            OutlinedButton(
                onPressed: _load,
                child: const Text('إعادة المحاولة')),
          ]),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            // Top bar
            Row(children: [
              IconButton.outlined(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward)),
              const Spacer(),
              IconButton.outlined(
                  onPressed: () => setState(() => saved = !saved),
                  icon: Icon(saved
                      ? PhosphorIcons.fill.bookmarkSimple
                      : PhosphorIcons.regular.bookmarkSimple),
                  color: saved ? cs.primary : null),
            ]),
            const SizedBox(height: 6),
            Text(widget.course.name,
                style: tt.displaySmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (widget.course.teacherName != null) ...[
              const SizedBox(height: 4),
              Text(widget.course.teacherName!, style: tt.bodySmall),
            ],
            const SizedBox(height: 12),
            Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (widget.course.hoursPerWeek != null)
                    TalibChip(
                        text:
                            '${widget.course.hoursPerWeek} ساعات/أسبوع'),
                  TalibChip(text: '$percent% مكتمل', filled: true),
                ]),
            const SizedBox(height: 16),

            // Tab bar
            _TabBar(
                current: tab,
                onChanged: (i) => setState(() => tab = i),
                tabs: _tabs),
            const SizedBox(height: 16),

            // Tab content
            if (tab == 0) ...[
              if (weeks.isEmpty)
                _EmptyState(
                    icon: PhosphorIcons.regular.books,
                    title: 'لم يُنشر محتوى بعد',
                    body:
                        'ستظهر الأسابيع هنا فور نشرها من لوحة الإدارة'),
              for (final w in weeks) _weekRow(cs, tt, w),
            ],
            if (tab == 1) ...[
              if (files.isEmpty)
                const _EmptyState(
                    icon: PhosphorIcons.regular.filePdf,
                    title: 'لا توجد ملفات بعد',
                    body: 'ستظهر الملفات هنا فور رفعها'),
              for (final f in files) _fileRow(cs, tt, f),
            ],
            if (tab == 2) ...[
              if (exams.isEmpty)
                const _EmptyState(
                    icon: PhosphorIcons.regular.clipboardText,
                    title: 'لا اختبارات مجدولة',
                    body: 'ستظهر الاختبارات هنا فور جدولتها'),
              for (final e in exams) _examCard(cs, tt, e),
            ],
            if (tab == 3) ..._overview(cs, tt),
          ],
        ),
      ),
    );
  }

  Widget _weekRow(ColorScheme cs, TextTheme tt, Week w) {
    final done = weekDone(w);
    final cur = !done && isCurrent(w);
    final hasLec = lecturesByWeek.containsKey(w.id);
    final fc = files.where((f) => f.weekId == w.id).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cur ? cs.primary.withOpacity(.08) : cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: cur
                ? cs.primary.withOpacity(.3)
                : cs.onSurface.withOpacity(.07)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openWeek(w),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(
                  done
                      ? PhosphorIcons.fill.checkCircle
                      : hasLec
                          ? PhosphorIcons.regular.pencilLine
                          : PhosphorIcons.regular.hourglass,
                  size: 22,
                  color: done || cur
                      ? cs.primary
                      : cs.onSurface.withOpacity(.35)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'الأسبوع ${w.orderIndex} · ${done ? 'مكتمل' : cur ? 'جارٍ' : hasLec ? 'جاهز' : 'قريبًا'}',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: cur
                                  ? cs.primary
                                  : cs.onSurface.withOpacity(.5))),
                      if (w.title != null)
                        Text(w.title!,
                            style: tt.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(
                          hasLec
                              ? 'محاضرة واحدة${fc > 0 ? ' · $fc ${fc == 1 ? 'ملف' : 'ملفات'}' : ''}'
                              : 'بانتظار نشر المحاضرة',
                          style: tt.bodySmall),
                    ]),
              ),
              if (cur)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(11)),
                  child: Text('متابعة',
                      style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _fileRow(ColorScheme cs, TextTheme tt, FileItem f) {
    final size = f.sizeLabel;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.onSurface.withOpacity(.07))),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openFile(f),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(children: [
              TalibIconTile.small(
                  icon: _fileIcon(f.fileType ?? ''), size: 34, radius: 11),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(f.title,
                        style: tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                        '${weekLabel(f.weekId)}${size.isEmpty ? '' : ' · $size'}',
                        style: tt.bodySmall),
                  ])),
              Icon(PhosphorIcons.regular.caretLeft,
                  color: cs.onSurface.withOpacity(.4)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _examCard(ColorScheme cs, TextTheme tt, ExamItem e) {
    final d = e.daysLeft;
    final dLabel = d < 0 ? 'انتهى' : '$d ${d == 1 ? 'يوم' : 'أيام'}';
    final date = e.examDate == null
        ? null
        : '${e.examDate!.day}/${e.examDate!.month}/${e.examDate!.year}';
    return TalibCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('اختبار',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9C6238))),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: const Color(0xFFC8956C).withOpacity(.16),
                        borderRadius: BorderRadius.circular(99)),
                    child: Text(dLabel,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9C6238))),
                  ]),
            const SizedBox(height: 10),
            Text(e.title,
                style: tt.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                if (date != null)
                  _meta(cs, PhosphorIcons.regular.calendarBlank, date),
                if (e.place != null)
                  _meta(cs, PhosphorIcons.regular.mapPin, e.place!),
                if (e.scope != null)
                  _meta(cs, PhosphorIcons.regular.info, e.scope!),
              ],
            ),
          ]),
    );
  }

  Widget _meta(ColorScheme cs, IconData i, String t) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(i, size: 15, color: cs.onSurface.withOpacity(.6)),
        const SizedBox(width: 5),
        Text(t,
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withOpacity(.6))),
      ]);

  List<Widget> _overview(ColorScheme cs, TextTheme tt) {
    final c = widget.course;
    return [
      TalibCard(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('وصف المقرر',
                  style: tt.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(c.description ?? 'لا يوجد وصف بعد',
                  style: tt.bodyMedium?.copyWith(height: 2)),
            ]),
      ),
      if (c.refs.isNotEmpty) ...[
        const SizedBox(height: 10),
        TalibCard(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الكتب والمراجع',
                    style: tt.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                for (final r in c.refs)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Icon(PhosphorIcons.regular.book,
                          size: 18, color: const Color(0xFF9C6238)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(r,
                              style: tt.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500))),
                    ]),
                  ),
              ]),
        ),
      ],
    ];
  }
}

// ─── Tab bar widget ──────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  const _TabBar(
      {required this.current, required this.onChanged, required this.tabs});
  final int current;
  final ValueChanged<int> onChanged;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: cs.primary.withOpacity(.09),
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        current == i ? cs.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(tabs[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: current == i
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: current == i
                              ? cs.primary
                              : cs.onSurface.withOpacity(.55))),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Empty state widget ───────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
              color: cs.primary.withOpacity(.09),
              borderRadius: BorderRadius.circular(20)),
          child: Icon(icon, size: 28, color: cs.primary),
        ),
        const SizedBox(height: 14),
        Text(title,
            style:
                tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(body,
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(height: 1.9)),
      ]),
    );
  }
}
