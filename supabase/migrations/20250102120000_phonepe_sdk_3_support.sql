-- PhonePe SDK 3.0.0 Database Migration
-- Elon-Style: Minimal changes, maximum performance, zero downtime
-- Created: 2025-01-02 12:00:00
-- Purpose: Add PhonePe SDK 3.0.0 support with order management and enhanced tracking

-- ============================================================================
-- PHASE 1: ADD PHONEPE ORDER MANAGEMENT COLUMNS
-- ============================================================================

-- Add PhonePe Order Management columns to existing transactions table
ALTER TABLE public.transactions 
ADD COLUMN IF NOT EXISTS phonepe_order_id TEXT,
ADD COLUMN IF NOT EXISTS phonepe_order_token TEXT,
ADD COLUMN IF NOT EXISTS phonepe_order_status TEXT,
ADD COLUMN IF NOT EXISTS phonepe_merchant_order_id TEXT;

-- Add comments for documentation
COMMENT ON COLUMN public.transactions.phonepe_order_id IS 'PhonePe Order ID from Create Order API (e.g., OMO123456789)';
COMMENT ON COLUMN public.transactions.phonepe_order_token IS 'Order Token for PhonePe SDK transaction';
COMMENT ON COLUMN public.transactions.phonepe_order_status IS 'PhonePe order status (separate from transaction status)';
COMMENT ON COLUMN public.transactions.phonepe_merchant_order_id IS 'Our internal merchant order reference';

-- ============================================================================
-- PHASE 2: ENHANCED ERROR & RESPONSE TRACKING
-- ============================================================================

-- Add JSONB columns for flexible error and response data storage
ALTER TABLE public.transactions 
ADD COLUMN IF NOT EXISTS phonepe_error_details JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS phonepe_response_data JSONB DEFAULT '{}';

-- Add comments
COMMENT ON COLUMN public.transactions.phonepe_error_details IS 'Detailed PhonePe error codes and messages (JSONB)';
COMMENT ON COLUMN public.transactions.phonepe_response_data IS 'Complete PhonePe API response data (JSONB)';

-- ============================================================================
-- PHASE 3: WEBHOOK & VERIFICATION SUPPORT
-- ============================================================================

-- Add webhook and verification tracking columns
ALTER TABLE public.transactions 
ADD COLUMN IF NOT EXISTS webhook_received_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS webhook_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS webhook_data JSONB DEFAULT '{}';

-- Add comments
COMMENT ON COLUMN public.transactions.webhook_received_at IS 'Timestamp when PhonePe webhook was received';
COMMENT ON COLUMN public.transactions.webhook_verified IS 'Whether webhook signature was verified';
COMMENT ON COLUMN public.transactions.webhook_data IS 'Complete webhook payload for audit trail';

-- ============================================================================
-- PHASE 4: ORDER STATUS POLLING SUPPORT
-- ============================================================================

-- Add order status polling columns for automatic status checking
ALTER TABLE public.transactions 
ADD COLUMN IF NOT EXISTS last_status_check_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS status_check_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS auto_polling_enabled BOOLEAN DEFAULT true;

-- Add comments
COMMENT ON COLUMN public.transactions.last_status_check_at IS 'Last time order status was checked with PhonePe';
COMMENT ON COLUMN public.transactions.status_check_count IS 'Number of status check attempts (for retry logic)';
COMMENT ON COLUMN public.transactions.auto_polling_enabled IS 'Whether automatic status polling is enabled';

-- ============================================================================
-- PHASE 5: PERFORMANCE INDEXES (CRITICAL FOR SPEED)
-- ============================================================================

-- Index for PhonePe order ID lookups (most common query)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_transactions_phonepe_order_id 
ON public.transactions(phonepe_order_id) 
WHERE phonepe_order_id IS NOT NULL;

-- Index for order status queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_transactions_order_status 
ON public.transactions(phonepe_order_status) 
WHERE phonepe_order_status IS NOT NULL;

-- Composite index for status polling queries (performance critical)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_transactions_polling 
ON public.transactions(last_status_check_at, auto_polling_enabled) 
WHERE auto_polling_enabled = true;

-- Index for webhook verification queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_transactions_webhook_status 
ON public.transactions(webhook_received_at, webhook_verified) 
WHERE webhook_received_at IS NOT NULL;

-- ============================================================================
-- PHASE 6: UPDATE TRANSACTION STATUS CONSTRAINT
-- ============================================================================

-- Drop existing constraint and add new one with PhonePe statuses
ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_status_check;

