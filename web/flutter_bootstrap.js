{{flutter_js}}
{{flutter_build_config}}

const loading = document.getElementById('app-loading');
const message = document.getElementById('loading-message');
const retry = document.getElementById('loading-retry');
retry?.addEventListener('click', () => window.location.reload());

function showStartupError() {
  if (message) message.textContent = 'No pudimos abrir tu espacio. Intenta cargarlo de nuevo.';
  if (retry) retry.hidden = false;
}

// Flutter serves these assets locally in development and includes them in build/web.
const flutterConfig = {
  canvasKitBaseUrl: 'canvaskit/',
  fontFallbackBaseUrl: 'fonts/fallback/',
};
_flutter.loader.load({
  config: flutterConfig,
  onEntrypointLoaded: async function(engineInitializer) {
    try {
      if (message) message.textContent = 'Abriendo Ritmo…';
      const appRunner = await engineInitializer.initializeEngine(flutterConfig);
      await appRunner.runApp();
      loading?.remove();
    } catch (_) {
      showStartupError();
    }
  },
}).catch(showStartupError);
