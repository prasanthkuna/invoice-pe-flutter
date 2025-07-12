-- Enable Row Level Security (RLS) and create policies for multi-tenant data isolation
-- Simple, effective policies that ensure users can only access their own data

-- 1. Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

-- 2. Drop any existing policies (clean slate)
DROP POLICY IF EXISTS "Users can manage their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can manage their own vendors" ON public.vendors;
DROP POLICY IF EXISTS "Users can manage their own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can manage their own invoices" ON public.invoices;

-- 3. Create profiles policies (profiles.id = auth.uid())
CREATE POLICY "Users can manage their own profile"
ON public.profiles
FOR ALL
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 4. Create vendors policies (vendors.user_id = auth.uid())
CREATE POLICY "Users can manage their own vendors"
ON public.vendors
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 5. Create transactions policies (transactions.user_id = auth.uid())
CREATE POLICY "Users can manage their own transactions"
ON public.transactions
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 6. Create invoices policies (invoices.user_id = auth.uid())
CREATE POLICY "Users can manage their own invoices"
ON public.invoices
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 7. Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.vendors TO authenticated;
GRANT ALL ON public.transactions TO authenticated;
GRANT ALL ON public.invoices TO authenticated;

-- 8. Grant permissions to anon users for auth operations
GRANT USAGE ON SCHEMA public TO anon;
GRANT INSERT ON public.profiles TO anon;

-- 9. Ensure sequence permissions for UUID generation
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon;
