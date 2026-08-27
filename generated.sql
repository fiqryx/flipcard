create table public.user_profiles (
   id          uuid not null default gen_random_uuid(),
   user_id     uuid unique,
   name        text not null,
   email       text not null,
   image_url   text,
   gender text,
   phone text,
   birth_date date,
   embergems integer default 0,
   total_decks integer default 0,
   total_cards integer default 0,
   shuffle boolean not null default true,
   created_at  timestamp with time zone default now(),
   updated_at  timestamp with time zone default now(),
   constraint user_profiles_pkey primary key ( id ),
   constraint user_profiles_user_id_fkey foreign key (user_id) references auth.users (id)
);

CREATE TABLE public.decks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  name text NOT NULL,
  description text,
  front_language text DEFAULT 'en-US'::text,
  back_language text DEFAULT 'en-US'::text,
  shuffle boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT decks_pkey PRIMARY KEY (id),
  CONSTRAINT decks_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

CREATE TABLE public.cards (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  deck_id uuid,
  front text NOT NULL,
  back text NOT NULL,
  description text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT cards_pkey PRIMARY KEY (id),
  CONSTRAINT cards_deck_id_fkey FOREIGN KEY (deck_id) REFERENCES public.decks(id)
);

CREATE TABLE public.quiz_results (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  deck_id uuid,
  deck_name character varying NOT NULL,
  total_cards integer NOT NULL CHECK (total_cards > 0),
  correct_answers integer NOT NULL DEFAULT 0 CHECK (correct_answers >= 0),
  incorrect_answers integer NOT NULL DEFAULT 0 CHECK (incorrect_answers >= 0),
  skipped_answers integer NOT NULL DEFAULT 0 CHECK (skipped_answers >= 0),
  accuracy_percentage numeric NOT NULL DEFAULT 0.00 CHECK (accuracy_percentage >= 0::numeric AND accuracy_percentage <= 100::numeric),
  time_spent_seconds integer NOT NULL DEFAULT 0 CHECK (time_spent_seconds >= 0),
  completed_at timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT quiz_results_pkey PRIMARY KEY (id),
  CONSTRAINT quiz_results_deck_id_fkey FOREIGN KEY (deck_id) REFERENCES public.decks(id),
  CONSTRAINT quiz_results_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

create or replace function increment_gems(user_id uuid, gems int)
returns bigint as $$
  update user_profiles
  set embergems = embergems + gems,
      updated_at = now()
  where user_id = $1
  returning embergems;
$$ language sql volatile;

-- ==============================================================================
-- 1. POLICIES UNTUK USER_PROFILES
-- ==============================================================================
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User bisa insert profil mereka sendiri" 
ON public.user_profiles FOR INSERT TO authenticated 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "User bisa lihat profil mereka sendiri" 
ON public.user_profiles FOR SELECT TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY "User bisa update profil mereka sendiri" 
ON public.user_profiles FOR UPDATE TO authenticated 
USING (auth.uid() = user_id);


-- ==============================================================================
-- 2. POLICIES UNTUK DECKS (Koleksi Kartu)
-- ==============================================================================
ALTER TABLE public.decks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User punya hak penuh atas deck mereka" 
ON public.decks FOR ALL TO authenticated 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);


-- ==============================================================================
-- 3. POLICIES UNTUK CARDS (Isi Kartu di dalam Deck)
-- Belajar dari relasi: User hanya bisa utak-atik kartu jika dia pemilik deck tersebut
-- ==============================================================================
ALTER TABLE public.cards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User hanya bisa akses kartu di dalam deck miliknya" 
ON public.cards FOR ALL TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM public.decks 
    WHERE public.decks.id = public.cards.deck_id 
    AND public.decks.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.decks 
    WHERE public.decks.id = public.cards.deck_id 
    AND public.decks.user_id = auth.uid()
  )
);


-- ==============================================================================
-- 4. POLICIES UNTUK QUIZ_RESULTS (Hasil Skor Kuis)
-- ==============================================================================
ALTER TABLE public.quiz_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User punya hak penuh atas hasil kuis mereka" 
ON public.quiz_results FOR ALL TO authenticated 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);