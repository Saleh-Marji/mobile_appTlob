class ReceiptModel {
  int? id;
  int? userId;
  int? itemId;
  String? url;
  String? path;
  String? userName;
  String? itemTitle;
  String? organizationName;
  String? itemCategory;
  String? itemDate;
  String? itemLocation;
  int? growthScore;

  ReceiptModel({
    this.id,
    this.userId,
    this.itemId,
    this.url,
    this.path,
    this.userName,
    this.itemTitle,
    this.organizationName,
    this.itemCategory,
    this.itemDate,
    this.itemLocation,
    this.growthScore,
  });

  ReceiptModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    itemId = json['item_id'];
    url = json['url'];
    path = json['path'];
    userName = json['user_name'];
    itemTitle = json['item_title'];
    organizationName = json['organization_name'];
    itemCategory = json['item_category'];
    itemDate = json['item_date'];
    itemLocation = json['item_location'];
    growthScore = json['growth_score'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['item_id'] = itemId;
    data['url'] = url;
    data['path'] = path;
    data['user_name'] = userName;
    data['item_title'] = itemTitle;
    data['organization_name'] = organizationName;
    data['item_category'] = itemCategory;
    data['item_date'] = itemDate;
    data['item_location'] = itemLocation;
    data['growth_score'] = growthScore;
    return data;
  }
}
