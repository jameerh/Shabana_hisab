import '../entities/transaction_model.dart';
import '../entities/voice_query_intent.dart';
import '../../data/database/database.dart';

class SnapParser {
  
  static final Map<String, List<String>> _intentMap = {
    'Income': [
      'जमा', 'प्राप्त', 'मिळकत', 'आवक', 'आय', 'इन्कम',
      'हाती आले', 'पैसे आले', 'रक्कम आली', 'जमा झाले', 'मिळालेत', 
      'आलेत', 'भेटले', 'भेटला', 'भेटली', 'पावले', 'कमवले', 'नफा', 'फायदा', 
      'उत्पन्न', 'उत्पन्न झाले', 'आलोत', 'गवसलं', 'पडले', 'हातात पडले', 'वसूल',
      'वसुली', 'रोजी आले', 'दिवसाची कमाई', 'आजची कमाई', 'उधारी वसूल', 'बिल आले', 
      'पेमेंट आले', 'पेमेंट मिळाले', 'ऑर्डर मिळाली', 'कॅश आली', 'गल्ल्यात टाकले',
      'गल्ला', 'कॅश काऊंटर', 'अडव्हान्स मिळाला', 'अडव्हान्स आला', 'विथड्रॉल',
      'कॅश दिली', 'एईपीएस', 'कस्टमर ने दिले', 'खात्यात आले',
      'जमा पावती', 'रिसीव्ह', 'रिसिव्ह', 'अकाउंटला आले',
      'फोनपे आले', 'गुगल पे आले', 'जीपे आले', 'पेटीएम आले', 'स्कॅन केले', 
      'upi आले', 'युपीआय', 'क्यूआर केले', 'ऑनलाईन आले',
      'मिळाला', 'मिल गया', 'मिल गए', 'बढ़ा', 'बरामद',
      'प्राप्त हुआ', 'आ चुके', 'मिळले', 'भेटले', 'कॅश आली', 'जमा केले', 'घेऊन आले', 'मिले', 'आ गए', 'आल्या',
      'aale', 'aala', 'mile', 'milale', 'milaleat', 'jama', 'getle', 'income', 'received', 'plus', 'aali', 'bhetle',
      // New Additions
      'credited', 'क्रेडिट झाले', 'account credited', 'खात्यात जमा', 'bank credit', 'पैसे घेतले', 'रक्कम घेतली', 'payment घेतलं',
      'स्कॅन करून पैसे आले', 'QR ने पैसे आले', 'UPI received', 'payment आला', 'cash आली', 'कमाई', 'सेल झाली', 'विक्री झाली',
      'sale झाली', 'sale zali', 'income aala', 'deposit aala', 'received payment', 'cash received', 'cash in', 'money received',
      'incoming', 'receipt', 'रिसीट आली', 'पेमेंट जमा', 'पेमेंट receive', 'fund received', 'transfer आला', 'bank transfer आला',
      'IMPS आला', 'NEFT आला', 'RTGS आला', 'phonepe आले', 'gpay आले', 'paytm आले', 'scanner payment आला', 'customer payment',
      'ग्राहकाने दिले', 'ग्राहकाकडून आले', 'उसूल', 'वसूल झाले', 'recovery', 'collection', 'जमा कर', 'वसुली'
    ],
    'Expense': [
      'दिले', 'खर्च', 'भरले', 'वजा', 'खरेदी', 'तोटा', 'नुकसान', 'खर्चिले',
      'घालवले', 'खर्च झाला', 'खर्च झाली', 'पैसे दिले', 
      'देऊन टाकले', 'चुकते केले', 'मोडले', 'वाटले', 'द्यावे लागले', 'निघाले',
      'सामान घेतला', 'माल घेतला', 'स्टॉक घेतला', 'भाडे दिले', 'लाईट बिल भरले', 
      'पाणी बिल भरले', 'मजुरी दिली', 'कामगार पैसे दिले', 'पगार दिला',
      'होलसेलरला दिले', 'डीलरला दिले', 'मेंटेनन्स', 'दुरुस्ती खर्च',
      'रिपेअरिंग ला दिले', 'वाहतूक खर्च', 'कूरियर चे दिले', 'डिपॉझिट केले',
      'बँकेत भरले', 'कमिशन कापले', 'चार्ज लागला', 'पेमेंट केले', 
      'डेबिट झाले', 'सेंड केले', 'ट्रान्सफर केले', 'हप्ता भरला', 'रिचार्ज मारला',
      'ऑनलाईन भरले', 'दिया', 'दिली', 'भरला', 'भरली', 
      'खर्च हो गया', 'दे दिया', 'चला गया', 'कट गए', 'पे किया', 'debit', 'debited', 'खर्चले', 'गेलेत', 'भरलेत',
      'dile', 'dila', 'dili', 'kharch', 'bharle', 'pay', 'paid', 'sent', 'minus', 'gave', 'cut', 'gela',
      // New Additions
      'ATM withdrawal', 'cash withdrawal', 'पैसे काढले', 'ATM मधून काढले', 'स्कॅन करून पैसे दिले', 'UPI पाठवले', 'payment केले',
      'खरेदी केली', 'purchase', 'purchase केले', 'purchase zala', 'stock घेतला', 'माल भरला', 'supplier ला दिले', 'vendor ला दिले',
      'rent दिले', 'भाडे', 'salary दिली', 'salary', 'wages', 'diesel', 'petrol', 'fuel', 'maintenance', 'repair', 'service charge',
      'packing', 'parcel खर्च', 'transport', 'delivery खर्च', 'emi', 'loan भरला', 'gst भरला', 'tax भरला', 'commission', 'brokerage',
      'charges', 'fee', 'subscription', 'renewal', 'recharge', 'bill भरला', 'electricity', 'internet', 'wifi', 'mobile recharge', 'office खर्च',
      'कापले', 'कापलं', 'कट झालं'
    ],
    'Udhaari': [
      'बाकी', 'उधारी', 'खात्यावर', 'कर्ज', 'उधार', 'बाकी आहे', 
      'देणे बाकी', 'येणे बाकी', 'उधार दिले', 'उधार घेतले', 'राहिले', 'राहिली',
      'नंतर देईल', 'लिहून ठेव', 'द्यायचेत', 'घ्यायचेत', 'बाकी राहिलं', 
      'बाकी ठेवा', 'उसणे दिले', 'हात उसणे', 'खात्यात टाक', 'उधारीत टाक', 
      'खात्यावर लिही', 'नामे', 'हिशोब बाकी', 'बुक मध्ये टाक', 'लोन',
      'वही मध्ये लिही', 'थकबाकी', 'येणे', 'देणे', 'पुढच्या वेळी देईल', 'उधार', 'loan', 'credit basis',
      'bakki', 'udhari', 'udhar',
      // Phonetic variations for udhari
      'उदार', 'उदर', 'उदारी', 'उदारे', 'उदहार',
      // New Additions
      'credit madhe', 'उचल', 'उचल दिली', 'उचल घेतली', 'खाते', 'खात्यात लिही', 'खात्यात टाका', 'उधारीत', 'नावावर', 'नावे',
      'खात्यावर दिले', 'खात्यावर गेले', 'बाकी ठेव', 'बाकी टाक', 'बाकी लिही', 'नंतर देतो', 'उद्या देतो', 'महिन्याला देतो',
      'on credit', 'pending payment', 'pending', 'receivable', 'payable', 'due', 'due amount', 'बाकी रक्कम', 'उसनं',
      'उसनं दिलं', 'उसनं घेतलं', 'हिशोबात टाक', 'नावावर टाक', 'बाकीत टाक', 'खात्यात लिहा', 'लिहून ठेवा'
    ],
  };

