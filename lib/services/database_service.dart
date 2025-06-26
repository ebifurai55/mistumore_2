import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../models/quote_model.dart';
import '../models/user_model.dart';
import '../models/contract_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Users collection
  CollectionReference get _usersCollection => _firestore.collection('users');
  
  // Requests collection
  CollectionReference get _requestsCollection => _firestore.collection('requests');
  
  // Quotes collection
  CollectionReference get _quotesCollection => _firestore.collection('quotes');
  
  // Contracts collection
  CollectionReference get _contractsCollection => _firestore.collection('contracts');

  // ===== USER OPERATIONS =====
  
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).update(
        user.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw e;
    }
  }

  Stream<List<UserModel>> getProfessionalsByCategory(ServiceCategory category) {
    return _usersCollection
        .where('userType', isEqualTo: 'professional')
        .where('skills', arrayContains: category.toString().split('.').last)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ===== REQUEST OPERATIONS =====
  
  Future<String> createRequest(RequestModel request) async {
    try {
      final docRef = await _requestsCollection.add(request.toMap());
      
      // Update the request with the generated ID
      final updatedRequest = request.copyWith(id: docRef.id);
      await docRef.update(updatedRequest.toMap());
      
      return docRef.id;
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateRequest(RequestModel request) async {
    try {
      await _requestsCollection.doc(request.id).update(
        request.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteRequest(String requestId) async {
    try {
      await _requestsCollection.doc(requestId).delete();
    } catch (e) {
      throw e;
    }
  }

  Future<void> cancelRequest(String requestId, String cancellationReason) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Update request status to cancelled
        final requestRef = _requestsCollection.doc(requestId);
        transaction.update(requestRef, {
          'status': 'cancelled',
          'cancellationReason': cancellationReason,
          'cancelledAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Cancel all pending quotes for this request
        final quotesSnapshot = await _quotesCollection
            .where('requestId', isEqualTo: requestId)
            .where('status', isEqualTo: 'pending')
            .get();

        for (final doc in quotesSnapshot.docs) {
          transaction.update(doc.reference, {
            'status': 'cancelled',
            'cancellationReason': 'Request was cancelled by client',
            'cancelledAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      });
    } catch (e) {
      throw e;
    }
  }

  Future<RequestModel?> getRequest(String requestId) async {
    try {
      final doc = await _requestsCollection.doc(requestId).get();
      if (doc.exists) {
        return RequestModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw e;
    }
  }

  Stream<List<RequestModel>> getRequestsByClient(String clientId) {
    return _requestsCollection
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<RequestModel>> getOpenRequests({ServiceCategory? category}) {
    Query query = _requestsCollection.where('status', isEqualTo: 'open');
    
    if (category != null) {
      query = query
          .where('category', isEqualTo: category.toString().split('.').last)
          .orderBy('createdAt', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }
    
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  // ===== QUOTE OPERATIONS =====
  
  Future<String> createQuote(QuoteModel quote) async {
    try {
      final docRef = await _quotesCollection.add(quote.toMap());
      
      // Update the quote with the generated ID
      final updatedQuote = quote.copyWith(id: docRef.id);
      await docRef.update(updatedQuote.toMap());
      
      // Update request status to 'quoted'
      final request = await getRequest(quote.requestId);
      if (request != null && request.status == RequestStatus.open) {
        await updateRequest(request.copyWith(status: RequestStatus.quoted));
      }
      
      return docRef.id;
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateQuote(QuoteModel quote) async {
    try {
      await _quotesCollection.doc(quote.id).update(
        quote.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteQuote(String quoteId) async {
    try {
      await _quotesCollection.doc(quoteId).delete();
    } catch (e) {
      throw e;
    }
  }

  Future<QuoteModel?> getQuote(String quoteId) async {
    try {
      final doc = await _quotesCollection.doc(quoteId).get();
      if (doc.exists) {
        return QuoteModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw e;
    }
  }

  Stream<List<QuoteModel>> getQuotesByRequest(String requestId) {
    return _quotesCollection
        .where('requestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuoteModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<QuoteModel>> getQuotesByProfessional(String professionalId) {
    return _quotesCollection
        .where('professionalId', isEqualTo: professionalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuoteModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<QuoteModel>> getQuotesForClient(String clientId) async* {
    // まず、クライアントの依頼を取得
    final requestsSnapshot = await _requestsCollection
        .where('clientId', isEqualTo: clientId)
        .get();
    
    final requestIds = requestsSnapshot.docs.map((doc) => doc.id).toList();
    
    if (requestIds.isEmpty) {
      yield [];
      return;
    }
    
    // 依頼IDのリストを使って見積もりを取得
    // Firestoreのin演算子は最大10個までなので、分割して処理
    List<QuoteModel> allQuotes = [];
    
    for (int i = 0; i < requestIds.length; i += 10) {
      final batchIds = requestIds.skip(i).take(10).toList();
      
      await for (final snapshot in _quotesCollection
          .where('requestId', whereIn: batchIds)
          .orderBy('createdAt', descending: true)
          .snapshots()) {
        final quotes = snapshot.docs
            .map((doc) => QuoteModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        
        // バッチごとの結果をマージ
        if (i == 0) {
          allQuotes = quotes;
        } else {
          // 重複を避けて追加
          for (final quote in quotes) {
            if (!allQuotes.any((q) => q.id == quote.id)) {
              allQuotes.add(quote);
            }
          }
          // 日付でソート
          allQuotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        
        yield allQuotes;
        break; // 最初のバッチのみ処理
      }
    }
  }

  Future<void> acceptQuote(String quoteId, String requestId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Update quote status to accepted
        final quoteRef = _quotesCollection.doc(quoteId);
        transaction.update(quoteRef, {
          'status': 'accepted',
          'acceptedAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Update request status and selected quote
        final requestRef = _requestsCollection.doc(requestId);
        transaction.update(requestRef, {
          'status': 'accepted',
          'selectedQuoteId': quoteId,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Reject other quotes for this request
        final otherQuotesSnapshot = await _quotesCollection
            .where('requestId', isEqualTo: requestId)
            .where('status', isEqualTo: 'pending')
            .get();

        for (final doc in otherQuotesSnapshot.docs) {
          if (doc.id != quoteId) {
            transaction.update(doc.reference, {
              'status': 'rejected',
              'rejectedAt': DateTime.now().toIso8601String(),
              'rejectionReason': 'Other quote was selected',
              'updatedAt': DateTime.now().toIso8601String(),
            });
          }
        }
      });
    } catch (e) {
      throw e;
    }
  }

  Future<void> rejectQuote(String quoteId, String reason) async {
    try {
      await _quotesCollection.doc(quoteId).update({
        'status': 'rejected',
        'rejectedAt': DateTime.now().toIso8601String(),
        'rejectionReason': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw e;
    }
  }

  // ===== CONTRACT OPERATIONS =====
  
  Future<String> createContract(ContractModel contract) async {
    try {
      final docRef = await _contractsCollection.add(contract.toMap());
      
      // Update the contract with the generated ID
      final updatedContract = contract.copyWith(id: docRef.id);
      await docRef.update(updatedContract.toMap());
      
      return docRef.id;
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateContract(ContractModel contract) async {
    try {
      await _contractsCollection.doc(contract.id).update(
        contract.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw e;
    }
  }

  Stream<List<ContractModel>> getContractsByUser(String userId, UserType userType) {
    final field = userType == UserType.client ? 'clientId' : 'professionalId';
    return _contractsCollection
        .where(field, isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContractModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<ContractModel?> getContract(String contractId) async {
    try {
      final doc = await _contractsCollection.doc(contractId).get();
      if (doc.exists) {
        return ContractModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw e;
    }
  }

  // ===== DASHBOARD DATA =====
  
  Future<Map<String, int>> getClientDashboardData(String clientId) async {
    try {
      final requestsSnapshot = await _requestsCollection
          .where('clientId', isEqualTo: clientId)
          .get();

      final requests = requestsSnapshot.docs
          .map((doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      final openRequests = requests.where((r) => r.status == RequestStatus.open).length;
      final quotedRequests = requests.where((r) => r.status == RequestStatus.quoted).length;
      final acceptedRequests = requests.where((r) => r.status == RequestStatus.accepted).length;
      final completedRequests = requests.where((r) => r.status == RequestStatus.completed).length;

      return {
        'total': requests.length,
        'open': openRequests,
        'quoted': quotedRequests,
        'accepted': acceptedRequests,
        'completed': completedRequests,
      };
    } catch (e) {
      throw e;
    }
  }

  Future<Map<String, int>> getProfessionalDashboardData(String professionalId) async {
    try {
      final quotesSnapshot = await _quotesCollection
          .where('professionalId', isEqualTo: professionalId)
          .get();

      final quotes = quotesSnapshot.docs
          .map((doc) => QuoteModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      final pendingQuotes = quotes.where((q) => q.status == QuoteStatus.pending).length;
      final acceptedQuotes = quotes.where((q) => q.status == QuoteStatus.accepted).length;
      final rejectedQuotes = quotes.where((q) => q.status == QuoteStatus.rejected).length;
      final completedQuotes = quotes.where((q) => q.status == QuoteStatus.completed).length;

      return {
        'total': quotes.length,
        'pending': pendingQuotes,
        'accepted': acceptedQuotes,
        'rejected': rejectedQuotes,
        'completed': completedQuotes,
      };
    } catch (e) {
      throw e;
    }
  }
} 