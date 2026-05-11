-- ================================================================
-- SUPABASE KEEPALIVE SETUP
-- Run this in any Supabase project's SQL Editor to prevent auto-pausing.
-- ================================================================

-- 1. Create the keepalive table
CREATE TABLE IF NOT EXISTS public._keepalive (
    id          serial PRIMARY KEY,
    project     text NOT NULL DEFAULT 'default',
    last_ping   timestamp with time zone DEFAULT now(),
    ping_count  bigint DEFAULT 0,
    notes       text
);

-- 2. Insert the initial row for this project
-- REPLACE 'your-project-name' with your actual project identifier
INSERT INTO public._keepalive (project, last_ping, ping_count, notes)
VALUES (
    'your-project-name',          
    now(),
    0,
    'Keepalive row - do not delete'
)
ON CONFLICT DO NOTHING;

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public._keepalive ENABLE ROW LEVEL SECURITY;

-- 4. Allow anon role to SELECT (read) the table
-- This is what the external cron job will use to ping the database
CREATE POLICY "keepalive_select" ON public._keepalive
    FOR SELECT TO anon USING (true);

-- 5. Verify setup
SELECT * FROM public._keepalive;
