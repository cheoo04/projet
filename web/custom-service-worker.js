// Service Worker Pharrell Phone
// Version incrémentée à chaque deploy Flutter (via flutter_service_worker.js)
// Stratégie : Network-First pour HTML/JS, Cache-First pour images

// ── Version ────────────────────────────────────────────────────────────────
// Ce nom de cache DOIT changer à chaque déploiement pour forcer la mise à
// jour chez tous les utilisateurs. Flutter le gère via son propre SW, mais
// on synchronise ici pour éviter les conflits.
const CACHE_VERSION = 'pharrell-v3';
const IMAGE_CACHE   = 'pharrell-images-v3';

// Ressources pré-cachées au démarrage
const PRECACHE_URLS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/styles.css',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
];

// Jamais mettre en cache : Firebase APIs, Cloud Functions, CDNs dynamiques
const NEVER_CACHE = [
  /firebasestorage\.googleapis\.com/,
  /firestore\.googleapis\.com/,
  /identitytoolkit\.googleapis\.com/,
  /securetoken\.googleapis\.com/,
  /fcmregistrations\.googleapis\.com/,
  /cloudfunctions\.net/,
  /generativelanguage\.googleapis\.com/,
  /googleapis\.com\/v1/,
  /\/api\//,
];

const IMAGE_EXTENSIONS = /\.(png|jpg|jpeg|webp|gif|svg)(\?.*)?$/i;
const STATIC_EXTENSIONS = /\.(js|css|woff|woff2|ttf|otf)(\?.*)?$/i;

// ── Install ────────────────────────────────────────────────────────────────
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_VERSION)
      .then((cache) => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting())
      .catch(() => self.skipWaiting()) // Ne pas bloquer si un asset manque
  );
});

// ── Activate : purge les anciens caches ───────────────────────────────────
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(
        keys
          .filter((k) => k !== CACHE_VERSION && k !== IMAGE_CACHE)
          .map((k) => caches.delete(k))
      ))
      .then(() => self.clients.claim())
  );
});

// ── Fetch ──────────────────────────────────────────────────────────────────
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Ignorer non-GET
  if (request.method !== 'GET') return;

  // Ignorer toutes les APIs Firebase et Cloud Functions
  if (NEVER_CACHE.some((p) => p.test(url.href))) return;

  // Images Cloudinary et statiques → Cache First
  if (IMAGE_EXTENSIONS.test(url.pathname) || url.hostname.includes('res.cloudinary.com')) {
    event.respondWith(cacheFirst(request, IMAGE_CACHE));
    return;
  }

  // JS/CSS/fonts Flutter → Stale While Revalidate
  // (Flutter génère des hash dans les noms, donc on peut servir le cache
  //  et mettre à jour en fond — le prochain reload aura le nouveau code)
  if (STATIC_EXTENSIONS.test(url.pathname)) {
    event.respondWith(staleWhileRevalidate(request, CACHE_VERSION));
    return;
  }

  // HTML et le reste → Network First avec fallback
  event.respondWith(networkFirst(request, CACHE_VERSION));
});

// ── Stratégies ─────────────────────────────────────────────────────────────

async function networkFirst(request, cacheName) {
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(cacheName);
      // Eviter de cacher des réponses opaques (cross-origin sans CORS)
      if (response.type !== 'opaque') {
        cache.put(request, response.clone());
      }
    }
    return response;
  } catch {
    const cached = await caches.match(request);
    if (cached) return cached;
    // Fallback vers index.html pour la navigation SPA
    if (request.destination === 'document') {
      return caches.match('/index.html');
    }
    return new Response('Hors ligne', { status: 503 });
  }
}

async function cacheFirst(request, cacheName) {
  const cached = await caches.match(request);
  if (cached) {
    // Mise à jour silencieuse en arrière-plan
    fetch(request).then((r) => {
      if (r.ok && r.type !== 'opaque') {
        caches.open(cacheName).then((c) => c.put(request, r));
      }
    }).catch(() => {});
    return cached;
  }
  try {
    const response = await fetch(request);
    if (response.ok && response.type !== 'opaque') {
      const cache = await caches.open(cacheName);
      cache.put(request, response.clone());
    }
    return response;
  } catch {
    // Placeholder SVG pour les images manquantes
    return new Response(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
      + '<rect fill="#f0f0f0" width="100" height="100"/></svg>',
      { headers: { 'Content-Type': 'image/svg+xml' } }
    );
  }
}

async function staleWhileRevalidate(request, cacheName) {
  const cached = await caches.match(request);
  const fetchPromise = fetch(request).then((r) => {
    if (r.ok && r.type !== 'opaque') {
      caches.open(cacheName).then((c) => c.put(request, r.clone()));
    }
    return r;
  }).catch(() => null);

  return cached || await fetchPromise;
}

// ── Messages ───────────────────────────────────────────────────────────────
self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') self.skipWaiting();
  if (event.data === 'clearCache') {
    caches.keys().then((keys) => keys.forEach((k) => caches.delete(k)));
  }
});

// ── Push Notifications (FCM) ───────────────────────────────────────────────
self.addEventListener('push', (event) => {
  if (!event.data) return;
  const data = event.data.json();
  event.waitUntil(
    self.registration.showNotification(
      data.notification?.title || 'Pharrell Phone',
      {
        body: data.notification?.body || '',
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        vibrate: [100, 50, 100],
        data: data.data || {},
      }
    )
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  if (event.action === 'dismiss') return;
  event.waitUntil(
    clients.openWindow(event.notification.data?.url || '/')
  );
});

console.log('🚀 Service Worker Pharrell Phone v3 chargé');