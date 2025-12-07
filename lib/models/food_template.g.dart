// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodTemplate _$FoodTemplateFromJson(Map<String, dynamic> json) => FoodTemplate(
      id: json['id'] as String?,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      description: json['description'] as String?,
      category: $enumDecode(_$FoodCategoryEnumMap, json['category']),
      nutritionPerServing: NutritionEstimate.fromJson(
          json['nutritionPerServing'] as Map<String, dynamic>),
      defaultServingSize: (json['defaultServingSize'] as num).toDouble(),
      servingUnit: $enumDecode(_$ServingUnitEnumMap, json['servingUnit']),
      servingDescription: json['servingDescription'] as String?,
      gramsPerServing: (json['gramsPerServing'] as num?)?.toDouble(),
      mlPerServing: (json['mlPerServing'] as num?)?.toDouble(),
      source: $enumDecodeNullable(_$NutritionSourceEnumMap, json['source']) ??
          NutritionSource.manual,
      sourceNotes: json['sourceNotes'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastUsed: json['lastUsed'] == null
          ? null
          : DateTime.parse(json['lastUsed'] as String),
      useCount: (json['useCount'] as num?)?.toInt() ?? 0,
      barcode: json['barcode'] as String?,
      imagePath: json['imagePath'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$FoodTemplateToJson(FoodTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'brand': instance.brand,
      'description': instance.description,
      'category': _$FoodCategoryEnumMap[instance.category]!,
      'nutritionPerServing': instance.nutritionPerServing,
      'defaultServingSize': instance.defaultServingSize,
      'servingUnit': _$ServingUnitEnumMap[instance.servingUnit]!,
      'servingDescription': instance.servingDescription,
      'gramsPerServing': instance.gramsPerServing,
      'mlPerServing': instance.mlPerServing,
      'source': _$NutritionSourceEnumMap[instance.source]!,
      'sourceNotes': instance.sourceNotes,
      'sourceUrl': instance.sourceUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastUsed': instance.lastUsed?.toIso8601String(),
      'useCount': instance.useCount,
      'barcode': instance.barcode,
      'imagePath': instance.imagePath,
      'isFavorite': instance.isFavorite,
      'tags': instance.tags,
    };

const _$FoodCategoryEnumMap = {
  FoodCategory.protein: 'protein',
  FoodCategory.dairy: 'dairy',
  FoodCategory.grain: 'grain',
  FoodCategory.vegetable: 'vegetable',
  FoodCategory.fruit: 'fruit',
  FoodCategory.fat: 'fat',
  FoodCategory.beverage: 'beverage',
  FoodCategory.snack: 'snack',
  FoodCategory.condiment: 'condiment',
  FoodCategory.prepared: 'prepared',
  FoodCategory.supplement: 'supplement',
  FoodCategory.other: 'other',
};

const _$ServingUnitEnumMap = {
  ServingUnit.gram: 'gram',
  ServingUnit.ounce: 'ounce',
  ServingUnit.pound: 'pound',
  ServingUnit.kilogram: 'kilogram',
  ServingUnit.cup: 'cup',
  ServingUnit.tablespoon: 'tablespoon',
  ServingUnit.teaspoon: 'teaspoon',
  ServingUnit.fluidOunce: 'fluidOunce',
  ServingUnit.milliliter: 'milliliter',
  ServingUnit.liter: 'liter',
  ServingUnit.piece: 'piece',
  ServingUnit.slice: 'slice',
  ServingUnit.serving: 'serving',
  ServingUnit.container: 'container',
  ServingUnit.packet: 'packet',
  ServingUnit.scoop: 'scoop',
  ServingUnit.bar: 'bar',
  ServingUnit.patty: 'patty',
  ServingUnit.fillet: 'fillet',
  ServingUnit.breast: 'breast',
  ServingUnit.thigh: 'thigh',
  ServingUnit.egg: 'egg',
  ServingUnit.strip: 'strip',
  ServingUnit.link: 'link',
  ServingUnit.bowl: 'bowl',
  ServingUnit.plate: 'plate',
  ServingUnit.sandwich: 'sandwich',
  ServingUnit.wrap: 'wrap',
  ServingUnit.burrito: 'burrito',
  ServingUnit.taco: 'taco',
};

const _$NutritionSourceEnumMap = {
  NutritionSource.aiEstimated: 'aiEstimated',
  NutritionSource.manual: 'manual',
  NutritionSource.verified: 'verified',
  NutritionSource.webSearch: 'webSearch',
  NutritionSource.imported: 'imported',
  NutritionSource.prePopulated: 'prePopulated',
};
