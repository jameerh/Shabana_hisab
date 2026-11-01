import 'package:flutter/material.dart';

class CategoryIconHelper {
  static IconData getIconForCategory(String name, String? keywords) {
    final search = (name + (keywords ?? "")).toLowerCase();

    // KIRANA / FOOD
    if (search.contains('किराणा') || search.contains('तेल') || search.contains('साखर') || search.contains('खाद्य') || search.contains('दूध') || search.contains('हॉटेल')) {
      return Icons.local_grocery_store;
    }
    
    // CSC / ONLINE / BANKING
    if (search.contains('सीएससी') || search.contains('ऑनलाईन') || search.contains('बँकिंग') || search.contains('एईपीएस') || search.contains('पॅन') || search.contains('आधार')) {
      return Icons.account_balance;
    }

    // ELECTRICAL / MOBILE
    if (search.contains('इलेक्ट्रिकल') || search.contains('मोबाईल') || search.contains('रिचार्ज') || search.contains('लाईट') || search.contains('बल्ब')) {
      return Icons.electrical_services;
    }

    // TRANSPORT / AUTO
    if (search.contains('वाहतूक') || search.contains('पेट्रोल') || search.contains('डिझेल') || search.contains('ऑटो') || search.contains('रिक्षा')) {
      return Icons.directions_car;
    }

    // AGRICULTURE
    if (search.contains('शेती') || search.contains('खत') || search.contains('बियाणे') || search.contains('ट्रॅक्टर')) {
      return Icons.agriculture;
    }

    // SALON
    if (search.contains('सलून') || search.contains('कटिंग') || search.contains('दाढी')) {
      return Icons.content_cut;
    }

    // HEALTH
    if (search.contains('आरोग्य') || search.contains('औषध') || search.contains('दवाखाना') || search.contains('मेडिकल')) {
      return Icons.medical_services;
    }

    // BILLS / TAX / RENT
    if (search.contains('बिल') || search.contains('कर') || search.contains('भाडे') || search.contains('टॅक्स')) {
      return Icons.receipt_long;
    }

    // EDUCATION
    if (search.contains('शिक्षण') || search.contains('शाळा') || search.contains('पुस्तक')) {
      return Icons.school;
    }

    // CLOTHES
    if (search.contains('खरेदी') || search.contains('कपडे') || search.contains('शॉपिंग')) {
      return Icons.shopping_bag;
    }

    // INVESTMENTS
    if (search.contains('गुंतवणूक') || search.contains('ट्रेडिंग') || search.contains('शेअर्स')) {
      return Icons.trending_up;
    }

    // TRAVEL / ENTERTAINMENT
    if (search.contains('प्रवास') || search.contains('सिनेमा') || search.contains('नाटक')) {
      return Icons.movie;
    }

    // SALARY / WAGES
    if (search.contains('पगार') || search.contains('मजुरी') || search.contains('हमाल')) {
      return Icons.payments;
    }

    return Icons.label; // Default
  }
}
