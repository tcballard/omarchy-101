.pragma library

var lessons = [
  { id: "super", title: "What's so Super about a key?", explain: "Super is the Windows-logo key on most keyboards, or Command on an Apple keyboard. In Omarchy it is your starting point for moving around the desktop.", action: "Find your Super key. You will use it in the next two exercises.", hint: "Look beside Alt or the space bar. A remapped keyboard may put Super somewhere else.", check: "manual" },
  { id: "terminal", title: "Meet your terminal", explain: "A terminal is an app where you talk to your computer through commands. Opening one does not change anything by itself.", action: "Open your terminal using your configured shortcut or application launcher. Leave it focused for a moment.", hint: "Look up Terminal in your application launcher. Use your own key bindings if you have changed the defaults.", check: "terminal" },
  { id: "workspace", title: "Give yourself another desk", explain: "A workspace is another place to arrange windows. Switching workspaces leaves your apps running where you put them.", action: "Switch to another numbered workspace on this monitor. Then come back when you are ready.", hint: "Use the workspace buttons in your bar, or your configured workspace shortcut. 101 stays here while you practise.", check: "workspace" },
  { id: "launcher", title: "Find an app without hunting", explain: "The application launcher lets you find an app by name. You do not have to remember which menu it lives in.", action: "Open your application launcher. Search for an app you recognise, then press Escape to leave without opening it.", hint: "Use the Launch apps shortcut shown below if it is available. This exercise is self-confirmed because 101 cannot inspect the launcher search.", check: "manual" },
  { id: "browser", title: "Open a window onto the web", explain: "Your browser is an ordinary desktop app. You can give it its own workspace and return to it whenever you need it.", action: "Open or focus your browser. Leave it focused for a moment so 101 can recognise it.", hint: "Use the Browser shortcut if shown, or find your browser in the launcher. No particular website needs to be opened.", check: "browser" },
  { id: "focus", title: "Move between your windows", explain: "Focus decides which window receives your typing. Changing focus is different from closing or moving a window.", action: "Have two app windows open on the same numbered workspace. Focus the other one using a shortcut or a click.", hint: "Click inside another app window. If you want keyboard practice, use a resolved Focus shortcut below. 101 verifies the focus change, not which key you pressed.", check: "focus" },
  { id: "help", title: "You don't have to remember everything", explain: "Learning Omarchy is a series of small habits. You can repeat any lesson, ask for a hint, or come back another day.", action: "Find the keyboard shortcut reference through your Omarchy menu. Choose one shortcut you want to practise next.", hint: "Explore the menu's help entries. This step is self-confirmed: 101 cannot see which help page you read.", check: "manual" }
];
function cleanContext(value) {
  value = value || {};
  return { available: value.available === true,
    app: typeof value.app === "string" ? value.app.slice(0, 160).toLowerCase() : "",
    address: typeof value.address === "string" ? value.address.slice(0, 80) : "",
    monitor: typeof value.monitor === "string" ? value.monitor.slice(0, 160) : "",
    workspace: typeof value.workspace === "number" && isFinite(value.workspace) ? value.workspace : null };
}
function isTerminal(app) {
  return /^(alacritty|kitty|foot|footclient|ghostty|com\.mitchellh\.ghostty|org\.wezfurlong\.wezterm|wezterm|org\.gnome\.terminal|org\.gnome\.ptyxis|konsole)$/.test(app);
}
function isBrowser(app) { return /^(firefox|org\.mozilla\.firefox|chromium|google-chrome|brave-browser|zen|app\.zen_browser\.zen)$/.test(app); }
function observed(kind, baseline, current) {
  var b = cleanContext(baseline), c = cleanContext(current);
  if (!b.available || !c.available) return false;
  if (kind === "browser") return isBrowser(c.app) && !!c.address && (c.address !== b.address || c.app !== b.app);
  if (kind === "focus") return !!b.address && !!c.address && b.address !== c.address && b.monitor === c.monitor && b.workspace > 0 && b.workspace === c.workspace;
  if (kind === "terminal") return isTerminal(c.app) && (c.address !== b.address || c.app !== b.app);
  if (kind === "workspace") return c.monitor === b.monitor && b.workspace > 0 && c.workspace > 0 && b.workspace !== c.workspace;
  return false;
}
function suggestion(context) {
  var c = cleanContext(context);
  if (!c.available) return "Desktop context is unavailable. You can still read lessons and confirm exercises yourself.";
  if (isTerminal(c.app)) return "You are in a terminal. Try the terminal lesson; there is nothing to paste or execute.";
  if (/^(firefox|chromium|google-chrome|brave-browser|zen|app.zen_browser.zen)$/.test(c.app)) return "You are in a browser. Workspaces can give browsing and other tasks their own space.";
  return "Try one small thing: open an app, then give it a workspace of its own.";
}
function restore(encoded) {
  var result = {};
  if (typeof encoded !== "string" || encoded.length > 4096) return result;
  try {
    var value = JSON.parse(encoded);
    if (!value || value.version !== 1 || !value.completed) return result;
    lessons.forEach(function(lesson) {
      var evidence = value.completed[lesson.id];
      if (evidence === "observed" || evidence === "self") result[lesson.id] = evidence;
    });
  } catch (_) {}
  return result;
}
function encode(completed) { return JSON.stringify({version: 1, completed: completed}); }

function nextIncomplete(completed) {
  for (var i = 0; i < lessons.length; i++) if (!completed[lessons[i].id]) return i;
  return 0;
}
