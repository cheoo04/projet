/* Firebase Messaging Service Worker for Web (Flutter)
 * This file must be served at /firebase-messaging-sw.js
 * to avoid the "unsupported MIME type 'text/html'" error.
 */

importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');
importScripts('/firebase-config.js'); // contains firebase.initializeApp(...)

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

try {
  const messaging = firebase.messaging();
  // Handle background messages (optional, logs payload)
  messaging.onBackgroundMessage((payload) => {
    // You can customize notifications here
    const notificationTitle = payload?.notification?.title || 'Notification';
    const notificationOptions = {
      body: payload?.notification?.body || '',
      icon: '/icons/Icon-192.png',
      data: payload?.data || {},
    };
    self.registration.showNotification(notificationTitle, notificationOptions);
  });
} catch (e) {
  // No-op: messaging may not be available in some contexts
}
