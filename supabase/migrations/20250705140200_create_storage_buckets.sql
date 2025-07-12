-- Create storage buckets for file uploads with proper RLS policies
-- Buckets for invoices, receipts, and vendor logos

-- 1. Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('invoices', 'invoices', false, 52428800, ARRAY['application/pdf', 'image/jpeg', 'image/png']),
    ('receipts', 'receipts', false, 52428800, ARRAY['application/pdf', 'image/jpeg', 'image/png']),
    ('vendor-logos', 'vendor-logos', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Drop existing storage policies
DROP POLICY IF EXISTS "Users can upload their own invoices" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own invoices" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own invoices" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own receipts" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own receipts" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own receipts" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload vendor logos" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view vendor logos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own vendor logos" ON storage.objects;

-- 3. Create RLS policies for invoices bucket
CREATE POLICY "Users can upload their own invoices"
ON storage.objects
FOR INSERT
WITH CHECK (
    bucket_id = 'invoices' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view their own invoices"
ON storage.objects
FOR SELECT
USING (
    bucket_id = 'invoices' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own invoices"
ON storage.objects
FOR DELETE
USING (
    bucket_id = 'invoices' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 4. Create RLS policies for receipts bucket
CREATE POLICY "Users can upload their own receipts"
ON storage.objects
FOR INSERT
WITH CHECK (
    bucket_id = 'receipts' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view their own receipts"
ON storage.objects
FOR SELECT
USING (
    bucket_id = 'receipts' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own receipts"
ON storage.objects
FOR DELETE
USING (
    bucket_id = 'receipts' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 5. Create RLS policies for vendor-logos bucket (public read, user-scoped write)
CREATE POLICY "Users can upload vendor logos"
ON storage.objects
FOR INSERT
WITH CHECK (
    bucket_id = 'vendor-logos' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Anyone can view vendor logos"
ON storage.objects
FOR SELECT
USING (bucket_id = 'vendor-logos');

CREATE POLICY "Users can delete their own vendor logos"
ON storage.objects
FOR DELETE
USING (
    bucket_id = 'vendor-logos' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);
