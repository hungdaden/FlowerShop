importScripts("https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js");

// Initialize Firebase App in Service Worker context
firebase.initializeApp({
  apiKey: "AIzaSyD8aedS6XAJ6--CoMWqWsh2eadVA5tCTW0",
  authDomain: "flowershop-bd3f5.firebaseapp.com",
  projectId: "flowershop-bd3f5",
  storageBucket: "flowershop-bd3f5.firebasestorage.app",
  messagingSenderId: "430075295854",
  appId: "1:430075295854:web:663c140df79ee6b5150e7f",
  measurementId: "G-HKR2P34HLJ"
});

const messaging = firebase.messaging();

// Receive background messages and display system notifications
messaging.onBackgroundMessage((payload) => {
  // Nếu payload đã có phần 'notification', trình duyệt/SDK sẽ tự hiển thị. Không gọi showNotification lần 2.
  if (payload.notification) {
    return;
  }

  const notificationTitle = payload.data ? payload.data.title : "Thông báo mới";
  const notificationOptions = {
    body: payload.data ? payload.data.body : "Bạn có một tin nhắn mới từ Flower Shop.",
    icon: "/icons/Icon-192.png"
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  // Retrieve click_action from data payload, fallback to webpush click_action, default to '/'
  const clickAction = event.notification.data && event.notification.data.click_action
    ? event.notification.data.click_action
    : (event.notification.clickAction || '/');

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      // If a tab is already open and running the app, focus and navigate
      for (let i = 0; i < windowClients.length; i++) {
        const client = windowClients[i];
        if (client.url.indexOf(clickAction) !== -1 && 'focus' in client) {
          return client.focus();
        }
      }
      // Otherwise open a new tab
      if (clients.openWindow) {
        return clients.openWindow(clickAction);
      }
    })
  );
});
