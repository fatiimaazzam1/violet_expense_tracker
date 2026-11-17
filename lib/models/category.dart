import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class Category {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String iconKey;

  @HiveField(3)
  final bool isDefault;

  const Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.isDefault,
  });
}
