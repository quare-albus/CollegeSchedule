// CollegeSchedule Supabase client configuration.
// Browser-safe project credentials. The legacy anon JWT is used only for
// Edge Function invocation because the function currently verifies JWTs.
window.COLLEGE_SCHEDULE_SUPABASE = Object.freeze({
  url: 'https://igdzpwckufwctxixqpjj.supabase.co',
  publishableKey: 'sb_publishable_eK7UjEqLisjPizOgz_D6Ag_inQnXH5s',
  functionKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlnZHpwd2NrdWZ3Y3R4aXhxcGpqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkxNDE1OTIsImV4cCI6MjEwNDcxNzU5Mn0.J_NSocXtUbBq0Pk8APFfx1iG6Ubqbd-tIMTKc0X1WtI'
});

(() => {
  const supabaseGlobal = window.supabase;
  if (!supabaseGlobal?.createClient) return;
  const originalCreateClient = supabaseGlobal.createClient;
  supabaseGlobal.createClient = (url, key, options) => {
    const client = originalCreateClient(url, key, options);
    const auth = client.auth;
    const originalGetSession = auth.getSession.bind(auth);
    const originalGetUser = auth.getUser.bind(auth);
    const withTimeout = (promise, label) => Promise.race([
      promise,
      new Promise(resolve => setTimeout(() => resolve({
        data: label === 'session' ? { session: null } : { user: null },
        error: new Error('Authentication request timed out. Please refresh and try again.')
      }), 10000))
    ]);
    auth.getSession = (...args) => withTimeout(originalGetSession(...args), 'session');
    auth.getUser = (...args) => withTimeout(originalGetUser(...args), 'user');

    const originalSignInWithOAuth = auth.signInWithOAuth.bind(auth);
    auth.signInWithOAuth = (oauthOptions = {}) => {
      const authOptions = oauthOptions.options || {};
      return originalSignInWithOAuth({
        ...oauthOptions,
        options: {
          ...authOptions,
          redirectTo: new URL('auth.html', window.location.href).href
        }
      });
    };
    return client;
  };
})();
