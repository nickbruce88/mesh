// Mesh Sports Service Worker — Push Notifications
// v1.0

const VAPID_PUBLIC_KEY = 'BDY_NFZqCYMcObVxvkoU4Z3UDOk_5sAwhmi_CVwNer5pA3UZ-qt23QH1G_BvH9-Fm-JjIcCPC81IUYPqi2H4BQ0';

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));

self.addEventListener('push', function(event) {
  if (!event.data) return;
  let payload;
  try { payload = event.data.json(); }
  catch(e) { payload = { title: 'Mesh Sports', body: event.data.text() }; }
  const title = payload.title || 'Mesh Sports';
  const options = {
    body: payload.body || '',
    icon: payload.icon || '/icon-192.png',
    badge: '/icon-192.png',
    tag: payload.tag || 'mesh-notification',
    renotify: true,
    data: { url: payload.url || '/' }
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  const url = event.notification.data?.url || '/';
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(clients => {
      for (const client of clients) {
        if (client.url.includes(self.location.origin) && 'focus' in client) return client.focus();
      }
      return self.clients.openWindow(url);
    })
  );
});