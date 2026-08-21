-- ============================================================
-- طالب | Tâlib — التهيئة الكاملة لقاعدة البيانات (Supabase)
-- التنفيذ: Supabase Dashboard → SQL Editor → New Query
--          الصق الملف كاملًا → Run  (مرة واحدة فقط)
-- ============================================================

-- ---------- ١. الجداول ----------

create table public.institutions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text not null default 'school',
  city text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.specializations (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  name text not null,
  is_active boolean not null default true
);

create table public.tracks (
  id uuid primary key default gen_random_uuid(),
  specialization_id uuid not null references public.specializations(id) on delete cascade,
  name text not null
);

create table public.levels (
  id uuid primary key default gen_random_uuid(),
  track_id uuid not null references public.tracks(id) on delete cascade,
  name text not null,
  order_index int not null default 0
);

create table public.semesters (
  id uuid primary key default gen_random_uuid(),
  level_id uuid not null references public.levels(id) on delete cascade,
  name text not null,
  order_index int not null default 0
);

create table public.courses (
  id uuid primary key default gen_random_uuid(),
  semester_id uuid not null references public.semesters(id) on delete cascade,
  name text not null,
  teacher_name text,
  hours_per_week int,
  description text,
  refs text[] default '{}',
  order_index int not null default 0
);

create table public.weeks (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  order_index int not null,
  title text,
  is_published boolean not null default false,
  published_at timestamptz
);

create table public.lectures (
  id uuid primary key default gen_random_uuid(),
  week_id uuid not null references public.weeks(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null,
  body text,
  minutes_read int
);

create table public.files (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  week_id uuid references public.weeks(id) on delete set null,
  lecture_id uuid references public.lectures(id) on delete set null,
  kind text not null default 'lecture'
    check (kind in ('lecture','exercise','reference','summary')),
  file_type text not null default 'pdf'
    check (file_type in ('pdf','docx','ppt','image','link')),
  title text not null,
  description text,
  storage_path text,
  external_url text,
  size_bytes bigint,
  uploaded_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.exams (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null,
  exam_date timestamptz,
  place text,
  scope text,
  kind text default 'فرض'
);

create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references public.courses(id) on delete cascade,
  title text not null,
  body text,
  created_at timestamptz not null default now()
);

create table public.schedules (
  id uuid primary key default gen_random_uuid(),
  semester_id uuid not null references public.semesters(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  weekday int not null check (weekday between 0 and 5),
  start_time time not null,
  end_time time not null,
  room text
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role text not null default 'student' check (role in ('student','admin')),
  institution_id uuid references public.institutions(id),
  specialization_id uuid references public.specializations(id),
  track_id uuid references public.tracks(id),
  level_id uuid references public.levels(id),
  semester_id uuid references public.semesters(id),
  created_at timestamptz not null default now()
);

create table public.progress (
  user_id uuid not null references public.profiles(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  completed_weeks int[] not null default '{}',
  read_lecture_ids uuid[] not null default '{}',
  percent int not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, course_id)
);

create table public.bookmarks (
  user_id uuid not null references public.profiles(id) on delete cascade,
  file_id uuid not null references public.files(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, file_id)
);

create table public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  lecture_id uuid not null references public.lectures(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------- ٢. الدوال والمشغّلات ----------

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'name', 'طالب جديد'));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.protect_role()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if new.role is distinct from old.role
     and auth.uid() is not null
     and not exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  then
    raise exception 'غير مسموح بتغيير الدور';
  end if;
  return new;
end;
$$;

create trigger protect_role_before_update
  before update on public.profiles
  for each row execute function public.protect_role();

-- ---------- ٣. الصلاحيات (RLS) ----------

alter table public.profiles enable row level security;

create policy "profiles_select_own" on public.profiles
  for select to authenticated using (id = auth.uid());

create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

do $$
declare t text;
begin
  foreach t in array array[
    'institutions','specializations','tracks','levels','semesters',
    'courses','weeks','lectures','files','exams','announcements','schedules'
  ]
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy "read_%1$s" on public.%1$I for select to authenticated using (true)', t);
    execute format('create policy "admin_write_%1$s" on public.%1$I for all to authenticated using (public.is_admin()) with check (public.is_admin())', t);
  end loop;
end $$;

do $$
declare t text;
begin
  foreach t in array array['progress','bookmarks','notes']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy "own_all_%1$s" on public.%1$I for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid())', t);
  end loop;
