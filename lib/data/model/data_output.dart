import 'package:flutter/material.dart';

/*when we need to parse API data. this class will helpfull it will give you easy
 access of data without using Map and if you see <T> in this class it will be any type,
its like dynamic, instead of creating new model for data output we use T, or any english Capital
alphabets you can use any like <B>*/
class DataOutput<T> {
  final int total;
  final List<T> modelList;
  final ExtraData? extraData;
  final int? page;
  final int? lastPage;

  DataOutput({
    required this.total,
    required this.modelList,
    this.extraData,
    this.page,
    this.lastPage,
  });

  DataOutput<T> copyWith({
    int? total,
    List<T>? modelList,
    ExtraData? extraData,
    int? page,
    int? lastPage,
  }) {
    return DataOutput<T>(
      total: total ?? this.total,
      modelList: modelList ?? this.modelList,
      extraData: extraData ?? this.extraData,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
    );
  }
}

@protected
class ExtraData<T> {
  final T data;

  ExtraData({
    required this.data,
  });
}
