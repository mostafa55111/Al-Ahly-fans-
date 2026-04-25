import 'dart:typed_data';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Remote Data Source
/// Centralizes all Firebase operations
class FirebaseRemoteDataSource {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Database Operations
  Future<DataSnapshot> getData(String path) async {
    return await _database.ref(path).get();
  }

  Future<void> setData(String path, Map<String, dynamic> data) async {
    await _database.ref(path).set(data);
  }

  Future<void> updateData(String path, Map<String, dynamic> data) async {
    await _database.ref(path).update(data);
  }

  Future<void> deleteData(String path) async {
    await _database.ref(path).remove();
  }

  Stream<DatabaseEvent> getDataStream(String path) {
    return _database.ref(path).onValue;
  }

  // Firestore Operations
  Future<firestore.DocumentSnapshot> getDocument(String collection, String docId) async {
    return await _firestore.collection(collection).doc(docId).get();
  }

  Future<firestore.QuerySnapshot> getCollection(String collection, {
    firestore.Query? query,
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    firestore.Query q = _firestore.collection(collection);
    
    if (query != null) q = query;
    if (limit != null) q = q.limit(limit);
    if (orderBy != null) q = q.orderBy(orderBy, descending: descending);
    
    return await q.get();
  }

  Future<void> setDocument(String collection, String docId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(docId).set(data);
  }

  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }

  Future<void> deleteDocument(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  Stream<firestore.DocumentSnapshot> getDocumentStream(String collection, String docId) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  Stream<firestore.QuerySnapshot> getCollectionStream(String collection, {
    firestore.Query? query,
    int? limit,
    String? orderBy,
    bool descending = false,
  }) {
    firestore.Query q = _firestore.collection(collection);
    
    if (query != null) q = query;
    if (limit != null) q = q.limit(limit);
    if (orderBy != null) q = q.orderBy(orderBy, descending: descending);
    
    return q.snapshots();
  }

  // Storage Operations
  Future<String> uploadFile(String path, Uint8List fileData, String contentType) async {
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putData(fileData, SettableMetadata(contentType: contentType));
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadFileFromPath(String path, File file, String contentType) async {
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(file, SettableMetadata(contentType: contentType));
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deleteFile(String path) async {
    await _storage.ref().child(path).delete();
  }

  // Auth Helper
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isUserLoggedIn => _auth.currentUser != null;
}