  static final Map<String, List<String>> _categoryKeywords = {
    'विक्री': ['विक्री', 'माल दिला', 'गल्ला', 'कमाई', 'सेल', 'sale'],
    'खरेदी': ['खरेदी', 'माल खरेदी', 'सामान', 'स्टॉक', 'होलसेल', 'purchase'],
    'उधारी': ['उधारी', 'उसणे', 'बाकी'],
    'भाडे': ['भाडे', 'रेंट', 'घराचे भाडे', 'गाडी भाडे', 'rent', 'भाडं'],
    'वीज बिल': ['वीज बिल', 'लाईट बिल', 'लाईट', 'मीटर', 'electricity', 'light bill'],
    'पाणी बिल': ['पाणी बिल', 'पाणी', 'water bill'],
    'पगार': ['पगार', 'मजुरी', 'सॅलरी', 'कामगार', 'salary', 'पगार दिला'],
    'पेट्रोल': ['पेट्रोल', 'डिझेल', 'इंधन', 'petrol', 'diesel'],
    'वाहतूक': ['वाहतूक', 'प्रवास', 'ट्रॅव्हल', 'टॅक्सी', 'रिक्षा', 'गाडी', 'भाडे दिले', 'बस', 'travel'],
    'किराणा': ['किराणा', 'माल', 'धान्य', 'साबण', 'grocery'],
    'भाजीपाला': ['भाजी', 'भाजीपाला', 'फळे', 'कांदा', 'बटाटा', 'vegetables'],
    'दूध': ['दूध', 'डेअरी', 'दही', 'milk', 'dairy'],
    'आरोग्य': ['आरोग्य', 'हॉस्पिटल', 'दवाखाना', 'औषध', 'मेडिकल', 'डॉक्टर', 'गोळ्या', 'hospital', 'medicine'],
    'शिक्षण': ['शिक्षण', 'शाळा', 'फी', 'क्लास', 'पुस्तके', 'वही', 'school', 'fee', 'education'],
    'मनोरंजन': ['मनोरंजन', 'चित्रपट', 'खेळ', 'पार्टी', 'movie'],
    'कपडे': ['कपडे', 'शर्ट', 'पँट', 'ड्रेस', 'clothes'],
    'दुरुस्ती': ['दुरुस्ती', 'रिपेअरिंग', 'गॅरेज', 'सर्व्हिसिंग', 'मेंटेनन्स', 'repair'],
    'कर': ['कर', 'टॅक्स', 'जीएसटी', 'gst', 'ग्रामपंचायत', 'tax'],
    'बँक': ['बँक', 'कमिशन', 'चार्जेस', 'व्याज', 'एटीएम', 'bank'],
    'बचत': ['बचत', 'गुंतवणूक', 'शेअर्स', 'म्युच्युअल फंड', 'savings'],
    'कर्ज': ['कर्ज', 'लोन', 'ईएमआय', 'emi', 'हप्ता', 'loan'],
    'इतर': ['इतर', 'किरकोळ', 'काहीतरी', 'खत', 'बियाणे', 'कटिंग', 'पार्ट्स', 'other']
  };

  static final Map<String, String> _learnedMap = {};

  static void learn(String keyword, String category) {
    final kw = keyword.trim().toLowerCase();
    if (kw.isNotEmpty && category.trim().isNotEmpty && kw != 'अज्ञात') {
      _learnedMap[kw] = category;
    }
  }

  int parseConfirmation(String input) {
    String text = input.toLowerCase();
    
    final yesWords = [
      'हो', 'होय', 'येस', 'yes', 'जतन', 'हां', 'save', 'ओके', 'ok', 'बरोबर', 
      'चालेल', 'कर', 'डन', 'done', 'नोंदवा', 'टाक', 'लिही', 'अस्सल',
      'अगदी बरोबर', 'सेव्ह कर', 'कन्फर्म', 'confirm', 'चालतेय'
    ];
    for (var w in yesWords) {
      if (RegExp('\\b$w\\b').hasMatch(text) || text.contains(w)) return 1;
    }

    final noWords = [
      'नाही', 'नाय', 'नाहीये', 'नको', 'no', 'रद्द', 'cancel', 'नहीं', 'नही', 'चुकलं', 
      'चुकीचे', 'wrong', 'नका', 'थांब', 'बदल', 'चूक', 'राहूदे', 'कॅन्सल'
    ];
    for (var w in noWords) {
      if (RegExp('\\b$w\\b').hasMatch(text) || text.contains(w)) return -1;
    }
    
    return 0;
  }

