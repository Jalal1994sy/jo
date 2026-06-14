
const CACHE_NAME = 'jouw-driver-v3';
const STATIC_CACHE = 'jouw-driver-static-v3';
const API_CACHE = 'jouw-driver-api-v3';

const STATIC_URLS = [
  '/driver-login',
  '/driver/taximeter',
  '/driver/trips',
  '/driver/messages',
  '/driver/notifications',
  '/driver/summary',
  '/driver/test',
];

const API_CACHE_URLS = [
  '/next_api/drivers/me',
  '/next_api/drivers/pricing',
  '/next_api/notifications/driver',
  '/next_api/messages/driver',
];

// Install event - cache static assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    Promise.all([
      caches.open(STATIC_CACHE).then((cache) => {
        return cache.addAll(STATIC_URLS).catch((err) => {
          console.warn('Some static URLs failed to cache:', err);
        });
      }),
    ])
  );
  self.skipWaiting();
});

// Activate event - clean old caches
self.addEventListener('activate', (event) => {
  const cacheWhitelist = [CACHE_NAME, STATIC_CACHE, API_CACHE];
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (!cacheWhitelist.includes(cacheName)) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
  self.clients.claim();
});

// Fetch event - smart caching strategy
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Skip non-GET requests for caching
  if (request.method !== 'GET') return;

  // Skip chrome-extension and non-http requests
  if (!url.protocol.startsWith('http')) return;

  // API routes - Network first, fallback to cache
  if (url.pathname.startsWith('/next_api/')) {
    event.respondWith(
      fetch(request)
        .then((response) => {
          if (response.ok && API_CACHE_URLS.some(u => url.pathname.startsWith(u))) {
            const responseClone = response.clone();
            caches.open(API_CACHE).then((cache) => {
              cache.put(request, responseClone);
            });
          }
          return response;
        })
        .catch(() => {
          return caches.match(request).then((cached) => {
            if (cached) return cached;
            return new Response(
              JSON.stringify({ success: false, error: 'Offline - cached data unavailable' }),
              { headers: { 'Content-Type': 'application/json' } }
            );
          });
        })
    );
    return;
  }

  // Static pages - Cache first, fallback to network
  if (STATIC_URLS.some(u => url.pathname === u || url.pathname.startsWith(u))) {
    event.respondWith(
      caches.match(request).then((cached) => {
        const networkFetch = fetch(request).then((response) => {
          if (response.ok) {
            const responseClone = response.clone();
            caches.open(STATIC_CACHE).then((cache) => {
              cache.put(request, responseClone);
            });
          }
          return response;
        });
        return cached || networkFetch;
      })
    );
    return;
  }

  // Default - Network first
  event.respondWith(
    fetch(request).catch(() => caches.match(request))
  );
});

// Background sync for offline trips
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-offline-trips') {
    event.waitUntil(syncOfflineTrips());
  }
});

async function syncOfflineTrips() {
  try {
    const clients = await self.clients.matchAll();
    clients.forEach((client) => {
      client.postMessage({ type: 'SYNC_OFFLINE_TRIPS' });
    });
  } catch (err) {
    console.error('Background sync failed:', err);
  }
}

// Push notifications
self.addEventListener('push', (event) => {
  if (!event.data) return;
  const data = event.data.json();
  const options = {
    body: data.body || '',
    icon: 'https://cdn.chat2db-ai.com/app/avatar/custom/16eda623-2b94-41ea-8390-395dcb708494_737955.png',
    badge: 'https://cdn.chat2db-ai.com/app/avatar/custom/16eda623-2b94-41ea-8390-395dcb708494_737955.png',
    vibrate: [100, 50, 100],
    data: { url: data.url || '/driver/notifications' },
    actions: [
      { action: 'open', title: 'Openen' },
      { action: 'close', title: 'Sluiten' },
    ],
  };
  event.waitUntil(
    self.registration.showNotification(data.title || 'Jouw Driver', options)
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  if (event.action === 'open' || !event.action) {
    const url = event.notification.data?.url || '/driver/taximeter';
    event.waitUntil(
      self.clients.matchAll({ type: 'window' }).then((clients) => {
        const existingClient = clients.find((c) => c.url.includes(url));
        if (existingClient) return existingClient.focus();
        return self.clients.openWindow(url);
      })
    );
  }
});