end $$;

-- ---------- ٤. التخزين (Storage) ----------

insert into storage.buckets (id, name, public)
values ('course-files', 'course-files', true)
on conflict (id) do nothing;

create policy "read_course_files" on storage.objects
  for select using (bucket_id = 'course-files');

create policy "admin_course_files" on storage.objects
  for all to authenticated
  using (bucket_id = 'course-files' and public.is_admin())
  with check (bucket_id = 'course-files' and public.is_admin());

-- ---------- ٥. فهارس للأداء ----------

create index on public.courses (semester_id);
create index on public.weeks (course_id, order_index);
create index on public.lectures (week_id);
create index on public.files (course_id);
create index on public.files (week_id);
create index on public.exams (course_id, exam_date);
create index on public.announcements (created_at desc);
create index on public.schedules (semester_id, weekday);
create index on public.notes (user_id, lecture_id);

-- ---------- ٦. البيانات الأولية — المؤسسة الأولى ----------

insert into public.institutions (id, name, type, city) values
('00000000-0000-0000-0000-000000000001','المدرسة العليا للأساتذة','school','الجزائر');

insert into public.specializations (id, institution_id, name) values
('00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000001','الأدب العربي');

insert into public.tracks (id, specialization_id, name) values
('00000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000002','ملمح ابتدائي');

insert into public.levels (id, track_id, name, order_index) values
('00000000-0000-0000-0000-0000000000011','00000000-0000-0000-0000-000000000003','السنة الأولى',1),
('00000000-0000-0000-0000-0000000000012','00000000-0000-0000-0000-000000000003','السنة الثانية',2),
('00000000-0000-0000-0000-0000000000013','00000000-0000-0000-0000-000000000003','السنة الثالثة',3),
('00000000-0000-0000-0000-0000000000014','00000000-0000-0000-0000-000000000003','السنة الرابعة',4);

insert into public.semesters (id, level_id, name, order_index) values
('00000000-0000-0000-0000-0000000000021','00000000-0000-0000-0000-0000000000011','السداسي الأول',1),
('00000000-0000-0000-0000-0000000000022','00000000-0000-0000-0000-0000000000011','السداسي الثاني',2),
('00000000-0000-0000-0000-0000000000023','00000000-0000-0000-0000-0000000000012','السداسي الأول',1),
('00000000-0000-0000-0000-0000000000024','00000000-0000-0000-0000-0000000000012','السداسي الثاني',2),
('00000000-0000-0000-0000-0000000000025','00000000-0000-0000-0000-0000000000013','السداسي الأول',1),
('00000000-0000-0000-0000-0000000000026','00000000-0000-0000-0000-0000000000013','السداسي الثاني',2),
('00000000-0000-0000-0000-0000000000027','00000000-0000-0000-0000-0000000000014','السداسي الأول',1),
('00000000-0000-0000-0000-0000000000028','00000000-0000-0000-0000-0000000000014','السداسي الثاني',2);

insert into public.courses (id, semester_id, name, teacher_name, hours_per_week, description, refs, order_index) values
('00000000-0000-0000-0000-0000000000101','00000000-0000-0000-0000-0000000000023','النحو والصرف','أ. عبد الرحمن مالكي',3,
 'مدخل إلى قواعد النحو العربي: الإعراب والبناء، المرفوعات والمنصوبات والمجرورات، مع تطبيقات على نصوص من التراث والأدب الحديث.',
 array['شرح ابن عقيل على ألفية ابن مالك','جامع الدروس العربية — مصطفى الغلاييني','النحو الوافي — عباس حسن'],1),
('00000000-0000-0000-0000-0000000000102','00000000-0000-0000-0000-0000000000023','الأدب الجاهلي','د. سامية ساعدية',3,
 'دراسة الشعر الجاهلي: خصائصه وأغراضه وشعراءه، مع تحليل نصوص مختارة.',
 array['تاريخ الأدب العربي — شوقي ضيف'],2),