  static final Map<String, int> _numbers = {
    // 1 to 10
    'एक': 1, 'दोन': 2, 'दोनं': 2, 'तीन': 3, 'चार': 4, 'पाच': 5,
    'सहा': 6, 'सात': 7, 'आठ': 8, 'नऊ': 9, 'दहा': 10,
    
    // 11 to 20
    'अकरा': 11, 'बारा': 12, 'तेरा': 13, 'चौदा': 14, 'पंधरा': 15,
    'सोळा': 16, 'सतरा': 17, 'अठरा': 18, 'एकोणीस': 19, 'वीस': 20,

    // 21 to 30
    'एकवीस': 21, 'बावीस': 22, 'तेवीस': 23, 'चोवीस': 24, 'पंचवीस': 25,
    'सव्वीस': 26, 'सत्तावीस': 27, 'अठ्ठावीस': 28, 'एकोणतीस': 29, 'तीस': 30,

    // 31 to 40
    'एकतीस': 31, 'बत्तीस': 32, 'तेहतीस': 33, 'चौतीस': 34, 'पस्तीस': 35,
    'छतीस': 36, 'सदतीस': 37, 'अडतीस': 38, 'एकोणचाळीस': 39, 'चाळीस': 40,

    // 41 to 50
    'एक्केचाळीस': 41, 'बेचाळीस': 42, 'त्रेचाळीस': 43, 'चव्वेचाळीस': 44, 'पंचेचाळीस': 45,
    'शेचाळीस': 46, 'सत्तेचाळीस': 47, 'अठ्ठेचाळीस': 48, 'एकोणपन्नास': 49, 'पन्नास': 50,

    // 51 to 60
    'एकावन्न': 51, 'बावन्न': 52, 'त्रेपन्न': 53, 'चोपन्न': 54, 'पंचावन्न': 55,
    'छप्पन्न': 56, 'सत्तावन्न': 57, 'अठ्ठावन्न': 58, 'एकोणसाठ': 59, 'साठ': 60,

    // 61 to 70
    'एकसष्ट': 61, 'बासष्ट': 62, 'त्रेसष्ट': 63, 'चौसष्ट': 64, 'पासष्ट': 65,
    'सहासष्ट': 66, 'सदुसष्ट': 67, 'अडुसष्ट': 68, 'एकोणसत्तर': 69, 'सत्तर': 70,

    // 71 to 80
    'एकाहत्तर': 71, 'बाहत्तर': 72, 'त्र्याहत्तर': 73, 'चौऱ्याहत्तर': 74, 'पंच्याहत्तर': 75,
    'शहात्तर': 76, 'सत्त्याहत्तर': 77, 'अठ्ठ्याहत्तर': 78, 'एकोणऐंशी': 79, 'ऐंशी': 80,

    // 81 to 90
    'एक्क्याऐंशी': 81, 'ब्याऐंशी': 82, 'त्र्याऐंशी': 83, 'चौऱ्याऐंशी': 84, 'पंच्याऐंशी': 85,
    'शहाऐंशी': 86, 'सत्त्याऐंशी': 87, 'अठ्ठ्याऐंशी': 88, 'एकोणनव्वद': 89, 'नव्वद': 90,

    // 91 to 100
    'एक्क्याण्णव': 91, 'ब्याण्णव': 92, 'त्र्याण्णव': 93, 'चौऱ्याण्णव': 94, 'पंच्याण्णव': 95,
    'शहाण्णव': 96, 'सत्त्याण्णव': 97, 'अठ्ठ्याण्णव': 98, 'नव्व्याण्णव': 99, 'शंभर': 100,

    // Hundreds Variants
    'शे': 100, 
    'सव्वाशे': 125, 'दीडशे': 150, 'पावणेदोनशे': 175,
    'दोनशे': 200, 'दोनसे': 200, 'अडीचशे': 250,
    'तीनशे': 300, 'तीनसे': 300, 'साडेतीनशे': 350,
    'चारशे': 400, 'चारसे': 400, 'साडेचारशे': 450,
    'पाचशे': 500, 'पाचसे': 500, 'साडेपाचशे': 550,
    'सहाशे': 600, 'सहासे': 600, 'साडेसहाशे': 650,
    'सातशे': 700, 'सातसे': 700, 'साडेसातशे': 750,
    'आठशे': 800, 'आठसे': 800, 'साडेआठशे': 850,
    'नऊशे': 900, 'नऊसे': 900, 'साडेनऊशे': 950,
    
    // Thousands Combinations
    'अकराशे': 1100, 'बाराशे': 1200, 'तेराशे': 1300, 'चौदाशे': 1400,
    'पंधराशे': 1500, 'सोळाशे': 1600, 'सतराशे': 1700, 'अठराशे': 1800, 'एकोणीसशे': 1900,
    
    // Base Units
    'हजार': 1000, 'लाख': 100000, 'करोड': 10000000, 'कोटी': 10000000
  };

  static final Map<String, double> _multipliers = {
    'सव्वा': 1.25, 'दीड': 1.5, 'पावणे दोन': 1.75, 'अडीच': 2.5,
    'साडे': 1.5, 'पावणे': 0.75, 'अर्धा': 0.5, 'पाऊण': 0.75, 'पाव': 0.25,
  };

