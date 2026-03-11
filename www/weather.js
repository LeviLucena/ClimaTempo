/* weather.js — ClimaTempo client-side logic */

/* ── 1. Particle canvas animation ─────────────────────────────────────────── */
(function () {
  var canvas, ctx, animId;

  function initCanvas() {
    var hero = document.querySelector('.ct-hero');
    if (!hero) return false;
    canvas = document.getElementById('weather-canvas');
    if (!canvas) {
      canvas = document.createElement('canvas');
      canvas.id = 'weather-canvas';
      hero.prepend(canvas);
    }
    canvas.width  = hero.offsetWidth;
    canvas.height = hero.offsetHeight;
    ctx = canvas.getContext('2d');
    return true;
  }

  function makeRain(w, h, fast) {
    return {
      x: Math.random() * w, y: Math.random() * h,
      vy: (fast ? 14 : 9) + Math.random() * 4,
      vx: fast ? -3 : -1.5,
      len: (fast ? 18 : 12) + Math.random() * 8,
      alpha: 0.4 + Math.random() * 0.4
    };
  }
  function makeSnow(w, h) {
    return {
      x: Math.random() * w, y: Math.random() * h,
      vy: 0.8 + Math.random() * 1.2,
      vx: 0, phase: Math.random() * Math.PI * 2,
      r: 2 + Math.random() * 3,
      alpha: 0.55 + Math.random() * 0.35
    };
  }

  function startAnim(cond) {
    cancelAnimationFrame(animId);
    if (!initCanvas()) return;
    var w = canvas.width, h = canvas.height;
    var particles = [];
    var isStorm = (cond === 'Tempestade');
    var isSnow  = (cond === 'Neve');
    var count   = isStorm ? 200 : isSnow ? 50 : 110;

    for (var i = 0; i < count; i++) {
      particles.push(isSnow ? makeSnow(w, h) : makeRain(w, h, isStorm));
    }

    var frame = 0;
    function draw() {
      ctx.clearRect(0, 0, w, h);
      frame++;
      particles.forEach(function (p) {
        ctx.save();
        ctx.globalAlpha = p.alpha;
        if (isSnow) {
          p.x += Math.sin(p.phase + frame * 0.02) * 0.5;
          p.y += p.vy;
          ctx.fillStyle = 'rgba(200,230,255,0.85)';
          ctx.beginPath();
          ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
          ctx.fill();
        } else {
          ctx.strokeStyle = isStorm
            ? 'rgba(160,130,255,0.65)'
            : 'rgba(120,190,255,0.65)';
          ctx.lineWidth = isStorm ? 1.5 : 1;
          ctx.beginPath();
          ctx.moveTo(p.x, p.y);
          ctx.lineTo(p.x + p.vx, p.y + p.len);
          ctx.stroke();
          p.x += p.vx;
          p.y += p.vy;
        }
        ctx.restore();
        if (p.y > h + 20) { p.y = -20; p.x = Math.random() * w; }
        if (p.x < -10)    { p.x = w + 5; }
      });
      animId = requestAnimationFrame(draw);
    }
    draw();
  }

  var ANIMATED = ['Chuva', 'Chuva forte', 'Tempestade', 'Neve'];

  function syncAnim() {
    var hero = document.querySelector('.ct-hero');
    if (!hero) return;
    var cond = hero.getAttribute('data-condition') || '';
    cancelAnimationFrame(animId);
    if (ANIMATED.indexOf(cond) >= 0) {
      startAnim(cond);
    } else {
      if (ctx && canvas) ctx.clearRect(0, 0, canvas.width, canvas.height);
    }
  }

  /* observe DOM changes to detect hero re-renders */
  var obs = new MutationObserver(function (muts) {
    for (var i = 0; i < muts.length; i++) {
      if (muts[i].type === 'attributes' || muts[i].addedNodes.length) {
        syncAnim(); break;
      }
    }
  });

  document.addEventListener('DOMContentLoaded', function () {
    obs.observe(document.body, {
      childList: true, subtree: true,
      attributes: true, attributeFilter: ['data-condition']
    });
    syncAnim();
  });

  window.addEventListener('resize', function () {
    if (canvas && canvas.parentElement) {
      canvas.width  = canvas.parentElement.offsetWidth;
      canvas.height = canvas.parentElement.offsetHeight;
    }
    syncAnim();
  });
})();

/* ── 2. Toast notifications ───────────────────────────────────────────────── */
function showToast(msg, type) {
  var container = document.getElementById('ct-toast-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'ct-toast-container';
    document.body.appendChild(container);
  }
  var toast = document.createElement('div');
  toast.className = 'ct-toast ' + (type || '');
  toast.innerHTML = msg;
  container.appendChild(toast);
  setTimeout(function () {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(20px)';
    setTimeout(function () { toast.remove(); }, 400);
  }, 5500);
}

if (window.Shiny) {
  Shiny.addCustomMessageHandler('showToast', function (data) {
    showToast(data.msg, data.type || '');
  });
}

/* ── 3. Dark / Light mode toggle ─────────────────────────────────────────── */
$(document).on('click', '#toggle_theme', function () {
  var isLight = document.body.classList.toggle('light-mode');
  $(this).find('i')
    .toggleClass('fa-circle-half-stroke', !isLight)
    .toggleClass('fa-sun', isLight);
});
