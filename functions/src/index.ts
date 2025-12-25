import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

// Initialiser Firebase Admin
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

interface NotificationData {
  title: string;
  body: string;
  type?: string;
  targetType?: string;
  targetUserIds?: string[];
  entityId?: string;
  imageUrl?: string;
  data?: Record<string, string>;
}

/**
 * Cloud Function déclenchée lors de la création d'une notification
 * dans la collection Firestore 'notifications'.
 * Envoie des push notifications FCM aux utilisateurs ciblés.
 */
export const sendPushNotification = functions
  .region("europe-west1")
  .firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const notification = snapshot.data() as NotificationData;
    const notificationId = context.params.notificationId;

    functions.logger.info(`📬 Nouvelle notification: ${notificationId}`, notification);

    try {
      // Récupérer les tokens FCM selon la cible
      const tokens = await getTargetTokens(notification);

      if (tokens.length === 0) {
        functions.logger.warn("⚠️ Aucun token FCM trouvé pour cette notification");
        return;
      }

      functions.logger.info(`📱 Envoi à ${tokens.length} appareil(s)`);

      // Préparer le message FCM
      const message: admin.messaging.MulticastMessage = {
        tokens: tokens,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl,
        },
        data: {
          notificationId: notificationId,
          type: notification.type || "general",
          entityId: notification.entityId || "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          ...notification.data,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "pharrell_phone_channel",
            icon: "ic_notification",
            color: "#9B6DB8",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        webpush: {
          notification: {
            icon: "/icons/Icon-192.png",
            badge: "/icons/Icon-192.png",
          },
          fcmOptions: {
            link: getNotificationLink(notification),
          },
        },
      };

      // Envoyer les notifications
      const response = await messaging.sendEachForMulticast(message);

      functions.logger.info(
        `✅ Notifications envoyées: ${response.successCount} succès, ${response.failureCount} échecs`
      );

      // Nettoyer les tokens invalides
      if (response.failureCount > 0) {
        await cleanupInvalidTokens(tokens, response.responses);
      }

      // Mettre à jour le statut de la notification
      await snapshot.ref.update({
        pushSent: true,
        pushSentAt: admin.firestore.FieldValue.serverTimestamp(),
        pushSuccessCount: response.successCount,
        pushFailureCount: response.failureCount,
      });
    } catch (error) {
      functions.logger.error("❌ Erreur envoi notification:", error);
      await snapshot.ref.update({
        pushSent: false,
        pushError: String(error),
      });
    }
  });

/**
 * Récupère les tokens FCM des utilisateurs ciblés par la notification
 */
async function getTargetTokens(notification: NotificationData): Promise<string[]> {
  const tokens: string[] = [];

  const targetType = notification.targetType || "all";

  if (targetType === "all") {
    // Récupérer tous les tokens de tous les utilisateurs
    const usersSnapshot = await db.collection("users")
      .where("fcmTokens", "!=", null)
      .get();

    usersSnapshot.forEach((doc) => {
      const userTokens = doc.data().fcmTokens as string[] | undefined;
      if (userTokens && Array.isArray(userTokens)) {
        tokens.push(...userTokens);
      }
    });
  } else if (targetType === "specific" && notification.targetUserIds) {
    // Récupérer les tokens des utilisateurs spécifiques
    for (const userId of notification.targetUserIds) {
      const userDoc = await db.collection("users").doc(userId).get();
      if (userDoc.exists) {
        const userTokens = userDoc.data()?.fcmTokens as string[] | undefined;
        if (userTokens && Array.isArray(userTokens)) {
          tokens.push(...userTokens);
        }
      }
    }
  } else if (targetType === "clients") {
    // Récupérer tous les tokens des clients
    const clientsSnapshot = await db.collection("users")
      .where("role", "in", ["client", "visitor"])
      .get();

    clientsSnapshot.forEach((doc) => {
      const userTokens = doc.data().fcmTokens as string[] | undefined;
      if (userTokens && Array.isArray(userTokens)) {
        tokens.push(...userTokens);
      }
    });
  } else if (targetType === "admins") {
    // Récupérer tous les tokens des admins
    const adminsSnapshot = await db.collection("users")
      .where("role", "in", ["admin", "manager"])
      .get();

    adminsSnapshot.forEach((doc) => {
      const userTokens = doc.data().fcmTokens as string[] | undefined;
      if (userTokens && Array.isArray(userTokens)) {
        tokens.push(...userTokens);
      }
    });
  }

  // Dédupliquer les tokens
  return [...new Set(tokens)];
}

/**
 * Génère le lien de redirection pour la notification web
 */
function getNotificationLink(notification: NotificationData): string {
  const baseUrl = "https://pharrellphone.com";

  switch (notification.type) {
  case "product":
    return notification.entityId ? `${baseUrl}/product/${notification.entityId}` : baseUrl;
  case "order":
    return `${baseUrl}/my-orders`;
  case "promotion":
    return `${baseUrl}/products`;
  default:
    return baseUrl;
  }
}

/**
 * Supprime les tokens FCM invalides de Firestore
 */
async function cleanupInvalidTokens(
  tokens: string[],
  responses: admin.messaging.SendResponse[]
): Promise<void> {
  const invalidTokens: string[] = [];

  responses.forEach((response, index) => {
    if (!response.success) {
      const error = response.error;
      // Codes d'erreur indiquant un token invalide
      if (
        error?.code === "messaging/invalid-registration-token" ||
        error?.code === "messaging/registration-token-not-registered"
      ) {
        invalidTokens.push(tokens[index]);
      }
    }
  });

  if (invalidTokens.length === 0) return;

  functions.logger.info(`🧹 Nettoyage de ${invalidTokens.length} token(s) invalide(s)`);

  // Trouver les utilisateurs avec ces tokens et les supprimer
  const usersSnapshot = await db.collection("users").get();

  const batch = db.batch();
  let batchCount = 0;

  usersSnapshot.forEach((doc) => {
    const userTokens = doc.data().fcmTokens as string[] | undefined;
    if (userTokens && Array.isArray(userTokens)) {
      const tokensToRemove = userTokens.filter((t) => invalidTokens.includes(t));
      if (tokensToRemove.length > 0) {
        batch.update(doc.ref, {
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
        });
        batchCount++;
      }
    }
  });

  if (batchCount > 0) {
    await batch.commit();
    functions.logger.info(`✅ ${batchCount} document(s) utilisateur mis à jour`);
  }
}

/**
 * Cloud Function pour envoyer une notification à un topic FCM
 * Utile pour les promotions et annonces générales
 */
export const sendTopicNotification = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    // Vérifier l'authentification admin
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentification requise");
    }

    const userDoc = await db.collection("users").doc(context.auth.uid).get();
    const userRole = userDoc.data()?.role;

    if (!["admin", "manager"].includes(userRole)) {
      throw new functions.https.HttpsError("permission-denied", "Accès admin requis");
    }

    const {topic, title, body, imageUrl, type, entityId} = data;

    if (!topic || !title || !body) {
      throw new functions.https.HttpsError("invalid-argument", "topic, title et body sont requis");
    }

    try {
      const message: admin.messaging.Message = {
        topic: topic,
        notification: {
          title: title,
          body: body,
          imageUrl: imageUrl,
        },
        data: {
          type: type || "general",
          entityId: entityId || "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      };

      const response = await messaging.send(message);

      functions.logger.info(`✅ Notification topic envoyée: ${response}`);

      return {success: true, messageId: response};
    } catch (error) {
      functions.logger.error("❌ Erreur envoi topic:", error);
      throw new functions.https.HttpsError("internal", String(error));
    }
  });
