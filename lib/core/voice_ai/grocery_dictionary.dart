class GroceryCanonical {
  final String id;
  final String displayName;
  final String category;
  final List<String> aliases;

  GroceryCanonical({
    required this.id,
    required this.displayName,
    required this.category,
    required this.aliases,
  });
}

class GroceryDictionary {
  static final List<GroceryCanonical> masterList = [
    // Staples
    GroceryCanonical(id: 'rava', displayName: 'रवा', category: 'grains', aliases: ['rava', 'rawa', 'ravva', 'रवा', 'राव', 'राव्वा', 'रव्वा']),
    GroceryCanonical(id: 'sakhar', displayName: 'साखर', category: 'staples', aliases: ['sakhar', 'sugar', 'shakkar', 'साखर', 'शक्कर', 'साकर']),
    GroceryCanonical(id: 'tandul', displayName: 'तांदूळ', category: 'grains', aliases: ['rice', 'tandul', 'tandool', 'तांदूळ', 'तांदुळ', 'चावल']),
    GroceryCanonical(id: 'gahu', displayName: 'गहू', category: 'grains', aliases: ['wheat', 'gahu', 'gehu', 'गहू', 'गेहू']),
    GroceryCanonical(id: 'dal', displayName: 'डाळ', category: 'grains', aliases: ['dal', 'daal', 'डाळ', 'दाल']),
    
    // Vegetables
    GroceryCanonical(id: 'kanda', displayName: 'कांदा', category: 'vegetables', aliases: ['onion', 'kanda', 'कांदा', 'कांदा', 'प्याझ']),
    GroceryCanonical(id: 'batata', displayName: 'बटाटा', category: 'vegetables', aliases: ['potato', 'batata', 'alu', 'बटाटा', 'बटाटा', 'आलू']),
    GroceryCanonical(id: 'tomato', displayName: 'टोमॅटो', category: 'vegetables', aliases: ['tomato', 'tamatar', 'टोमॅटो', 'टमाटर']),
    
    // Dairy
    GroceryCanonical(id: 'dudh', displayName: 'दूध', category: 'dairy', aliases: ['milk', 'dudh', 'doodh', 'दूध', 'दूध']),
    GroceryCanonical(id: 'tup', displayName: 'तूप', category: 'dairy', aliases: ['ghee', 'tup', 'toop', 'तूप', 'तूप', 'घी']),
    
    // Household
    GroceryCanonical(id: 'kadepeti', displayName: 'काडेपेटी', category: 'household', aliases: ['matchbox', 'kadepeti', 'kadpeti', 'काडेपेटी', 'कडेपेटी', 'कडपेटी', 'कडपतिया']),
    GroceryCanonical(id: 'saban', displayName: 'साबण', category: 'household', aliases: ['soap', 'saban', 'sabun', 'साबण', 'साबुन']),
  ];

  static String? lookup(String input) {
    String lower = input.toLowerCase().trim();
    for (var item in masterList) {
      if (item.aliases.any((a) => a.toLowerCase() == lower)) {
        return item.displayName;
      }
    }
    return null;
  }

  static List<String> getAllAliases() {
    return masterList.expand((e) => e.aliases).toList();
  }

  static String getCanonicalByAlias(String alias) {
    String lower = alias.toLowerCase().trim();
    for (var item in masterList) {
      if (item.aliases.any((a) => a.toLowerCase() == lower)) {
        return item.displayName;
      }
    }
    return alias;
  }

  static String getCategory(String displayName) {
    for (var item in masterList) {
      if (item.displayName == displayName) {
        // Capitalize category
        return item.category[0].toUpperCase() + item.category.substring(1);
      }
    }
    return 'Other';
  }
}
