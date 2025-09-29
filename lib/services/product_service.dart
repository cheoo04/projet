import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final CollectionReference _col = FirebaseFirestore.instance.collection(
    'products',
  );

  Future<List<Product>> fetchAll() async {
    final snapshot = await _col.get();
    return snapshot.docs
        .map(
          (doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Future<void> add(Product p) async {
    await _col.doc(p.id).set(p.toMap());
  }

  Future<void> update(Product p) async {
    await _col.doc(p.id).update(p.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
