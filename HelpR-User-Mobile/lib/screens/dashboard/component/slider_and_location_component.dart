import 'dart:async';

import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/dashboard_model.dart';
import 'package:booking_system_flutter/model/service_response.dart';
import 'package:booking_system_flutter/screens/notification/notification_screen.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:booking_system_flutter/screens/map/map_screen_two.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../model/service_data_model.dart';
import '../../../utils/common.dart';
import '../../service/search_service_screen.dart';

class SliderLocationComponent extends StatefulWidget {
  final List<SliderModel> sliderList;
  final List<ServiceData>? featuredList;
  final VoidCallback? callback;
  final List<ServiceLocationResponse>? serviceLocations;

  SliderLocationComponent({required this.sliderList, this.callback, this.featuredList, required this.serviceLocations});

  @override
  State<SliderLocationComponent> createState() => _SliderLocationComponentState();
}

class _SliderLocationComponentState extends State<SliderLocationComponent> {
  PageController sliderPageController = PageController(initialPage: 0);
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    appStore.setLoading(false);
    super.initState();
    if (getBoolAsync(AUTO_SLIDER_STATUS, defaultValue: true) && widget.sliderList.length >= 2) {
      _timer = Timer.periodic(Duration(seconds: DASHBOARD_AUTO_SLIDER_SECOND), (Timer timer) {
        if (_currentPage < widget.sliderList.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        sliderPageController.animateToPage(_currentPage, duration: Duration(milliseconds: 950), curve: Curves.easeOutQuart);
      });

      sliderPageController.addListener(() {
        _currentPage = sliderPageController.page!.toInt();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    sliderPageController.dispose();
  }

  Widget getSliderWidget() {
    print("HELLO");
    return SizedBox(
      height: 325,
      width: context.width(),
      child: Stack(
        children: [
          widget.sliderList.isNotEmpty
              ? PageView(
                  controller: sliderPageController,
                  children: List.generate(
                    widget.sliderList.length,
                    (index) {
                      SliderModel data = widget.sliderList[index];
                      return CachedImageWidget(url: data.sliderImage.validate(), height: 250, width: context.width(), fit: BoxFit.cover).onTap(() {
                        if (data.type == SERVICE) {
                          ServiceDetailScreen(serviceId: data.typeId.validate().toInt()).launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
                        }
                      });
                    },
                  ),
                )
              : CachedImageWidget(url: '', height: 250, width: context.width()),
          if (widget.sliderList.length.validate() > 1)
            Positioned(
              bottom: 34,
              left: 0,
              right: 0,
              child: DotIndicator(
                pageController: sliderPageController,
                pages: widget.sliderList,
                indicatorColor: white,
                unselectedIndicatorColor: white,
                currentBoxShape: BoxShape.rectangle,
                boxShape: BoxShape.rectangle,
                borderRadius: radius(2),
                currentBorderRadius: radius(3),
                currentDotSize: 18,
                currentDotWidth: 6,
                dotSize: 6,
              ),
            ),
          if (appStore.isLoggedIn)
            Positioned(
              top: context.statusBarHeight + 16,
              right: 16,
              child: Container(
                decoration: boxDecorationDefault(color: context.cardColor, shape: BoxShape.circle),
                height: 36,
                padding: EdgeInsets.all(8),
                width: 36,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ic_notification.iconImage(size: 24, color: primaryColor).center(),
                    Observer(builder: (context) {
                      return Positioned(
                        top: -20,
                        right: -10,
                        child: appStore.unreadCount.validate() > 0
                            ? Container(
                                padding: EdgeInsets.all(4),
                                child: FittedBox(
                                  child: Text(appStore.unreadCount.toString(), style: primaryTextStyle(size: 12, color: Colors.white)),
                                ),
                                decoration: boxDecorationDefault(color: Colors.red, shape: BoxShape.circle),
                              )
                            : Offstage(),
                      );
                    })
                  ],
                ),
              ).onTap(() {
                NotificationScreen().launch(context);
              }),
            )
        ],
      ),
    );
  }

  Decoration get commonDecoration {
    return boxDecorationDefault(
      color: context.cardColor,
      boxShadow: [
        BoxShadow(color: shadowColorGlobal, offset: Offset(1, 0)),
        BoxShadow(color: shadowColorGlobal, offset: Offset(0, 1)),
        BoxShadow(color: shadowColorGlobal, offset: Offset(-1, 0)),
      ],
    );
  }

    @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        getSliderWidget(),
        Positioned(
          bottom: -24,
          right: 16,
          left: 16,
          child: Row(
            children: [
              Observer(
                builder: (context) {
                  return AppButton(
                    padding: EdgeInsets.all(0),
                    width: context.width(),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: commonDecoration,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ic_location.iconImage(color: appStore.isDarkMode ? Colors.white : Colors.black),
                          8.width,
                          Text(
                            appStore.isCurrentLocation ? getStringAsync(CURRENT_ADDRESS) : language.lblLocationOff,
                            style: secondaryTextStyle(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ).expand(),
                          8.width,
                          ic_active_location.iconImage(size: 24, color: appStore.isCurrentLocation ? primaryColor : grey),
                        ],
                      ),
                    ),
                    onTap: () async {
                      locationWiseService(context, () {
                        widget.callback?.call();
                      });           
                    },
                  );
                },
              ).expand(),
              16.width,
              GestureDetector(
                onTap: () {
                  SearchServiceScreen(featuredList: widget.featuredList).launch(context);
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: commonDecoration,
                  child: ic_search.iconImage(color: primaryColor),
                ),
              ),
              16.width,
              GestureDetector(
                
                
                onTap: () async {
                  // Check for location permission
                  PermissionStatus permissionStatus = await Permission.location.request();

                  if (permissionStatus.isGranted) {
                    try {
                      appStore.setLoading(true);
                      // Fetch the current position
                      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

                      // Navigate to the MapSample screen with the current location
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapSample(
                            latitude: position.latitude,
                            longitude: position.longitude,
                            serviceLocations: widget.serviceLocations ?? []
                          ),
                        ),
                      );
                    } catch (e) {
                      // Handle location errors (e.g., location unavailable)
                      print('Error getting location: $e');
                    }
                  } else {
                    // Handle the case where permission is denied
                    print('Location permission denied');
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: commonDecoration,
                  child: Icon(Icons.map, color: primaryColor),
                ),
              ),

            ],
          ),
        ),
      ],
    );
  }

}
