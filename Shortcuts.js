.pragma library
function parse(text) {
  if (typeof text !== "string" || text.length > 131072) return {status:"oversized", bindings:[]};
  var rows = [], row = null;
  text.split("\n").forEach(function(line) {
    if (/^bind/.test(line)) { if (row) rows.push(row); row = {}; }
    else if (row) {
      var m = /^\t([a-z]+): (.*)$/.exec(line);
      if (m && ["key","modmask","description","dispatcher","arg","submap","keycode"].indexOf(m[1]) >= 0)
        row[m[1]] = m[1] === "arg" ? (/^[1-9]$/.test(m[2]) ? m[2] : "") : m[2].slice(0, 256);
    }
  });
  if (row) rows.push(row);
  return {status:rows.length ? "ready" : "unavailable", bindings:rows};
}
function chord(row) {
  if (row.submap && row.submap !== "default") return "";
  var mask = Number(row.modmask);
  if (!Number.isInteger(mask) || mask < 0 || (mask & ~77)) return "";
  var key = String(row.key || "").split(" + ").pop();
  // Raw keycodes and missing symbols need a keyboard-layout resolver, not a guess.
  if (!key || key.indexOf("code:") === 0 || !/^[A-Za-z0-9_]+$/.test(key)) return "";
  var parts=[];
  [[64,"Super"],[4,"Ctrl"],[8,"Alt"],[1,"Shift"]].forEach(function(pair) { if (mask & pair[0]) parts.push(pair[1]); });
  parts.push(key.toUpperCase()); return parts.join(" + ");
}
function forLesson(rows, id) {
  var names = {terminal:["Terminal"], browser:["Browser"], launcher:["Launch apps"], help:["Keybindings"], focus:["Focus left","Focus right","Focus up","Focus down"], workspace:["Switch to workspace 1","Switch to workspace 2","Switch to workspace 3"]};
  var accepted = names[id] || [], result=[];
  rows.forEach(function(row) {
    var matches = accepted.indexOf(row.description) >= 0;
    if (id === "workspace" && row.dispatcher === "workspace" && /^[1-9]$/.test(row.arg || "")) matches = true;
    if (!matches) return;
    var keys = chord(row);
    if (keys && result.length < 4) result.push(keys + " — " + (row.description || "Workspace " + row.arg));
  });
  return result;
}
