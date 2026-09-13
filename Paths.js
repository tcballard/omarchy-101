.pragma library
function settingsUrl(home, config) {
  var directory = typeof config === "string" && config[0] === "/" ? config :
    (typeof home === "string" && home[0] === "/" ? home + "/.config" : "");
  if (!directory) return "";
  return "file://" + (directory + "/omarchy-101.ini").split("/").map(encodeURIComponent).join("/");
}

function configDirectory(home, config) {
  return typeof config === "string" && config[0] === "/" ? config :
    (typeof home === "string" && home[0] === "/" ? home + "/.config" : "");
}
