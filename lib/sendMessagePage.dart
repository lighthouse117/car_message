import 'dart:async';
import 'dart:io';
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

class SendMessagePage extends StatefulWidget {
  @override
  _SendMessagePageState createState() => _SendMessagePageState();
}

class _SendMessagePageState extends State<SendMessagePage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3, initialIndex: 0);
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
            Container(
              margin: EdgeInsets.only(left: 25),
              alignment: Alignment.centerLeft,
              child: Text(
                "最近",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFEAF1F6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 25, top: 10),
              child: Row(
                children: [
                  buildMessageButton("お先にどうぞ"),
                  SizedBox(
                    width: 25,
                  ),
                  buildMessageButton("緊急車両が接近"),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              margin: EdgeInsets.only(left: 25),
              alignment: Alignment.centerLeft,
              child: Text(
                "よく使う",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFEAF1F6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 25, top: 10),
              child: Row(
                children: [
                  buildMessageButton("ありがとう"),
                  SizedBox(width: 25),
                  buildMessageButton("ライトつけて"),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.lightBlue[100],
              labelPadding: EdgeInsets.only(bottom: 10),
              tabs: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_emotions_rounded,
                      size: 20,
                    ),
                    SizedBox(width: 5),
                    Text(
                      "感情",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.construction_rounded,
                      size: 20,
                    ),
                    SizedBox(width: 5),
                    Text(
                      "整備",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.report_problem_rounded,
                      size: 20,
                    ),
                    SizedBox(width: 5),
                    Text(
                      "事故",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: BouncingScrollPhysics(),
                children: [
                  emotionTab(),
                  maintenanceTab(),
                  accidentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMessageButton(String title) {
    Widget messageImage = Container();
    switch (title) {
      case "ありがとう":
        messageImage = SvgPicture.asset(
          "assets/thanks_hands.svg",
          color: Color(0xFFA5B2C6),
          height: 40,
        );
        break;
      case "緊急車両が接近":
        messageImage = SvgPicture.asset(
          "assets/car-emergency.svg",
          color: Color(0xFFA5B2C6),
          height: 40,
        );
        break;
      case "お先にどうぞ":
        messageImage = SvgPicture.asset(
          "assets/goahead.svg",
          color: Color(0xFFA5B2C6),
          height: 40,
        );
        break;
      case "ライトつけて":
        messageImage = SvgPicture.asset(
          "assets/car-light.svg",
          color: Color(0xFFA5B2C6),
          height: 40,
        );
        break;
      case "ごめんね":
        messageImage = SvgPicture.asset(
          "assets/thanks_hands.svg",
          color: Color(0xFFA5B2C6),
          height: 40,
        );
        break;
      case "あぶない！":
        messageImage = SvgPicture.asset(
          "assets/sad-face.svg",
          color: Color(0xFFA5B2C6),
          height: 40,
        );
        break;
      default:
    }
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      color: Color(0xFF333D48),
      child: InkWell(
        child: Container(
          width: 140,
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              messageImage,
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget emotionTab() {
    return Container();
  }

  Widget maintenanceTab() {
    return Container();
  }

  Widget accidentTab() {
    return Container();
  }
}
