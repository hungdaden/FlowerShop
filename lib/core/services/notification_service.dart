import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Requests notification permission and retrieves the browser FCM Token.
  Future<void> initNotifications({String? conversationId}) async {
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('FCM: Quyền thông báo đã được cho phép.');
        String? token = await _fcm.getToken(
          vapidKey: "BI3jocSRLjO06h8S_WUUy-DDsENyw5quSRC7YiS7E-UZ11DCtfaolzs-powxcvzR2d9l49AkaXt-GzDJqNDniuk",
        );

        if (token != null && conversationId != null) {
          await saveUserToken(conversationId, token);
          print('FCM: Đồng bộ Token thành công cho cuộc trò chuyện: $conversationId');
        } else {
          print('FCM: Không thể lấy token hoặc thiếu conversationId.');
        }
      } else {
        print('FCM: Quyền thông báo hiện tại: ${settings.authorizationStatus}');
      }
    } catch (e) {
      print('FCM ERROR during initNotifications: $e');
    }
  }

  /// Saves the guest user's FCM token to Firestore
  Future<void> saveUserToken(String conversationId, String token) async {
    try {
      await _db.collection('conversation_metadata').doc(conversationId).set({
        'userToken': token,
      }, SetOptions(merge: true));
      print('FCM: Đã lưu Token vào Firestore thành công.');
    } catch (e) {
      print('FCM ERROR during saveUserToken: $e');
    }
  }

  /// Silently refresh FCM token at app startup (only when permission already granted).
  /// Does NOT request permission — just gets a fresh token and saves it.
  Future<void> silentTokenRefresh(String conversationId) async {
    try {
      final settings = await _fcm.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await _fcm.getToken(
          vapidKey: "BI3jocSRLjO06h8S_WUUy-DDsENyw5quSRC7YiS7E-UZ11DCtfaolzs-powxcvzR2d9l49AkaXt-GzDJqNDniuk",
        );
        if (token != null) {
          await saveUserToken(conversationId, token);
          print('FCM: Silent token refresh thành công.');
        }
      }
    } catch (e) {
      print('FCM: Silent token refresh bỏ qua (có thể chưa cấp quyền): $e');
    }
  }

  /// Listen for FCM token changes and auto-update Firestore.
  /// Call once at app startup. When browser rotates the token, Firestore stays in sync.
  void listenForTokenRefresh(String conversationId) {
    _fcm.onTokenRefresh.listen((newToken) async {
      print('FCM: Token đã được refresh tự động.');
      await saveUserToken(conversationId, newToken);
    }).onError((error) {
      print('FCM: Token refresh listener error: $error');
    });
  }

  /// Saves/appends the admin's FCM token to their device list
  Future<void> saveAdminToken(String adminUid, String token) async {
    try {
      final docRef = _db.collection('admins').doc(adminUid);
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          final data = snapshot.data();
          List<dynamic> tokens = data?['fcmTokens'] ?? [];
          if (!tokens.contains(token)) {
            tokens.add(token);
            transaction.update(docRef, {'fcmTokens': tokens});
          }
        } else {
          transaction.set(docRef, {
            'fcmTokens': [token],
          });
        }
      });
    } catch (e) {
      print('FCM ERROR during saveAdminToken: $e');
    }
  }

  // Cache variables for Google OAuth2 access token
  static String? _cachedAccessToken;
  static DateTime? _tokenExpiry;

  /// Retrieves a Google OAuth2 access token using the service account credentials fetched from Firestore.
  Future<String?> _getAccessToken(Map<String, dynamic> config) async {
    if (_cachedAccessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedAccessToken;
    }

    final projectId = config['projectId'] ?? '';
    final clientEmail = config['clientEmail'] ?? '';
    final rawPrivateKey = config['privateKey'] ?? '';
    final privateKey = rawPrivateKey.replaceAll(r'\n', '\n').trim();

    if (projectId.isEmpty || clientEmail.isEmpty || privateKey.isEmpty) {
      return null;
    }

    try {
      final jwt = JWT(
        {
          'iss': clientEmail,
          'scope': 'https://www.googleapis.com/auth/firebase.messaging',
          'aud': 'https://oauth2.googleapis.com/token',
          'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
      );

      final rsaKey = RSAPrivateKey(privateKey);
      final token = jwt.sign(rsaKey, algorithm: JWTAlgorithm.RS256);

      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': token,
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _cachedAccessToken = body['access_token'];
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));
        return _cachedAccessToken;
      }
      print('FCM ERROR during OAuth token exchange: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('FCM ERROR during JWT sign: $e');
      return null;
    }
  }

  /// General method to send a push notification using FCM HTTP v1 API.
  /// Returns [true] if successful, and [false] if the token is invalid/unregistered.
  Future<bool> sendPushNotification({
    required String targetToken,
    required String title,
    required String body,
  }) async {
    try {
      // Fetch FCM configuration from Firestore
      final configDoc = await _db.collection('conversation_metadata').doc('fcm_config').get();
      final config = configDoc.data();
      if (config == null) {
        return true; // Don't delete token on config error
      }

      final accessToken = await _getAccessToken(config);
      if (accessToken == null) {
        return true; // Don't delete token on auth error
      }

      final projectId = config['projectId'] ?? '';

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': targetToken,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
            'webpush': {
              'notification': {
                'icon': '/icons/Icon-192.png',
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('FCM ERROR: HTTP v1 send failed: ${response.body}');
        final isUnregistered = response.statusCode == 404 || response.body.contains('UNREGISTERED');
        if (isUnregistered) {
          return false; // Signal caller to delete/cleanup this invalid token
        }
        return true; // Other errors (e.g. rate limit, server error), keep token
      }
    } catch (e) {
      print('FCM ERROR during sendPushNotification HTTP POST: $e');
      return true;
    }
  }

  /// Sends a push notification to all registered admin devices and cleans up expired tokens
  Future<void> sendNotificationToAdmin({
    required String title,
    required String body,
  }) async {
    try {
      final snapshot = await _db.collection('admins').get();
      
      for (final doc in snapshot.docs) {
        final List<dynamic> tokens = doc.data()['fcmTokens'] ?? [];
        final List<String> validTokens = [];
        bool hasExpiredTokens = false;

        for (final t in tokens) {
          if (t is String && t.isNotEmpty) {
            final isValid = await sendPushNotification(
              targetToken: t,
              title: title,
              body: body,
            );
            if (isValid) {
              validTokens.add(t);
            } else {
              hasExpiredTokens = true;
            }
          }
        }

        if (hasExpiredTokens) {
          await doc.reference.update({'fcmTokens': validTokens});
        }
      }
    } catch (e) {
      print('FCM ERROR during sendNotificationToAdmin: $e');
    }
  }

  /// Sends a push notification to a specific guest user and cleans up if expired
  Future<void> sendNotificationToUser({
    required String conversationId,
    required String title,
    required String body,
  }) async {
    try {
      final docRef = _db.collection('conversation_metadata').doc(conversationId);
      final doc = await docRef.get();
      final userToken = doc.data()?['userToken'] ?? '';
      
      if (userToken.isNotEmpty) {
        final isValid = await sendPushNotification(
          targetToken: userToken,
          title: title,
          body: body,
        );
        if (!isValid) {
          await docRef.update({
            'userToken': FieldValue.delete(),
          });
        }
      }
    } catch (e) {
      print('FCM ERROR during sendNotificationToUser: $e');
    }
  }
}
