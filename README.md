# Coursework — Online Course Platform

A Next.js app with Supabase (auth + database) and Stripe (payments), including
a built-in admin panel for managing courses, modules, and lessons.

## What's included

- Public site: home, course catalog, course detail, checkout
- Student area: dashboard, video player with progress tracking
- Admin panel at `/admin`: create/edit courses, publish/unpublish, add modules
  and lessons
- Stripe Checkout + webhook that unlocks course access after payment
- Row Level Security policies so lessons are only visible to paying students

## 1. Set up Supabase

1. Create a project at supabase.com
2. Go to the SQL Editor and run the contents of `supabase/schema.sql`
3. Go to Settings → API and copy your Project URL, anon key, and service role key

## 2. Set up Stripe

1. Create a Stripe account (test mode is fine to start)
2. Go to Developers → API keys, copy your secret key
3. For local testing, install the Stripe CLI and run:
   ```
   stripe listen --forward-to localhost:3000/api/webhook
   ```
   This prints a webhook signing secret — put it in `.env.local`
4. For production, add a webhook endpoint in the Stripe Dashboard pointing to
   `https://yourdomain.com/api/webhook`, subscribed to `checkout.session.completed`

## 3. Configure environment variables

Copy `.env.local.example` to `.env.local` and fill in your keys:
```
cp .env.local.example .env.local
```

## 4. Install and run

```
npm install
npm run dev
```
Visit http://localhost:3000

## 5. Make yourself an admin

1. Sign up for an account through the app's `/signup` page
2. In the Supabase SQL Editor, run:
   ```sql
   update profiles set is_admin = true where id = 'your-user-uuid';
   ```
   (Find your user's UUID under Authentication → Users in Supabase)
3. Visit `/admin` — you should now have access

## 6. Add your first course

1. Go to `/admin` → "+ New course"
2. Fill in title, description, price → this saves as a draft
3. Open the course, add modules and lessons (paste a YouTube/Vimeo *embed* URL
   for each lesson's video)
4. Go back to `/admin`, click "Publish" — it now appears on the public site

## Deploying

- Push this repo to GitHub, then import it in Vercel (free tier works well)
- Add the same environment variables in Vercel's project settings
- Update `NEXT_PUBLIC_SITE_URL` to your live domain
- Point your Stripe webhook at the live domain's `/api/webhook`

## Security notes

- The service role key (`SUPABASE_SERVICE_ROLE_KEY`) bypasses Row Level
  Security — it's only used server-side in the webhook handler, never in the
  browser
- Course access is enforced by Supabase RLS policies, not just frontend
  checks — even a manipulated frontend can't read lesson data without a paid
  enrollment
- The Stripe webhook verifies the signature on every request, so no one can
  fake a "payment successful" event
