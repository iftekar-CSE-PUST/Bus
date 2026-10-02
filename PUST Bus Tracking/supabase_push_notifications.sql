-- =======================================================================
-- PUST Bus Tracking - Real Apple Push Notification (APNs) Server Setup
-- =======================================================================
-- Delivers real native push notifications when the app is completely 
-- CLOSED / OFF / KILLED (exact same architecture as Messenger & WhatsApp).

-- 1. Create table to store iPhone APNs Device Push Tokens
CREATE TABLE IF NOT EXISTS public.device_push_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token TEXT UNIQUE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    platform TEXT DEFAULT 'ios',
    subscribed_buses INT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.device_push_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow token sync" ON public.device_push_tokens;
CREATE POLICY "Allow token sync" ON public.device_push_tokens
    FOR ALL USING (true) WITH CHECK (true);

-- 2. Index for instant token lookup by subscribed bus
CREATE INDEX IF NOT EXISTS idx_device_push_tokens_buses 
    ON public.device_push_tokens USING GIN (subscribed_buses);

COMMENT ON TABLE public.device_push_tokens IS 'Stores real iOS APNs push tokens for offline background delivery';

-- =======================================================================
-- Option A: Setup via Supabase Dashboard UI (Recommended & Easiest):
-- -----------------------------------------------------------------------
-- 1. Go to Supabase Dashboard -> Database -> Webhooks.
-- 2. Click "Create Webhook".
-- 3. Name: send-chat-push-webhook
-- 4. Table: public.chat_messages
-- 5. Events: Insert
-- 6. Webhook Type: Supabase Edge Functions
-- 7. Edge Function: send-chat-push
-- 8. Method: POST
-- 9. Click "Save Webhook".
-- =======================================================================

-- =======================================================================
-- Option B: Setup via SQL Trigger (Using pg_net):
-- -----------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.tr_notify_subscribers_on_new_chat()
RETURNS TRIGGER AS $$
DECLARE
    function_url TEXT;
    service_role_key TEXT;
    request_id BIGINT;
BEGIN
    -- Replace with your Supabase Project URL and Service Role Key:
    -- function_url := 'https://<YOUR-PROJECT-REF>.supabase.co/functions/v1/send-chat-push';
    -- service_role_key := '<YOUR-SERVICE-ROLE-KEY>';

    -- Asynchronously invoke the Edge Function
    /*
    SELECT net.http_post(
        url := function_url,
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || service_role_key
        ),
        body := jsonb_build_object(
            'record', jsonb_build_object(
                'id', NEW.id,
                'bus_n', NEW.bus_n,
                'user_name', NEW.user_name,
                'student_roll', NEW.student_roll,
                'body', NEW.body,
                'created_at', NEW.created_at
            )
        )
    ) INTO request_id;
    */

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_push_on_chat_insert ON public.chat_messages;
CREATE TRIGGER tr_push_on_chat_insert
    AFTER INSERT ON public.chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION public.tr_notify_subscribers_on_new_chat();
