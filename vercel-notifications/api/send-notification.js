// API Vercel pour envoyer des notifications FCM
// Endpoint: POST /api/send-notification

const admin = require('firebase-admin');

// Initialiser Firebase Admin (une seule fois)
if (!admin.apps.length) {
  const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

module.exports = async (req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // Handle preflight
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Vérifier le token Firebase de l'admin
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Token manquant' });
    }

    const idToken = authHeader.split('Bearer ')[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const uid = decodedToken.uid;

    // Vérifier que l'utilisateur est admin
    const userDoc = await admin.firestore().collection('users').doc(uid).get();
    if (!userDoc.exists) {
      return res.status(403).json({ error: 'Utilisateur non trouvé' });
    }

    const userData = userDoc.data();
    if (userData.role !== 'admin' && userData.role !== 'manager') {
      return res.status(403).json({ error: 'Accès refusé - Admin requis' });
    }

    // Récupérer les données de la notification
    const { title, body, topic = 'all_users', data = {} } = req.body;

    if (!title || !body) {
      return res.status(400).json({ error: 'Titre et message requis' });
    }

    // Construire le message FCM
    const message = {
      topic: topic,
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        timestamp: new Date().toISOString(),
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'high_importance_channel',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
      webpush: {
        notification: {
          icon: '/icons/Icon-192.png',
          badge: '/icons/Icon-192.png',
        },
      },
    };

    // Envoyer la notification
    const response = await admin.messaging().send(message);

    // Logger dans Firestore (optionnel)
    await admin.firestore().collection('notifications_log').add({
      title,
      body,
      topic,
      sentBy: uid,
      sentByEmail: userData.email || decodedToken.email,
      messageId: response,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('✅ Notification envoyée:', response);
    return res.status(200).json({ 
      success: true, 
      messageId: response,
      message: `Notification envoyée au topic "${topic}"` 
    });

  } catch (error) {
    console.error('❌ Erreur:', error);
    return res.status(500).json({ 
      error: error.message,
      code: error.code || 'UNKNOWN_ERROR'
    });
  }
};
