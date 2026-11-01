import '../voice_ai/grocery_dictionary.dart';

class KiranaCategoryEngine {
  String detectCategory(String canonicalName, String rawText) {
    // 1. Try master dictionary category first
    final dictCategory = GroceryDictionary.getCategory(canonicalName);
    if (dictCategory != 'Other') {
      return dictCategory;
    }

    final textLower = '${canonicalName.toLowerCase()} ${rawText.toLowerCase()}';

    // 2. Keyword fallback rules
    if (RegExp(r'\b(oil|tel|tup|ghee|तेल|तूप|घी)\b').hasMatch(textLower)) {
      return 'Oils & Ghee';
    }

    if (RegExp(r'\b(dal|daal|rice|chawal|tandul|wheat|gahu|gehu|atta|flour|rava|besan|maida|pohe|poha|shabudana|sabudana|matki|moong|toor|masoor|chole|chhole|vatana|डाळ|दाल|तांदूळ|आटा|रवा|बेसन)\b').hasMatch(textLower)) {
      return 'Grains & Pulses';
    }

    if (RegExp(r'\b(masala|mirchi|haldi|halad|jeera|jira|mohri|rai|salt|meeth|mith|sugar|sakhar|shakkar|powder|pud|मसाला|मीठ|साखर)\b').hasMatch(textLower)) {
      return 'Spices & Staples';
    }

    if (RegExp(r'\b(biscuit|parle|bourbon|burbon|farsan|namkeen|shengdana|khobra|chaha|tea|chai|coffee|चहा|कॉफी|फरसाण)\b').hasMatch(textLower)) {
      return 'Snacks & Beverages';
    }

    if (RegExp(r'\b(soap|saban|sabun|surf|detergent|vim|matchbox|kadepeti|साबण|काडेपेटी)\b').hasMatch(textLower)) {
      return 'Household';
    }

    if (RegExp(r'\b(milk|dudh|doodh|curd|dahi|paneer|butter|cheese|दूध|दही|पनीर)\b').hasMatch(textLower)) {
      return 'Dairy';
    }

    return 'Groceries';
  }
}
