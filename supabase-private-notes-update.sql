-- Add private shopper notes to an existing Secret Wishlist database.
-- Run this ONCE in Supabase -> SQL Editor -> New query -> Run.

create table if not exists public.gift_notes (
  id uuid primary key default gen_random_uuid(),
  wish_id uuid not null references public.wishes(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 500),
  created_at timestamptz not null default now()
);

grant select, insert, delete on public.gift_notes to authenticated;
alter table public.gift_notes enable row level security;

drop policy if exists "friends can read private gift notes" on public.gift_notes;
create policy "friends can read private gift notes" on public.gift_notes
for select to authenticated using (
  exists (
    select 1 from public.wishes
    where wishes.id = gift_notes.wish_id
      and wishes.owner_id <> (select auth.uid())
      and private.are_friends((select auth.uid()), wishes.owner_id)
  )
);

drop policy if exists "friends can add private gift notes" on public.gift_notes;
create policy "friends can add private gift notes" on public.gift_notes
for insert to authenticated with check (
  author_id = (select auth.uid())
  and exists (
    select 1 from public.wishes
    where wishes.id = gift_notes.wish_id
      and wishes.owner_id <> (select auth.uid())
      and private.are_friends((select auth.uid()), wishes.owner_id)
  )
);

drop policy if exists "authors remove their private gift notes" on public.gift_notes;
create policy "authors remove their private gift notes" on public.gift_notes
for delete to authenticated using (author_id = (select auth.uid()));
