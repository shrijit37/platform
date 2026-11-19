/**
 * Shared identity verification for the fleet's Supabase Auth -> Clerk migration.
 *
 * Copy this file into an app's src/lib/ (the platform repo is not published as a
 * package yet). During transition it accepts BOTH Clerk and legacy Supabase
 * GoTrue tokens, so apps can migrate independently without a flag day.
 *
 * Required env (set as GitHub secrets, never committed):
 *   CLERK_SECRET_KEY, CLERK_API_URL, CLERK_JWKS_URL,
 *   SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY
 */

import { verifyToken } from '@clerk/backend';
import { createClient } from '@supabase/supabase-js';

export type FleetIdentity = {
  id: string;
  email: string;
  name: string;
  source: 'clerk' | 'supabase';
};

let legacyClient: ReturnType<typeof createClient> | null = null;

function getLegacyClient() {
  if (!legacyClient) {
    legacyClient = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_PUBLISHABLE_KEY!,
      { auth: { persistSession: false, autoRefreshToken: false } },
    );
  }
  return legacyClient;
}

/**
 * Verify a bearer token. Clerk is tried first, then legacy Supabase.
 * Returns null when neither verifier accepts the token.
 */
export async function verifyEitherToken(token: string): Promise<FleetIdentity | null> {
  if (!token) return null;

  try {
    const claims = await verifyToken(token, {
      secretKey: process.env.CLERK_SECRET_KEY!,
      // RS256 verification also works from the public JWKS at CLERK_JWKS_URL.
      // On Cloudflare Workers use that instead of the secret key.
      apiUrl: process.env.CLERK_API_URL,
    });
    return {
      id: claims.sub,
      email: (claims.email as string) ?? '',
      name: (claims.name as string) ?? '',
      source: 'clerk',
    };
  } catch {
    // Not a Clerk token (or Clerk verify failed) — try the legacy provider.
  }

  const { data, error } = await getLegacyClient().auth.getUser(token);
  if (error || !data.user) return null;
  return {
    id: data.user.id,
    email: data.user.email ?? '',
    name: (data.user.user_metadata?.name as string) ?? '',
    source: 'supabase',
  };
}

/** Extract a bearer token from an Authorization header or query string. */
export function tokenFromRequest(header: string | null, queryToken?: string): string | null {
  if (header?.startsWith('Bearer ')) return header.slice(7).trim();
  return queryToken ?? null;
}

/**
 * Cutover helper: once all clients send Clerk session tokens, flip the
 * preference below and remove the legacy branch entirely.
 */
export const PREFERRED_SOURCE: 'clerk' | 'either' = 'either';