('00000000-0000-0000-0000-0000000000103','00000000-0000-0000-0000-0000000000023','البلاغة','أ. نادية حمودي',2,
 'علم المعنى وعلم البيان وعلم البديع مع تطبيقات نصية.',
 array['البلاغة الواضحة — علي الجارم ومصطفى أمين'],3),
('00000000-0000-0000-0000-0000000000104','00000000-0000-0000-0000-0000000000023','اللسانيات','د. محمد بلحاج',2,
 'مدخل إلى اللسانيات العامة: مفاهيمها وفروعها ومدارسها.',
 array['مدخل إلى اللسانيات'],4),
('00000000-0000-0000-0000-0000000000105','00000000-0000-0000-0000-0000000000023','فقه اللغة','أ. صالح بوعلام',2,
 'مدخل إلى فقه اللغة العربية وعلاقتها بالمعاجم واللهجات.',
 array[]::text[],5),
('00000000-0000-0000-0000-0000000000106','00000000-0000-0000-0000-0000000000024','علوم التربية','د. فاطمة الزهراء',2,
 'المفاهيم الأساسية في علوم التربية والبيداغوجيا.',
 array[]::text[],1);

insert into public.weeks (id, course_id, order_index, title, is_published, published_at) values
('00000000-0000-0000-0000-0000000000201','00000000-0000-0000-0000-0000000000101',1,'مدخل إلى علم النحو',true, now() - interval '28 days'),
('00000000-0000-0000-0000-0000000000202','00000000-0000-0000-0000-0000000000101',2,'المرفوعات',true, now() - interval '21 days'),
('00000000-0000-0000-0000-0000000000203','00000000-0000-0000-0000-0000000000101',3,'المنصوبات',true, now() - interval '14 days'),
('00000000-0000-0000-0000-0000000000204','00000000-0000-0000-0000-0000000000101',4,'الإعراب والبناء',true, now() - interval '2 hours'),
('00000000-0000-0000-0000-0000000000205','00000000-0000-0000-0000-0000000000101',5,'الأفعال الخمسة',false,null),
('00000000-0000-0000-0000-0000000000206','00000000-0000-0000-0000-0000000000101',6,'المجرورات',false,null);

