const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const ctx={}; vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(__dirname,'../Articles.js'),'utf8').replace(/^\.pragma library\s*/,''),ctx);
test('only known lesson IDs can be summoned',()=>{
 const lessons=[{id:'super'},{id:'terminal'}];
 assert.equal(ctx.requestedLesson('{"lesson":"terminal"}',lessons),1);
 for(const payload of ['bad','null','[]','{"lesson":"unknown"}','{"lesson":"__proto__"}','x'.repeat(1025)]) assert.equal(ctx.requestedLesson(payload,lessons),-1);
});
test('payload URLs and completion flags do not affect lesson selection',()=>{
 assert.equal(ctx.requestedLesson('{"lesson":"super","url":"file:///etc/passwd","completed":true}',[{id:'super'}]),0);
});
test('unverified article titles stay hidden',()=>{
 assert.equal(ctx.forLesson('super'),null);
 assert.equal(ctx.forLesson('__proto__'),null);
});
test('article URLs reject commands, lookalike hosts, credentials and tracking queries',()=>{
 for(const url of ['file:///tmp/a','javascript:alert(1)','https://tcballard.substack.com.evil/p/a','https://tcballard.dev@evil/a','https://tcballard.substack.com/p/a?redirect=evil']) assert.equal(ctx.safeUrl(url),'');
 assert.equal(ctx.safeUrl('https://tcballard.substack.com/p/example'),'https://tcballard.substack.com/p/example');
});
test('a curated entry exposes exactly its title and checked URL',()=>{
 ctx.catalog.test={title:'Fixture only',url:'https://tcballard.substack.com/p/fixture'};
 assert.equal(ctx.forLesson('test').title,'Fixture only');
 delete ctx.catalog.test;
});
