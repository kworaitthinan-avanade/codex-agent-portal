/* codex-agent - shared frontend helpers.
   Display only. No ticket processing happens here. */

const BRIDGE = 'http://localhost:8765';

async function getJSON(file) {
  const r = await fetch('./' + file + '?t=' + Date.now());
  if (!r.ok) throw new Error(file + ' not found - run the board-refresh skill first');
  return r.json();
}

function fmtTime(iso) {
  if (!iso) return '--:--';
  return new Date(iso).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
}

function fmtDuration(sec) {
  if (sec == null) return '--';
  const m = Math.floor(sec / 60), s = sec % 60;
  return m + 'm ' + String(s).padStart(2, '0') + 's';
}

function needsYou(t) {
  return t.state === 'pending-grouping' || t.state === 'pending-action';
}

function hasWrite(t) {
  return (t.plan || []).some(s => s.write);
}

function escHtml(s) {
  if (s == null) return '';
  return String(s).replace(/[&<>"']/g, c => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
  ));
}

/* ---- nav ---- */
function renderNav(active, count) {
  const el = document.querySelector('header');
  if (!el) return;
  const badge = count > 0 ? ' <span class="badge">' + count + '</span>' : '';
  el.innerHTML =
    '<div class="brand">codex-agent</div>' +
    '<nav>' +
      '<a href="index.html"    class="' + (active === 'overview' ? 'active' : '') + '">Overview</a>' +
      '<a href="review.html"   class="' + (active === 'review'   ? 'active' : '') + '">Review Queue' + badge + '</a>' +
      '<a href="insights.html" class="' + (active === 'insights' ? 'active' : '') + '">Insights</a>' +
    '</nav>' +
    '<div class="stamp" id="stamp"></div>';
}

function stamp(iso) {
  const el = document.getElementById('stamp');
  if (el) el.textContent = 'refreshed ' + fmtTime(iso);
}

/* ---- confidence bar with the threshold marked ---- */
function confBar(value, threshold) {
  if (value == null) return '';
  const pct = Math.round(value * 100);
  const ok = value >= threshold;
  return '<div class="conf">' +
    '<small>confidence</small>' +
    '<div class="bar ' + (ok ? 'ok' : '') + '">' +
      '<i style="width:' + pct + '%"></i>' +
      '<span class="thr" style="left:' + Math.round(threshold * 100) + '%"></span>' +
    '</div>' +
    '<small><b>' + value.toFixed(2) + '</b> / threshold ' + threshold.toFixed(2) + '</small>' +
  '</div>';
}

/* ---- optional click-to-run bridge ----
   A browser cannot launch a process, so bridge.ps1 sits in between and
   calls `codex exec`. Without it running, the UI stays read-only. */
async function runInCodex(ticket, action, extra) {
  try {
    const r = await fetch(BRIDGE, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ticket, action, extra: extra || null })
    });
    return await r.json();
  } catch (e) {
    alert(
      'Bridge not reachable at ' + BRIDGE + '.\n\n' +
      'Start it with:  .\\web\\bridge.ps1\n\n' +
      'Or run this in Codex directly:\n' +
      '  run approval-gate on ' + ticket + ' (' + action +
      (extra ? ': ' + extra : '') + ')'
    );
    return null;
  }
}
