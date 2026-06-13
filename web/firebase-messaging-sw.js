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
  console.log("[firebase-messaging-sw.js] Nhận thông báo chạy ngầm: ", payload);

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
