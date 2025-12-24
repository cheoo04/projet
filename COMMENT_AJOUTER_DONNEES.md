# 📊 Guide: Comment Ajouter des Données dans Firestore

## 🎯 Objectif
Votre application Pharrell Phone est prête, mais Firestore est vide. Ce guide vous montre comment ajouter facilement des produits et catégories.

---

## 🚀 Méthode 1: Utiliser l'Écran de Gestion (RECOMMANDÉ)

### Étapes:

1. **Lancez l'application**
   ```bash
   flutter run
   ```

2. **Accédez au Dashboard Admin**
   - Sur l'écran d'accueil, appuyez sur "Admin" dans la bottom bar
   - OU naviguez vers `/admin`

3. **Cliquez sur "Peupler DB"**
   - Dans les "Actions rapides", cherchez le bouton bleu "Peupler DB"
   - Cliquez dessus

4. **Ajoutez les données**
   - Cliquez sur "Ajouter les Données"
   - Attendez quelques secondes
   - ✅ Terminé! Vous verrez un message de succès

### Ce qui est ajouté:

#### 📦 **4 Catégories:**
- 📱 Smartphones
- 🎧 Accessoires  
- 📲 Tablettes
- 💻 Ordinateurs

#### 📱 **10 Produits:**

**Smartphones:**
- iPhone 15 Pro Max (1,250,000 FCFA)
- Samsung Galaxy S24 Ultra (1,100,000 FCFA)
- Google Pixel 8 Pro (850,000 FCFA)
- iPhone 14 (850,000 FCFA) - En rupture de stock

**Accessoires:**
- AirPods Pro 2 (280,000 FCFA)
- Galaxy Buds2 Pro (180,000 FCFA)
- Chargeur MagSafe (45,000 FCFA)

**Tablettes:**
- iPad Pro 13" M4 (1,400,000 FCFA)
- Galaxy Tab S9 Ultra (1,200,000 FCFA)

**Ordinateurs:**
- MacBook Pro 14" M3 Pro (2,200,000 FCFA)

---

## 🔧 Méthode 2: Via la Console Firebase (Manuelle)

### Étapes:

1. **Ouvrez Firebase Console**
   - Allez sur https://console.firebase.google.com
   - Sélectionnez votre projet "First-pro-cheoo"
   - Cliquez sur "Firestore Database"

2. **Créez la collection "products"**
   - Cliquez sur "Commencer une collection"
   - Nom: `products`
   - Cliquez sur "Suivant"

3. **Ajoutez un document produit**
   
   **ID du document:** `prod_iphone15pro`
   
   **Champs:**
   ```
   brand: "Apple"
   category: "Smartphones"
   categoryId: "cat_smartphones"
   createdAt: [timestamp]
   description: "Le dernier iPhone Pro Max avec puce A17 Pro..."
   id: "prod_iphone15pro"
   imageUrls: ["https://via.placeholder.com/600x600"]
   isInStock: true
   name: "iPhone 15 Pro Max"
   price: 1250000
   specs: {
     "Écran": "6.7 Super Retina XDR",
     "Processeur": "A17 Pro",
     "Mémoire": "256 GB"
   }
   specifications: {
     "Écran": "6.7 Super Retina XDR",
     "Processeur": "A17 Pro"
   }
   stock: 5
   supplierReference: "APL-IP15PM-256"
   ```

4. **Répétez pour d'autres produits**

---

## 📸 Comment Ajouter des Images?

### Option 1: URLs Placeholder (Temporaire)
```dart
imageUrls: ['https://via.placeholder.com/600x600/9B6DB8/FFFFFF?text=iPhone'],
```

### Option 2: Firebase Storage (Recommandé pour production)

1. **Uploadez vos images dans Firebase Storage:**
   - Console Firebase > Storage
   - Créez un dossier `products/`
   - Uploadez vos images

2. **Récupérez les URLs:**
   - Clic droit sur l'image > "Obtenir l'URL de téléchargement"
   - Copiez l'URL

3. **Utilisez l'URL dans votre produit:**
   ```dart
   imageUrls: [
     'https://firebasestorage.googleapis.com/v0/b/votre-projet.appspot.com/o/products%2Fiphone.jpg?alt=media&token=...',
   ],
   ```

---

## ✅ Vérifier que ça Fonctionne

Après avoir ajouté des données:

1. **Redémarrez l'app** (hot restart)
   ```bash
   # Appuyez sur 'R' dans le terminal
   # OU
   flutter run
   ```

2. **Naviguez vers le Catalogue**
   - Les produits devraient s'afficher
   - Si vide, vérifiez la console pour les erreurs

3. **Vérifiez dans Firebase Console**
   - Allez dans Firestore Database
   - Vous devriez voir:
     - Collection `products` avec 10 documents
     - Collection `categories` avec 4 documents

---

## 🗑️ Supprimer Toutes les Données

Si vous voulez repartir à zéro:

1. **Via l'app:**
   - Écran de gestion des données
   - Bouton "Tout Supprimer"
   - ⚠️ Confirmez (irréversible!)

2. **Via Firebase Console:**
   - Sélectionnez la collection `products`
   - Cliquez sur les 3 points > "Supprimer la collection"
   - Répétez pour `categories`

---

## ❓ FAQ

### Q: Les images ne s'affichent pas
**R:** Les URLs placeholder fonctionnent, mais peuvent être lentes. Utilisez Firebase Storage pour de vraies images.

### Q: J'ai une erreur "Permission denied"
**R:** Vérifiez vos règles Firestore dans `firestore.rules`:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Lecture publique, écriture authentifiée
    match /{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### Q: Les produits n'apparaissent pas
**R:** 
1. Vérifiez la console: `flutter run -v`
2. Assurez-vous que Firebase est initialisé
3. Vérifiez que les collections existent dans Firebase Console

### Q: Comment modifier un produit existant?
**R:** 
- **Via l'app**: Utilisez l'écran de gestion des produits (bientôt disponible)
- **Via Firebase Console**: Cliquez sur le document > Modifiez les champs

---

## 🎯 Prochaines Étapes

Une fois les données ajoutées:

1. ✅ Testez le catalogue
2. ✅ Testez la recherche
3. ✅ Testez le panier
4. ✅ Testez le détail produit
5. 🔄 Ajoutez vos propres produits
6. 📸 Uploadez de vraies images
7. 🚀 Déployez en production

---

## 📞 Besoin d'Aide?

**WhatsApp:** 0788711896  
**Slogan:** "Qualité supérieure/satisfaction garantie"

---

**Date:** 20 Décembre 2025
