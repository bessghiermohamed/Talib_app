import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ui.dart';
import '../data/repository.dart';
import '../models/academic.dart';
import 'course_screen.dart';

/// الهيكل الرئيسي — شريط تنقل سفلي مخصص بخمسة تبويبات
/// تصميم v0.2: شريط سفلي مخصص، بطاقات مطابقة للنموذج المعتمد
class HomeShell extends StatefulWidget {
  const HomeShell(
      {super.key, required this.profile, required this.onLogout});
  final Profile profile;
  final VoidCallback onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int idx = 0;

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pages = [
      _HomePage(profile: widget.profile, onLogout: _logout),
      _CoursesPage(semesterId: widget.profile.semesterId!),
      const _ComingSoon(
          title: 'الجدول',
          icon: PhosphorIconsRegular.calendarBlank,
          note: 'جدولك الأسبوعي قادم في الإصدار القادم — بياناته موجودة أصلًا في قاعدة البيانات'),
      const _ComingSoon(
          title: 'ملفاتي',
          icon: PhosphorIconsRegular.folders,
          note: 'المحفوظات والتحميلات والملاحظات — بعد صفحة المقرر'),
      const _ComingSoon(
          title: 'المزيد',
          icon: PhosphorIconsRegular.dotsThree,
          note: 'الإعدادات والملف الشخصي'),
    ];
    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: _TalibBottomNav(
        currentIndex: idx,
        onTap: (i) => setState(() => idx = i),
      ),
    );
  }
}

// ─── Custom Bottom Navigation Bar ───────────────────────────────
class _TalibBottomNav extends StatelessWidget {
  const _TalibBottomNav(
      {required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (PhosphorIconsRegular.house, PhosphorIconsFill.house, 'الرئيسية'),
    (PhosphorIconsRegular.books, PhosphorIconsFill.books, 'المقررات'),
    (PhosphorIconsRegular.calendarBlank, PhosphorIconsFill.calendarBlank, 'الجدول'),
    (PhosphorIconsRegular.folders, PhosphorIconsFill.folders, 'ملفاتي'),
    (PhosphorIconsRegular.dotsThree, PhosphorIconsFill.dotsThree, 'المزيد'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
            top: BorderSide(color: cs.onSurface.withOpacity(.08))),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Row(
        children: [
          for (int i = 0; i < _items.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: _NavItem(
                  active: i == currentIndex,
                  regularIcon: _items[i].$1,
                  fillIcon: _items[i].$2,
                  label: _items[i].$3,
                  activeColor: cs.primary,
                  mutedColor: cs.onSurface.withOpacity(.4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends ImplicitlyAnimatedWidget {
  const _NavItem({
    required this.active,
    required this.regularIcon,
    required this.fillIcon,
    required this.label,
    required this.activeColor,
    required this.mutedColor,
  }) : super(duration: const Duration(milliseconds: 200));

  final bool active;
  final IconData regularIcon;
  final IconData fillIcon;
  final String label;
  final Color activeColor;
  final Color mutedColor;

  @override
  ImplicitlyAnimatedWidgetState<_NavItem> createState() =>
      _NavItemState();
}

class _NavItemState extends ImplicitlyAnimatedWidgetState<_NavItem> {
  late final ColorAnimation _colorAnim;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _colorAnim = visitor(
      _colorAnim,
      widget.active ? widget.activeColor : widget.mutedColor,
      (value) => ColorTween(begin: value as Color?, end: value as Color?),
      (value) => value as Color,
    ) as ColorAnimation;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorAnim.value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
            widget.active ? widget.fillIcon : widget.regularIcon,
            size: 21,
            color: color),
        const SizedBox(height: 3),
        Text(widget.label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color)),
      ],
    );
  }
}

// ─── Home Page ──────────────────────────────────────────────────
class _HomePage extends StatelessWidget {
  const _HomePage({required this.profile, required this.onLogout});
  final Profile profile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final name = profile.displayName ?? 'طالب';
    final firstChar = name.isNotEmpty ? name.characters.first : '?';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: screenPaddingH),
        children: [
          const SizedBox(height: 12),
          // Header row: avatar + greeting + bell
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(firstChar,
                    style: TextStyle(
                        color: cs.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 14),
              // Greeting
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مرحبًا، $name',
                          style: const TextStyle(
                              fontSize: 21, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                          'سعيدون بعودتك — هذه أول نسخة حية من طالب',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: cs.onSurface.withOpacity(.5))),
                    ]),
              ),
              // Bell icon with notification dot
              SizedBox(
                width: 38,
                height: 38,
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            color: cs.onSurface.withOpacity(.1))),
                    child: const Icon(PhosphorIconsRegular.bell, size: 20),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC8956C),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Hero card: ما عليك اليوم
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(22)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ما عليك اليوم',
                            style: tt.titleMedium?.copyWith(
                                color: cs.onPrimary,
                                fontWeight: FontWeight.w700)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                              color: cs.onPrimary.withOpacity(.15),
                              borderRadius: BorderRadius.circular(99)),
                          child: Text('قريبًا',
                              style: tt.labelSmall
                                  ?.copyWith(color: cs.onPrimary)),
                        ),
                      ]),
                  const SizedBox(height: 10),
                  Text(
                    'جدول حصصك اليوم سيظهر هنا في الإصدار القادم — بياناته جاهزة في قاعدة البيانات بالفعل.',
                    style: tt.bodySmall?.copyWith(
                        color: cs.onPrimary.withOpacity(.85),
                        height: 1.9),
                  ),
                ]),
          ),
          const SizedBox(height: 18),

          // Resume card: أكمل من حيث توقفت
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.primary.withOpacity(.16)),
            ),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(PhosphorIconsFill.play,
                    color: cs.onPrimary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text('أكمل من حيث توقفت',
                    style: tt.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Icon(PhosphorIconsRegular.caretLeft,
                  color: cs.onSurface.withOpacity(.4)),
            ]),
          ),
          const SizedBox(height: 24),

          // Courses section
          Text('مقرراتك',
              style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _CoursesPage(
              semesterId: profile.semesterId!, embedded: true),
        ],
      ),
    );
  }
}

