-- Table to store user FCM tokens for push notifications
CREATE TABLE IF NOT EXISTS public.user_devices (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    fcm_token     TEXT NOT NULL,
    platform      TEXT CHECK (platform IN ('ios', 'android', 'web')),
    last_seen_at  TIMESTAMPTZ DEFAULT now(),
    created_at    TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, fcm_token) -- Support for targeted upserts
);

-- Index for fast lookup by token
CREATE UNIQUE INDEX idx_ud_token ON public.user_devices(fcm_token);

-- RLS
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own devices" ON public.user_devices
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins view all devices" ON public.user_devices
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'reviewer'))
    );
