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

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Stream<QuerySnapshot> _testStream; // Firebaseからのストリーム

  double currentLat = 0; // 現在の緯度
  double currentLng = 0; // 現在の経度
  double currentSpeed = 0; // 現在の速度

  late String myUniqueID; //　デバイスの固有ID

  List newMessages = []; // 新規メッセージのリスト

// 最初に一度だけ実行される初期化処理
  @override
  void initState() {
    super.initState();
    getLocationUpdates(); // 現在地情報を常に取得する
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
    final double topPadding = MediaQuery.of(context).padding.top; // 上の余白

    return Scaffold(
      body: Center(
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
                // 背景のグラデーション
                Container(
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
                ),
                // 速度
                Positioned(
                  top: topPadding,
                  child: Column(
                    children: [
                      Container(
                        child: Text(
                          // currentSpeed.toStringAsFixed(6),
                          "56",
                          style: GoogleFonts.montserrat(
                            fontSize: 40,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.8,
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
                // ブロードキャストボタン
                Positioned(
                  top: 70,
                  left: 40,
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white12,
                            blurRadius: 30,
                            offset: Offset(-7, -7),
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF343A41),
                            Color(0xFF171B20),
                          ],
                        )),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.transparent,
                        shape: CircleBorder(),
                        elevation: 0,
                      ),
                      onPressed: () {},
                      child: SvgPicture.asset(
                        "assets/broadcast.svg",
                        color: Colors.white70,
                        height: 100,
                        width: 100,
                      ),
                    ),
                  ),
                ),
                // 音声入力ボタン
                Positioned(
                  top: 70,
                  right: 40,
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white12,
                            blurRadius: 30,
                            offset: Offset(-7, -7),
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF343A41),
                            Color(0xFF171B20),
                          ],
                        )),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.transparent,
                        shape: CircleBorder(),
                        elevation: 0,
                      ),
                      onPressed: () {},
                      child: Icon(
                        Icons.mic_rounded,
                        size: 30,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
                // 自分の車
                Positioned(
                  top: 190,
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.white10,
                            blurRadius: 50,
                            spreadRadius: 0),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 205,
                  child: Image.asset(
                    'assets/mycar.png',
                    height: 120,
                  ),
                ),
                // 前の車
                Positioned(
                  top: 110,
                  child: GestureDetector(
                    child: SvgPicture.asset(
                      "assets/car-top.svg",
                      color: Colors.white.withOpacity(0.2),
                      height: 90,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return SendMessagePage();
                          },
                        ),
                      );
                    },
                  ),
                ),
                // 後ろの車
                Positioned(
                  top: 335,
                  child: GestureDetector(
                    child: SvgPicture.asset(
                      "assets/car-top.svg",
                      color: Colors.white.withOpacity(0.2),
                      height: 90,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return SendMessagePage();
                          },
                        ),
                      );
                    },
                  ),
                ),
                // 左の車
                Positioned(
                  top: 220,
                  left: 50,
                  child: GestureDetector(
                    child: SvgPicture.asset(
                      "assets/car-top.svg",
                      color: Colors.white.withOpacity(0.2),
                      height: 90,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return SendMessagePage();
                          },
                        ),
                      );
                    },
                  ),
                ),
                // 右の車
                Positioned(
                  top: 220,
                  right: 50,
                  child: GestureDetector(
                    child: SvgPicture.asset(
                      "assets/car-top.svg",
                      color: Colors.white.withOpacity(0.2),
                      height: 90,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return SendMessagePage();
                          },
                        ),
                      );
                    },
                  ),
                ),
                // 対向車線の車
                Positioned(
                  top: 135,
                  right: -5,
                  child: RotatedBox(
                    quarterTurns: 2,
                    child: GestureDetector(
                      child: SvgPicture.asset(
                        "assets/car-top.svg",
                        color: Colors.white.withOpacity(0.2),
                        height: 90,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return SendMessagePage();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // 車線
                Positioned(
                  top: 110,
                  left: 130,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white12,
                        height: 90,
                        width: 1.5,
                      ),
                      SizedBox(height: 25),
                      Container(
                        color: Colors.white12,
                        height: 90,
                        width: 1.5,
                      ),
                      SizedBox(height: 25),
                      Container(
                        color: Colors.white12,
                        height: 90,
                        width: 1.5,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 110,
                  right: 130,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white12,
                        height: 90,
                        width: 1.5,
                      ),
                      SizedBox(height: 25),
                      Container(
                        color: Colors.white12,
                        height: 90,
                        width: 1.5,
                      ),
                      SizedBox(height: 25),
                      Container(
                        color: Colors.white12,
                        height: 90,
                        width: 1.5,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 440,
                  child: Container(
                    height: deviceHeight - 440 + 10,
                    width: deviceWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(50),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF414954),
                          Color(0xFF202326),
                        ],
                      ),
                      border: Border.all(
                        color: Color(0xFF47515B),
                        width: 3,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.only(top: 15, left: 30),
                          child: Text(
                            "前の車からのメッセージ",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            margin: EdgeInsets.only(top: 10),
                            child: Text(
                              "ありがとう",
                              style: TextStyle(
                                fontSize: 23,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            margin: EdgeInsets.only(top: 15),
                            child: SvgPicture.asset(
                              "assets/thanks_hands.svg",
                              color: Color(0xFFA5B2C6),
                              height: 100,
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(
                            top: 25,
                            left: 25,
                            right: 25,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 通報ボタン
                              Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white12,
                                        blurRadius: 30,
                                        offset: Offset(-7, -7),
                                      ),
                                    ],
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF343A41),
                                        Color(0xFF171B20),
                                      ],
                                    )),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.transparent,
                                    shape: CircleBorder(),
                                    elevation: 0,
                                  ),
                                  onPressed: () {},
                                  child: Icon(
                                    Icons.report_rounded,
                                    size: 30,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                              // SizedBox(width: 20),
                              // いいねボタン
                              Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white12,
                                        blurRadius: 30,
                                        offset: Offset(-7, -7),
                                      ),
                                    ],
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFF66B84),
                                        Color(0xFFB43148),
                                      ],
                                    )),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.transparent,
                                    shape: CircleBorder(),
                                    elevation: 0,
                                  ),
                                  onPressed: () {},
                                  child: Icon(
                                    Icons.favorite_rounded,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // SizedBox(width: 20),
                              // OKボタン
                              Container(
                                height: 60,
                                width: 160,
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
                                    shape: CircleBorder(),
                                    elevation: 0,
                                  ),
                                  onPressed: () {},
                                  child: Text(
                                    "OK",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            );
          },
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

    // 緯度経度から住所を取得
    Placemark placemark = await getAddressFromLatLng(currentLat, currentLng);
    String? prefecture = placemark.administrativeArea; // 都道府県名
    String? city = placemark.locality; // 市区町村名

    // Firebaseに投稿する
    await FirebaseFirestore.instance.collection('test').add({
      'sentAt': now, // 送信日時
      'latLng': GeoPoint(currentLat, currentLng), // 現在地（緯度経度）
      'area': prefecture! + city!, // 住所
      'uid': myUniqueID, // 固有ID
    });
  }

  // 新規メッセージをダイアログで表示
  void showMessage() async {
    final prefs = await SharedPreferences.getInstance();
    bool isRead = prefs.getBool("showOnBoarding") ?? false;

    // 現在地を取得
    double lat = currentLat;
    double lng = currentLng;

    for (Map message in newMessages) {
      // 自分のメッセージ以外を表示
      if (message["uid"] != myUniqueID) {
        // 現在地からの距離を計算
        double distanceFromHere = Geolocator.distanceBetween(
            lat, lng, message['latLng'].latitude, message['latLng'].longitude);

        Future.delayed(Duration.zero, () {
          showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text("新規メッセージを検知"),
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

  void getLocationUpdates() async {
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

    // 現在地を常に取得するストリーム
    StreamSubscription postionStream = Geolocator.getPositionStream(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
    ).listen((Position position) {
      // 現在地に変更があると実行される
      setState(() {
        currentLat = position.latitude; // 緯度を更新
        currentLng = position.longitude; // 経度を更新
        currentSpeed = position.speed; // 速度を更新 (m/s)
      });
    });
  }

  // Widget buildListView() {
  //   // メッセージをリストで表示
  //   return ListView.builder(
  //     physics: BouncingScrollPhysics(),
  //     padding: EdgeInsets.only(top: 10, bottom: 50),
  //     itemCount: newMessages.length,
  //     itemBuilder: (BuildContext context, int index) {
  //       // １つ１つのメッセージを取り出す
  //       var message = newMessages[index];
  //       // 固有IDで自分のメッセージかを判断
  //       bool isMyMessage = message["uid"] == myUniqueID;

  //       return Container(
  //         margin: EdgeInsets.only(
  //           left: 20,
  //           right: 20,
  //           bottom: 15,
  //         ),
  //         height: 90,
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(10),
  //           color: isMyMessage
  //               ? Colors.orange[200]!.withOpacity(0.3)
  //               : Colors.grey[700],
  //         ),
  //         child: Container(
  //           margin: EdgeInsets.only(
  //             top: 10,
  //             bottom: 10,
  //             left: 10,
  //           ),
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Row(
  //                 children: [
  //                   Text(
  //                     "送信日時：",
  //                     style: TextStyle(
  //                       fontSize: 15,
  //                       color: Colors.grey[500],
  //                     ),
  //                   ),
  //                   Text(
  //                     DateFormat('M月d日 HH:mm')
  //                         .format(message["sentAt"].toDate()),
  //                     style: TextStyle(
  //                       fontSize: 15,
  //                       color: Colors.grey[300],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               Row(
  //                 children: [
  //                   Text(
  //                     "緯度経度：",
  //                     style: TextStyle(
  //                       fontSize: 15,
  //                       color: Colors.grey[500],
  //                     ),
  //                   ),
  //                   Text(
  //                     message["latLng"].latitude.toStringAsFixed(4) +
  //                         ",  " +
  //                         message["latLng"].longitude.toStringAsFixed(4),
  //                     style: TextStyle(
  //                       fontSize: 15,
  //                       color: Colors.grey[300],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               Row(
  //                 children: [
  //                   Text(
  //                     "エリア：",
  //                     style: TextStyle(
  //                       fontSize: 15,
  //                       color: Colors.grey[500],
  //                     ),
  //                   ),
  //                   Text(
  //                     message["area"],
  //                     style: TextStyle(
  //                       fontSize: 15,
  //                       color: Colors.grey[300],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
}
