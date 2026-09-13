.pragma library

// Only add an article URL after checking the published page and its lesson match.
// A recovered draft title is not evidence that its publication URL exists.
var catalog = {
  super: { title: "What’s so Super about a key?", url: "" }
};
function safeUrl(url) {
  if (typeof url !== "string" || url.length > 2048) return "";
  if (/^https:\/\/tcballard\.substack\.com\/p\/[a-z0-9-]+$/.test(url)) return url;
  if (/^https:\/\/tcballard\.dev\/[a-zA-Z0-9/_-]+$/.test(url)) return url;
  if (/^https:\/\/x\.com\/tcballard\/status\/[0-9]+$/.test(url)) return url;
  return "";
}
function forLesson(id) {
  if (!Object.prototype.hasOwnProperty.call(catalog, id)) return null;
  var entry = catalog[id], url = safeUrl(entry.url);
  return url && typeof entry.title === "string" && entry.title.length > 0 && entry.title.length <= 200
    ? {title:entry.title, url:url} : null;
}
function requestedLesson(encoded, lessons) {
  if (typeof encoded !== "string" || encoded.length > 1024) return -1;
  try {
    var value = JSON.parse(encoded);
    if (!value || typeof value.lesson !== "string") return -1;
    for (var i=0; i<lessons.length; i++) if (lessons[i].id === value.lesson) return i;
  } catch (_) {}
  return -1;
}
