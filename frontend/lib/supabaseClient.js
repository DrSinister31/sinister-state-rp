// lib/supabaseClient.js
import { createClient } from '@supabase/supabase-js';

let supabaseInstance = null;

export const getSupabase = () => {
  if (!supabaseInstance) {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

    if (!url || !key) {
      // During build on Vercel, this will still be called, but we can safely return a dummy client
      // or throw a clear error with instructions.
      if (typeof window === 'undefined') {
        // On the server (build time), return a dummy client that won't break the build
        // but will log a warning.
        console.warn('Supabase env vars not available during build – using dummy client.');
        supabaseInstance = createClient('https://dummy-url.supabase.co', 'dummy-key');
        return supabaseInstance;
      }
      throw new Error('Supabase environment variables are not set. Please ensure NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY are defined.');
    }

    supabaseInstance = createClient(url, key);
  }
  return supabaseInstance;
};

// For backward compatibility, you can also export a proxy that forwards calls to the lazy client.
// But it's better to update imports to use getSupabase().