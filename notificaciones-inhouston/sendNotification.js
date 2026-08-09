const admin = require("firebase-admin");
const serviceAccount = require("./inhouston-209c0-firebase-adminsdk-eqa6b-8e0fb0bf7b.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// ✅ Token FCM del dispositivo (válido y completo)
const fcmToken = "eIXVBrFjPE-juV3GUtclsh:APA91bFodpoIttOWc3S8s2yLgK-DTM3lGSUoOa3H5o_C1RTfCJmRuJoQrthJM_7oBDs9PDx9ZhDZVZ1gI5yRTfgjs9V4-n-1fTryqBiAIeSIkLwX6_JbdWo";

// 📩 Mensaje que quieres enviar
const message = {
  token: fcmToken,
  notification: {
    title: "🔥 ¡Prueba real desde Node.js!",
    body: "🚀 ¡Si ves esto en tu iPhone, todo funciona perfecto!",
  },
};

// 🚀 Enviar notificación
admin
  .messaging()
  .send(message)
  .then((response) => {
    console.log("✅ Notificación enviada:", response);
  })
  .catch((error) => {
    console.error("❌ Error al enviar notificación:", error);
  });
