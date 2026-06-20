import React, { useState, useEffect, useRef } from 'react';
import { supabase } from '../supabaseClient';
import { deriveKey, generateRecoveryKey } from '../cryptoHelper';
import { useBiometric } from '../hooks/useBiometric';
import { Capacitor } from '@capacitor/core';

export default function Login({ onAuthSuccess, initialMessage, clearInitialMessage }) {
  // Modes: 'login' or 'register'
  const [authMode, setAuthMode] = useState('login');
  const { isSupported, isEnrolled, saveCredentials, deleteCredentials, authenticate } = useBiometric();

  useEffect(() => {
    if (initialMessage) {
      showCustomAlert('Security Notification', initialMessage);
      if (clearInitialMessage) clearInitialMessage();
    }
  }, [initialMessage]);
  
  // Login fields
  const [emailOrUsername, setEmailOrUsername] = useState('');
  const [password, setPassword] = useState('');
  const [rememberMe, setRememberMe] = useState(false);
  const [obscurePassword, setObscurePassword] = useState(true);

  // Registration fields
  const [regEmail, setRegEmail] = useState('');
  const [regUsername, setRegUsername] = useState('');
  const [regPassword, setRegPassword] = useState('');
  const [regConfirmPassword, setRegConfirmPassword] = useState('');
  const [obscureRegPassword, setObscureRegPassword] = useState(true);

  // States
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [shakeCard, setShakeCard] = useState(false);

  // Custom alert modal state
  const [showAlert, setShowAlert] = useState(false);
  const [alertTitle, setAlertTitle] = useState('');
  const [alertContent, setAlertContent] = useState('');
  const [alertCallback, setAlertCallback] = useState(null);

  // Biometric overlay state
  const [showBiometric, setShowBiometric] = useState(false);
  const [bioTitle, setBioTitle] = useState('Biometric Authentication');
  const [bioDesc, setBioDesc] = useState('Place registered finger on sensor to decrypt local database keys.');
  const [bioStatus, setBioStatus] = useState('default'); // 'default', 'scanning', 'success'
  const bioTimeoutRef = useRef(null);

  // Parallax cursor spotlight
  const cardRef = useRef(null);
  const spotlightRef = useRef(null);

  useEffect(() => {
    const handleMouseMove = (e) => {
      if (!cardRef.current || !spotlightRef.current) return;
      const rect = cardRef.current.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      spotlightRef.current.style.left = `${x}px`;
      spotlightRef.current.style.top = `${y}px`;
    };

    const cardEl = cardRef.current;
    if (cardEl) {
      cardEl.addEventListener('mousemove', handleMouseMove);
    }
    return () => {
      if (cardEl) {
        cardEl.removeEventListener('mousemove', handleMouseMove);
      }
      if (bioTimeoutRef.current) clearTimeout(bioTimeoutRef.current);
    };
  }, []);

  // Pre-load credentials if rememberMe was active
  useEffect(() => {
    const rememberedUser = localStorage.getItem('diaro_remembered_email');
    if (rememberedUser) {
      setEmailOrUsername(rememberedUser);
      setRememberMe(true);
    }
  }, []);

  const triggerShake = () => {
    setShakeCard(true);
    setTimeout(() => setShakeCard(false), 400);
  };

  const showCustomAlert = (title, message, callback = null) => {
    setAlertTitle(title);
    setAlertContent(message);
    setAlertCallback(() => callback);
    setShowAlert(true);
  };

  const handleLoginSubmit = async (e) => {
    e.preventDefault();
    setErrorMsg('');

    if (!emailOrUsername.trim()) {
      setErrorMsg('Email or Username is required to fetch decryption keys.');
      triggerShake();
      return;
    }
    if (!password) {
      setErrorMsg('Master Password is required to decrypt entries.');
      triggerShake();
      return;
    }

    setIsLoading(true);

    try {
      // 1. Resolve email address if username was entered
      let loginEmail = emailOrUsername.trim();
      if (!loginEmail.includes('@')) {
        loginEmail = `${loginEmail.toLowerCase()}@diaro.io`;
      }

      // 2. Authenticate with Supabase Auth
      const { data, error } = await supabase.auth.signInWithPassword({
        email: loginEmail,
        password: password,
      });

      if (error) {
        // Fallback: If it's the mock/placeholder project, let's allow bypass for testing!
        if (supabase.supabaseUrl && supabase.supabaseUrl.includes('your-project')) {
          console.warn('Supabase using placeholder. Falling back to offline sandbox session.');
          const derivedVaultKey = deriveKey(password);
          onAuthSuccess({
            user: { email: loginEmail, user_metadata: { username: emailOrUsername } },
            vaultKey: derivedVaultKey,
            isDecoy: false,
          });
          return;
        }
        setErrorMsg('Decryption failed. Incorrect master password or invalid credentials.');
        triggerShake();
        setIsLoading(false);
        return;
      }

      // 3. Cache master password in LocalStorage and Keystore/Keychain if rememberMe is enabled
      if (rememberMe) {
        localStorage.setItem('diaro_remembered_email', emailOrUsername);
        if (!Capacitor.isNativePlatform()) {
          localStorage.setItem('diaro_cached_password', password);
        }
        await saveCredentials(loginEmail, password);
      } else {
        localStorage.removeItem('diaro_remembered_email');
        localStorage.removeItem('diaro_cached_password');
        await deleteCredentials();
      }

      // 4. Derive symmetric vault key from master password
      const derivedVaultKey = deriveKey(password);

      // 5. Notify parent app of success
      onAuthSuccess({
        user: data.user,
        vaultKey: derivedVaultKey,
        isDecoy: false,
      });

    } catch (err) {
      console.error(err);
      setErrorMsg('An unexpected security error occurred during key exchange.');
      triggerShake();
    } finally {
      setIsLoading(false);
    }
  };

  const handleRegisterSubmit = async (e) => {
    e.preventDefault();
    setErrorMsg('');

    const passwordRegex = /^(?=.*[A-Z])(?=.*\d).{8,}$/;
    if (!regEmail.includes('@')) {
      showCustomAlert('Invalid Inputs', 'Please provide a valid email format.');
      return;
    }
    if (regUsername.trim().length < 3) {
      showCustomAlert('Invalid Inputs', 'Username must be at least 3 characters.');
      return;
    }
    if (!passwordRegex.test(regPassword)) {
      showCustomAlert('Weak Password', 'Master Password must be at least 8 characters, contain one uppercase letter and one digit.');
      return;
    }
    if (regPassword !== regConfirmPassword) {
      showCustomAlert('Validation Error', 'Confirmation password does not match Master Password.');
      return;
    }

    setIsLoading(true);

    try {
      // 1. Sign up user in Supabase
      const { data, error } = await supabase.auth.signUp({
        email: regEmail,
        password: regPassword,
        options: {
          data: {
            username: regUsername,
          }
        }
      });

      if (error) {
        if (supabase.supabaseUrl && supabase.supabaseUrl.includes('your-project')) {
          console.warn('Supabase using placeholder. Falling back to offline sandbox registration.');
          const recoveryKey = generateRecoveryKey();
          showCustomAlert(
            'Sandbox Vault Initialized', 
            `[Offline Sandbox Mode]\nVault created successfully!\n\nYour SECURE RECOVERY KEY is:\n${recoveryKey}\n\nSave this key immediately. It is required to recover your vault if you forget your master password.`,
            () => {
              const derivedVaultKey = deriveKey(regPassword);
              onAuthSuccess({
                user: { email: regEmail, user_metadata: { username: regUsername } },
                vaultKey: derivedVaultKey,
                isDecoy: false,
              });
            }
          );
          return;
        }
        showCustomAlert('Registration Failed', error.message);
        setIsLoading(false);
        return;
      }

      // 2. Generate a secure recovery key for display
      const recoveryKey = generateRecoveryKey();
      showCustomAlert(
        'Vault Initialized Successfully',
        `Your SECURE RECOVERY KEY is:\n${recoveryKey}\n\nSave this key immediately. It is required to recover your vault if you forget your master password.`,
        () => {
          const derivedVaultKey = deriveKey(regPassword);
          onAuthSuccess({
            user: data.user,
            vaultKey: derivedVaultKey,
            isDecoy: false,
          });
        }
      );

    } catch (err) {
      console.error(err);
      showCustomAlert('Encryption Error', 'Could not initialize cryptographic modules.');
    } finally {
      setIsLoading(false);
    }
  };

  const triggerBiometric = async () => {
    setShowBiometric(true);
    setBioStatus('scanning');
    setBioTitle('Scanning Biometric Key...');
    setBioDesc('Hold finger on the sensor. Validating secure biometric signature.');

    try {
      const creds = await authenticate();
      if (creds && creds.username && creds.password) {
        setBioStatus('success');
        setBioTitle('Access Key Verified');
        setBioDesc('Initializing secure database connections. Decrypting diaries...');

        setTimeout(async () => {
          setShowBiometric(false);
          let loginEmail = creds.username.includes('@') ? creds.username : `${creds.username.toLowerCase()}@diaro.io`;
          
          const { data, error } = await supabase.auth.signInWithPassword({
            email: loginEmail,
            password: creds.password,
          });

          if (error) {
            if (supabase.supabaseUrl && supabase.supabaseUrl.includes('your-project')) {
              console.warn('Supabase using placeholder. Falling back to offline sandbox session.');
              const derivedVaultKey = deriveKey(creds.password);
              onAuthSuccess({
                user: { email: loginEmail, user_metadata: { username: creds.username } },
                vaultKey: derivedVaultKey,
                isDecoy: false,
              });
              return;
            }
            setErrorMsg('Biometric authentication succeeded, but database sync failed.');
            triggerShake();
            return;
          }

          const key = deriveKey(creds.password);
          onAuthSuccess({
            user: data?.user || { email: loginEmail },
            vaultKey: key,
            isDecoy: false,
          });
        }, 1000);
      } else {
        setShowBiometric(false);
        setBioStatus('default');
      }
    } catch (err) {
      console.error(err);
      setShowBiometric(false);
      setBioStatus('default');
      setErrorMsg('Biometric authentication failed.');
      triggerShake();
    }
  };

  const cancelBiometric = () => {
    if (bioTimeoutRef.current) clearTimeout(bioTimeoutRef.current);
    setShowBiometric(false);
    setBioStatus('default');
  };

  const handleForgotPassword = (e) => {
    e.preventDefault();
    showCustomAlert('Password Recovery', 'To recover access, enter the 14-character Recovery Key (format: YN-XXXX-XXXX-XXXX) on the device application screen.');
  };

  return (
    <div className="min-h-screen flex flex-col justify-between overflow-hidden relative bg-bgDark text-blue-100 font-sans">
      
      {/* Background Ambient Glow Objects */}
      <div className="fixed inset-0 z-0 pointer-events-none">
        <div className="absolute top-[-10%] left-[-10%] w-[60%] h-[60%] ambient-glow-1 rounded-full"></div>
        <div className="absolute bottom-[-10%] right-[-10%] w-[60%] h-[60%] ambient-glow-2 rounded-full"></div>
        <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.003)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.003)_1px,transparent_1px)] bg-[size:30px_30px] opacity-25"></div>
      </div>

      <div className="h-8"></div>

      {/* Main Workspace Container */}
      <main className="relative z-10 w-full max-w-[480px] mx-auto px-4 my-auto">
        
        {/* Diaro Header Branding */}
        <header className="text-center mb-8 flex flex-col items-center">
          <div className="w-16 h-16 rounded-2xl bg-cyberBlue-950/60 border border-cyberBlue-500/25 flex items-center justify-center mb-4 shadow-[0_0_20px_rgba(59,130,246,0.15)]">
            <span className="material-symbols-outlined text-[36px] text-cyberBlue-400 font-light" style={{ fontVariationSettings: "'FILL' 0" }}>lock</span>
          </div>
          <h1 className="text-4xl font-bold tracking-tight text-white mb-2 select-none">
            <span className="shimmer-text">Diaro</span>
          </h1>
          <p className="text-sm font-mono text-cyberBlue-400 uppercase tracking-[0.25em] text-xs">
            Your Thoughts. Your Privacy. 🔐
          </p>
        </header>

        {/* Authentication Container Panel */}
        <div 
          ref={cardRef} 
          className={`glass-card rounded-3xl p-8 md:p-10 shadow-2xl relative overflow-hidden transition-all duration-500 ${shakeCard ? 'shake' : ''}`}
          id="auth-panel"
        >
          {/* Dynamic cursor hover spotlight */}
          <div ref={spotlightRef} className="interactive-glow" id="hover-spotlight"></div>
          
          {/* LOGIN CONTAINER */}
          {authMode === 'login' ? (
            <div className="relative z-10" id="login-container">
              <div className="flex flex-col mb-6">
                <h2 className="text-2xl font-semibold text-white tracking-wide">Unlock Vault</h2>
                <p className="text-sm text-blue-300/60 mt-1">Provide credential keys to decrypt your digital journal.</p>
              </div>

              {/* Error Notice Box */}
              {errorMsg && (
                <div className="mb-6 p-4 rounded-xl border border-red-500/30 bg-red-950/20 text-red-400 text-sm flex gap-3 items-start animate-fade-in" role="alert">
                  <span className="material-symbols-outlined text-[18px] shrink-0 mt-0.5" style={{ fontVariationSettings: "'FILL' 1" }}>error</span>
                  <span>{errorMsg}</span>
                </div>
              )}

              <form className="space-y-5" onSubmit={handleLoginSubmit} noValidate>
                {/* Email / Username field */}
                <div className="space-y-2">
                  <label className="block text-xs font-mono text-cyberBlue-300 uppercase tracking-widest" htmlFor="email-or-username">Email / Username</label>
                  <div className="relative flex items-center">
                    <span className="material-symbols-outlined absolute left-4 text-[20px] text-blue-400/50" style={{ fontVariationSettings: "'FILL' 0" }}>alternate_email</span>
                    <input 
                      className="w-full pl-12 pr-4 py-3.5 rounded-xl text-white font-sans placeholder:text-blue-200/20 cyber-input outline-none focus:ring-0 text-sm" 
                      id="email-or-username" 
                      placeholder="e.g. secure@diaro.io" 
                      required 
                      tabIndex="1"
                      type="text"
                      value={emailOrUsername}
                      onChange={(e) => setEmailOrUsername(e.target.value)}
                    />
                  </div>
                </div>

                {/* Password field */}
                <div className="space-y-2">
                  <div className="flex justify-between items-center">
                    <label className="block text-xs font-mono text-cyberBlue-300 uppercase tracking-widest" htmlFor="password">Master Password</label>
                    <a 
                      className="text-xs font-mono text-cyberBlue-400 hover:text-white hover:underline transition-colors focus:outline-none focus:ring-1 focus:ring-cyberBlue-500 rounded px-1" 
                      href="#" 
                      onClick={handleForgotPassword}
                      tabIndex="5"
                    >
                      Forgot password?
                    </a>
                  </div>
                  <div className="relative flex items-center">
                    <span className="material-symbols-outlined absolute left-4 text-[20px] text-blue-400/50" style={{ fontVariationSettings: "'FILL' 1" }}>lock</span>
                    <input 
                      className="w-full pl-12 pr-12 py-3.5 rounded-xl text-white font-sans placeholder:text-blue-200/20 cyber-input outline-none focus:ring-0 text-sm" 
                      id="password" 
                      placeholder="Enter Decryption Key" 
                      required 
                      tabIndex="2"
                      type={obscurePassword ? 'password' : 'text'}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                    />
                    <button 
                      className="absolute right-4 text-blue-400/50 hover:text-white transition-colors focus:outline-none" 
                      onClick={() => setObscurePassword(!obscurePassword)}
                      tabIndex="3"
                      type="button"
                    >
                      <span className="material-symbols-outlined text-[20px]">
                        {obscurePassword ? 'visibility' : 'visibility_off'}
                      </span>
                    </button>
                  </div>
                </div>

                {/* Remember me option */}
                <div className="flex items-center">
                  <input 
                    className="w-4.5 h-4.5 rounded bg-slate-900 border-blue-400/20 text-cyberBlue-600 focus:ring-0 focus:ring-offset-0 cursor-pointer" 
                    id="remember-me" 
                    tabIndex="4"
                    type="checkbox"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                  />
                  <label className="ml-2.5 text-xs text-blue-200/50 select-none cursor-pointer hover:text-blue-100 transition-colors" htmlFor="remember-me">
                    Keep keys cached on this device (Remember Me)
                  </label>
                </div>

                {/* Action Buttons */}
                <div className="space-y-3 pt-2">
                  <button 
                    disabled={isLoading}
                    className="w-full py-4 bg-cyberBlue-600 hover:bg-cyberBlue-500 text-white font-semibold text-xs uppercase tracking-[0.15em] rounded-xl hover:shadow-[0_0_20px_rgba(59,130,246,0.3)] active:scale-[0.98] transition-all duration-200 flex items-center justify-center gap-2 focus:outline-none focus:ring-2 focus:ring-cyberBlue-500 disabled:opacity-50" 
                    id="login-submit-btn"
                    tabIndex="6"
                    type="submit"
                  >
                    {isLoading ? (
                      <div className="flex items-center gap-2">
                        <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        <span>Decrypting Vault...</span>
                      </div>
                    ) : (
                      <>
                        <span>Unlock Vault</span>
                        <span className="material-symbols-outlined text-[16px]" style={{ fontVariationSettings: "'FILL' 1" }}>key</span>
                      </>
                    )}
                  </button>

                  {/* Biometrics Button */}
                  {isEnrolled && (
                    <button 
                      className="w-full py-3.5 bg-cyberBlue-950/40 hover:bg-cyberBlue-900/40 border border-cyberBlue-500/20 text-cyberBlue-400 hover:text-cyberBlue-300 font-semibold text-xs uppercase tracking-[0.15em] rounded-xl active:scale-[0.98] transition-all duration-200 flex items-center justify-center gap-2.5 focus:outline-none focus:ring-2 focus:ring-cyberBlue-500" 
                      id="biometric-btn"
                      onClick={triggerBiometric}
                      tabIndex="7"
                      type="button"
                    >
                      <span className="material-symbols-outlined text-[18px]">fingerprint</span>
                      <span>Verify Biometrics</span>
                    </button>
                  )}
                </div>
              </form>

              {/* Create Account Link */}
              <div className="mt-8 text-center border-t border-slate-800/60 pt-6">
                <p className="text-xs text-blue-200/40">
                  First time setting up your secure diary?
                  <a 
                    className="text-cyberBlue-400 hover:text-white font-semibold ml-1.5 focus:outline-none hover:underline" 
                    href="#" 
                    onClick={(e) => { e.preventDefault(); setAuthMode('register'); }}
                    tabIndex="8"
                  >
                    Initialize New Account
                  </a>
                </p>
              </div>
            </div>
          ) : (
            /* REGISTER CONTAINER */
            <div className="relative z-10" id="register-container">
              <div className="flex flex-col mb-6">
                <h2 className="text-2xl font-semibold text-white tracking-wide">Initialize Vault</h2>
                <p className="text-sm text-blue-300/60 mt-1">Deploy keys to protect your encrypted diary.</p>
              </div>

              <form className="space-y-4" onSubmit={handleRegisterSubmit} noValidate>
                {/* Email field */}
                <div className="space-y-1">
                  <label className="block text-xs font-mono text-cyberBlue-300 uppercase tracking-widest" htmlFor="reg-email">Email Address</label>
                  <div className="relative flex items-center">
                    <span className="material-symbols-outlined absolute left-4 text-[20px] text-blue-400/50">mail</span>
                    <input 
                      className="w-full pl-12 pr-4 py-3 rounded-xl text-white font-sans placeholder:text-blue-200/20 cyber-input outline-none focus:ring-0 text-sm" 
                      id="reg-email" 
                      placeholder="secure@diaro.io" 
                      required 
                      type="email"
                      value={regEmail}
                      onChange={(e) => setRegEmail(e.target.value)}
                    />
                  </div>
                </div>

                {/* Username field */}
                <div className="space-y-1">
                  <label className="block text-xs font-mono text-cyberBlue-300 uppercase tracking-widest" htmlFor="reg-username">Username</label>
                  <div className="relative flex items-center">
                    <span className="material-symbols-outlined absolute left-4 text-[20px] text-blue-400/50">person</span>
                    <input 
                      className="w-full pl-12 pr-4 py-3 rounded-xl text-white font-sans placeholder:text-blue-200/20 cyber-input outline-none focus:ring-0 text-sm" 
                      id="reg-username" 
                      placeholder="secure_user" 
                      required 
                      type="text"
                      value={regUsername}
                      onChange={(e) => setRegUsername(e.target.value)}
                    />
                  </div>
                </div>

                {/* Master Password field */}
                <div className="space-y-1">
                  <label className="block text-xs font-mono text-cyberBlue-300 uppercase tracking-widest" htmlFor="reg-password">Master Password</label>
                  <div className="relative flex items-center">
                    <span className="material-symbols-outlined absolute left-4 text-[20px] text-blue-400/50" style={{ fontVariationSettings: "'FILL' 1" }}>lock</span>
                    <input 
                      className="w-full pl-12 pr-12 py-3 rounded-xl text-white font-sans placeholder:text-blue-200/20 cyber-input outline-none focus:ring-0 text-sm" 
                      id="reg-password" 
                      placeholder="Min 8 chars, 1 uppercase, 1 digit" 
                      required 
                      type={obscureRegPassword ? 'password' : 'text'}
                      value={regPassword}
                      onChange={(e) => setRegPassword(e.target.value)}
                    />
                    <button 
                      className="absolute right-4 text-blue-400/50 hover:text-white transition-colors focus:outline-none" 
                      onClick={() => setObscureRegPassword(!obscureRegPassword)}
                      type="button"
                    >
                      <span className="material-symbols-outlined text-[20px]">
                        {obscureRegPassword ? 'visibility' : 'visibility_off'}
                      </span>
                    </button>
                  </div>
                </div>

                {/* Confirm Password field */}
                <div className="space-y-1">
                  <label className="block text-xs font-mono text-cyberBlue-300 uppercase tracking-widest" htmlFor="reg-confirm-password">Confirm Password</label>
                  <div className="relative flex items-center">
                    <span className="material-symbols-outlined absolute left-4 text-[20px] text-blue-400/50" style={{ fontVariationSettings: "'FILL' 1" }}>lock_reset</span>
                    <input 
                      className="w-full pl-12 pr-4 py-3 rounded-xl text-white font-sans placeholder:text-blue-200/20 cyber-input outline-none focus:ring-0 text-sm" 
                      id="reg-confirm-password" 
                      placeholder="Verify Decryption Key" 
                      required 
                      type="password"
                      value={regConfirmPassword}
                      onChange={(e) => setRegConfirmPassword(e.target.value)}
                    />
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="pt-3">
                  <button 
                    disabled={isLoading}
                    className="w-full py-4 bg-cyberBlue-600 hover:bg-cyberBlue-500 text-white font-semibold text-xs uppercase tracking-[0.15em] rounded-xl hover:shadow-[0_0_20px_rgba(59,130,246,0.3)] active:scale-[0.98] transition-all duration-200 flex items-center justify-center gap-2 focus:outline-none focus:ring-2 focus:ring-cyberBlue-500 disabled:opacity-50" 
                    id="register-submit-btn"
                    type="submit"
                  >
                    {isLoading ? (
                      <div className="flex items-center gap-2">
                        <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        <span>Generating RSA Keys...</span>
                      </div>
                    ) : (
                      <>
                        <span>Register & Generate Keys</span>
                        <span className="material-symbols-outlined text-[16px]">vpn_key</span>
                      </>
                    )}
                  </button>
                </div>
              </form>

              {/* Back to Login Link */}
              <div className="mt-6 text-center border-t border-slate-800/60 pt-4">
                <p className="text-xs text-blue-200/40">
                  Already have initialized keys?
                  <a 
                    className="text-cyberBlue-400 hover:text-white font-semibold ml-1.5 focus:outline-none hover:underline" 
                    href="#" 
                    onClick={(e) => { e.preventDefault(); setAuthMode('login'); }}
                  >
                    Unlock Existing Vault
                  </a>
                </p>
              </div>
            </div>
          )}
          
          {/* Biometric Overlay Scanner Screen */}
          {showBiometric && (
            <div className="absolute inset-0 bg-slate-950/95 z-30 flex flex-col items-center justify-center p-8 transition-opacity duration-300" id="biometric-overlay">
              <div className="relative w-32 h-32 flex items-center justify-center rounded-full border border-cyberBlue-500/20 bg-cyberBlue-950/20 mb-6">
                <span 
                  className={`material-symbols-outlined text-[72px] ${bioStatus === 'success' ? 'text-emerald-400' : 'text-cyberBlue-400'} ${bioStatus === 'scanning' ? 'animate-pulse' : ''}`}
                  id="fingerprint-icon"
                >
                  fingerprint
                </span>
                {/* Scanner Laser Beam Line */}
                {bioStatus === 'scanning' && (
                  <div className="scanline absolute w-[80%] left-[10%]" id="overlay-scanline"></div>
                )}
              </div>
              
              <h3 className="text-lg font-semibold text-white mb-2" id="bio-title">{bioTitle}</h3>
              <p className="text-sm text-blue-300/60 text-center max-w-[280px]" id="bio-desc">{bioDesc}</p>
              
              <button 
                className="mt-8 px-5 py-2 bg-slate-800 hover:bg-slate-700 text-blue-200 text-xs font-mono uppercase tracking-widest rounded-lg focus:outline-none border border-slate-700 transition-colors" 
                onClick={cancelBiometric}
              >
                Cancel Verification
              </button>
            </div>
          )}
        </div>

        {/* Security and Encryption Trust Footer */}
        <footer className="mt-8 flex items-center justify-center gap-2 text-blue-200/30 select-none">
          <span className="material-symbols-outlined text-[14px]">encrypted</span>
          <span className="font-mono text-[10px] uppercase tracking-widest">End-to-End Local AES-256 Architecture</span>
        </footer>
      </main>

      {/* CUSTOM ALERT DIALOG MODAL */}
      {showAlert && (
        <div className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-4">
          <div className="glass-card rounded-3xl p-6 w-full max-w-md space-y-4 text-center border border-cyberBlue-500/30 shadow-2xl relative overflow-hidden">
            <h3 className="text-lg font-semibold text-white tracking-wide">{alertTitle}</h3>
            <p className="text-sm text-blue-300/70 whitespace-pre-line leading-relaxed font-sans">{alertContent}</p>
            <button 
              type="button" 
              onClick={() => {
                setShowAlert(false);
                if (alertCallback) alertCallback();
              }}
              className="w-full py-3 bg-cyberBlue-600 hover:bg-cyberBlue-500 text-white text-xs font-semibold uppercase tracking-wider rounded-xl transition-all duration-200 hover:shadow-[0_0_15px_rgba(59,130,246,0.3)] active:scale-[0.98]"
            >
              OK
            </button>
          </div>
        </div>
      )}

      <div className="h-8"></div>
    </div>
  );
}
