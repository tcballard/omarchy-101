const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const os=require('node:os');
const {spawn}=require('node:child_process');
const qml=fs.readFileSync(path.join(__dirname,'../Shortcuts.qml'),'utf8');
const argv=JSON.parse(qml.match(/^    command: (\[.*\])$/m)[1]);
function alive(pid) {
 try { return !/\) Z /.test(fs.readFileSync('/proc/'+pid+'/stat','utf8')); }
 catch { return false; }
}
async function run(mode,cancel=false) {
 const dir=fs.mkdtempSync(path.join(os.tmpdir(),'101-process-'));
 const pidfile=path.join(dir,'pids');
 const child=spawn(argv[0],argv.slice(1),{env:{...process.env,PATH:path.join(__dirname,'fixtures')+':'+process.env.PATH,TEST_HYPRCTL_MODE:mode,TEST_HYPRCTL_PID:pidfile}});
 let output=''; child.stdout.on('data',chunk=>output+=chunk);
 let timedOut=false;
 const safety=setTimeout(()=>{
  timedOut=true;
  if(fs.existsSync(pidfile)) for(const pid of fs.readFileSync(pidfile,'utf8').trim().split('\n')) {try {process.kill(Number(pid),'SIGKILL')}catch{}}
  child.kill('SIGKILL');
 },7500);
 let cancellation;
 if(cancel) cancellation=setTimeout(()=>child.kill('SIGALRM'),250);
 try {
  await new Promise((resolve,reject)=>{child.on('error',reject);child.on('close',resolve)});
  assert.equal(timedOut,false,'production deadline must terminate without test cleanup');
  const pids=fs.existsSync(pidfile)?fs.readFileSync(pidfile,'utf8').trim().split('\n'):[];
  await new Promise(resolve=>setTimeout(resolve,100));
  assert.ok(pids.every(pid=>!alive(pid)), 'descendants must terminate');
  return output;
 } finally {
  clearTimeout(safety);clearTimeout(cancellation);
  if(fs.existsSync(pidfile)) for(const pid of fs.readFileSync(pidfile,'utf8').trim().split('\n')) {try {process.kill(Number(pid),'SIGKILL')}catch{}}
  fs.rmSync(dir,{recursive:true,force:true});
 }
}
test('production pipeline retains small binding output',async()=>{assert.match(await run('success'),/Terminal/)});
test('production pipeline bounds oversized output before collection',async()=>{assert.equal((await run('oversized')).length,131073)});
test('deadline kills a helper and descendant that ignore TERM',{timeout:10000},async()=>{await run('hang')});
test('closing via timeout alarm kills a helper and descendant that ignore TERM',{timeout:10000},async()=>{await run('hang',true)});
