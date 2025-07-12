-- Fix OTP authentication and logging system issues
-- This migration addresses:
-- 1. "Signups not allowed for otp" error
-- 2. "DB_SAVE_FAILED: AuthRetryableFetchException" error
-- 3. Proper RLS policies for all tables
-- 4. Logging system permissions

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tables already exist from previous migrations, just ensure they have correct structure

-- Create logs table for centralized logging
CREATE TABLE IF NOT EXISTS public.logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    level TEXT NOT NULL CHECK (level IN ('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL')),
    category TEXT NOT NULL,
    message TEXT NOT NULL,
    operation TEXT,
    context_data JSONB,
    stack_trace TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS logs_user_id_idx ON public.logs(user_id);
CREATE INDEX IF NOT EXISTS logs_level_idx ON public.logs(level);
CREATE INDEX IF NOT EXISTS logs_category_idx ON public.logs(category);
CREATE INDEX IF NOT EXISTS logs_operation_idx ON public.logs(operation);
CREATE INDEX IF NOT EXISTS logs_created_at_idx ON public.logs(created_at);

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can manage their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can manage their own vendors" ON public.vendors;
DROP POLICY IF EXISTS "Users can manage their own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can manage their own invoices" ON public.invoices;
DROP POLICY IF EXISTS "Users can view their own logs" ON public.logs;
DROP POLICY IF EXISTS "Users can insert their own logs" ON public.logs;

-- Create comprehensive RLS policies (using correct column names)
CREATE POLICY "Users can manage their own profile" ON public.profiles
    FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users can manage their own vendors" ON public.vendors
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own transactions" ON public.transactions
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own invoices" ON public.invoices
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own logs" ON public.logs
    FOR SELECT USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can insert their own logs" ON public.logs
    FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.vendors TO authenticated;
GRANT ALL ON public.transactions TO authenticated;
GRANT ALL ON public.invoices TO authenticated;
GRANT SELECT, INSERT ON public.logs TO authenticated;

-- Create or replace the profile creation trigger function
CREATE OR REPLACE FUNCTION public.create_profile_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, phone)
    VALUES (NEW.id, NEW.phone)
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS create_profile_trigger ON auth.users;

-- Create trigger for automatic profile creation
CREATE TRIGGER create_profile_trigger
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.create_profile_for_new_user();

-- Create log cleanup function
CREATE OR REPLACE FUNCTION public.clean_old_logs()
RETURNS void AS $$
BEGIN
    DELETE FROM public.logs 
    WHERE created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing view if it exists
DROP VIEW IF EXISTS public.log_summary;

-- Create log summary view
CREATE VIEW public.log_summary AS
SELECT
    level,
    category,
    COUNT(*) as count,
    MAX(created_at) as latest_occurrence
FROM public.logs
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY level, category
ORDER BY count DESC;
