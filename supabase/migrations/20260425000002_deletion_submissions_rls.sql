-- Enable RLS
ALTER TABLE public.deletion_submissions ENABLE ROW LEVEL SECURITY;

-- Allow inserts (since the edge function uses ANON key, we need this for unauthenticated/authenticated users to submit requests)
CREATE POLICY "Anyone can insert deletion submissions" 
ON public.deletion_submissions 
FOR INSERT 
WITH CHECK (true);

-- Allow admins to view reports
CREATE POLICY "Admins can view deletion submissions" 
ON public.deletion_submissions 
FOR SELECT 
USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'reviewer'))
);

-- Allow admins to delete reports
CREATE POLICY "Admins can delete deletion submissions" 
ON public.deletion_submissions 
FOR DELETE 
USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'reviewer'))
);
