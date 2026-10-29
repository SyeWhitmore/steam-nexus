const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const ts = require('typescript');
const Module = require('node:module');
const compiled = ts.transpileModule(fs.readFileSync('frontend/core/lifecycle.ts', 'utf8'), {
  compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 },
}).outputText;
const loaded = new Module('lifecycle');
loaded._compile(compiled, 'lifecycle.cjs');
const { FeatureRegistry } = loaded.exports;
const makeFeature = (id, events) => ({
  id, name: id, description: id,
  async enable() { events.push(`${id}:enable`); },
  async disable() { events.push(`${id}:disable`); },
});

test('serializes rapid changes, avoids duplicates, cleans up and rejects work after disposal', async () => {
  const events = [];
  const registry = new FeatureRegistry([makeFeature('drive', events)]);
  await Promise.all([registry.setEnabled('drive', true), registry.setEnabled('drive', true),
    registry.setEnabled('drive', false), registry.setEnabled('drive', true)]);
  await registry.dispose();
  assert.deepEqual(events, ['drive:enable', 'drive:disable', 'drive:enable', 'drive:disable']);
  await assert.rejects(registry.setEnabled('drive', true), /stopped/);
});

test('failed enable is cleaned up and does not poison the queue', async () => {
  const events = [];
  const bad = makeFeature('bad', events);
  bad.enable = async () => { throw new Error('enable failed'); };
  const registry = new FeatureRegistry([bad, makeFeature('good', events)]);
  await assert.rejects(registry.setEnabled('bad', true), /enable failed/);
  await registry.setEnabled('good', true);
  await registry.dispose();
  assert.deepEqual(events, ['bad:disable', 'good:enable', 'good:disable']);
});

test('disposal cleans other features even when one fails', async () => {
  const events = [];
  const bad = makeFeature('bad', events);
  bad.disable = async () => { throw new Error('cleanup failed'); };
  const registry = new FeatureRegistry([bad, makeFeature('good', events)]);
  await registry.setEnabled('bad', true);
  await registry.setEnabled('good', true);
  await assert.rejects(registry.dispose(), /Failed to disable/);
  assert.ok(events.includes('good:disable'));
});

test('rejects duplicate IDs and unknown features', async () => {
  assert.throws(() => new FeatureRegistry([makeFeature('same', []), makeFeature('same', [])]), /Duplicate/);
  await assert.rejects(new FeatureRegistry([]).setEnabled('missing', true), /Unknown/);
});
