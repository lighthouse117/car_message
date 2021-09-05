import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
                          getAddressFromLatlng(data["LatLng"].latitude,
                                  data["LatLng"].longitude)
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
                              color: Colors.grey[700],
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
                                        data["LatLng"]
                                                .latitude
                                                .toStringAsFixed(4) +
                                            ",  " +
                                            data["LatLng"]
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

  Future<Placemark> getAddressFromLatlng(double lat, double lng) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(lat, lng, localeIdentifier: "ja_JP");
    return placemarks[0];
  }

  void sendMyLocation() async {
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
        await getAddressFromLatlng(position.latitude, position.longitude);
    String? prefecture = placemark.administrativeArea;
    String? city = placemark.locality;

    var now = DateTime.now();
    await FirebaseFirestore.instance.collection('test').add({
      'sentAt': now,
      'LatLng': GeoPoint(position.latitude, position.longitude),
      'area': prefecture! + city!,
    });
  }
}
