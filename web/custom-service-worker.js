// Service Worker personnalisé pour Pharrell Phone
// Stratégie de cache: Network-First avec fallback cache pour les ressources critiques

const CACHE_NAME = 'pharrell-phone-v1';
const STATIC_CACHE_NAME = 'pharrell-phone-static-v1';
const IMAGE_CACHE_NAME = 'pharrell-phone-images-v1';

// Ressources à mettre en cache immédiatement
const PRECACHE_URLS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/styles.css',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
];

// Ressources Firebase à ne jamais mettre en cache
const NEVER_CACHE_PATTERNS = [
  /firebasestorage\.googleapis\.com/, // Storage dynamique
  /firestore\.googleapis\.com/,        // API Firestore
  /identitytoolkit\.googleapis\.com/,  // Auth API
  /securetoken\.googleapis\.com/,      // Tokens
  /fcmregistrations\.googleapis\.com/, // FCM
  /\/api\//,                           // Endpoints API
];

// Patterns pour le cache d'images (1 jour)
const IMAGE_CACHE_PATTERNS = [
  /\.png$/,
  /\.jpg$/,
  /\.jpeg$/,
  /\.webp$/,
  /\.gif$/,
  /\.svg$/,
];

// Installation du Service Worker
self.addEventListener('install', (event) => {
  console.log('📦 Service Worker: Installation');
  
  event.waitUntil(
    caches.open(STATIC_CACHE_NAME)
      .then((cache) => {
        console.log('📦 Pre-caching ressources statiques');
        return cache.addAll(PRECACHE_URLS);
      })
      .then(() => self.skipWaiting())
      .catch((error) => {
        console.warn('⚠️ Erreur pre-cache:', error);
      })
  );
});

// Activation et nettoyage des anciens caches
self.addEventListener('activate', (event) => {
  console.log('✅ Service Worker: Activation');
  
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            // Supprimer les anciens caches (versions précédentes)
            if (cacheName !== CACHE_NAME && 
                cacheName !== STATIC_CACHE_NAME && 
                cacheName !== IMAGE_CACHE_NAME) {
              console.log('🗑️ Suppression ancien cache:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      })
      .then(() => self.clients.claim())
  );
});

// Stratégie de fetch
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Ignorer les requêtes non-GET
  if (request.method !== 'GET') {
    return;
  }
  
  // Ignorer les requêtes Firebase (toujours réseau)
  if (shouldNeverCache(url)) {
    return;
  }
  
  // Stratégie spéciale pour les images
  if (isImageRequest(url)) {
    event.respondWith(cacheFirstWithNetworkFallback(request, IMAGE_CACHE_NAME));
    return;
  }
  
  // Stratégie pour les fichiers statiques (CSS, JS, fonts)
  if (isStaticAsset(url)) {
    event.respondWith(staleWhileRevalidate(request, STATIC_CACHE_NAME));
    return;
  }
  
  // Stratégie par défaut: Network first, cache fallback
  event.respondWith(networkFirstWithCacheFallback(request, CACHE_NAME));
});

// === STRATÉGIES DE CACHE ===

// Network First: Essayer le réseau, fallback vers le cache
async function networkFirstWithCacheFallback(request, cacheName) {
  try {
    const response = await fetch(request);
    
    // Mettre en cache si réponse valide
    if (response.ok) {
      const cache = await caches.open(cacheName);
      cache.put(request, response.clone());
    }
    
    return response;
  } catch (error) {
    // Fallback vers le cache
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      console.log('📱 Serving from cache:', request.url);
      return cachedResponse;
    }
    
    // Page offline si disponible
    if (request.destination === 'document') {
      return caches.match('/index.html');
    }
    
    throw error;
  }
}

// Cache First: Servir du cache, mettre à jour en arrière-plan
async function cacheFirstWithNetworkFallback(request, cacheName) {
  const cachedResponse = await caches.match(request);
  
  if (cachedResponse) {
    // Mettre à jour en arrière-plan (pour les images)
    updateCacheInBackground(request, cacheName);
    return cachedResponse;
  }
  
  try {
    const response = await fetch(request);
    
    if (response.ok) {
      const cache = await caches.open(cacheName);
      cache.put(request, response.clone());
    }
    
    return response;
  } catch (error) {
    // Retourner une image placeholder si échec
    return new Response(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect fill="#ccc" width="100" height="100"/><text x="50" y="55" text-anchor="middle" fill="#666">Image</text></svg>',
      { headers: { 'Content-Type': 'image/svg+xml' } }
    );
  }
}

// Stale While Revalidate: Servir du cache, mettre à jour simultanément
async function staleWhileRevalidate(request, cacheName) {
  const cachedResponse = await caches.match(request);
  
  // Si on a une réponse en cache, la retourner immédiatement
  // et mettre à jour en arrière-plan
  if (cachedResponse) {
    // Mise à jour en arrière-plan (ne pas attendre)
    fetch(request).then((response) => {
      if (response.ok) {
        caches.open(cacheName).then((cache) => {
          cache.put(request, response);
        });
      }
    }).catch(() => {});
    
    return cachedResponse;
  }
  
  // Pas de cache, faire la requête réseau
  try {
    const response = await fetch(request);
    if (response.ok) {
      const responseClone = response.clone();
      caches.open(cacheName).then((cache) => {
        cache.put(request, responseClone);
      });
    }
    return response;
  } catch (error) {
    throw error;
  }
}

// Mise à jour du cache en arrière-plan
async function updateCacheInBackground(request, cacheName) {
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(cacheName);
      cache.put(request, response.clone());
    }
  } catch (error) {
    // Ignorer les erreurs de mise à jour en arrière-plan
  }
}

// === HELPERS ===

function shouldNeverCache(url) {
  return NEVER_CACHE_PATTERNS.some(pattern => pattern.test(url.href));
}

function isImageRequest(url) {
  return IMAGE_CACHE_PATTERNS.some(pattern => pattern.test(url.pathname)) ||
         url.hostname.includes('firebasestorage');
}

function isStaticAsset(url) {
  return url.pathname.endsWith('.js') ||
         url.pathname.endsWith('.css') ||
         url.pathname.endsWith('.woff') ||
         url.pathname.endsWith('.woff2') ||
         url.pathname.endsWith('.ttf');
}

// === GESTION DES MESSAGES ===

self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
  }
  
  if (event.data === 'clearCache') {
    caches.keys().then((names) => {
      names.forEach((name) => caches.delete(name));
    });
  }
});

// === PUSH NOTIFICATIONS (FCM) ===

self.addEventListener('push', (event) => {
  if (!event.data) return;
  
  const data = event.data.json();
  const options = {
    body: data.notification?.body || 'Nouvelle notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    vibrate: [100, 50, 100],
    data: data.data || {},
    actions: [
      { action: 'open', title: 'Ouvrir' },
      { action: 'dismiss', title: 'Fermer' },
    ],
  };
  
  event.waitUntil(
    self.registration.showNotification(
      data.notification?.title || 'Pharrell Phone',
      options
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

console.log('🚀 Service Worker Pharrell Phone chargé');
