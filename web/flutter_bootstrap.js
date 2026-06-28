{{flutter_js}}
{{flutter_build_config}}

// Masque le splash avec un fondu doux
function hideSplash() {
  var splash = document.getElementById('pharrell-splash');
  if (!splash || splash._hidden) return;
  splash._hidden = true;
  splash.style.transition = 'opacity 0.4s ease';
  splash.style.opacity = '0';
  setTimeout(function() {
    if (splash.parentNode) splash.parentNode.removeChild(splash);
  }, 420);
}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    // Moteur Flutter chargé → initialise
    const appRunner = await engineInitializer.initializeEngine();
    // App prête → cache le splash exactement maintenant
    hideSplash();
    await appRunner.runApp();
  }
});