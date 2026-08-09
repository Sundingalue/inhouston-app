const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const { getFirestore } = require('firebase-admin/firestore');
const logger = require('firebase-functions/logger');

initializeApp();

// 🔔 FUNCIÓN AUTOMÁTICA: cuando se agrega una empresa
exports.notificarNuevoServicioV3 = onDocumentCreated(
  'empresas_ofertas/{empresaId}',
  async (event) => {
    const snapshot = event.data;

    if (!snapshot) {
      logger.error('❌ No se encontró el documento');
      return;
    }

    const empresa = snapshot.data();
    const empresaId = event.params.empresaId;

    const nombreEmpresa =
      empresa.nombre_negocio?.trim() ||
      empresa.nombre?.trim() ||
      'una nueva empresa';

    const mensaje = {
      topic: 'todos',
      data: {
        empresaId: empresaId,
        categoria: empresa.categoria || '',
      },
      notification: {
        title: "🎯 ¡Nuevo descuento exclusivo!",
        body: `Descubre a ${empresa.nombre_negocio ?? "una empresa"} y aprovecha su promoción.`,
      },
    };

    try {
      const response = await getMessaging().send(mensaje);
      logger.info(`✅ Notificación enviada correctamente para ${nombreEmpresa}: ${response}`);
    } catch (error) {
      logger.error(`❌ Error al enviar notificación para ${nombreEmpresa}:`, error);
    }
  }
);

// 📢 FUNCIÓN MANUAL: enviar notificación personalizada con link
exports.enviarNotificacionManual = onRequest(async (req, res) => {
  try {
    const { titulo, cuerpo, link } = req.body;

    if (!titulo || !cuerpo) {
      res.status(400).send('❌ Faltan parámetros: título y cuerpo son requeridos');
      return;
    }

    const db = getFirestore();
    const usersSnapshot = await db.collection('Users').get();

    const tokens = [];
    usersSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.fcmToken) {
        tokens.push(data.fcmToken);
      }
    });

    if (tokens.length === 0) {
      res.status(200).send('⚠️ No se encontraron tokens FCM.');
      return;
    }

    const mensaje = {
      notification: {
        title: titulo,
        body: cuerpo,
      },
      data: {
        link: link || '',
      },
      tokens: tokens,
    };

    const response = await getMessaging().sendEachForMulticast(mensaje);
    logger.info(`✅ Notificación enviada a ${response.successCount} dispositivos`);
    res.status(200).send(`✅ Notificación enviada a ${response.successCount} dispositivos`);
  } catch (error) {
    logger.error('❌ Error al enviar la notificación manual:', error);
    res.status(500).send('❌ Error interno');
  }
});
