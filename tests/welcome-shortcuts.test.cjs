const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
function load(file) { const ctx={}; vm.createContext(ctx); vm.runInContext(fs.readFileSync(path.join(__dirname,'..',file),'utf8').replace(/^\.pragma library\s*/,''),ctx); return ctx; }
const welcome=load('Welcome.js'), shortcuts=load('Shortcuts.js');
test('welcome offered only without an existing decision',()=>{
 assert.equal(welcome.shouldOffer(''),true);
 for(const state of ['offered','started','dismissed','finished','future']) assert.equal(welcome.shouldOffer(state),false);
});
test('invalid actions cannot clear the welcome decision',()=>{
 assert.equal(welcome.acknowledge('dismissed',''), 'dismissed');
 assert.equal(welcome.acknowledge('dismissed','started'),'started');
});
const fixture='bindd\n\tmodmask: 68\n\tkey: SUPER + CTRL + Return\n\tdescription: Terminal\n\tdispatcher: __lua\n\targ: hidden\n\tsubmap: \n';
test('plain bindings resolve actual customised modifiers with Lua dispatchers',()=>{
 const result=shortcuts.parse(fixture);
 assert.equal(result.status,'ready');
 assert.equal(shortcuts.forLesson(result.bindings,'terminal')[0],'Super + Ctrl + RETURN — Terminal');
});
test('unrecognised descriptions cannot accidentally recommend destructive actions',()=>{
 const result=shortcuts.parse(fixture.replace('description: Terminal','description: Close all terminal windows'));
 assert.equal(shortcuts.forLesson(result.bindings,'terminal').length,0);
});
test('unresolved keycodes, submaps and unknown modifiers remain unresolved',()=>{
 for(const row of [{modmask:'64',key:'code:36'},{modmask:'64',key:'Return',submap:'resize'},{modmask:'999',key:'Return'},{modmask:'oops',key:'Return'}]) assert.equal(shortcuts.chord(row),'');
});
test('bounded parsing rejects oversized input and exposes empty state',()=>{
 assert.equal(shortcuts.parse('x'.repeat(131073)).status,'oversized');
 assert.equal(shortcuts.parse('').status,'unavailable');
});
test('workspace dispatch recognition does not match move-window operations',()=>{
 const rows=[{modmask:'64',key:'2',dispatcher:'workspace',arg:'2'},{modmask:'65',key:'3',dispatcher:'movetoworkspace',arg:'3'}];
 assert.equal(shortcuts.forLesson(rows,'workspace').length,1);
});
