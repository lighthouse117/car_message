import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:device_info/device_info.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final Stream<QuerySnapshot> _testStream = FirebaseFirestore.instance
      .collection("test")
      .orderBy("sentAt", descending: true)
      .snapshots();

  String? prefecture;
  String? city;

  late String uniqueID;

  @override
  void initState() {
    super.initState();
    getUqniqueID();
  }

  @override
  Widget build(BuildContext context) {
    // ステータスバーを透明にする
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    final double deviceWidth = MediaQuery.of(context).size.width;
    final double deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Stack(
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
                        "57",
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
              Positioned(
                top: 260,
                child: Container(
                  child: ElevatedButton(
                    child: Text("位置情報を送信"),
                    onPressed: sendMyLocation,
                  ),
                ),
              ),
              Positioned(
                top: 340,
                child: StreamBuilder(
                  stream: _testStream,
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return Text("エラーが発生しました。");
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }

                    List docs = snapshot.data!.docs;

                    return Container(
                      color: Colors.grey[800],
                      width: deviceWidth,
                      height: 400,
                      child: ListView.builder(
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.only(top: 10, bottom: 50),
                        itemCount: docs.length,
                        itemBuilder: (BuildContext context, int index) {
                          DocumentSnapshot data = docs[index];
                          bool isMyMessage = data["id"] == uniqueID;

                          getAddressFromLatLng(data["latLng"].latitude,
                                  data["latLng"].longitude)
                              .then((placemark) {
                            setState(() {
                              prefecture = placemark.administrativeArea;
                              city = placemark.locality;
                            });
                          });

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
                                            .format(data["sentAt"].toDate()),
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
                                        data["latLng"]
                                                .latitude
                                                .toStringAsFixed(4) +
                                            ",  " +
                                            data["latLng"]
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
                                        data["area"],
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Placemark> getAddressFromLatLng(double lat, double lng) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(lat, lng, localeIdentifier: "ja_JP");
    return placemarks[0];
  }

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
    uniqueID = id;
  }

  void sendMyLocation() async {
    var now = DateTime.now();

    bool serviceEnabled;
    LocationPermission permission;

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

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    Placemark placemark =
        await getAddressFromLatLng(position.latitude, position.longitude);
    String? prefecture = placemark.administrativeArea;
    String? city = placemark.locality;

    await FirebaseFirestore.instance.collection('test').add({
      'sentAt': now,
      'latLng': GeoPoint(position.latitude, position.longitude),
      'area': prefecture! + city!,
      'id': uniqueID,
    });
  }
}
