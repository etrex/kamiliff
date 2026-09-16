const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync(require('node:path').join(__dirname, '../../app/assets/javascripts/kamiliff.js'), 'utf8');

test('old public link navigates to canonical entry without initializing SDK', async () => {
  let replaced, inits = 0;
  const location = new URL('https://example.test/ranking'); location.replace = value => {replaced = value;};
  const context = {window: {liff: {init: async () => {inits++;}}}, location, URL, setTimeout, clearTimeout};
  vm.runInNewContext(source, context);
  const client = context.window.Kamiliff.createSession({liffId: 'example', endpointPath: '/entry', entryUrl: '/entry?page=ranking&group=3', sessionUrl: '/session', csrfToken: () => 'csrf'});
  void client.ready(); await new Promise(resolve => setImmediate(resolve));
  assert.equal(replaced, 'https://example.test/entry?page=ranking&group=3'); assert.equal(inits, 0);
});

test('SDK return outside endpoint fails closed and never changes URL', async () => {
  for (const query of ['?liff.state=%3Fpage%3Dranking', '?code=opaque&state=opaque', '#access_token=opaque']) {
    let replaced = false;
    const location = new URL('https://example.test/wrong' + query); location.replace = () => {replaced = true;};
    const context = {window: {}, location, URL, setTimeout, clearTimeout}; vm.runInNewContext(source, context);
    const client = context.window.Kamiliff.createSession({liffId: 'example', endpointPath: '/entry', entryUrl: '/entry', sessionUrl: '/session', csrfToken: () => 'csrf'});
    await assert.rejects(client.authenticate(), {code: 'invalid_liff_endpoint'}); assert.equal(replaced, false);
  }
});

test('initial redirect completes init before login and preserves canonical return parameters', async () => {
  let complete, calls = [];
  const context = {window: {liff: {init: () => {calls.push('init');return new Promise(resolve => {complete = resolve;});},
    isLoggedIn: () => false, login: (options) => {assert.equal(options.redirectUri, 'https://example.test/entry?page=ranking&group=3');calls.push('login');}}},
    location: new URL('https://example.test/entry?liff.state=%3Fpage%3Dranking'), URL, setTimeout, clearTimeout};
  vm.runInNewContext(source, context);
  const client = context.window.Kamiliff.createSession({liffId: 'example', endpointPath: '/entry', entryUrl: '/entry?page=ranking&group=3', sessionUrl: '/session', csrfToken: () => 'csrf'});
  void client.authenticate(); await new Promise(resolve => setImmediate(resolve)); assert.deepEqual(calls, ['init']);
  complete(); await new Promise(resolve => setImmediate(resolve)); assert.deepEqual(calls, ['init', 'login']);
});

test('timed-out init has no late login and retry shares the existing init', async () => {
  let complete, inits = 0, logins = 0, recovered = 0;
  const context = {window: {liff: {init: () => {inits++;return new Promise(resolve => {complete = resolve;});},
    isLoggedIn: () => false, login: () => {logins++;}}}, location: new URL('https://example.test/entry'), URL, setTimeout, clearTimeout};
  vm.runInNewContext(source, context);
  const client = context.window.Kamiliff.createSession({liffId: 'example', endpointPath: '/entry', entryUrl: '/entry', sessionUrl: '/session', csrfToken: () => 'csrf', timeout: 10,
    fallback: async error => {assert.equal(error.code, 'liff_timeout');recovered++;}});
  await client.authenticate(); assert.equal(recovered, 1);
  complete(); await new Promise(resolve => setImmediate(resolve)); assert.equal(logins, 0);
  void client.authenticate(); await new Promise(resolve => setImmediate(resolve)); assert.equal(inits, 1); assert.equal(logins, 1);
});

test('unsafe or missing configuration rejected before any token transmission', () => {
  const context = {window: {}, location: new URL('https://example.test/entry'), URL, setTimeout, clearTimeout}; vm.runInNewContext(source, context);
  const config = {liffId: 'example', endpointPath: '/entry', entryUrl: '/entry', sessionUrl: '/session', csrfToken: () => 'csrf'};
  for (const override of [{entryUrl: '//evil.test/'}, {sessionUrl: 'https://evil.test/session'}, {entryUrl: '/wrong'}, {endpointPath: undefined}, {sessionUrl: undefined}, {csrfToken: 'csrf'}, {fallback: true}, {timeout: 0}]) {
    assert.throws(() => context.window.Kamiliff.createSession({...config, ...override}));
  }
});
