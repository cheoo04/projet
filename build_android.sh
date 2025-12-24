#!/bin/bash

# 🚀 Script de build optimisé pour Android - Pharrell Phone
# Usage: ./build_android.sh

set -e

echo "🚀 ========================================"
echo "   BUILD ANDROID - PHARRELL PHONE"
echo "=========================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Nettoyage
echo -e "${BLUE}📦 Étape 1: Nettoyage...${NC}"
flutter clean
echo -e "${GREEN}✅ Nettoyage terminé${NC}"
echo ""

# 2. Dépendances
echo -e "${BLUE}📦 Étape 2: Installation des dépendances...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dépendances installées${NC}"
echo ""

# 3. Vérification
echo -e "${BLUE}🔍 Étape 3: Vérification du code...${NC}"
flutter analyze
echo -e "${GREEN}✅ Code vérifié${NC}"
echo ""

# 4. Tests (optionnel)
echo -e "${BLUE}🧪 Étape 4: Tests...${NC}"
# flutter test
echo -e "${YELLOW}⏭️  Tests ignorés (décommenter si nécessaire)${NC}"
echo ""

# 5. Build APK optimisé
echo -e "${BLUE}🏗️  Étape 5: Build APK release...${NC}"
flutter build apk --release --split-per-abi --shrink --obfuscate --split-debug-info=./debug-info
echo -e "${GREEN}✅ APK créé avec succès${NC}"
echo ""

# 6. Informations
echo -e "${BLUE}📊 Étape 6: Analyse de la taille...${NC}"
flutter build apk --analyze-size --target-platform android-arm64
echo ""

# 7. Localisation des fichiers
echo -e "${GREEN}=========================================="
echo "✅ BUILD TERMINÉ"
echo "==========================================${NC}"
echo ""
echo "📱 Fichiers APK générés dans:"
echo "   build/app/outputs/flutter-apk/"
echo ""
echo "   - app-armeabi-v7a-release.apk  (32-bit)"
echo "   - app-arm64-v8a-release.apk    (64-bit - recommandé)"
echo "   - app-x86_64-release.apk       (émulateurs)"
echo ""
echo -e "${YELLOW}💡 Pour installer sur votre téléphone:${NC}"
echo "   adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
echo ""
echo -e "${YELLOW}💡 Pour Google Play Store, utilisez:${NC}"
echo "   flutter build appbundle --release"
echo ""

# 8. Ouvrir le dossier (optionnel)
read -p "Voulez-vous ouvrir le dossier des APK ? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    xdg-open build/app/outputs/flutter-apk/ 2>/dev/null || open build/app/outputs/flutter-apk/ 2>/dev/null || explorer build/app/outputs/flutter-apk/ 2>/dev/null
fi

echo -e "${GREEN}🎉 Prêt pour le déploiement !${NC}"
