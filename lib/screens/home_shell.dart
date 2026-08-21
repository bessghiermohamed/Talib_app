import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repository.dart';
import '../models/academic.dart';

/// الهيكل الرئيسي — شريط تنقل سفلي بخمسة تبويبات كما في التصميم
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.profile, required this.onLogout});
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: [
          NavigationDestination(
              icon: Icon(PhosphorIconsRegular.house),
              selectedIcon: Icon(PhosphorIconsFill.house, color: cs.primary),
              label: 'الرئيسية'),
          NavigationDestination(
              icon: Icon(PhosphorIconsRegular.books),
              selectedIcon: Icon(PhosphorIconsFill.books, color: cs.primary),
              label: 'المقررات'),
          NavigationDestination(
              icon: Icon(PhosphorIconsRegular.calendarBlank),
              selectedIcon:
                  Icon(PhosphorIconsFill.calendarBlank, color: cs.primary),
              label: 'الجدول'),
          NavigationDestination(
              icon: Icon(PhosphorIconsRegular.folders),
              selectedIcon: Icon(PhosphorIconsFill.folders, color: cs.primary),
              label: 'ملفاتي'),
          NavigationDestination(
              icon: Icon(PhosphorIconsRegular.dotsThree),
              selectedIcon:
                  Icon(PhosphorIconsFill.dotsThree, color: cs.primary),
              label: 'المزيد'),
        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.profile, required this.onLogout});
  final Profile profile;
  final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final name = profile.displayName ?? 'طالب';
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مرحبًا، $name',
                        style: tt.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('سعيدون بعودتك — هذه أول نسخة حية من طالب',
                        style: tt.bodySmall),
                  ]),
            ),
            IconButton.outlined(
                onPressed: onLogout,
                icon: Icon(PhosphorIconsRegular.signOut)),
          ]),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: cs.primary, borderRadius: BorderRadius.circular(22)),
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
                        color: cs.onPrimary.withOpacity(.85), height: 1.9),
                  ),
                ]),
          ),
          const SizedBox(height: 20),
          Text('مقرراتك',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _CoursesPage(semesterId: profile.semesterId!, embedded: true),
        ],
      ),
    );
  }
}

class _CoursesPage extends StatefulWidget {
  const _CoursesPage({required this.semesterId, this.embedded = false});
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
                  onPressed: _refresh, child: const Text('إعادة المحاولة')),
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
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
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

class _CourseCard extends StatelessWidget {
  const _CourseCard(this.course);
  final Course course;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final sub = [
      course.teacherName,
      course.hoursPerWeek != null ? '${course.hoursPerWeek} ساعات/أسبوع' : null,
    ].whereType<String>().join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: cs.primary.withOpacity(.09),
              borderRadius: BorderRadius.circular(14)),
          child: Icon(PhosphorIconsRegular.bookOpenText,
              color: cs.primary, size: 20),
        ),
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
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title, required this.icon, required this.note});
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