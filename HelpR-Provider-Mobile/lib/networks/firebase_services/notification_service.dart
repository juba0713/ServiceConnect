import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../main.dart';
import '../../models/user_data.dart';

class NotificationService {
  Future<void> sendPushNotifications(String title, String content, {String? image, required UserData receiverUser, required UserData senderUserData}) async {
    Map<String, dynamic> data = senderUserData.toJson();

    /*if (email.validate().isNotEmpty) {
      */ /*data.putIfAbsent("email", () => email);
      data.putIfAbsent("sender_uid", () => uid);
      data.putIfAbsent("receiver_uid", () => receiverPlayerId);*/ /*
    }*/

    data.putIfAbsent("is_chat", () => true);

    Map req = {
      'to': "/topics/user_${receiverUser.id.validate()}",
      "collapse_key": "type_a",
      "notification": {
        "body": content,
        "title": "$title sent you a message", //TODO translate
      },
      'data': data,
    };

    log(req);
    var header = {
      HttpHeaders.authorizationHeader: 'key=${appConfigurationStore.firebaseServerKey.validate()}',
      HttpHeaders.contentTypeHeader: 'application/json',
    };

    Response res = await post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      body: jsonEncode(req),
      headers: header,
    );

    log(res.statusCode);
    log(res.body);

    if (res.statusCode.isSuccessful()) {
    } else {
      throw errorSomethingWentWrong;
    }
  }
}
