// KML-BROWSER-001: docs/acceptance/browser_runtime.md. Framework-only SDK
// substitutes reproduce the manually operated synthetic browser; not live LINE.
const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync(require('node:path').join(__dirname, '../../app/assets/javascripts/kamiliff.js'), 'utf8');

test('concurrent authentication, share outcomes, delivery and account conflict', async () => {
  let mode = 'success', inits = 0, closes = 0, requests = 0, fallbacks = 0;
  const sdk = {init: async () => { inits++; }, isLoggedIn: () => true, getIDToken: () => mode,
    isInClient: () => true, isApiAvailable: () => mode !== 'unsupported',
    shareTargetPicker: async () => mode === 'cancel' ? undefined : {status: 'success'},
    sendMessages: async () => { if (mode === 'fail') throw Error('delivery_failed'); }, closeWindow: () => { closes++; }};
  const context = {window: {liff: sdk}, location: new URL('https://example.test/entry'), URL, setTimeout, clearTimeout, AbortController,
    fetch: async (url, request) => {
      requests++;
      assert.equal(url, 'https://example.test/session'); assert.equal(request.redirect, 'error');
      assert.equal(request.credentials, 'same-origin'); assert.equal(request.headers['X-CSRF-Token'], 'synthetic-csrf');
      assert.equal(JSON.parse(request.body).id_token, mode);
      const error = {conflict: 'explicit_link_required', invalid: 'invalid_line_identity'}[mode];
      return {ok: !error, json: async () => error ? {error} : {status: 'verified'}};
    }};
  vm.runInNewContext(source, context);
  const client = context.window.Kamiliff.createSession({liffId: 'synthetic-app', endpointPath: '/entry', entryUrl: '/entry',
    sessionUrl: '/session', csrfToken: () => 'synthetic-csrf', fallback: async () => { fallbacks++; return {status: 'fallback'}; }});
  await Promise.all([client.authenticate(), client.authenticate()]);
  assert.equal(inits, 1); assert.equal(requests, 1);
  const message = [{type: 'text', text: 'synthetic'}];
  mode = 'cancel'; assert.equal((await client.shareMessages(message, {close: true})).status, 'cancelled'); assert.equal(closes, 0);
  mode = 'unsupported'; assert.equal((await client.shareMessages(message, {close: true})).status, 'unsupported'); assert.equal(closes, 0);
  mode = 'share'; assert.equal((await client.shareMessages(message, {close: true})).status, 'success'); assert.equal(closes, 1);
  mode = 'fail'; await assert.rejects(client.sendMessages(message, {close: true}), /delivery_failed/); assert.equal(closes, 1);
  mode = 'send'; assert.equal((await client.sendMessages(message, {close: true})).status, 'success'); assert.equal(closes, 2);
  mode = 'conflict'; await assert.rejects(client.authenticate(), {code: 'explicit_link_required'}); assert.equal(fallbacks, 0);
  mode = 'invalid'; assert.equal((await client.authenticate()).status, 'fallback'); assert.equal(fallbacks, 1);
  assert.equal(inits, 1);
});

test('external browser shares successfully without closing and cannot send to chat', async () => {
  let closes = 0, sends = 0;
  const context = {window: {liff: {init: async () => {}, isInClient: () => false, isApiAvailable: () => true,
    shareTargetPicker: async () => ({status: 'success'}), sendMessages: async () => {sends++;}, closeWindow: () => {closes++;}}},
    location: new URL('https://example.test/entry'), URL, setTimeout, clearTimeout};
  vm.runInNewContext(source, context);
  const client = context.window.Kamiliff.createSession({liffId: 'example', endpointPath: '/entry', entryUrl: '/entry', sessionUrl: '/session', csrfToken: () => 'csrf'});
  assert.equal((await client.shareMessages([{type: 'text', text: 'hi'}], {close: true})).status, 'success');
  assert.equal((await client.sendMessages([{type: 'text', text: 'hi'}], {close: true})).status, 'unsupported');
  assert.equal(await client.close(), false); assert.equal(closes, 0); assert.equal(sends, 0);
  await assert.rejects(client.sendMessages([]), {code: 'invalid_messages'});
});
