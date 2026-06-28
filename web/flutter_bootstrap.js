{{flutter_js}}
{{flutter_build_config}}

// Masque le splash avec fondu doux
function hideSplash() {
  var el = document.getElementById('pharrell-splash');
  if (!el || el._hidden) return;
  el._hidden = true;
  el.style.transition = 'opacity 0.45s ease';
  el.style.opacity = '0';
  setTimeout(function() { el.remove(); }, 480);
}

// Timeout de sécurité : si Flutter met > 30s, on cache quand même le splash
// pour ne pas bloquer l'utilisateur indéfiniment
setTimeout(hideSplash, 30000);

// Démarrer Flutter immédiatement — sans attendre window.load
// C'est la clé : ne pas bloquer sur les scripts Firebase async
_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    hideSplash();
    await appRunner.runApp();
  }
});