insert into public.lectures (id, week_id, course_id, title, body, minutes_read) values
('00000000-0000-0000-0000-0000000000301','00000000-0000-0000-0000-0000000000204','00000000-0000-0000-0000-0000000000101','الإعراب والبناء',
'الإعراب تغيّرٌ يلحق أواخر الكلمات بحسب موقعها في الجملة، والعوامل المتقدّمة عليها من فاعلية أو مفعولية أو غيرهما. فالكلمة الواحدة قد تأتي مرفوعةً تارةً، ومنصوبةً أخرى، بحسب العامل الذي يسبقها.

وللإعراب علامات أصلية: الضمة علامة الرفع، والفتحة علامة النصب، والكسرة علامة الجر، والسكون علامة الجزم. وقد تنوب عنها علامات فرعية في المثنى وجمع المذكر السالم والأسماء الخمسة.

أما البناء فهو لزوم آخر الكلمة حالةً واحدة لا تتغيّر مهما تغيّر موقعها في الجملة. ومن المبنيّ: الضمائر، وأسماء الإشارة (إلا «هذا» و«ذلك»)، والأسماء الموصولة، وبعض الظروف.

أمثلة: «جاء الطالبُ المجتهدُ» — الطالبُ: فاعل مرفوع. «رأيتُ الطالبَ» — الطالبَ: مفعول به منصوب.

قاعدة سريعة: المرفوعات أربعة: الفاعل، ونائب الفاعل، والمبتدأ، وخبر المبتدأ. فإذا وجدتَ أحدها فاطلب له الضمة أو ما ينوب عنها.',8);

insert into public.files (id, course_id, week_id, kind, file_type, title, size_bytes, created_at) values
('00000000-0000-0000-0000-0000000000401','00000000-0000-0000-0000-0000000000101','00000000-0000-0000-0000-0000000000203','lecture','pdf','نحو-أسبوع3-الإعراب.pdf',2400000, now() - interval '14 days'),
('00000000-0000-0000-0000-0000000000402','00000000-0000-0000-0000-0000000000101','00000000-0000-0000-0000-0000000000202','exercise','docx','تمارين محلولة في النحو.docx',640000, now() - interval '21 days'),
('00000000-0000-0000-0000-0000000000403','00000000-0000-0000-0000-0000000000101','00000000-0000-0000-0000-0000000000203','lecture','ppt','عرض المنصوبات.pptx',3200000, now() - interval '13 days'),
('00000000-0000-0000-0000-0000000000404','00000000-0000-0000-0000-0000000000101','00000000-0000-0000-0000-0000000000204','lecture','pdf','محاضرة الأسبوع ٤ — الإعراب والبناء.pdf',1800000, now() - interval '2 hours');

insert into public.exams (id, course_id, title, exam_date, place, scope, kind) values
('00000000-0000-0000-0000-0000000000501','00000000-0000-0000-0000-0000000000102','الفرض الأول','2025-12-19 10:00:00+01','قاعة ٣','يشمل الأسابيع ١–٤','فرض');

insert into public.announcements (id, course_id, title, body, created_at) values
('00000000-0000-0000-0000-0000000000601','00000000-0000-0000-0000-0000000000101','رُفعت محاضرة الأسبوع ٤','أضيفت محاضرة «الإعراب والبناء» مع ملف PDF إلى الأسبوع الرابع.', now() - interval '2 hours'),
('00000000-0000-0000-0000-0000000000602',null,'تأجيل حصة اللسانيات','تؤجّل حصة اللسانيات إلى يوم الإثنين القادم بإذن الله. — إدارة القسم', now() - interval '1 day');

insert into public.schedules (id, semester_id, course_id, weekday, start_time, end_time, room) values
('00000000-0000-0000-0000-0000000000701','00000000-0000-0000-0000-0000000000023','00000000-0000-0000-0000-0000000000105',0,'08:00','09:30','قاعة ٨'),
('00000000-0000-0000-0000-0000000000702','00000000-0000-0000-0000-0000000000023','00000000-0000-0000-0000-0000000000101',0,'10:00','11:30','قاعة ١٢'),
('00000000-0000-0000-0000-0000000000703','00000000-0000-0000-0000-0000000000023','00000000-0000-0000-0000-0000000000103',0,'14:00','15:30','المدرج ٢'),
('00000000-0000-0000-0000-0000000000704','00000000-0000-0000-0000-0000000000023','00000000-0000-0000-0000-0000000000102',1,'09:00','10:30','قاعة ٥'),
('00000000-0000-0000-0000-0000000000705','00000000-0000-0000-0000-0000000000023','00000000-0000-0000-0000-0000000000104',1,'11:00','12:30','المدرج ٢'),
('00000000-0000-0000-0000-0000000000706','00000000-0000-0000-0000-0000000000023','00000000-0000-0000-0000-0000000000104',2,'08:00','09:30','المدرج ٢'),
('00000000-0000-0000-0000-0000000000707','00000000-0000-0000-0000-0000000000023','00000000-0000-0000-0000-0000000000101',2,'10:00','11:30','قاعة ١٢'),
('00000000-0000-0000-0000-0000000000708','00000000-0000-0000-0000-0000000000023','00000000-0000-0000-0000-0000000000102',3,'09:00','10:30','قاعة ٥'),
('00000000-0000-0000-0000-0000000000709','00000000-0000-0000-0000-0000000000023','00000000-0000-0000-0000-0000000000103',3,'11:00','12:30','المدرج ٢'),
('00000000-0000-0000-0000-0000000000710','00000000-0000-0000-0000-0000000000023','00000000-0000-0000-0000-0000000000101',4,'08:00','09:30','قاعة ١٢'),
('00000000-0000-0000-0000-0000000000711','00000000-0000-0000-0000-0000000000023','00000000-0000-0000-0000-0000000000105',4,'10:00','11:30','قاعة ٨'),
('00000000-0000-0000-0000-0000000000712','00000000-0000-0000-0000-0000000000023','00000000-0000-0000-0000-0000000000104',5,'09:00','10:30','المدرج ٢');

-- ---------- ٧. بعد أول تسجيل دخول: ترقية حساب المالك إلى admin ----------
-- استبدل البريد ثم نفّذ:
-- update public.profiles set role = 'admin'
-- where id = (select id from auth.users where email = 'your@email.com');