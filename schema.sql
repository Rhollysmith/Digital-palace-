-- ========== PROFILES ==========
create table profiles (
  id uuid references auth.users primary key,
  full_name text,
  avatar_url text,
  is_admin boolean default false,
  created_at timestamp default now()
);

-- Auto-create a profile row whenever a new auth user signs up
create function handle_new_user() returns trigger as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

-- ========== COURSES ==========
create table courses (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  price numeric not null,
  thumbnail_url text,
  is_published boolean default false,
  created_at timestamp default now()
);

-- ========== MODULES ==========
create table modules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references courses(id) on delete cascade,
  title text not null,
  position int not null
);

-- ========== LESSONS ==========
create table lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid references modules(id) on delete cascade,
  title text not null,
  video_url text,
  content text,
  position int not null,
  duration_seconds int
);

-- ========== ENROLLMENTS ==========
create table enrollments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  course_id uuid references courses(id),
  payment_status text default 'pending',
  stripe_session_id text,
  enrolled_at timestamp default now(),
  unique(user_id, course_id)
);

-- ========== LESSON PROGRESS ==========
create table lesson_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  lesson_id uuid references lessons(id),
  completed boolean default false,
  completed_at timestamp,
  unique(user_id, lesson_id)
);

-- ========== ROW LEVEL SECURITY ==========
alter table profiles enable row level security;
alter table courses enable row level security;
alter table modules enable row level security;
alter table lessons enable row level security;
alter table enrollments enable row level security;
alter table lesson_progress enable row level security;

-- Profiles: users can read/update their own profile
create policy "View own profile" on profiles for select using (auth.uid() = id);
create policy "Update own profile" on profiles for update using (auth.uid() = id);

-- Courses: published courses are publicly readable; admins can manage all
create policy "Public can view published courses" on courses
  for select using (is_published = true);

create policy "Admins manage courses" on courses
  for all using (
    exists (select 1 from profiles where id = auth.uid() and is_admin = true)
  );

-- Modules: readable if the parent course is published
create policy "View modules of published courses" on modules
  for select using (
    exists (select 1 from courses where courses.id = modules.course_id and courses.is_published = true)
  );

create policy "Admins manage modules" on modules
  for all using (
    exists (select 1 from profiles where id = auth.uid() and is_admin = true)
  );

-- Lessons: metadata (title) visible to anyone browsing; video_url only
-- returned to the client when the enrollment check in application code
-- passes. For stricter protection, serve lessons via a server route instead
-- of direct table access — see /app/api/lesson/[id]/route.js pattern.
create policy "View lessons if enrolled or admin" on lessons
  for select using (
    exists (
      select 1 from enrollments e
      join modules m on m.course_id = e.course_id
      where m.id = lessons.module_id
      and e.user_id = auth.uid()
      and e.payment_status = 'paid'
    )
    or exists (select 1 from profiles where id = auth.uid() and is_admin = true)
  );

create policy "Admins manage lessons" on lessons
  for all using (
    exists (select 1 from profiles where id = auth.uid() and is_admin = true)
  );

-- Enrollments: users see their own; admins see all
create policy "View own enrollments" on enrollments
  for select using (auth.uid() = user_id);

create policy "Admins view all enrollments" on enrollments
  for select using (
    exists (select 1 from profiles where id = auth.uid() and is_admin = true)
  );

-- Lesson progress: users manage their own
create policy "Manage own progress" on lesson_progress
  for all using (auth.uid() = user_id);

-- To make a user an admin, run manually in the Supabase SQL editor:
-- update profiles set is_admin = true where id = 'the-users-auth-uid';
