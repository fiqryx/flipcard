/// application name
const appName = 'FlipCard';

/// build version
const appVersion = '1.1.4';

/// supabase url
const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');

/// supabase anon key
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);
