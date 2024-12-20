import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/service_address_response.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/service_address/components/add_service_component.dart';
import 'package:nb_utils/nb_utils.dart';

class ServiceAddressComponent extends StatefulWidget {
  final List<int>? selectedList;
  final Function(List<int> val) onSelectedList;

  ServiceAddressComponent({this.selectedList, required this.onSelectedList});

  @override
  State<ServiceAddressComponent> createState() => _ServiceAddressComponentState();
}

class _ServiceAddressComponentState extends State<ServiceAddressComponent> {
  List<AddressResponse> addressList = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    getServiceAddresses();
  }

  Future<void> getServiceAddresses() async {
    await getAddresses(providerId: appStore.userId).then((value) {
      addressList = value.addressResponse.validate();

      if (widget.selectedList != null) {
        addressList.forEach((element) {
          log("${element.id}" + "${element.address.validate()}");

          element.isSelected = widget.selectedList!.contains(element.id.validate());
        });

        widget.onSelectedList.call(addressList.where((element) => element.isSelected == true).map((e) => e.id.validate()).toList());
      }

      setState(() {});
    }).catchError((e) {
      log(e.toString());
    });
  }

  bool isExpanded = false;

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: radius(),
            color: context.scaffoldBackgroundColor,
          ),
          child: Theme(
            data: ThemeData(dividerColor: Colors.transparent),
            child: ExpansionTile(
              iconColor: context.iconColor,
              tilePadding: EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: EdgeInsets.symmetric(horizontal: 16),
              initiallyExpanded: widget.selectedList.validate().isNotEmpty,
              title: Text(languages.selectAddress, style: secondaryTextStyle()),
              onExpansionChanged: (value) {
                isExpanded = value;
                setState(() {});
              },
              trailing: AnimatedCrossFade(
                firstChild: Icon(Icons.arrow_drop_down),
                secondChild: Icon(Icons.arrow_drop_up),
                crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstCurve: Curves.linear,
                secondCurve: Curves.linear,
                duration: 200.milliseconds,
              ),
              children: List.generate(
                addressList.length,
                (index) {
                  AddressResponse data = addressList[index];
                  bool isSelected = data.isSelected.validate();
                  return Container(
                    margin: EdgeInsets.only(bottom: 8.0),
                    child: Theme(
                      data: ThemeData(
                        unselectedWidgetColor: appStore.isDarkMode ? context.dividerColor : context.iconColor,
                      ),
                      child: CheckboxListTile(
                        checkboxShape: RoundedRectangleBorder(borderRadius: radius(4)),
                        autofocus: false,
                        activeColor: context.primaryColor,
                        checkColor: appStore.isDarkMode ? context.iconColor : context.cardColor,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        title: Text(
                          addressList[index].address.validate(),
                          style: secondaryTextStyle(color: context.iconColor),
                        ),
                        value: isSelected,
                        onChanged: (bool? val) {
                          data.isSelected = !data.isSelected.validate();
                          widget.onSelectedList.call(addressList.where((element) => element.isSelected == true).map((e) => e.id.validate()).toList());

                          setState(() {});
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: TextButton(
            style: ButtonStyle(visualDensity: VisualDensity.compact),
            onPressed: () {
              print("Open Diaglog for adding address");
              print("Is Expanded: $isExpanded");
              showInDialog(
                context,
                contentPadding: EdgeInsets.all(0),
                dialogAnimation: DialogAnimation.SCALE,
                builder: (_) {
                  return AddServiceComponent();
                },
              ).then((value) {
                print("Value: $value");
                if (value != null) {
                  if (value) {
                    init();
                    isExpanded = true;
                    setState(() {});
                  }
                }
              });
            },
            child: Text(languages.lblAddServiceAddress, style: secondaryTextStyle()),
          ),
        ),
      ],
    );
  }
}
