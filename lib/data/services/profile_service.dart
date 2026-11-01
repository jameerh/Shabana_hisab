import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import '../../main.dart';
import 'package:drift/drift.dart' as drift;

class ProfileService {
  static const String _activeProfileIdKey = 'active_profile_id';
  static int? _cachedActiveId;
  static ProfileType? _cachedActiveType;

  // Ensure Initialized: Checks defaults and caches active IDs
  static Future<void> ensureInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if profiles exist in DB
    final profiles = await database.select(database.profiles).get();
    
    if (profiles.isEmpty) {
      // Seed default profiles
      await createDefaultProfiles();
    } else {
      // Check if categories are empty (e.g. user deleted them)
      final categories = await database.select(database.categories).get();
      if (categories.isEmpty) {
        for (var p in profiles) {
          await _seedDefaultCategoriesForProfile(p.id, p.type);
        }
      }
      
      // Check if units are empty
      final units = await database.select(database.units).get();
      if (units.isEmpty) {
        await seedDefaultUnits();
      }
    }

    final id = prefs.getInt(_activeProfileIdKey);
    
    if (id == null) {
      // Default to first profile (usually SHOP or FARMER)
      final allProfiles = await database.select(database.profiles).get();
      if (allProfiles.isNotEmpty) {
        await setActiveProfileId(allProfiles.first.id);
      }
    } else {
      // Load into cache
      _cachedActiveId = id;
      final profile = await (database.select(database.profiles)..where((p) => p.id.equals(id))).getSingleOrNull();
      if (profile != null) {
        _cachedActiveType = profile.type;
      } else {
         // Fallback if deleted somehow
        final allProfiles = await database.select(database.profiles).get();
        if (allProfiles.isNotEmpty) {
          await setActiveProfileId(allProfiles.first.id);
        }
      }
    }
  }

  static Future<int> getActiveProfileId() async {
    if (_cachedActiveId != null) return _cachedActiveId!;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activeProfileIdKey) ?? 1; // Fallback to 1
  }

  static Future<ProfileType> getActiveProfileType() async {
    if (_cachedActiveType != null) return _cachedActiveType!;
    final id = await getActiveProfileId();
    final profile = await (database.select(database.profiles)..where((p) => p.id.equals(id))).getSingleOrNull();
    return profile?.type ?? ProfileType.SHOP;
  }

  static Future<void> setActiveProfileId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeProfileIdKey, id);
    _cachedActiveId = id;
    
    final profile = await (database.select(database.profiles)..where((p) => p.id.equals(id))).getSingleOrNull();
    if (profile != null) {
      _cachedActiveType = profile.type;
    }
  }

  static Future<List<Profile>> getProfiles() async {
    return await database.select(database.profiles).get();
  }

  static Future<void> createDefaultProfiles() async {
    final defaultProfiles = [
      ProfilesCompanion.insert(name: 'माझे दुकान (My Shop)', type: ProfileType.SHOP),
    ];

    for (var p in defaultProfiles) {
      final pid = await database.into(database.profiles).insert(p);
      await _seedDefaultCategoriesForProfile(pid, p.type.value);
    }
  }

  static Future<void> _seedDefaultCategoriesForProfile(int profileId, ProfileType type) async {
    List<Map<String, String>> categoryData = [];
    
    switch (type) {
      case ProfileType.SHOP:
        categoryData = [
          {'name': 'इलेक्ट्रिकल आणि इलेक्ट्रॉनिक्स', 'keywords': 'वायर,केबल,स्विच,बोर्ड,बल्ब,लाईट,फॅन,मोटर'},
          {'name': 'सीएससी आणि ऑनलाईन सेवा', 'keywords': 'पॅन कार्ड,आधार,झेरॉक्स,प्रिंट,तिकीट,ऑनलाईन फॉर्म'},
          {'name': 'बँकिंग आणि एईपीएस', 'keywords': 'एईपीएस,कॅश विथड्रॉल,कॅश डिपॉझिट,मनी ट्रान्सफर,खाते,पासबुक'},
          {'name': 'किराणा आणि खाद्य', 'keywords': 'किराणा,तेल,साखर,गहू,तांदूळ,साबण,खाद्य'},
          {'name': 'वाहतूक आणि ऑटो', 'keywords': 'पेट्रोल,डिझेल,प्रवास,ऑटो,रिक्षा,सर्व्हिसिंग'},
          {'name': 'बिल, कर आणि भाडे', 'keywords': 'लाईट बिल,पाणी बिल,भाडे,टॅक्स,gst'},
          {'name': 'मोबाईल आणि डिजिटल सेवा', 'keywords': 'रिचार्ज,मोबाईल,डेटा,कव्हर,चार्जर'},
          {'name': 'दुकान आणि देखभाल खर्च', 'keywords': 'सामान,स्टॉक,भाडे,दुरुस्ती,मेंटेनन्स'},
          {'name': 'पगार आणि मजुरी', 'keywords': 'पगार,मजुरी,कामगार,हमाल'},
          {'name': 'शेती आणि खत (पुरवठाकर्ते)', 'keywords': 'खत,बियाणे,औषध फवारणी,ट्रॅक्टर'},
        ];
        break;
      case ProfileType.FARMER:
        categoryData = [
          {'name': 'शेती आणि खत', 'keywords': 'खत,युरिया,बियाणे,फवारणी,ट्रॅक्टर,मजुरी,ठिबक'},
          {'name': 'वाहतूक आणि ऑटो', 'keywords': 'पेट्रोल,डिझेल,प्रवास,ऑटो,रिक्षा,सर्व्हिसिंग'},
          {'name': 'किराणा आणि खाद्य', 'keywords': 'भाजी,किराणा,तेल,खाद्य,जेवण'},
          {'name': 'आरोग्य आणि वैद्यकीय', 'keywords': 'औषध,डॉक्टर,दवाखाना,मेडिकल'},
        ];
        break;
      case ProfileType.SALON:
        categoryData = [
          {'name': 'सलून सेवा', 'keywords': 'कटिंग,दाढी,हेअर,शेव,कलर,फेशियल'},
          {'name': 'दुकान खर्च', 'keywords': 'सामान,भाडे,लाईट बिल,पाणी बिल'},
          {'name': 'किराणा आणि खाद्य', 'keywords': 'चहा,नाश्ता,जेवण,खाद्य'},
        ];
        break;
      case ProfileType.PERSONAL:
        categoryData = [
          {'name': 'किराणा आणि खाद्य', 'keywords': 'किराणा,भाजी,पोळी,दूध,नाश्ता,हॉटेल'},
          {'name': 'बिल, कर आणि भाडे', 'keywords': 'लाईट बिल,पाणी बिल,भाडे,रेंट,टॅक्स'},
          {'name': 'मनोरंजन आणि प्रवास', 'keywords': 'सिनेमा,प्रवास,पेट्रोल,तिकीट'},
          {'name': 'आरोग्य आणि वैद्यकीय', 'keywords': 'औषध,डॉक्टर,हॉस्पिटल,मेडिकल'},
          {'name': 'गुंतवणूक आणि ट्रेडिंग', 'keywords': 'शेअर्स,म्युच्युअल फंड,एसआयपी,गुंतवणूक,ट्रेडिंग'},
          {'name': 'शिक्षण आणि खरेदी', 'keywords': 'फी,शाळा,कॉलेज,पुस्तक,खरेदी,कपडे'},
        ];
        break;
    }

    for (var cat in categoryData) {
      await database.into(database.categories).insert(CategoriesCompanion.insert(
        name: cat['name']!,
        keywords: cat['keywords']!,
        type: 'Expense', // default
        profileType: drift.Value(type.name),
      ));
    }
    
    // Always add an Unknown category for fallback
    await database.into(database.categories).insert(CategoriesCompanion.insert(
      name: 'अज्ञात',
      keywords: '',
      type: 'Expense',
      profileType: drift.Value(type.name),
    ));
  }

  static Future<void> seedDefaultUnits() async {
    final defaultUnits = ['kg', 'gm', 'liter', 'ml', 'pack', 'nos', 'dozen', 'bundle'];
    for (var u in defaultUnits) {
      await database.addUnit(UnitsCompanion.insert(name: u, normalizedName: u.toLowerCase()));
    }
  }
}
