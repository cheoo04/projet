# Firebase Cloud Functions - Pharrell Phone

## Description

Cloud Functions pour l'application Pharrell Phone. Ces fonctions gèrent l'envoi de push notifications FCM.

## Fonctions disponibles

### `sendPushNotification`
**Trigger**: Création de document dans `notifications` collection

Envoie des push notifications FCM aux utilisateurs ciblés quand une notification est créée dans Firestore.

**Champs attendus dans le document:**
```json
{
  "title": "Titre de la notification",
  "body": "Message de la notification",
  "type": "info|promotion|order|stock|...",
  "targetType": "all|clients|admins|specific",
  "targetUserIds": ["uid1", "uid2"], // Si targetType = "specific"
  "entityId": "product123", // Optionnel
  "imageUrl": "https://...", // Optionnel
  "data": {} // Données additionnelles
}
```

### `sendTopicNotification`
**Trigger**: HTTPS Callable

Permet d'envoyer une notification à un topic FCM. Nécessite une authentification admin.

## Installation

```bash
cd functions
npm install
```

## Développement local

```bash
# Compiler TypeScript
npm run build

# Lancer l'émulateur
npm run serve
```

## Déploiement

```bash
# Déployer les fonctions
npm run deploy

# Ou depuis la racine du projet
firebase deploy --only functions
```

## Configuration

Les fonctions utilisent la région `europe-west1` (Belgique) pour minimiser la latence.

## Logs

```bash
firebase functions:log
```
