-- Remediation for the live fleet-core cloud project.
-- Migration 0003_rehearse was applied before table namespacing, so its
-- organizations/organization_members tables were created under the generic
-- names (and the organizations table is shared with auth-service). This
-- migration creates Rehearse's own namespaced copies without disturbing
-- auth-service's organizations table.

CREATE TABLE IF NOT EXISTS public.rehearse_organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar(200) NOT NULL,
  slug varchar(200) NOT NULL,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS rehearse_organizations_slug_key
  ON public.rehearse_organizations (slug);

CREATE TABLE IF NOT EXISTS public.rehearse_organization_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES public.rehearse_organizations (id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.users (id) ON DELETE CASCADE,
  role public.org_member_role NOT NULL DEFAULT 'recruiter',
  joined_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS rehearse_organization_members_org_user_key
  ON public.rehearse_organization_members (organization_id, user_id);
CREATE INDEX IF NOT EXISTS rehearse_organization_members_user_idx
  ON public.rehearse_organization_members (user_id);

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['rehearse_organizations', 'rehearse_organization_members'] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS rehearse_all ON public.%I', t);
    EXECUTE format(
      'CREATE POLICY rehearse_all ON public.%I FOR ALL TO anon, authenticated USING (true) WITH CHECK (true)',
      t
    );
  END LOOP;
END $$;
