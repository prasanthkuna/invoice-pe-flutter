-- Add 'draft' status to invoices table to match Flutter InvoiceStatus enum
-- This ensures perfect alignment between database constraints and Flutter models

-- Drop the existing constraint
ALTER TABLE public.invoices DROP CONSTRAINT IF EXISTS invoices_status_check;

-- Add the new constraint with 'draft' status included
ALTER TABLE public.invoices
ADD CONSTRAINT invoices_status_check
CHECK (status IN ('draft', 'pending', 'paid', 'overdue', 'cancelled'));

-- Update the default status to 'draft' for new invoices
ALTER TABLE public.invoices
ALTER COLUMN status SET DEFAULT 'draft';

-- Create user_cards table for PhonePe masked card storage
CREATE TABLE IF NOT EXISTS public.user_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    card_token TEXT NOT NULL, -- PhonePe masked card token
    card_last_four VARCHAR(4) NOT NULL, -- Last 4 digits for display
    card_type TEXT NOT NULL, -- VISA, MASTERCARD, RUPAY, etc.
    card_network TEXT, -- Additional network info
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure only one default card per user
    CONSTRAINT unique_default_card_per_user EXCLUDE (user_id WITH =) WHERE (is_default = true)
);

-- Create indexes for user_cards
CREATE INDEX idx_user_cards_user_id ON public.user_cards(user_id);
CREATE INDEX idx_user_cards_is_default ON public.user_cards(user_id, is_default) WHERE is_default = true;
CREATE INDEX idx_user_cards_is_active ON public.user_cards(user_id, is_active) WHERE is_active = true;

-- Enable RLS on user_cards
ALTER TABLE public.user_cards ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for user_cards
CREATE POLICY "Users can manage their own cards"
ON public.user_cards
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Grant permissions
GRANT ALL ON public.user_cards TO authenticated;

-- Add updated_at trigger for user_cards
CREATE TRIGGER trigger_user_cards_updated_at
    BEFORE UPDATE ON public.user_cards
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();