  static final List<String> _stopWords = [
    'काल', 'आज', 'उद्या', 'परवा', 'तेरवा', 'रोज', 'नेहमी',
    'रात्री', 'सकाळी', 'दुपारी', 'संध्याकाळी', 'पहाटे',
    'सोमवारी', 'मंगळवारी', 'बुधवारी', 'गुरुवारी', 'शुक्रवारी', 'शनिवारी', 'रविवारी',
    'महिन्यात', 'आठवड्यात', 'दिवसा', 'तारखेला', 'महिन्याला', 'वर्षी',
    'जानेवारी', 'फेब्रुवारी', 'मार्च', 'एप्रिल', 'मे', 'जून', 'जुलै', 'ऑगस्ट', 'सप्टेंबर', 'ऑक्टोबर', 'नोव्हेंबर', 'डिसेंबर',
    'ने', 'मध्ये', 'साठी', 'करिता', 'बद्दल', 'वर', 'खाली', 'जवळ',
    'कडून', 'पासून', 'पर्यंत', 'चे', 'ची', 'चा', 'च्या', 'कडे', 'विषयी',
    'आणि', 'व', 'पण', 'परंतु', 'किंवा', 'तसेच', 'जर', 'तर', 'म्हणून',
    'रुपये', '₹', 'रु', 'रुपया', 'पैसे', 'कॅश', 'रोख', 'रुपयाचे', 'रुपयांची',
    'नोटा', 'सुट्टे', ' चिल्लर',
    'आला', 'आली', 'झालं', 'गेला', 'गेली', 'केल',
    'असतात', 'असतील', 'असेल', 'होतो', 'होती', 'होणार',
    'माझे', 'तुझे', 'त्याचे', 'तिचे', 'आपले', 'त्यांना', 'त्याला', 'तिला', 'मला', 'तुला',
    'इथे', 'तिथे', 'कुठे', 'का', 'काय', 'कधी', 'कसं', 'कसे', 'कोण',
    'बरं', 'ठीक', 'चालेल', 'नाही', 'नको', 'असेल', 'नसतील', 'दे', 'घे',
    'एकदा', 'परत', 'पुन्हा', 'आधी', 'नंतर', 'सध्या', 'आता', 'मगाशी',
    'थोडे', 'जास्त', 'कमी', 'भरपूर', 'सगळे', 'सर्व',
    'अं', 'अरे', 'हं', 'हो', 'म्हणजे', 'तर', 'असं', 'तसं', 'कसंय', 'बघ',
    'बिल', 'रसीद', 'एंट्री', 'नोंद', 'नोंदवा', 'टाका', 'लिहा',
    'सेव्ह', 'जतन', 'ओके', 'done', 'ok', 'खाते', 'अकाउंट', 'रजिस्टर',
    'ne', 'se', 'kadun', 'rupaye', 'rupaya', 'rupees', 'rs'
  ];

