.pragma library
function shouldOffer(state) { return state === ""; }
function acknowledge(current, action) {
  return ["offered", "started", "dismissed", "finished"].indexOf(action) >= 0 ? action : current;
}
