const admin = require("firebase-admin");

// ✅ Ruta correcta al archivo .json con credenciales nuevas
const serviceAccount = require("./inhouston-209c0-firebase-adminsdk-eqa6b-8e0fb0bf7b.json");

// ✅ Inicializar Firebase Admin con las credenciales correctas
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// 🔑 Token FCM (cópialo desde tu consola Flutter cada vez que lo pruebes)
const fcmToken = "eIXVBrFjPE-juV3GUtclsh:APA91bFodpoIttOWc3S8s2yLgK-DTM3lGSUoOa3H5o_C1RTfCJmRuJoQrthJM_7oBDs9PDx9ZhDZVZ1gI5yRTfgjs9V4-n-1fTryqBiAIeSIkLwX6_JbdWo";

// 📩 Mensaje de notificación
const message = {
  token: fcmToken,
  notification: {
    title: "🚀 ¡Notificación enviada correctamente!",
    body: "📲 Si ves esto en tu iPhone, todo está funcionando al 100%.",
  },
};

// 🚀 Enviar la notificación push
admin
  .messaging()
  .send(message)
  .then((response) => {
    console.log("✅ Notificación enviada:", response);
  })
  .catch((error) => {
    console.error("❌ Error al enviar notificación:", error);
  });
