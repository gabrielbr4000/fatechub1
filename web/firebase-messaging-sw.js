importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "SUA_API_KEY",
  authDomain: "fatechub-621ee.firebaseapp.com",
  projectId: "fatechub-621ee",
  storageBucket: "fatechub-621ee.appspot.com",
  messagingSenderId: "SEU_SENDER_ID",
  appId: "SEU_APP_ID"
});

const messaging = firebase.messaging();

// Recebe notificações com app em background
messaging.onBackgroundMessage((payload) => {
  console.log('Notificação em background:', payload);

  self.registration.showNotification(payload.notification.title, {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png',
  });
});