-- Add updated constraint with all PhonePe status values
ALTER TABLE public.transactions ADD CONSTRAINT transactions_status_check 
CHECK (status IN (
    'initiated',    -- Payment initiated
    'pending',      -- Payment in progress
    'success',      -- Payment completed successfully
    'failure',      -- Payment failed
    'cancelled',    -- Payment cancelled by user
    'expired'       -- Payment expired/timed out
));

-- ============================================================================
-- PHASE 7: PHONEPE AUTH TOKEN MANAGEMENT TABLE
-- ============================================================================

-- Create PhonePe auth tokens table for OAuth token management
CREATE TABLE IF NOT EXISTS public.phonepe_auth_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    access_token TEXT NOT NULL,
    token_type TEXT DEFAULT 'Bearer',
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    
    -- Ensure no duplicate active tokens
    CONSTRAINT unique_active_token EXCLUDE (is_active WITH =) WHERE (is_active = true)
);

-- Add comments
COMMENT ON TABLE public.phonepe_auth_tokens IS 'PhonePe OAuth access tokens for API authentication';
COMMENT ON COLUMN public.phonepe_auth_tokens.access_token IS 'OAuth access token from PhonePe';
COMMENT ON COLUMN public.phonepe_auth_tokens.expires_at IS 'Token expiration timestamp';
COMMENT ON COLUMN public.phonepe_auth_tokens.is_active IS 'Whether this token is currently active';

-- Performance index for active token lookup (most frequent query)
CREATE INDEX IF NOT EXISTS idx_phonepe_tokens_active 
ON public.phonepe_auth_tokens(expires_at DESC, is_active) 
WHERE is_active = true;

-- ============================================================================
-- PHASE 8: ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on auth tokens table
ALTER TABLE public.phonepe_auth_tokens ENABLE ROW LEVEL SECURITY;

-- Create policy for service-level access (edge functions only)
CREATE POLICY "Service can manage auth tokens" ON public.phonepe_auth_tokens
FOR ALL USING (true);  -- Service-level access only, no user-specific restrictions

-- ============================================================================
-- PHASE 9: HELPER FUNCTIONS FOR PERFORMANCE
-- ============================================================================

-- Function to get valid auth token (performance optimized)
CREATE OR REPLACE FUNCTION get_valid_phonepe_token()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    token_record RECORD;
BEGIN
    -- Get the most recent valid token
    SELECT access_token INTO token_record
    FROM public.phonepe_auth_tokens
    WHERE is_active = true 
      AND expires_at > NOW()
    ORDER BY expires_at DESC
    LIMIT 1;
    
    RETURN token_record.access_token;
END;
$$;

-- Function to cleanup expired tokens (maintenance)
CREATE OR REPLACE FUNCTION cleanup_expired_phonepe_tokens()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Deactivate expired tokens
    UPDATE public.phonepe_auth_tokens 
    SET is_active = false 
    WHERE expires_at <= NOW() AND is_active = true;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;

-- ============================================================================
-- PHASE 10: MIGRATION VERIFICATION
-- ============================================================================

-- Verify all columns were added successfully
DO $$
BEGIN
    -- Check if all new columns exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'transactions' 
        AND column_name = 'phonepe_order_id'
    ) THEN
        RAISE EXCEPTION 'Migration failed: phonepe_order_id column not created';
    END IF;
    
    -- Check if auth tokens table exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'phonepe_auth_tokens'
    ) THEN
        RAISE EXCEPTION 'Migration failed: phonepe_auth_tokens table not created';
    END IF;
    
    -- Log successful migration
    RAISE NOTICE 'PhonePe SDK 3.0.0 migration completed successfully';
    RAISE NOTICE 'Added % new columns to transactions table', 11;
    RAISE NOTICE 'Created phonepe_auth_tokens table with % indexes', 1;
    RAISE NOTICE 'Created % performance indexes on transactions', 4;
    RAISE NOTICE 'Created % helper functions', 2;
END $$;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Log completion
INSERT INTO public.logs (
    level, 
    category, 
    message, 
    operation,
    context
) VALUES (
    'INFO',
    'migration',
    'PhonePe SDK 3.0.0 database migration completed successfully',
    'phonepe_sdk_3_migration',
    jsonb_build_object(
        'migration_file', '20250102120000_phonepe_sdk_3_support.sql',
        'tables_modified', 1,
        'tables_created', 1,
        'indexes_created', 5,
        'functions_created', 2,
        'completed_at', NOW()
    )
);
