import 'dart:async';
import 'dart:io';
import 'package:car_message/sendMessagePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:device_info/device_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mainPage.dart';

class ConfirmSendMessagePage extends StatefulWidget {
  final String message;
  ConfirmSendMessagePage(this.message);
  @override
  _ConfirmSendMessagePageState createState() => _ConfirmSendMessagePageState();
}

class _ConfirmSendMessagePageState extends State<ConfirmSendMessagePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // ステータスバーを透明にする
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    final double deviceWidth = MediaQuery.of(context).size.width; // デバイスの幅
    final double deviceHeight = MediaQuery.of(context).size.height; // デバイスの高さ
    final double topPadding = MediaQuery.of(context).padding.top; // 上の余白

    return Scaffold(
      body: Container(
        width: deviceWidth,
        height: deviceHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF353A40),
              Color(0xFF202326),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              alignment: Alignment.topLeft,
              padding: EdgeInsets.only(left: 20, top: 50),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Color(0xFFEAF1F6),
                      size: 27,
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Text(
                    "右の車に送る",
                    style: TextStyle(
                      fontSize: 23,
                      color: Color(0xFFEAF1F6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 50, top: 10),
              child: Row(
                children: [
                  Container(
                    color: Colors.white12,
                    height: 90,
                    width: 1.5,
                  ),
                  SizedBox(width: 15),
                  Image.asset(
                    'assets/mycar.png',
                    height: 80,
                  ),
                  SizedBox(width: 15),
                  Container(
                    color: Colors.white12,
                    height: 90,
                    width: 1.5,
                  ),
                  SizedBox(width: 30),
                  SvgPicture.asset(
                    "assets/car-top.svg",
                    color: Colors.lightBlue[200],
                    height: 120,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 25,
            ),
            buildMessageCard(widget.message),
            SizedBox(
              height: 50,
            ),
            Container(
              height: 70,
              width: 180,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white12,
                      blurRadius: 30,
                      offset: Offset(-7, -7),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1DA1EB),
                      Color(0xFF0A5A86),
                    ],
                  )),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.transparent,
                  shape: StadiumBorder(),
                  elevation: 0,
                ),
                child: Text(
                  "送信",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  sendMessage();
                  Navigator.of(context).pop(widget.message);
                },
              ),
            ),
            SizedBox(
              height: 30,
            ),
            Container(
              height: 70,
              width: 180,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white12,
                      blurRadius: 30,
                      offset: Offset(-7, -7),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF626D7B),
                      Color(0xFF3D444D),
                    ],
                  )),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.transparent,
                  shape: StadiumBorder(),
                  elevation: 0,
                ),
                child: Text(
                  "キャンセル",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    // fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMessageCard(String title) {
    return Container(
      width: 260,
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Color(0xFF333D48),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          getMessageIcon(title, 90),
        ],
      ),
    );
  }

  // Firebaseにメッセージを送信
  void sendMessage() async {
    // 現在時刻
    var now = DateTime.now();

    //　現在地
    var pos = await getCurrentLocation();
    double currentLat = pos.latitude;
    double currentLng = pos.longitude;

    // 固有ID
    var uniqueId = await getUniqueID();

    // 緯度経度から住所を取得
    Placemark placemark = await getAddressFromLatLng(currentLat, currentLng);
    String? prefecture = placemark.administrativeArea; // 都道府県名
    String? city = placemark.locality; // 市区町村名

    // Firebaseに投稿する
    await FirebaseFirestore.instance.collection('test').add({
      'sentAt': now, // 送信日時
      'latLng': GeoPoint(currentLat, currentLng), // 現在地（緯度経度）
      'area': prefecture! + city!, // 住所
      'uid': uniqueId, // 固有ID
      'message': widget.message,
    });
  }

  // デバイスの固有IDを取得
  Future<String> getUniqueID() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String id = "";

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      id = androidInfo.androidId;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      id = iosInfo.identifierForVendor;
    }
    return id;
  }

  // 現在地を取得
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 位置情報の許可関連
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return Geolocator.getCurrentPosition();
  }

  // 緯度経度の情報から住所を取得
  Future<Placemark> getAddressFromLatLng(double lat, double lng) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(lat, lng, localeIdentifier: "ja_JP");
    return placemarks[0];
  }
}
