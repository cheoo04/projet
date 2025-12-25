# Pharrell Phone - API Notifications Vercel

API serverless gratuite pour envoyer des notifications push FCM.

## 🚀 Déploiement (5 minutes)

### Étape 1 : Créer un compte Vercel
1. Va sur [vercel.com](https://vercel.com)
2. Clique **"Sign Up"** → connecte-toi avec GitHub
3. **Aucune carte bancaire requise**

### Étape 2 : Obtenir la clé Firebase
1. Va sur [Firebase Console > Paramètres > Comptes de service](https://console.firebase.google.com/project/first-pro-cheoo/settings/serviceaccounts/adminsdk)
2. Clique **"Générer une nouvelle clé privée"**
3. Télécharge le fichier JSON (garde-le secret !)

### Étape 3 : Déployer
```bash
# Installer Vercel CLI
npm install -g vercel

# Se connecter
vercel login

# Déployer
cd vercel-notifications
vercel

# Suivre les instructions :
# - "Set up and deploy?" → Yes
# - "Which scope?" → Ton compte
# - "Link to existing project?" → No
# - "Project name?" → pharrell-phone-notifications
# - "Directory?" → ./
```

### Étape 4 : Configurer la variable d'environnement
1. Va sur [Vercel Dashboard](https://vercel.com/dashboard)
2. Clique sur ton projet **pharrell-phone-notifications**
3. Va dans **Settings** → **Environment Variables**
4. Ajoute :
   - **Name:** `FIREBASE_SERVICE_ACCOUNT_KEY`
   - **Value:** Colle le contenu ENTIER du fichier JSON téléchargé
5. Clique **Save**

### Étape 5 : Redéployer
```bash
vercel --prod
```

## ✅ C'est prêt !

Ton URL sera : `https://pharrell-phone-notifications.vercel.app/api/send-notification`

## 📡 Test avec curl

```bash
# Remplace <TOKEN> par ton token Firebase (récupéré depuis l'app)
curl -X POST https://pharrell-phone-notifications.vercel.app/api/send-notification \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{"title": "Test", "body": "Ceci est un test !"}'
```

## 🔒 Sécurité

- Seuls les admins/managers peuvent envoyer des notifications
- Le token Firebase est vérifié à chaque requête
- Les envois sont loggés dans Firestore (`notifications_log`)

## 💰 Coût

**GRATUIT** avec le plan Hobby de Vercel :
- 100 000 invocations/mois
- Largement suffisant pour des notifications occasionnelles
