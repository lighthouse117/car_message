import 'package:car_message/confirmSendMessagePage.dart';
import 'package:car_message/mainPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
              height: 25,
            ),
            Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white12,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.lightBlue[100],
                  labelPadding: EdgeInsets.only(bottom: 10),
                  indicatorWeight: 1.5,
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
              getMessageIcon(title, 40),
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return ConfirmSendMessagePage(title);
              },
            ),
          ).then((message) {
            if (message != null) Navigator.of(context).pop(message);
          });
        },
      ),
    );
  }

  Widget emotionTab() {
    return Container(
      margin: EdgeInsets.only(left: 25, top: 20),
      child: Column(
        children: [
          Row(
            children: [
              buildMessageButton("ありがとう"),
              SizedBox(width: 25),
              buildMessageButton("ごめんね"),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            children: [
              buildMessageButton("お先にどうぞ"),
              SizedBox(width: 25),
              buildMessageButton("あぶない！"),
            ],
          )
        ],
      ),
    );
  }

  Widget maintenanceTab() {
    return Container(
      margin: EdgeInsets.only(left: 25, top: 20),
      child: Column(
        children: [
          Row(
            children: [
              buildMessageButton("ライトつけて"),
              SizedBox(width: 25),
              buildMessageButton("ライトまぶしい"),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            children: [
              buildMessageButton("ドアが開いてる"),
              SizedBox(width: 25),
              buildMessageButton("エンスト"),
            ],
          )
        ],
      ),
    );
  }

  Widget accidentTab() {
    return Container(
      margin: EdgeInsets.only(left: 25, top: 20),
      child: Column(
        children: [
          Row(
            children: [
              buildMessageButton("事故発生"),
              SizedBox(width: 25),
              buildMessageButton("停車中の車あり"),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            children: [
              buildMessageButton("急病人"),
              SizedBox(width: 25),
              buildMessageButton("緊急車両が接近"),
            ],
          )
        ],
      ),
    );
  }
}
