import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:device_info/device_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // Firebaseからのストリーム
  late Stream<QuerySnapshot> _testStream;

  String? prefecture; // 都道府県
  String? city; // 市町村

  late String myUniqueID; //　固有ID

  String testText = "57";

  List newMessages = [];

  @override
  void initState() {
    super.initState();
    getUqniqueID(); // デバイスごとの固有IDを取得
    var initialTime = DateTime.now(); // アプリ起動時の時刻

    // Firebaseからのストリーム
    // アプリ起動時刻より後のメッセージだけを送信時間でソートして取得
    _testStream = FirebaseFirestore.instance
        .collection("test")
        .where("sentAt", isGreaterThan: initialTime)
        .orderBy("sentAt", descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    // ステータスバーを透明にする
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    final double deviceWidth = MediaQuery.of(context).size.width; // デバイスの幅
    final double deviceHeight = MediaQuery.of(context).size.height; // デバイスの高さ

    return Scaffold(
      body: SafeArea(
        child: Center(
          // Firebaseのデータが更新されるたびに再描画される
          child: StreamBuilder(
            stream: _testStream,
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return Text("エラーが発生しました。");
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              // 変更されたメッセージを取得（新規追加含む）
              newMessages = snapshot.data!.docChanges.map((change) {
                // ドキュメントIDも含めてマップにしてリストに格納
                Map data = change.doc.data() as Map;
                data["docId"] = change.doc.id;
                return data;
              }).toList();

              // 新規メッセージをダイアログで表示
              showMessage();

              return Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  Container(
                    width: deviceWidth,
                    height: deviceHeight,
                  ),
                  Positioned(
                    top: 20,
                    child: Column(
                      children: [
                        Container(
                          child: Text(
                            // "57",
                            testText,
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          child: Text(
                            "km/h",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 100,
                    child: Container(
                      child: Image.asset(
                        'assets/mycar.png',
                        height: 140,
                      ),
                    ),
                  ),
                  // 位置情報を送信するボタン
                  Positioned(
                    top: 260,
                    child: Container(
                      child: ElevatedButton(
                        child: Text("位置情報を送信"),
                        onPressed: sendMyLocation, // 押されたときに実行
                      ),
                    ),
                  ),
                  Positioned(
                    top: 300,
                    child: Container(
                      child: ElevatedButton(
                          child: Text("リセット"),
                          onPressed: () {
                            setState(() {
                              testText = "リセット";
                            });
                          }),
                    ),
                  ),
                  Positioned(
                    top: 340,
                    // Firebaseのデータが更新されるたび再描画される
                    child: Container(
                      color: Colors.grey[800],
                      width: deviceWidth,
                      height: 400,

                      // メッセージをリストで表示
                      child: ListView.builder(
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.only(top: 10, bottom: 50),
                        itemCount: newMessages.length,
                        itemBuilder: (BuildContext context, int index) {
                          // １つ１つのメッセージを取り出す
                          var message = newMessages[index];
                          // 固有IDで自分のメッセージかを判断
                          bool isMyMessage = message["uid"] == myUniqueID;

                          return Container(
                            margin: EdgeInsets.only(
                              left: 20,
                              right: 20,
                              bottom: 15,
                            ),
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: isMyMessage
                                  ? Colors.orange[200]!.withOpacity(0.3)
                                  : Colors.grey[700],
                            ),
                            child: Container(
                              margin: EdgeInsets.only(
                                top: 10,
                                bottom: 10,
                                left: 10,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "送信日時：",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      Text(
                                        DateFormat('M月d日 HH:mm')
                                            .format(message["sentAt"].toDate()),
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey[300],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "緯度経度：",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      Text(
                                        message["latLng"]
                                                .latitude
                                                .toStringAsFixed(4) +
                                            ",  " +
                                            message["latLng"]
                                                .longitude
                                                .toStringAsFixed(4),
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey[300],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "エリア：",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      Text(
                                        message["area"],
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey[300],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // 緯度経度の情報から住所を取得
  Future<Placemark> getAddressFromLatLng(double lat, double lng) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(lat, lng, localeIdentifier: "ja_JP");
    return placemarks[0];
  }

  // デバイスの固有IDを取得
  Future<void> getUqniqueID() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String id = "";

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      id = androidInfo.androidId;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      id = iosInfo.identifierForVendor;
    }
    myUniqueID = id;
  }

  // Firebaseに自分の位置情報のデータを送送信
  void sendMyLocation() async {
    // 現在時刻
    var now = DateTime.now();

    // 現在地を取得
    Position currentPos = await getCurrentPosition();

    // 緯度経度から住所を取得
    Placemark placemark =
        await getAddressFromLatLng(currentPos.latitude, currentPos.longitude);
    String? prefecture = placemark.administrativeArea; // 都道府県名
    String? city = placemark.locality; // 市区町村名

    // Firebaseに投稿する
    await FirebaseFirestore.instance.collection('test').add({
      'sentAt': now, // 送信日時
      'latLng':
          GeoPoint(currentPos.latitude, currentPos.longitude), // 現在地（緯度経度）
      'area': prefecture! + city!, // 住所
      'uid': myUniqueID, // 固有ID
    });
  }

  // 現在地を取得して返す
  Future<Position> getCurrentPosition() async {
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

    // 現在地を取得
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return position;
  }

  // 新規メッセージをダイアログで表示
  void showMessage() async {
    final prefs = await SharedPreferences.getInstance();
    bool isRead = prefs.getBool("showOnBoarding") ?? false;

    // 現在地を取得
    Position currentPos = await getCurrentPosition();
    double currentLat = currentPos.latitude;
    double currentLng = currentPos.longitude;

    for (Map message in newMessages) {
      // 自分のメッセージ以外を表示
      if (message["uid"] != myUniqueID) {
        // 現在地からの距離を計算
        double distanceFromHere = Geolocator.distanceBetween(
            currentPos.latitude,
            currentPos.longitude,
            message['latLng'].latitude,
            message['latLng'].longitude);

        Future.delayed(Duration.zero, () {
          showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text("新規メッセージ"),
                content: Column(children: [
                  Text(DateFormat('M月d日 HH:mm')
                      .format(message["sentAt"].toDate())),
                  Text(message["docId"]),
                  Text(message["latLng"].latitude.toString()),
                  Text(message["latLng"].longitude.toString()),
                  Text(currentLat.toString()),
                  Text(currentLng.toString()),
                  Text(distanceFromHere.toString()),
                ]),
                actions: [
                  SimpleDialogOption(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          );
        });
      }
    }
  }
}
