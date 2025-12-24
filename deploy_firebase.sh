#!/bin/bash

# Script de déploiement Firebase pour Pharrell Phone
# Ce script déploie les configurations Firebase (Firestore rules, indexes, etc.)

set -e  # Arrêter en cas d'erreur

echo "🚀 Déploiement Firebase - Pharrell Phone"
echo "========================================"
echo ""

# Charger nvm si disponible
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "📦 Chargement de nvm..."
    . "$NVM_DIR/nvm.sh"
    nvm use 20 &> /dev/null || echo "⚠️  Node.js v20 non trouvé, utilisation de la version par défaut"
fi

# Vérifier que Firebase CLI est installé
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI n'est pas installé"
    echo "   Installez-le avec:"
    echo "   1. Charger nvm: source ~/.nvm/nvm.sh"
    echo "   2. Installer Firebase: npm install -g firebase-tools"
    exit 1
fi

echo "✅ Firebase CLI détecté"
echo ""

# Vérifier l'authentification Firebase
echo "🔐 Vérification de l'authentification..."
if ! firebase projects:list &> /dev/null; then
    echo "❌ Non authentifié. Exécutez: firebase login"
    exit 1
fi

echo "✅ Authentifié"
echo ""

# Afficher le projet actuel
PROJECT=$(firebase use)
echo "📱 Projet Firebase: $PROJECT"
echo ""

# Demander confirmation
read -p "Voulez-vous déployer sur ce projet ? (o/y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
    echo "❌ Déploiement annulé"
    exit 0
fi

echo ""
echo "📦 Déploiement des configurations Firebase..."
echo ""

# Déployer les rules Firestore
echo "1️⃣ Déploiement des règles Firestore..."
if firebase deploy --only firestore:rules; then
    echo "   ✅ Règles Firestore déployées"
else
    echo "   ❌ Erreur lors du déploiement des règles"
    exit 1
fi
echo ""

# Déployer les indexes Firestore
echo "2️⃣ Déploiement des indexes Firestore..."
if firebase deploy --only firestore:indexes; then
    echo "   ✅ Indexes Firestore déployés"
    echo "   ⏳ Note: La création des indexes peut prendre quelques minutes"
else
    echo "   ⚠️  Avertissement lors du déploiement des indexes"
    echo "   Vérifiez manuellement dans la console Firebase"
fi
echo ""

# Déployer les règles Storage (si présentes)
if [ -f "storage.rules" ]; then
    echo "3️⃣ Déploiement des règles Storage..."
    if firebase deploy --only storage; then
        echo "   ✅ Règles Storage déployées"
    else
        echo "   ⚠️  Avertissement lors du déploiement des règles Storage"
    fi
    echo ""
fi

echo "========================================"
echo "✅ Déploiement terminé avec succès!"
echo ""
echo "📊 Vérifications recommandées:"
echo "   1. Console Firebase: https://console.firebase.google.com"
echo "   2. Vérifier l'état des indexes (section Firestore)"
echo "   3. Tester l'application en mode release"
echo ""
echo "🎯 Prochaines étapes:"
echo "   - Tester les requêtes Firestore complexes"
echo "   - Monitorer les performances dans la console"
echo "   - Vérifier les règles de sécurité"
echo ""
