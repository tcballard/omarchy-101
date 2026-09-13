const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const engine = {};
vm.createContext(engine);
vm.runInContext(fs.readFileSync(path.join(__dirname, '../Lessons.js'), 'utf8').replace(/^\.pragma library\s*/, ''), engine);
const base = {available:true, app:'firefox', address:'a', monitor:'DP-1', workspace:1};
test('requires an action after arming, not an already focused terminal', () => {
 const terminal = {...base, app:'kitty'};
 assert.equal(engine.observed('terminal', terminal, terminal), false);
 assert.equal(engine.observed('terminal', base, {...base, app:'kitty', address:'b'}), true);
});
test('a second terminal window counts without changing app class', () => {
 assert.equal(engine.observed('terminal', {...base, app:'kitty'}, {...base, app:'kitty', address:'b'}), true);
});
test('unknown apps and lookalike terminal names do not complete a lesson', () => {
 for (const app of ['kitty-password-manager','not-alacritty','', '<b>kitty</b>'])
  assert.equal(engine.observed('terminal', base, {...base, app}), false);
});
test('only a workspace change on the same monitor counts', () => {
 assert.equal(engine.observed('workspace', base, {...base, workspace:2}), true);
 assert.equal(engine.observed('workspace', base, {...base, workspace:2, monitor:'DP-2'}), false);
 assert.equal(engine.observed('workspace', base, {...base, workspace:-99}), false);
 assert.equal(engine.observed('workspace', base, {...base, workspace:null}), false);
});
test('unavailable context never creates evidence', () => {
 assert.equal(engine.observed('workspace', {}, {...base,workspace:2}), false);
 assert.equal(engine.observed('terminal', base, {...base,app:'kitty',available:false}), false);
});
test('manual lessons cannot be automatically completed', () => {
 assert.equal(engine.observed('manual', base, {...base, workspace:2}), false);
});
test('context minimisation discards titles, text, credentials and bounds identifiers', () => {
 const c = engine.cleanContext({...base,app:'a'.repeat(2000),title:'secret',token:'secret',text:'secret'});
 assert.equal(c.app.length,160);
 assert.deepEqual(Object.keys(c).sort(), ['address','app','available','monitor','workspace']);
});
test('corrupt, oversized and future-version progress starts empty', () => {
 for (const input of ['broken', 'x'.repeat(5000), 'null', '{"version":2,"completed":{"super":"self"}}'])
  assert.equal(Object.keys(engine.restore(input)).length, 0);
});
test('restore accepts only known lessons and explicit evidence types', () => {
 const restored = engine.restore('{"version":1,"completed":{"super":"self","terminal":"observed","workspace":true,"evil":"observed"}}');
 assert.deepEqual(Object.keys(restored).sort(), ['super','terminal']);
 assert.equal(engine.restore(engine.encode(restored)).terminal,'observed');
});
test('lesson identifiers are unique and each has actionable copy and a known check', () => {
 assert.equal(new Set(engine.lessons.map(x=>x.id)).size,engine.lessons.length);
 for (const lesson of engine.lessons) {
  for (const key of ['title','explain','action','hint']) assert.ok(lesson[key].length > 10);
  assert.ok(['manual','terminal','workspace','browser','focus'].includes(lesson.check));
 }
});
test('suggestions distinguish unavailable context, terminal, browser and other apps', () => {
 assert.match(engine.suggestion({}), /unavailable/);
 assert.match(engine.suggestion({...base,app:'kitty'}), /terminal/);
 assert.match(engine.suggestion(base), /browser/);
 assert.match(engine.suggestion({...base,app:'other'}), /one small thing/);
});
test('browser observation requires a new recognised focus', () => {
 const browser = {...base, app:'firefox'};
 assert.equal(engine.observed('browser', browser, browser), false);
 assert.equal(engine.observed('browser', {...base, app:'kitty'}, browser), true);
 assert.equal(engine.observed('browser', base, {...base,app:'firefox-fake',address:'b'}), false);
});
test('focus exercise excludes workspace and monitor changes and missing addresses', () => {
 assert.equal(engine.observed('focus',base,{...base,address:'b'}),true);
 for (const change of [{workspace:2},{monitor:'DP-2'},{address:''},{available:false}])
  assert.equal(engine.observed('focus',base,{...base,address:'b',...change}),false);
});
test('resume skips completed lessons while retaining old lesson IDs', () => {
 assert.equal(engine.nextIncomplete({super:'self'}),1);
 const all={}; engine.lessons.forEach(x=>all[x.id]='self');
 assert.equal(engine.nextIncomplete(all),0);
 assert.equal(engine.restore('{"version":1,"completed":{"help":"self"}}').help,'self');
});