// ─── Courses Page ───────────────────────────────────────────────
class _CoursesPage extends StatefulWidget {
  const _CoursesPage(
      {required this.semesterId, this.embedded = false});
  final String semesterId;
  final bool embedded;

  @override
  State<_CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<_CoursesPage> {
  late Future<List<Course>> _future;

  @override
  void initState() {
    super.initState();
    _future = TalibRepo().courses(widget.semesterId);
  }

  Future<void> _refresh() async {
    final f = TalibRepo().courses(widget.semesterId);
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return FutureBuilder<List<Course>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('تعذّر جلب المقررات', style: tt.titleSmall),
              const SizedBox(height: 8),
              OutlinedButton(
                  onPressed: _refresh,
                  child: const Text('إعادة المحاولة')),
            ]),
          );
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Center(
              child: Text('لا توجد مقررات منشورة لهذا السداسي بعد',
                  style: tt.bodySmall));
        }
        final cards = [for (final c in list) _CourseCard(c)];
        if (widget.embedded) return Column(children: cards);
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(screenPaddingH, 12, screenPaddingH, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('${list.length} مقررات · سداسيّك الحالي',
                    style: tt.bodySmall),
              ),
              ...cards,
            ],
          ),
        );
      },
    );
  }
}

// ─── Course Card — now clickable ────────────────────────────────
class _CourseCard extends StatelessWidget {
  const _CourseCard(this.course);
  final Course course;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final sub = [
      course.teacherName,
      course.hoursPerWeek != null
          ? '${course.hoursPerWeek} ساعات/أسبوع'
          : null,
    ].whereType<String>().join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CourseScreen(course: course))),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.onSurface.withOpacity(.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.06),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                  spreadRadius: -18,
                ),
              ],
            ),
            child: Row(children: [
              TalibIconTile(
                  icon: PhosphorIconsRegular.bookOpenText),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.name,
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      if (sub.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(sub, style: tt.bodySmall),
                      ],
                    ]),
              ),
              Icon(PhosphorIconsRegular.caretLeft,
                  color: cs.onSurface.withOpacity(.4)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Coming Soon placeholder ────────────────────────────────────
class _ComingSoon extends StatelessWidget {
  const _ComingSoon(
      {required this.title, required this.icon, required this.note});
  final String title;
  final IconData icon;
  final String note;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.09),
                  borderRadius: BorderRadius.circular(24)),
              child: Icon(icon, size: 34, color: cs.primary),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: tt.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(note, textAlign: TextAlign.center, style: tt.bodySmall),
          ],
        ),
      ),
    );
  }
}
