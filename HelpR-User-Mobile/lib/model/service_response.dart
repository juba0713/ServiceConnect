import 'package:booking_system_flutter/model/service_data_model.dart';

import 'pagination_model.dart';

class ServiceResponse {
  List<ServiceData>? serviceList;
  Pagination? pagination;
  int? max;
  int? min;
  List<ServiceData>? userServices;

  ServiceResponse({this.serviceList, this.pagination, this.max, this.min, this.userServices});

  factory ServiceResponse.fromJson(Map<String, dynamic> json) {
    return ServiceResponse(
      serviceList: json['data'] != null ? (json['data'] as List).map((i) => ServiceData.fromJson(i)).toList() : null,
      max: json['max'],
      min: json['min'],
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
      userServices: json['user_services'] != null ? (json['user_services'] as List).map((i) => ServiceData.fromJson(i)).toList() : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['max'] = this.max;
    data['min'] = this.min;
    if (this.serviceList != null) {
      data['data'] = this.serviceList!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    if (this.userServices != null) {
      data['user_services'] = this.userServices!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ServiceLocationResponse{
  int? serviceId;
  String? serviceName;
  int? categoryId;
  String? categoryName;
  List<ServiceAddressMapping>? serviceAddressMapping;
  String? categoryImage;

  ServiceLocationResponse({this.serviceId, this.serviceName, this.categoryId, this.categoryName, this.serviceAddressMapping, this.categoryImage});
  
  factory ServiceLocationResponse.fromJson(Map<String, dynamic> json) {
    return ServiceLocationResponse(
      serviceId: json['service_id'],
      serviceName : json['service_name'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      serviceAddressMapping: json['service_address_mapping'] != null ? (json['service_address_mapping'] as List).map((i) => ServiceAddressMapping.fromJson(i)).toList() : null,
      categoryImage: json['category_image']
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['service_id'] = this.serviceId;
    data['service_name'] = this.serviceName;
    data['category_id'] = this.categoryId;
    data['category_name'] = this.categoryName;
    data['service_address_mapping'] = this.serviceAddressMapping;
    data['category_image'] = this.categoryImage;
    return data;
  }
}
