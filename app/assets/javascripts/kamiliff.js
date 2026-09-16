/* Kamiliff: one SDK initialization per document; the host owns verified sessions. */
'use strict';
(() => {
  const pendingNavigation = () => new Promise(() => {});
  const failure = (code, message = code) => Object.assign(new Error(message), {code});
  let loading, initialized, initializedId, active;

  function bounded(promise, timeout) {
    let timer;
    return Promise.race([promise, new Promise((_, reject) => {
      timer = setTimeout(() => reject(failure('liff_timeout')), timeout);
    })]).finally(() => clearTimeout(timer));
  }

  function loadSDK(timeout) {
    if (window.liff) return Promise.resolve(window.liff);
    if (!loading) {
      loading = new Promise((resolve, reject) => {
        const script = document.createElement('script');
        const timer = setTimeout(() => finish(failure('sdk_load_timeout')), timeout);
        function finish(error) {
          clearTimeout(timer); script.onload = script.onerror = null;
          if (error) { script.remove(); reject(error); }
          else if (!window.liff) reject(failure('sdk_unavailable'));
          else resolve(window.liff);
        }
        script.src = 'https://static.line-scdn.net/liff/edge/2/sdk.js';
        script.onload = () => finish();
        script.onerror = () => finish(failure('sdk_load_failed'));
        document.head.append(script);
      }).catch(error => { loading = undefined; throw error; });
    }
    return loading;
  }

  function localURL(value) {
    if (typeof value !== 'string' || !value.startsWith('/') || value.startsWith('//')) throw failure('invalid_local_url');
    const url = new URL(value, location.origin);
    if (url.origin !== location.origin || url.username || url.password || url.hash) throw failure('invalid_local_url');
    return url;
  }
  function under(path, endpoint) {
    return path === endpoint || path.startsWith(endpoint.replace(/\/$/, '') + '/');
  }
  function messages(value) {
    if (!Array.isArray(value) || !value.length || value.length > 5 ||
        value.some(item => !item || typeof item !== 'object' || Array.isArray(item) || typeof item.type !== 'string')) {
      throw failure('invalid_messages');
    }
    return value;
  }

  function createSession(options) {
    const {liffId, endpointPath, entryUrl, sessionUrl, csrfToken, onVerified, fallback, webAuthenticated = false, timeout = 10000} = options;
    if (!/^[A-Za-z0-9_-]{1,128}$/.test(liffId || '') || !Number.isFinite(timeout) || timeout <= 0) throw failure('invalid_configuration');
    if (typeof csrfToken !== 'function' || [onVerified, fallback].some(value => value !== undefined && typeof value !== 'function')) throw failure('invalid_configuration');
    const endpoint = localURL(endpointPath);
    const entry = localURL(entryUrl);
    const session = localURL(sessionUrl);
    if (endpoint.search || !under(entry.pathname, endpoint.pathname)) throw failure('invalid_entry_url');
    let authenticating;

    async function ready() {
      if (!under(location.pathname, endpoint.pathname)) {
        // Never rewrite LINE's primary/secondary redirect before the SDK handles it.
        const current = new URL(location.href);
        if ([...current.searchParams.keys()].some(key => /^(liff[.]|access_token$|id_token$|code$|state$|liffClientId$|liffRedirectUri$)/.test(key)) || current.hash) {
          throw failure('invalid_liff_endpoint');
        }
        location.replace(entry.href);
        return pendingNavigation();
      }
      const sdk = await loadSDK(timeout);
      if (initializedId && initializedId !== liffId) throw failure('different_liff_app');
      if (!initialized) {
        initializedId = liffId;
        initialized = Promise.resolve().then(() => sdk.init({liffId})).then(() => sdk).catch(error => {
          initialized = undefined; initializedId = undefined; throw error;
        });
      }
      // A timeout does not start another overlapping SDK init. Later retries await
      // the same initialization; no late callback triggers login or verification.
      return bounded(initialized, timeout);
    }

    async function recover(error) {
      if (typeof fallback === 'function') return fallback(error);
      throw error;
    }
    async function authenticateOnce() {
      let sdk;
      try { sdk = await ready(); }
      catch (error) {
        if (['invalid_liff_endpoint', 'different_liff_app'].includes(error.code)) throw error;
        return recover(error);
      }
      if (!sdk.isLoggedIn()) {
        if (webAuthenticated) return {status: 'web_session'};
        try { sdk.login(); } catch (error) { return recover(error); }
        return pendingNavigation();
      }
      const token = sdk.getIDToken();
      if (!token) return recover(failure('missing_id_token'));
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), timeout);
      let response, data;
      try {
        response = await fetch(session.href, {
          method: 'POST', credentials: 'same-origin', cache: 'no-store', redirect: 'error', signal: controller.signal,
          headers: {'Content-Type': 'application/json', 'X-CSRF-Token': csrfToken?.() || ''},
          body: JSON.stringify({id_token: token})
        });
        data = await response.json();
      } finally { clearTimeout(timer); }
      if (!response.ok) {
        const error = failure(data.error || 'identity_verification_failed');
        if (error.code === 'invalid_line_identity') return recover(error);
        throw error;
      }
      if (onVerified) await onVerified(data);
      return data;
    }
    const client = Object.freeze({
      ready,
      authenticate() {
        authenticating ||= authenticateOnce().finally(() => { authenticating = undefined; });
        return authenticating;
      },
      async sendMessages(value, {close = false} = {}) {
        messages(value);
        const sdk = await ready();
        if (!sdk.isInClient()) return {status: 'unsupported'};
        await sdk.sendMessages(value);
        if (close) sdk.closeWindow();
        return {status: 'success'};
      },
      async shareMessages(value, {close = false} = {}) {
        messages(value);
        const sdk = await ready();
        if (!sdk.isApiAvailable('shareTargetPicker')) return {status: 'unsupported'};
        const result = await sdk.shareTargetPicker(value, {isMultiple: true});
        if (result?.status !== 'success') return {status: 'cancelled'};
        if (close && sdk.isInClient()) sdk.closeWindow();
        return {status: 'success'};
      },
      async close() {
        const sdk = await ready();
        if (!sdk.isInClient()) return false;
        sdk.closeWindow(); return true;
      }
    });
    active = client;
    return client;
  }
  function current() {
    if (!active) throw failure('session_not_configured');
    return active;
  }
  window.Kamiliff = Object.freeze({
    createSession,
    sendMessages: (value, options) => current().sendMessages(value, options),
    shareMessages: (value, options) => current().shareMessages(value, options),
    sendText: (text, options) => current().sendMessages([{type: 'text', text: String(text)}], options),
    close: () => current().close()
  });
})();
