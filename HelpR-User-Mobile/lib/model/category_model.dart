import 'package:booking_system_flutter/model/pagination_model.dart';

class CategoryResponse {
  List<CategoryData>? categoryList;
  Pagination? pagination;

  CategoryResponse({this.categoryList, this.pagination});

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      categoryList: json['data'] != null ? (json['data'] as List).map((i) => CategoryData.fromJson(i)).toList() : null,
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.categoryList != null) {
      data['data'] = this.categoryList!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class CategoryData {
  String? categoryImage;
  String? color;
  String? description;
  int? id;
  int? isFeatured;
  String? name;
  int? status;
  bool isSelected;
  int? services;

  CategoryData({this.categoryImage, this.color, this.description, this.id, this.isFeatured, this.name, this.status, this.isSelected = false, this.services});

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      categoryImage: json['category_image'],
      color: json['color'],
      description: json['description'],
      id: json['id'],
      isFeatured: json['is_featured'],
      name: json['name'],
      status: json['status'],
      services: json['services'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['category_image'] = this.categoryImage;
    data['color'] = this.color;
    data['description'] = this.description;
    data['id'] = this.id;
    data['is_featured'] = this.isFeatured;
    data['name'] = this.name;
    data['status'] = this.status;
    data['services'] = this.services;
    return data;
  }
}

class RealCategoryData {
  int? id;
  String? name;
  String? description;
  String? color;
  int? status;
  int? isFeatured;

  RealCategoryData({this.id, this.name, this.description, this.color, this.status, this.isFeatured});
  
  factory RealCategoryData.fromJson(Map<String, dynamic> json) {
    return RealCategoryData(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      color: json['color'],
      status: json['status'],
      isFeatured: json['isFeatured'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;
    data['color'] = this.color;   
    data['is_featured'] = this.isFeatured;
    data['status'] = this.status;
    return data;
  }
}