  String _normalize(String input) {
    String text = input.toLowerCase();

    // Force Devanagari numbers to digits immediately (Google STT compatibility)
    text = text.replaceAll('०', '0').replaceAll('१', '1').replaceAll('२', '2')
               .replaceAll('३', '3').replaceAll('४', '4').replaceAll('५', '5')
               .replaceAll('६', '6').replaceAll('७', '7').replaceAll('८', '8')
               .replaceAll('९', '9');

    // Handle hybrid STT digit + 'शे' patterns e.g. "13शे" -> "1300", "12 शे" -> "1200", "1 शे" -> "100"
    text = text.replaceAllMapped(RegExp(r'(\d+)\s*शे(?=[^\u0900-\u097F]|$)'), (m) {
      final multiplier = int.tryParse(m.group(1)!) ?? 1;
      return ' ${multiplier * 100} ';
    });

    // General phrase corrections
    final phraseCorrections = {
      'उदार': 'उधार',
      'उदर': 'उधार',
      'उदारी': 'उधारी',
      'उदारे': 'उधार',
      'उदहार': 'उधार',
      
      // Hundreds combinations (1100 to 1900)
      'अकराशे': ' 1100 ',
      'बाराशे': ' 1200 ',
      'तेराशे': ' 1300 ',
      'चौदाशे': ' 1400 ',
      'पंधराशे': ' 1500 ',
      'सोळाशे': ' 1600 ',
      'सतराशे': ' 1700 ',
      'अठराशे': ' 1800 ',
      'एकोणीसशे': ' 1900 ',

      // Fractional Hundreds
      'सव्वाशे': ' 125 ',
      'दीडशे': ' 150 ',
      'पावणेदोनशे': ' 175 ',
      'अडीचशे': ' 250 ',
      'साडेतीनशे': ' 350 ',
      'साडेचारशे': ' 450 ',
      'साडेपाचशे': ' 550 ',
      'साडेसहाशे': ' 650 ',
      'साडेसातशे': ' 750 ',
      'साडेआठशे': ' 850 ',
      'साडेनऊशे': ' 950 ',

      // Standard Hundreds
      'दोनशे': ' 200 ',
      'तीनशे': ' 300 ',
      'चारशे': ' 400 ',
      'पाचशे': ' 500 ',
      'सहाशे': ' 600 ',
      'सातशे': ' 700 ',
      'आठशे': ' 800 ',
      'नऊशे': ' 900 ',

      'हजार': ' 1000 ',
      'लाख': ' 100000 ',
      'करोड': ' 10000000 ',
      'कोटी': ' 10000000 ',
      'शंभर': ' 100 ',
      'बात से': 'कडून', 'पास से': 'कडून', 'तरफ से': 'कडून', 'के पास से': 'कडून',
      'की तरफ से': 'कडून', 'करो': 'कडून', 'रन बनाए': 'मिळाले', 'बढ़ा है': 'मिळाले',
      'बरामद': 'मिळाले', 'मिल गया': 'मिळाले', 'मिल गए': 'मिळाले', 'आ गया': 'आले',
      'मिलाई': 'मिळाले', 'दे दिया': 'दिले', 'खर्च हो गया': 'खर्च', 'भर दिया': 'भरले',
      'चला गया': 'गेले', 'ले लिया': 'घेतले', 'लेना': 'घेतले', 'प्राप्त किया': 'प्राप्त',
      'हजार रुपए': '1000', 'लाख रुपए': '100000',
    };

    phraseCorrections.forEach((wrong, correct) {
      text = text.replaceAll(wrong, correct);
    });

    // Handle hybrid STT digit + 'शे' patterns e.g. "13शे" -> "1300", "12 शे" -> "1200", "1 शे" -> "100"
    text = text.replaceAllMapped(RegExp(r'(\d+)\s*शे\b'), (m) {
      final multiplier = int.tryParse(m.group(1)!) ?? 1;
      return ' ${multiplier * 100} ';
    });

    // 🔥 CONTROLLED PHONETIC FIXES (Safe)
    if (RegExp(r'^\s*संपर्क\s*$').hasMatch(text)) {
      text = '100';
    }

    // MASSIVE PHONETIC NUMBER CORRECTIONS
    final wordCorrections = {
      // Shambhar (100) variants
      r'\bशंबर\b': 'शंभर', r'\bछंभर\b': 'शंभर', r'\bचंभर\b': 'शंभर', r'\bएक सौ\b': 'शंभर',
      r'\bशंभर\b': '100',
      
      // Pachshe (500) variants
      r'\bपासशे\b': 'पाचशे', r'\bपांचशे\b': 'पाचशे', r'\bपांचसे\b': 'पाचशे', 
      r'\bपांच सौ\b': 'पाचशे', r'\bपाससे\b': 'पाचशे', 

      // Other hundreds variants
      r'\bदोनसे\b': 'दोनशे', r'\bदो सौ\b': 'दोनशे',
      r'\bतीनसे\b': 'तीनशे', r'\bतीन सौ\b': 'तीनशे',
      r'\bचारसे\b': 'चारशे', r'\bचार सौ\b': 'चारशे',
      r'\bसहासे\b': 'सहाशे', r'\bछह सौ\b': 'सहाशे', r'\bसासे\b': 'सहाशे',
      r'\bसातसे\b': 'सातशे', r'\bसात सौ\b': 'सातशे',
      r'\bआठसे\b': 'आठशे', r'\bआठ सौ\b': 'आठशे',
      r'\bनऊसे\b': 'नऊशे', r'\bनौ सौ\b': 'नऊशे', r'\bनवसे\b': 'नऊशे',

      // Hazar (1000) variants
      r'\bहजारो\b': 'हजार', r'\bहाजार\b': 'हजार', r'\bअजार\b': 'हजार',

      // Decimals / Fractions
      r'\bडेढ सौ\b': '150', r'\bढाई सौ\b': '250', 
      r'\bचवा\b': 'सव्वा', r'\bदिड\b': 'दीड', r'\bअडीज\b': 'अडीच',

      // Tens variants
      r'\bपणास\b': 'पन्नास', r'\bपन्नाश\b': 'पन्नास', r'\bपचास\b': '50',
      r'\bचालीस\b': 'चाळीस', r'\bचाळीश\b': 'चाळीस', r'\bचालीस\b': '40',
      r'\bबीस\b': '20', r'\bतीस\b': '30', r'\bसाठ\b': '60', 
      r'\bसत्तर\b': '70', r'\bअस्सी\b': '80', r'\bनब्बे\b': '90',

      // Core Grammar Fixes
      r'\bकरून\b': 'कडून', r'\bमधे\b': 'मध्ये', r'\bबढ़ा\b': 'मिळाले',
      r'\bबडा\b': 'मिळाले', r'\bदिया\b': 'दिले', r'\bदिये\b': 'दिले',
      r'\bलिए\b': 'घेतले', r'\bपांच\b': 'पाच', r'\bपाँच\b': 'पाच',
      r'\bदो\b': 'दोन', r'\bहै\b': '', r'\bथा\b': '', r'\bथे\b': '', 
      r'\bगया\b': '', r'\bगई\b': '', r'\bहुआ\b': '', 
      r'\bरुपये\b': '', r'\bरु\b': '', r'\bरुपया\b': '', r'\bरू\b': '',
      r'\bरुपयांची\b': '', r'\bरुपयाचे\b': '',
      
      // Common missing numbers/transliteration
      r'\bफिफ्टी\b': '50', r'\bहंड्रेड\b': '100', r'\bथर्टी\b': '30',
      r'\bट्वेंटी\b': '20', r'\bटेन\b': '10', r'\bथाउजंड\b': '1000',
      r'\bवन\b': '1', r'\bटू\b': '2', r'\bथ्री\b': '3', 
      r'\bफोर\b': '4', r'\bफाईव्ह\b': '5', r'\bसिक्स\b': '6',
      r'\bविस\b': '20', r'\bतीष\b': '30', r'\bपन्नास\b': '50',
      r'(?<=\d)\s*शे\b': '00', r'\bशे\b': '100',
      r'\bशंभर\b': '100', r'\bदोनशे\b': '200', r'\bपाचशे\b': ' 500 ', r'\bपाच शे\b': ' 500 ',
      r'\bहजार\b': ' 1000 ', r'\bदोन हजार\b': ' 2000 ',
      r'(^|\s)एक(?=\s|$)': r'$1 1 ', r'(^|\s)दोन(?=\s|$)': r'$1 2 ', 
      r'(^|\s)तीन(?=\s|$)': r'$1 3 ', r'(^|\s)चार(?=\s|$)': r'$1 4 ', 
      r'(^|\s)पाच(?=\s|$)': r'$1 5 ', r'(^|\s)सहा(?=\s|$)': r'$1 6 ', 
      r'(^|\s)सात(?=\s|$)': r'$1 7 ', r'(^|\s)आठ(?=\s|$)': r'$1 8 ', 
      r'(^|\s)नऊ(?=\s|$)': r'$1 9 ', r'(^|\s)दहा(?=\s|$)': r'$1 10 ',
      r' लाल ': ' ला ', r' लाल$': ' ला',
      r'\bसो\b': ' ', r'\bसौ\b': ' ',
      
      // Marathlish Number Phonetics
      r'\bteenashe\b': ' 300 ', r'\bteen she\b': ' 300 ', r'\btinashe\b': ' 300 ', r'\btin she\b': ' 300 ',
      r'\bdonashe\b': ' 200 ', r'\bdon she\b': ' 200 ', r'\bdonshe\b': ' 200 ',
      r'\bpachashe\b': ' 500 ', r'\bpach she\b': ' 500 ', r'\bpachshe\b': ' 500 ', r'\bpachsher\b': ' 500 ',
      r'\bcharashe\b': ' 400 ', r'\bchar she\b': ' 400 ', r'\bcharshe\b': ' 400 ',
      r'\bsahashe\b': ' 600 ', r'\bsatashe\b': ' 700 ', r'\batashe\b': ' 800 ', r'\bnavashe\b': ' 900 ',
      r'\bshambhar\b': ' 100 ', r'\bekshe\b': ' 100 ', r'\bek she\b': ' 100 ', r'\bambhar\b': ' 100 ',
      r'\bhazar\b': ' 1000 ', r'\bhajar\b': ' 1000 ', r'\bhajaar\b': ' 1000 ',
      r'\bek\b': ' 1 ', r'\bdon\b': ' 2 ', r'\bteen\b': ' 3 ', r'\bchar\b': ' 4 ', r'\bpaach\b': ' 5 ',
      r'\bsaha\b': ' 6 ', r'\bsaat\b': ' 7 ', r'\baath\b': ' 8 ', r'\bnau\b': ' 9 ', r'\bdah\b': ' 10 ',
      
      // Marathlish Action Phonetics
      r'\bdile\b': ' दिले ', r'\bdila\b': ' दिले ', r'\baale\b': ' आले ', r'\baala\b': ' आले ',
      r'\bbakki\b': ' बाकी ', r'\budhari\b': ' उधारी ', r'\brupaye\b': ' रुपये ', r'\brupay\b': ' रुपये ',
      r'\bgave\b': ' दिले ', r'\bgiven\b': ' दिले ', r'\breceived\b': ' आले ', r'\bgot\b': ' आले ',
      r'\btook\b': ' घेतले ', r'\btaken\b': ' घेतले ', r'\bspend\b': ' खर्च ', r'\bspent\b': ' खर्च ',
      r'\bpay\b': ' दिले ', r'\bpaid\b': ' दिले ',
      r'\bhundread\b': ' 100 ', r'\bthousand\b': ' 1000 ', r'\bfive hundred\b': ' 500 ',
      r'\bpasso\b': ' 500 ', r'\bpanchaso\b': ' 500 ', r'\bshambher\b': ' 100 ',
      r'\bhajar\b': ' 1000 ', r'\bajan\b': ' 1000 ',
      r'\bmilale\b': ' मिळाले ', r'\bmilala\b': ' मिळाला ', r'\bmilali\b': ' मिळाली ',
      r'\bmille\b': ' मिळाले ', r'\bmilaale\b': ' मिळाले ', r'\bmilele\b': ' मिळाले ',
      r'\bdile\b': ' दिले ', r'\bdila\b': ' दिला ', r'\bdili\b': ' दिली ',
      r'\bसो\b': '', r'\bसौ\b': '',
      r'\bdeela\b': ' दिला ', r'\bdele\b': ' दिले ',
      r'\bghetle\b': ' घेतले ', r'\bghetla\b': ' घेतला ', r'\bghetli\b': ' घेतली ',
      r'\bgetle\b': ' घेतले ', r'\bkatle\b': ' घेतले ',
    };

    wordCorrections.forEach((wrong, correct) {
      text = text.replaceAllMapped(RegExp(wrong), (m) {
        if (m.groupCount > 0) {
          // Handle cases like r'(^|\s)एक(?=\s|$)' where $1 is the prefix
          return '${m.group(1)}${correct.replaceFirst(r'$1', '')}';
        }
        return correct;
      });
    });

    // 🔥 SAFE NUMBER NORMALIZATION
    // Avoids $1 corruption by using replaceAllMapped
    text = text.replaceAllMapped(RegExp(r'\d+'), (m) => ' ${m.group(0)} ');

    // Convert digit + शे patterns (e.g. "13 शे" -> "1300", "12 शे" -> "1200", "1 शे" -> "100")
    text = text.replaceAllMapped(RegExp(r'(\d+)\s*शे(?=[^\u0900-\u097F]|$)'), (m) {
      final multiplier = int.tryParse(m.group(1)!) ?? 1;
      return ' ${multiplier * 100} ';
    });

    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Public wrapper for HomeView
  String normalizePublic(String input) => _normalize(input);

  DateTime _extractTime(String text) {
    DateTime now = DateTime.now();
    
    // Pattern for specific date like "10 तारखेला" or "10 तारीख"
    final dateMatch = RegExp(r'(\d+)\s*(तारखेला|तारीख|tarikh)').firstMatch(text);
    if (dateMatch != null) {
      int day = int.parse(dateMatch.group(1)!);
      if (day >= 1 && day <= 31) {
        try {
          return DateTime(now.year, now.month, day);
        } catch (e) {
          return now;
        }
      }
    }

    if (text.contains('काल रात्री')) return now.subtract(const Duration(days: 1)).copyWith(hour: 21, minute: 0);
    if (text.contains('आज सकाळी')) return now.copyWith(hour: 9, minute: 0);
    if (text.contains('काल सकाळी')) return now.subtract(const Duration(days: 1)).copyWith(hour: 9, minute: 0);
    if (text.contains('काल')) return now.subtract(const Duration(days: 1));
    if (text.contains('परवा')) return now.subtract(const Duration(days: 2));
    if (text.contains('तेरवा')) return now.subtract(const Duration(days: 3));
    return now;
  }

  double _extractAmount(List<String>? words, String fullInput) {
    // Normalize Devanagari digits to ASCII digits in the input first
    String processedInput = fullInput.toLowerCase();
    processedInput = processedInput
        .replaceAll('०', '0')
        .replaceAll('१', '1')
        .replaceAll('२', '2')
        .replaceAll('३', '3')
        .replaceAll('४', '4')
        .replaceAll('५', '5')
        .replaceAll('६', '6')
        .replaceAll('७', '7')
        .replaceAll('८', '8')
        .replaceAll('९', '9');

    // 🔥 STEP 1: Direct digit extraction (PRIMARY)
    final matches = RegExp(r'\d+').allMatches(processedInput);

    if (matches.isNotEmpty) {
      final numbers = matches.map((e) => int.parse(e.group(0)!)).toList();

      // Case: "एक से 50" -> [1, 50]
      if (numbers.length == 2 && processedInput.contains('से')) {
        return (numbers[0] * 100).toDouble() + numbers[1];
      }

      // Case: Multi-number compound arithmetic
      // Handles both multipliers (e.g. [3, 1000] -> 3000, [5, 100] -> 500)
      // AND additive increments (e.g. [1300, 50] -> 1350, [1000, 50] -> 1050, [1000, 200, 50] -> 1250)
      double total = 0;
      double current = 0;
      for (int i = 0; i < numbers.length; i++) {
        int n = numbers[i];
        if (n == 100 || n == 1000 || n == 100000 || n == 10000000) {
          total += (current == 0 ? 1 : current) * n;
          current = 0;
        } else if (current > 0 && n < current) {
          // If previous was a higher base (e.g. 1000, 1200, 1300, 500) and current is smaller (e.g. 50)
          total += current + n;
          current = 0;
        } else {
          if (current > 0) {
            total += current;
          }
          current = n.toDouble();
        }
      }
      total += current;

      // Also check if any residual Marathi number word is adjacent (e.g. "1300 पन्नास" or "1000 पन्नास")
      if (words != null) {
        for (var w in words) {
          if (_numbers.containsKey(w)) {
            final val = _numbers[w]!;
            if (val < 100) {
              total += val;
            }
          }
        }
      }

      if (total > 0) {
        return total;
      }

      // Default: take the first number found
      return numbers.first.toDouble();
    }

    // 2. Fallback to word-based extraction for purely Marathi words
    double total = 0;
    double currentSegment = 0;
    for (int i = 0; i < (words?.length ?? 0); i++) {
      final w = words![i].trim();
      if (_numbers.containsKey(w)) {
        int val = _numbers[w]!;
        if (val == 1000 || val == 100000) {
          total += (currentSegment == 0 ? 1 : currentSegment) * val;
          currentSegment = 0;
        } else if (val == 100) {
          total += (currentSegment == 0 ? 1 : currentSegment) * 100;
          currentSegment = 0;
        } else {
          currentSegment += val;
        }
      }
    }
    return total + currentSegment;
  }

  String _detectIntent(String text) {
    String bestIntent = 'Expense'; 
    int maxScore = 0;

    _intentMap.forEach((type, keywords) {
      int score = 0;
      
      // Give more priority to exact longer phrase matches
      for (var k in keywords) {
        if (text.contains(k)) {
          // If the keyword has spaces (phrase), give it more weight
          score += k.contains(' ') ? 4 : 2; 
        } else if (RegExp('\\b$k\\b').hasMatch(text)) {
          score += 2;
        }
      }
      
      if (type == 'Udhaari' && (text.contains('उधारीत') || text.contains('बाकी'))) score += 6;
      if (type == 'Income' && text.contains('कडून')) score += 5; 
      if (type == 'Expense' && text.contains('खरेदी')) score += 4;
      if (type == 'Expense' && text.contains('लाईट बिल')) score += 4;
      if (type == 'Udhaari' && text.contains('खात्यात')) score += 4;
      if (type == 'Income' && text.contains('विथड्रॉल')) score += 4; 

      if (score > maxScore) {
        maxScore = score;
        bestIntent = type;
      }
    });

    return bestIntent;
  }

  bool _similar(String a, String b) {
    if (a == b) return true;
    if (a.length < 3 || b.length < 3) return false;
    return a.startsWith(b) || b.startsWith(a);
  }

  String _cleanParty(String party) {
    party = party.replaceAll(RegExp(r'[^\w\s\u0900-\u097F]'), '').trim();
    
    // Remove temporal prefixes
    if (party.startsWith('काल') && party.length > 3) {
      if (!RegExp(r'^[\u093E-\u094C\u094D]').hasMatch(party.substring(3))) {
         party = party.substring(3).trim();
      }
    } else if (party.startsWith('आज') && party.length > 2) {
      if (!RegExp(r'^[\u093E-\u094C\u094D]').hasMatch(party.substring(2))) {
         party = party.substring(2).trim();
      }
    } else if (party.startsWith('उद्या') && party.length > 4) {
      if (!RegExp(r'^[\u093E-\u094C\u094D]').hasMatch(party.substring(4))) {
         party = party.substring(4).trim();
      }
    }

    // Strip trailing Marathi case suffixes (vibhakti pratyay)
    final suffixesToStrip = ['कडून', 'साठी', 'पासून', 'पर्यंत', 'लाही', 'च्या'];
    for (var suffix in suffixesToStrip) {
      if (party.endsWith(suffix) && party.length > suffix.length + 2) {
        party = party.substring(0, party.length - suffix.length).trim();
        break;
      }
    }

    // Strip shorter ambiguous suffixes only if they leave a valid name of at least 3 characters
    final shortSuffixes = ['ला', 'ने', 'चे', 'ची', 'चा', 'कडे', 'तून'];
    for (var suffix in shortSuffixes) {
      if (party.endsWith(suffix) && party.length > suffix.length + 2) {
        party = party.substring(0, party.length - suffix.length).trim();
        break;
      }
    }

    // Filter out common Marathi pronouns from becoming party names
    final marathiPronouns = {
      'मला', 'तुला', 'त्याला', 'तिला', 'आपल्याला', 'स्वता', 'स्वतः',
      'तुम्हाला', 'आम्हाला', 'त्यांना', 'माझ्या', 'तुझ्या', 'त्याच्या', 'तिच्या'
    };
    if (marathiPronouns.contains(party.toLowerCase()) || marathiPronouns.contains(party)) {
      return 'अज्ञात';
    }

    if (party.length <= 2 || party.isEmpty) return 'अज्ञात';
    return party;
  }

  bool _isCategoryWord(String w, List<Category>? categories) {
    // Check built-in keywords
    for (var list in _categoryKeywords.values) {
      if (list.contains(w)) return true;
    }
    
    if (categories == null) return false;

    for (var cat in categories) {
      if (cat.name.toLowerCase() == w.toLowerCase()) return true;

      final kws = cat.keywords?.split(',') ?? [];
      for (var k in kws) {
        if (k.trim().toLowerCase() == w.toLowerCase()) return true;
      }
    }

    return false;
  }

  String _extractParty(String input, List<String> words, List<Category>? categories) {
    // 1. Pattern based extraction
    final patterns = [
      RegExp(r'(.+?)(कडून|kade|kadun)'),
      RegExp(r'(.+?)(?<!\s)(ला|la)\b'),
      RegExp(r'(.+?)(ने|ne)'),
    ];

    for (var p in patterns) {
      final match = p.firstMatch(input);
      if (match != null) {
        String res = match.group(1)!.trim();
        // Remove any numeric prefixes that might have been caught
        res = res.replaceAll(RegExp(r'^\d+\s*'), '');
        // Clean potential party from category words
        List<String> pWords = res.split(RegExp(r'\s+'));
        List<String> cleanedPWords = [];
        for (var pw in pWords) {
          if (!_isCategoryWord(pw, categories) && !_stopWords.contains(pw)) {
            cleanedPWords.add(pw);
          }
        }
        String potentialParty = cleanedPWords.join(' ').trim();

        if (potentialParty.isNotEmpty && double.tryParse(potentialParty) == null) {
           return _cleanParty(potentialParty);
        }
      }
    }

    // 2. Fallback: accumulate words that are not numbers, stop words, intents, or categories
    List<String> partyWords = [];

    for (var w in words) {
      if (_numbers.containsKey(w)) continue;
      if (double.tryParse(w) != null) continue;
      if (_stopWords.contains(w)) continue;
      
      bool isIntent = false;
      _intentMap.forEach((_, list) {
        if (list.contains(w)) isIntent = true;
      });
      if (isIntent) continue;

      if (_isCategoryWord(w, categories)) continue;

      partyWords.add(w);
    }

    String pName = partyWords.join(' ').trim();
    if (pName.isNotEmpty) {
       pName = _cleanParty(pName);
    }
    return pName.isEmpty || pName == 'अज्ञात'
        ? "अज्ञात"
        : pName;
  }

  String? _detectCategory(String input, String profileType, List<Category>? activeCategories) {
    // 1. Learned mapping
    for (var key in _learnedMap.keys) {
      if (input.contains(key)) return _learnedMap[key];
    }

    // Removed profile keywords completely since we have a streamlined 22-category list

    // 3. Fallback active categories
    if (activeCategories != null && activeCategories.isNotEmpty) {
      for (var cat in activeCategories) {
        final keywords = cat.keywords?.split(',') ?? [cat.name];
        for (var kw in keywords) {
          if (kw.trim().isNotEmpty && input.contains(kw.trim().toLowerCase())) {
            return cat.name;
          }
        }
      }
    }

    // 4. Built-in global fallback
    for (var catName in _categoryKeywords.keys) {
      for (var kw in _categoryKeywords[catName]!) {
        if (input.contains(kw.trim().toLowerCase())) {
          return catName;
        }
      }
    }

    return null;
  }

  TransactionModel? parse(
    String input, {
    required String profileType,
    required int profileId,
    List<Category>? activeCategories,
    List<String>? knownParties,
  }) {
    if (input.trim().isEmpty) return null;

    // BIFURCATION: Only split if it looks like two separate transactions
    // Otherwise process as one whole sentence for better context
    List<String> segments = [input];
    if (input.contains(RegExp(r'\d+.*(आणि|and|व).*\d+'))) {
      segments = input.split(RegExp(r'\s+(आणि|and|व)\s+'));
    }
    
    String primaryInput = segments.first;

    input = _normalize(primaryInput);
    if (input.isEmpty) return null;

    DateTime time = _extractTime(input);

    // Clean input from date pattern to avoid amount interference
    String amountInput = input.replaceAll(RegExp(r'\d+\s*(तारखेला|तारीख|tarikh)'), '').trim();

    List<String> words = amountInput
        .split(RegExp(r'\s+'))
        .where((w) => !_stopWords.contains(w) && w.isNotEmpty)
        .toList();

    if (words.isEmpty) return null;

    double amount = _extractAmount(words, amountInput);
    
    print("RAW: $primaryInput");
    print("NORMALIZED: $input");
    print("AMOUNT: $amount");

    if (amount == 0) {
      // Try fallback to the second segment if the first has no amount
      if (segments.length > 1) {
        return parse(segments[1], profileType: profileType, profileId: profileId, activeCategories: activeCategories);
      }
      return null; 
    }

    String type = _detectIntent(input);
    String? category = _detectCategory(input, profileType, activeCategories);
    String party = _extractParty(input, words, activeCategories);

    return TransactionModel(
      amount: amount,
      partyName: party,
      type: type,
      categoryName: category ?? "अज्ञात",
      profileId: profileId,
      timestamp: time,
      createdAt: DateTime.now(),
    );
  }

  VoiceQueryIntent? parseVoiceIntent(String rawInput) {
    String input = _normalize(rawInput);
    
    // 1. Action Detection
    if (input.contains('डिलीट') || input.contains('काढून टाक')) {
      if (input.contains('शेवटचा') || input.contains('मागचा') || input.contains('last')) {
        return VoiceQueryIntent(type: IntentType.action, actionTarget: ActionTarget.deleteLast);
      }
    }
    if (input.contains('अंडू') || input.contains('undo') || input.contains('मागे घे')) {
      return VoiceQueryIntent(type: IntentType.action, actionTarget: ActionTarget.undo);
    }

    // 2. Query Detection
    bool isQuery = input.contains('किती') || input.contains('सांग') || input.contains('दाखव') || 
                   input.contains('how much') || input.contains('show') || input.contains('total');
    
    if (isQuery) {
      QueryTarget target = QueryTarget.unknown;
      String? category;
      String? person;
      DateTime? date;

      if (input.contains('आज')) {
        target = QueryTarget.todayTotal;
        date = DateTime.now();
      } else if (input.contains('महिना')) {
        target = QueryTarget.monthTotal;
      }

      // Detect Category in Query
      for (var catName in _categoryKeywords.keys) {
        for (var kw in _categoryKeywords[catName]!) {
          if (input.contains(kw)) {
            category = catName;
            target = QueryTarget.categoryTotal;
            break;
          }
        }
        if (category != null) break;
      }

      return VoiceQueryIntent(
        type: IntentType.query,
        queryTarget: target,
        category: category,
        person: person,
        date: date,
      );
    }

    return null;
  }
}