/**
 * audio_bridge.js
 * Lightweight Web Audio API bridge for Spikerbot SFX.
 * Replaces SoLoud (which requires native WASM not available on web).
 *
 * API:
 *   window.webAudioInit()                    → bool
 *   window.webAudioLoad(name, url)           → Promise<bool>
 *   window.webAudioPlay(name, loop)          → handleId (int)
 *   window.webAudioStop(handleId)            → void
 *   window.webAudioFadeStop(handleId, ms)    → void
 *   window.webAudioFadeVolume(handleId, vol, ms) → void
 *   window.webAudioSetLoop(handleId, loop)   → void
 *   window.webAudioIsInit()                  → bool
 */

(function() {
  'use strict';

  var ctx = null;           // AudioContext
  var buffers = {};         // name → AudioBuffer
  var handles = {};         // handleId → { source, gain, startTime }
  var nextHandle = 1;
  var isInit = false;

  // ─── Init ─────────────────────────────────────────────────────────────────
  window.webAudioInit = function() {
    try {
      if (ctx) { isInit = true; return true; }
      ctx = new (window.AudioContext || window.webkitAudioContext)();
      isInit = true;
      console.log('WebAudio: Initialized (sampleRate=' + ctx.sampleRate + ')');
      return true;
    } catch (e) {
      console.error('WebAudio: init failed:', e);
      return false;
    }
  };

  window.webAudioIsInit = function() {
    return isInit && ctx !== null;
  };

  // ─── Load ─────────────────────────────────────────────────────────────────
  // Fetches an MP3 from the Flutter asset path and decodes it into an AudioBuffer.
  window.webAudioLoad = async function(name, url) {
    if (!ctx) return false;
    try {
      var response = await fetch(url);
      if (!response.ok) {
        console.error('WebAudio: fetch failed for', name, ':', response.status);
        return false;
      }
      var arrayBuffer = await response.arrayBuffer();
      var audioBuffer = await ctx.decodeAudioData(arrayBuffer);
      buffers[name] = audioBuffer;
      console.log('WebAudio: Loaded "' + name + '" (' + audioBuffer.duration.toFixed(1) + 's)');
      return true;
    } catch (e) {
      console.error('WebAudio: load error for', name, ':', e);
      return false;
    }
  };

  // ─── Play ─────────────────────────────────────────────────────────────────
  // Returns an integer handle for subsequent fade/stop/loop calls.
  window.webAudioPlay = function(name, loop) {
    if (!ctx || !buffers[name]) return -1;

    // Resume context if suspended (browser autoplay policy)
    if (ctx.state === 'suspended') ctx.resume();

    var source = ctx.createBufferSource();
    source.buffer = buffers[name];
    source.loop = !!loop;

    var gain = ctx.createGain();
    gain.gain.value = 1.0;

    source.connect(gain);
    gain.connect(ctx.destination);

    var handleId = nextHandle++;
    handles[handleId] = { source: source, gain: gain };

    // Auto-cleanup on end (for non-looping sounds)
    source.onended = function() {
      delete handles[handleId];
    };

    source.start(0);
    return handleId;
  };

  // ─── Stop ─────────────────────────────────────────────────────────────────
  window.webAudioStop = function(handleId) {
    var h = handles[handleId];
    if (!h) return;
    try { h.source.stop(); } catch (_) {}
    delete handles[handleId];
  };

  // ─── Fade Volume ──────────────────────────────────────────────────────────
  // Smoothly ramp to target volume over durationMs.
  window.webAudioFadeVolume = function(handleId, targetVol, durationMs) {
    var h = handles[handleId];
    if (!h || !ctx) return;
    var now = ctx.currentTime;
    h.gain.gain.cancelScheduledValues(now);
    h.gain.gain.setValueAtTime(h.gain.gain.value, now);
    h.gain.gain.linearRampToValueAtTime(targetVol, now + durationMs / 1000.0);
  };

  // ─── Fade Out + Stop ──────────────────────────────────────────────────────
  // Fades to 0 over durationMs, then stops the source.
  window.webAudioFadeStop = function(handleId, durationMs) {
    var h = handles[handleId];
    if (!h || !ctx) return;
    var now = ctx.currentTime;
    var endTime = now + durationMs / 1000.0;
    h.gain.gain.cancelScheduledValues(now);
    h.gain.gain.setValueAtTime(h.gain.gain.value, now);
    h.gain.gain.linearRampToValueAtTime(0, endTime);
    try { h.source.stop(endTime + 0.05); } catch (_) {}
    // Cleanup after fade completes
    setTimeout(function() { delete handles[handleId]; }, durationMs + 100);
  };

  // ─── Set Looping ──────────────────────────────────────────────────────────
  window.webAudioSetLoop = function(handleId, loop) {
    var h = handles[handleId];
    if (!h) return;
    h.source.loop = !!loop;
  };

})();
