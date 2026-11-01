import 'package:flutter/material.dart';
import '../recurring/recurring_manager_view.dart';
import '../recurring/recurring_assistant_wizard.dart';
import 'package:flutter/services.dart'; 
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../domain/parser/snap_parser.dart';
import '../../data/services/voice_service.dart';
import '../../data/services/pdf_service.dart';
import '../../domain/entities/transaction_model.dart';
import '../../domain/entities/transaction_action.dart';
import 'dart:async';
import '../../main.dart';
import '../../data/database/database.dart';
import '../../data/services/profile_service.dart';
import '../analytics/analytics_view.dart';
import 'package:drift/drift.dart' as drift;
import '../categories/category_view.dart';
import '../categories/category_icon_helper.dart';
import '../profiles/profile_view.dart';
import '../settings/settings_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/core/config/app_config.dart';
import '../../data/services/backup_service.dart';
import '../../data/services/auth_service.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/services/voice_log_service.dart';
import '../../domain/entities/voice_query_intent.dart';
import '../quick_tools/quick_calculator_view.dart';
import '../quick_tools/grocery_notes_view.dart';
import '../quick_tools/unit_management_view.dart';
import '../quick_tools/mileage_calculator_view.dart';
import '../health/health_home_view.dart';
import '../planning/financial_planning_hub.dart';
import 'widgets/intelligence_dashboard_section.dart';
import 'widgets/transaction_tile.dart';
import 'models/filter_criteria.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/sort_bottom_sheet.dart';
import 'widgets/home_composition_widget.dart';
import 'widgets/universal_command_center.dart';
import 'widgets/balance_summary.dart';
import 'widgets/greeting_section.dart';
import 'widgets/smart_mic_fab.dart';
import '../../core/localization/bilingual_text.dart';
import '../../l10n/app_localizations.dart';
import '../../core/security/subscription_manager.dart';
import '../subscription/subscription_modal.dart';
import '../../core/services/review_prompt_service.dart';
import '../core/widgets/ad_interstitial_modal.dart';
import '../core/promotion_settings_view.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  final SnapParser _parser = SnapParser();
  final VoiceService _voiceService = VoiceService();
  final TextEditingController _textController = TextEditingController();
  
  late TextEditingController _confirmAmountCtrl;
  late TextEditingController _confirmNameCtrl;
  late TextEditingController _confirmKmCtrl;
  late TextEditingController _confirmLitersCtrl;
  String? _calculatedMileage;
  String _confirmType = 'Expense';
  String? _confirmCategory;
  List<String> _allCategoryNames = [];
  DateTime _confirmDate = DateTime.now();
  List<String> _pendingImages = [];


  TransactionModel? _pendingTransaction;
  bool _isListening = false;
  Timer? _saveTimer;
  Timer? _silenceTimer; 
  double _progressValue = 0.0;
  String _rawLog = "Raw Voice Log...";
  List<String> _suggestions = [];
  String _lastText = ""; 
  String _lastPartialText = "";
  bool _wasResultHandled = false;
  Function(String)? _onTargetedListenComplete;
  String? _voiceQueryResult;
  
  late AnimationController _pulsateController;
  late AnimationController _progressController;

  // Undo / Redo Stacks
  final List<TransactionAction> _undoHistory = [];
  final List<TransactionAction> _redoHistory = [];

  // Profiles
  int? _activeProfileId;
  List<Profile> _allProfiles = [];
  String _activeProfileName = 'Loading...';

  // Filters & Sorting
  String _searchQuery = "";
  String _sortBy = "DATE_DESC";
  FilterCriteria _filterCriteria = FilterCriteria();
  bool _isBackupOverdue = false;
  
  // Selection Mode
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};
  bool _isBalanceExpanded = false;

  @override
  void initState() {
    super.initState();
    
    _confirmAmountCtrl = TextEditingController();
    _confirmNameCtrl = TextEditingController();
    _confirmKmCtrl = TextEditingController();
    _confirmLitersCtrl = TextEditingController();

    _initProfiles();
    _setupVoiceListener();
    _checkBackupStatus();
    _checkMondayReviewPrompt();
    
    _pulsateController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
      
    _progressController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 3)
    )..addListener(() {
        setState(() {
          _progressValue = _progressController.value;
        });
      });
  }

  Future<void> _initProfiles() async {
    final activeId = await ProfileService.getActiveProfileId();
    final allProfiles = await ProfileService.getProfiles();
    
    setState(() {
      _activeProfileId = activeId;
      _allProfiles = allProfiles;
      _activeProfileName = allProfiles.firstWhere((p) => p.id == activeId, orElse: () => allProfiles.first).name;
    });

    if (activeId != null) {
      intelligenceOrchestrator.runPipeline(activeId);
    }
  }

  Future<void> _checkBackupStatus() async {
    final overdue = await BackupService.isBackupOverdue();
    setState(() => _isBackupOverdue = overdue);
  }

  Future<void> _checkMondayReviewPrompt() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final shouldShow = await ReviewPromptService.shouldShowMondayPrompt();
      if (shouldShow && mounted) {
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          ReviewPromptService.showReviewModal(context);
        }
      }
    });
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 15), () {
      if (_isListening) {
        _stopListening();
        setState(() => _rawLog = "शांतता (Silence Timeout)");
        
        if (!_wasResultHandled && _lastPartialText.isNotEmpty) {
          _processFinalText(_lastPartialText);
        }
      }
    });
  }

  void _setupVoiceListener() {
    _voiceService.onTextResult.listen((rawText) {
      if (rawText.startsWith("ERROR:")) {
        String err = rawText.substring(6).trim();
        setState(() {
          if (err.contains("error_no_match")) {
            _rawLog = "काहीही ऐकू आले नाही. पुन्हा बोला.";
          } else if (err.contains("error_speech_timeout")) {
            _rawLog = "वेळ संपली. पुन्हा प्रयत्न करा.";
          } else {
            _rawLog = "त्रुटी: $err";
          }
          _isListening = false;
        });
        return;
      }

      if (rawText.startsWith("STATUS:")) {
        String status = rawText.substring(7);
        if (status.contains("Using mr")) {
          setState(() => _rawLog = "मराठी मोड सुरू होत आहे...");
        } else if (status == "listening") {
          setState(() {
            _rawLog = "बोलणे सुरू करा...";
            _isListening = true;
            _wasResultHandled = false;
            _lastPartialText = "";
          });
        } else if (status == "notListening") {
          if (_isListening) {
             setState(() => _isListening = false);
             if (!_wasResultHandled && _lastPartialText.isNotEmpty) {
               _processFinalText(_lastPartialText);
             }
          }
        }
        return;
      }

      _resetSilenceTimer(); 

      if (rawText.startsWith("PARTIAL:")) {
        String partialText = rawText.substring(8).trim();
        if (partialText.isEmpty) return; 
        setState(() {
          _lastPartialText = partialText;
          _rawLog = "Hearing: $partialText";
        });
        return;
      }

      _processFinalText(rawText);
    });
  }

  void _processFinalText(String rawText) {
    if (_wasResultHandled) return;
    String text = rawText.toLowerCase().trim();
    text = text.replaceAll(RegExp(r'[^\w\s\u0900-\u097F\.]'), '');

    if (text.isEmpty) return; 
    if (text == _lastText) return;
    _lastText = text;
    _wasResultHandled = true;

    try {
      final normalized = _parser.normalizePublic(text);
      print("VOICE PARSER INPUT: '$text'");
      print("VOICE PARSER NORMALIZED: '$normalized'");

      setState(() {
        _rawLog = "Recognized: $normalized";
      });

      HapticFeedback.mediumImpact();
      _stopListening();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (_onTargetedListenComplete != null) {
          _onTargetedListenComplete!(text);
          _onTargetedListenComplete = null;
        } else {
          _handleParsedText(normalized);
        }
      });
    } catch (e) {
      setState(() {
        _rawLog = "Parser Error: $e";
        _isListening = false;
      });
    }
  }
  
  void _startListening({Function(String)? onTargetedComplete}) async {
    try {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
          setState(() {
            _rawLog = "Microphone permission denied.";
            _isListening = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Permission error: $e");
    }

    try {
      HapticFeedback.lightImpact(); 
      setState(() {
        _isListening = true;
        _lastText = ""; 
        _rawLog = "Mic Starting..."; 
        _onTargetedListenComplete = onTargetedComplete;
        _wasResultHandled = false;
      });
      
      await _voiceService.startNativeGoogleVoice();
    } catch (e) {
      setState(() {
        _isListening = false;
        _rawLog = "ERROR: App crashed while starting mic - $e";
        _onTargetedListenComplete = null;
      });
    }
  }

  void _stopListening() async {
    _silenceTimer?.cancel();
    await _voiceService.stopListening();
    setState(() => _isListening = false);
  }

  Future<void> _pickImages({Function(List<String>)? onComplete}) async {
    final ImagePicker picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () => Navigator.pop(context, ImageSource.camera)),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
          ],
        ),
      ),
    );

    if (source != null) {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await picker.pickMultiImage();
        if (images.isNotEmpty) {
          if (onComplete != null) onComplete(images.map((i) => i.path).toList());
          else setState(() => _pendingImages.addAll(images.map((i) => i.path)));
        }
      } else {
        final XFile? image = await picker.pickImage(source: source);
        if (image != null) {
          if (onComplete != null) onComplete([image.path]);
          else setState(() => _pendingImages.add(image.path));
        }
      }
    }
  }


  void _handleParsedText(String text) async {
    if (_pendingTransaction != null) {
      int confirm = _parser.parseConfirmation(text);
      if (confirm == 1) {
        final updatedTx = TransactionModel(
          amount: double.tryParse(_confirmAmountCtrl.text) ?? _pendingTransaction!.amount,
          partyName: _confirmNameCtrl.text,
          type: _confirmType,
          categoryName: _confirmCategory,
          profileId: _pendingTransaction!.profileId,
          timestamp: _confirmDate,
        );
        _saveTransaction(updatedTx);
        setState(() {
          _textController.clear();
          _voiceQueryResult = null;
        });
      } else if (confirm == -1) {
        _cancelTransaction();
        setState(() {
          _textController.clear();
          _voiceQueryResult = null;
        });
      }
      return;
    }

    // 🔥 Check for Voice Intents (Queries/Actions)
    final intent = _parser.parseVoiceIntent(text);
    if (intent != null) {
      _handleVoiceIntent(intent);
      return;
    }
    
    if (_activeProfileId == null) return;
    final activeProfileType = await ProfileService.getActiveProfileType();
    final activeCategories = await database.select(database.categories).get();
    final parsed = _parser.parse(
      text, 
      profileType: activeProfileType.name,
      profileId: _activeProfileId!,
      activeCategories: activeCategories
    );
    
    if (parsed != null) {
      setState(() {
        _textController.clear();
        _suggestions.clear();
        _pendingTransaction = parsed;
        _confirmAmountCtrl.text = parsed.amount.toStringAsFixed(0);
        _confirmNameCtrl.text = parsed.partyName;
        _confirmType = parsed.type;
        _allCategoryNames = {...activeCategories.map((c) => c.name), "अज्ञात"}.toList();
        _confirmCategory = parsed.categoryName ?? "अज्ञात";
        if (!_allCategoryNames.contains(_confirmCategory)) {
          _confirmCategory = "अज्ञात";
        }
        _confirmDate = parsed.timestamp;
        _pendingImages = []; // Reset images for new transaction
        _confirmKmCtrl.clear();
        _confirmLitersCtrl.clear();
        _calculatedMileage = null;
      });
    } else {

      setState(() {
        _textController.text = text;
        _rawLog = "FAIL: No amount in '$text'"; 
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('व्यवहार समजला नाही. कृपया रक्कम आणि नाव स्पष्ट सांगा.'))
      );
      Future.delayed(const Duration(seconds: 1), () => _startListening());
    }
  }

  void _handleVoiceIntent(VoiceQueryIntent intent) async {
    if (intent.type == IntentType.action) {
      if (intent.actionTarget == ActionTarget.deleteLast) {
        final lastTx = await (database.select(database.transactions)
          ..where((t) => t.profileId.equals(_activeProfileId!))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.id)])
          ..limit(1)).getSingleOrNull();
        if (lastTx != null) {
          _deleteTransaction(lastTx);
        }
      } else if (intent.actionTarget == ActionTarget.undo) {
        _undo();
      }
    } else if (intent.type == IntentType.query) {
      double total = 0;
      String message = "";

      if (intent.queryTarget == QueryTarget.todayTotal) {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final txs = await (database.select(database.transactions)
          ..where((t) => t.profileId.equals(_activeProfileId!) & t.timestamp.isBiggerOrEqualValue(startOfDay))).get();
        
        for (var t in txs) {
          if (t.type == 'Expense') total += t.amount;
        }
        message = "आजचा एकूण खर्च: ₹${total.toStringAsFixed(0)}";
      } else if (intent.queryTarget == QueryTarget.categoryTotal && intent.category != null) {
        final txs = await (database.select(database.transactions)
          ..where((t) => t.profileId.equals(_activeProfileId!) & t.categoryName.equals(intent.category!))).get();
        
        for (var t in txs) {
          if (t.type == 'Expense') total += t.amount;
        }
        message = "${intent.category} वरील खर्च: ₹${total.toStringAsFixed(0)}";
      }

      if (message.isNotEmpty) {
        setState(() {
          _voiceQueryResult = message;
          _rawLog = message;
        });
        HapticFeedback.mediumImpact();
        // Clear message after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _voiceQueryResult = null);
        });
      }
    }
  }

  void _updateSuggestions(String input) async {
    if (input.isEmpty) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions.clear());
      return;
    }
    final categories = await database.select(database.categories).get();
    setState(() {
      _suggestions = categories
          .map((c) => c.name)
          .where((c) => c.toLowerCase().startsWith(input.toLowerCase()))
          .toList();
    });
  }

  void _cancelTransaction() {
    _saveTimer?.cancel();
    _progressController.stop();
    setState(() {
      _pendingTransaction = null;
      _makeRecurring = false;
    });
  }

  void _recordAction(TransactionAction action) {
    setState(() {
      _undoHistory.add(action);
      if (_undoHistory.length > 10) _undoHistory.removeAt(0);
      _redoHistory.clear();
    });
  }

  Future<void> _saveTransaction(TransactionModel tx) async {
    if (_activeProfileId == null) return;
    final entry = TransactionsCompanion.insert(
      amount: tx.amount,
      partyName: tx.partyName,
      type: tx.type,
      categoryName: drift.Value(tx.categoryName ?? "अज्ञात"),
      timestamp: tx.timestamp,
      profileId: _activeProfileId!,
      images: drift.Value(tx.images != null ? jsonEncode(tx.images) : null),
      metadata: drift.Value(tx.metadata != null ? jsonEncode(tx.metadata) : null),
    );

    final id = await database.into(database.transactions).insert(entry);
    final newTx = TransactionModel(
      id: id,
      amount: tx.amount,
      partyName: tx.partyName,
      type: tx.type,
      categoryName: tx.categoryName,
      profileId: _activeProfileId!,
      timestamp: tx.timestamp,
      createdAt: DateTime.now(),
      images: tx.images,
      metadata: tx.metadata,
    );

    if (tx.partyName.isNotEmpty && tx.partyName != "अज्ञात" && tx.categoryName != null && tx.categoryName != "अज्ञात") {
      SnapParser.learn(tx.partyName, tx.categoryName!);
    }
    _recordAction(TransactionAction(type: ActionType.add, current: newTx));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('सेव्ह केले: ₹${tx.amount} ${tx.partyName}')));
    setState(() {
      _pendingTransaction = null;
    });
    
    if (_makeRecurring) {
      _makeRecurring = false; // reset
      if (context.mounted) {
        RecurringAssistantWizard.show(context, _activeProfileId!); // TODO: Pre-fill wizard values
      }
    }
    
    // Refresh intelligence pipeline after save
    intelligenceOrchestrator.runPipeline(_activeProfileId!);
  }

  void _deleteTransaction(Transaction tx) async {
    final txModel = TransactionModel(
      id: tx.id, amount: tx.amount, partyName: tx.partyName, type: tx.type, categoryName: tx.categoryName, profileId: tx.profileId, timestamp: tx.timestamp, createdAt: tx.createdAt,
    );
    await database.deleteTransaction(tx);
    _recordAction(TransactionAction(type: ActionType.delete, current: txModel));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('व्यवहार डिलीट केला'), action: SnackBarAction(label: 'अंडू', onPressed: _undo)));
    
    // Refresh intelligence pipeline after delete
    intelligenceOrchestrator.runPipeline(tx.profileId);
  }

  void _undo() async {
    if (_undoHistory.isEmpty) return;
    final action = _undoHistory.removeLast();
    _redoHistory.add(action);
    HapticFeedback.lightImpact();
    if (action.type == ActionType.delete) {
      await database.into(database.transactions).insert(TransactionsCompanion.insert(
        id: drift.Value(action.current.id!), amount: action.current.amount, partyName: action.current.partyName, type: action.current.type, categoryName: drift.Value(action.current.categoryName ?? "अज्ञात"), profileId: action.current.profileId, timestamp: action.current.timestamp, createdAt: drift.Value(action.current.createdAt ?? DateTime.now()),
      ));
    } else if (action.type == ActionType.add) {
      await database.transactions.deleteWhere((t) => t.id.equals(action.current.id!));
    } else if (action.type == ActionType.edit && action.previous != null) {
      await database.updateTransaction(Transaction(
        id: action.previous!.id!, amount: action.previous!.amount, partyName: action.previous!.partyName, type: action.previous!.type, categoryName: action.previous!.categoryName, profileId: action.previous!.profileId, timestamp: action.previous!.timestamp, createdAt: action.previous!.createdAt ?? DateTime.now(),
      ));
    }
    setState(() {});
    
    // Refresh intelligence pipeline after undo
    if (_activeProfileId != null) {
      intelligenceOrchestrator.runPipeline(_activeProfileId!);
    }
  }

  void _redo() async {
    if (_redoHistory.isEmpty) return;
    final action = _redoHistory.removeLast();
    _undoHistory.add(action);
    HapticFeedback.lightImpact();
    if (action.type == ActionType.delete) {
      await database.transactions.deleteWhere((t) => t.id.equals(action.current.id!));
    } else if (action.type == ActionType.add) {
       await database.into(database.transactions).insert(TransactionsCompanion.insert(
        id: drift.Value(action.current.id!), amount: action.current.amount, partyName: action.current.partyName, type: action.current.type, categoryName: drift.Value(action.current.categoryName ?? "अज्ञात"), profileId: action.current.profileId, timestamp: action.current.timestamp, createdAt: drift.Value(action.current.createdAt ?? DateTime.now()),
      ), mode: drift.InsertMode.replace);
    } else if (action.type == ActionType.edit) {
       await database.updateTransaction(Transaction(
        id: action.current.id!, amount: action.current.amount, partyName: action.current.partyName, type: action.current.type, categoryName: action.current.categoryName, profileId: action.current.profileId, timestamp: action.current.timestamp, createdAt: action.current.createdAt ?? DateTime.now(),
      ));
    }
    setState(() {});
    
    // Refresh intelligence pipeline after redo
    if (_activeProfileId != null) {
      intelligenceOrchestrator.runPipeline(_activeProfileId!);
    }
  }

  void _showFullScreenImage(String path, {VoidCallback? onChange}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (onChange != null)
              Positioned(
                bottom: 40,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("फोटो बदला (Change Photo)"),
                  onPressed: () {
                    Navigator.pop(context);
                    onChange();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _editTransactionDialog(Transaction tx) async {
    TextEditingController amountCtrl = TextEditingController(text: tx.amount.toString());
    TextEditingController nameCtrl = TextEditingController(text: tx.partyName);
    String selectedType = tx.type;
    int selectedProfileId = tx.profileId;
    final categories = await database.select(database.categories).get();
    String? selectedCategory = tx.categoryName ?? "अज्ञात";
    DateTime selectedDate = tx.timestamp;
    List<String> currentImages = [];
    try {
      if (tx.images != null) {
        currentImages = List<String>.from(jsonDecode(tx.images!));
      }
    } catch (e) {
      debugPrint("Image parse error: $e");
    }


    showDialog(context: context, builder: (context) {
      final l10n = AppLocalizations.of(context);

      return StatefulBuilder(builder: (context, setStateDialog) {
        final unknownLabel = l10n?.unknownCategory ?? "अज्ञात";
        final allNames = {...categories.map((c) => c.name), unknownLabel}.toList();
        if (!allNames.contains(selectedCategory)) selectedCategory = unknownLabel;

        return AlertDialog(
          title: BilingualText(
            english: 'Edit Transaction',
            marathi: 'व्यवहार संपादित करा',
            languageController: languageController,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  decoration: InputDecoration(
                    labelText: l10n?.amount ?? 'Amount',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.mic, color: Colors.blue),
                      onPressed: () {
                        _startListening(onTargetedComplete: (text) {
                          final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
                          if (digits.isNotEmpty) setStateDialog(() => amountCtrl.text = digits);
                        });
                      },
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n?.nameOptional ?? 'Party Name (Optional)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.mic, color: Colors.blue),
                      onPressed: () {
                        _startListening(onTargetedComplete: (text) => setStateDialog(() => nameCtrl.text = text));
                      },
                    ),
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: ['Income', 'Expense', 'Udhaari'].map((t) {
                    final displayLabel = t == 'Income'
                        ? (l10n?.income ?? 'Income')
                        : (t == 'Expense' ? (l10n?.expense ?? 'Expense') : (l10n?.creditShort ?? 'Credit'));
                    return DropdownMenuItem(value: t, child: Text(displayLabel));
                  }).toList(),
                  onChanged: (val) => setStateDialog(() => selectedType = val!),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: allNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                  onChanged: (val) => setStateDialog(() => selectedCategory = val!),
                  decoration: InputDecoration(labelText: l10n?.category ?? 'Category'),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                    Text('Time: ${selectedDate.hour}:${selectedDate.minute.toString().padLeft(2, '0')}'),
                  ]),
                  TextButton(onPressed: () async {
                    DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime.now());
                    if (picked != null) {
                      TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(selectedDate));
                      if (time != null) {
                        setStateDialog(() => selectedDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute));
                      }
                    }
                  }, child: Text(l10n?.changeDate ?? 'Change Date')),
                ]),

                  const SizedBox(height: 16),
                  BilingualText(
                    english: 'Photos',
                    marathi: 'फोटो',
                    languageController: languageController,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...currentImages.map((path) => Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _showFullScreenImage(path, onChange: () {
                              _pickImages(onComplete: (paths) {
                                if (paths.isNotEmpty) {
                                  setStateDialog(() {
                                    final index = currentImages.indexOf(path);
                                    if (index != -1) {
                                      currentImages[index] = paths.first;
                                      if (paths.length > 1) {
                                        currentImages.addAll(paths.skip(1));
                                      }
                                    }
                                  });
                                }
                              });
                            }),
                            child: Image.file(File(path), width: 60, height: 60, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 0, top: 0,
                            child: GestureDetector(
                              onTap: () => setStateDialog(() => currentImages.remove(path)),
                              child: Container(color: Colors.black54, child: const Icon(Icons.close, size: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      )),
                      GestureDetector(
                        onTap: () => _pickImages(onComplete: (paths) => setStateDialog(() => currentImages.addAll(paths))),
                        child: Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.add_a_photo)),
                      ),
                    ],
                  ),
                ],
              ),
            ),


            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('कॅन्सल')),
              ElevatedButton(onPressed: () async {
                final updatedTx = tx.copyWith(
                  amount: double.tryParse(amountCtrl.text) ?? tx.amount, 
                  partyName: nameCtrl.text, 
                  type: selectedType, 
                  categoryName: drift.Value(selectedCategory), 
                  timestamp: selectedDate, 
                  profileId: selectedProfileId,
                  images: drift.Value(currentImages.isNotEmpty ? jsonEncode(currentImages) : null),
                );
                await database.updateTransaction(updatedTx);
                Navigator.pop(context);
              }, child: const Text('अपडेट करा'))
            ],
          );
        },
      );
    });
  }



  Future<void> _shareTransactionPdf(Transaction tx) async {
    // Show brief professional ad (800ms) before opening the share system dialog
    await AdInterstitialModal.show(context, duration: const Duration(milliseconds: 800));

    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    File? file;
    try { file = await PdfService.generateReceiptFile(tx); } catch (e) { debugPrint("PDF Error: $e"); }
    if (mounted) Navigator.pop(context); 
    if (file != null) await Share.shareXFiles([XFile(file.path)], text: 'Receipt for Rs.${tx.amount}');
  }

  Color _getTypeColor(String type) {
    if (type == 'Income') return Colors.green;
    if (type == 'Expense') return Colors.red;
    return Colors.orange;
  }

  Widget _buildFilterChip(String label, String? type) {
    final isSelected = _filterCriteria.type == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) => setState(() => _filterCriteria = _filterCriteria.copyWith(type: val ? type : null)),
        selectedColor: Colors.green.withOpacity(0.2),
        checkmarkColor: Colors.green,
      ),
    );
  }

  Widget _buildHeaderToolButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSortButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuButton<String>(
      onSelected: (val) => setState(() => _sortBy = val),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'DATE_DESC', child: Text('तारीख (नवीनतम)')),
        const PopupMenuItem(value: 'DATE_ASC', child: Text('तारीख (जुने)')),
        const PopupMenuItem(value: 'NAME_ASC', child: Text('नावानुसार (A-Z)')),
        const PopupMenuItem(value: 'AMOUNT_DESC', child: Text('रक्कम (जास्त)')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareCurrentListPdf() async {
    if (_activeProfileId == null) return;

    // Show brief professional ad (800ms) before sharing current report
    await AdInterstitialModal.show(context, duration: const Duration(milliseconds: 800));
    if (!mounted) return;

    final includeChart = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('रिपोर्ट चार्ट? (Include Chart?)'),
        content: const Text('तुम्हाला रिपोर्टमध्ये पाय चार्ट (Pie Chart) समाविष्ट करायचा आहे का?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('नाही (No)')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('हो (Yes)')),
        ],
      ),
    ) ?? false;
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      final transactions = await database.watchTransactionsFiltered(
        profileId: _activeProfileId!,
        type: _filterCriteria.type,
        startDate: _filterCriteria.startDate,
        endDate: _filterCriteria.endDate,
        sortBy: _sortBy,
      ).first;
      
      if (transactions.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('शेअर करण्यासाठी व्यवहार नाहीत')));
        return;
      }
      
      Navigator.pop(context);
      await PdfService.generateListPdf(
        transactions: transactions, 
        profileName: _activeProfileName,
        filterDesc: _filterCriteria.type ?? 'सर्व (All)',
        includeChart: includeChart,
      );
    } catch (e) {
      Navigator.pop(context);
      debugPrint("PDF Report Error: $e");
    }
  }

  void _copySelected() {
    // Implement copy to clipboard logic for selected items
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('निवडलेले व्यवहार कॉपी केले')));
    setState(() { _isSelectionMode = false; _selectedIds.clear(); });
  }

  void _shareSelected() async {
    // Implement selective sharing
    setState(() { _isSelectionMode = false; _selectedIds.clear(); });
  }

  void _deleteSelected() async {
    for (var id in _selectedIds) {
      final tx = await (database.select(database.transactions)..where((t) => t.id.equals(id))).getSingle();
      await database.deleteTransaction(tx);
    }
    setState(() { _isSelectionMode = false; _selectedIds.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF00796B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/shabana Hisab App.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.account_balance_wallet, color: Colors.green, size: 36),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppConfig.appName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'बोलून हिशेब करा',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'Voice-First Expense Manager',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 1. Core Financial Features
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.blueAccent),
              title: BilingualText(
                english: 'Financial Planning',
                marathi: 'आर्थिक नियोजन',
                languageController: languageController,
              ),
              onTap: () {
                Navigator.pop(context);
                if (_activeProfileId != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => FinancialPlanningHubView(profileId: _activeProfileId!)));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.blue),
              title: BilingualText(
                english: 'Analytics',
                marathi: 'एनालिटिक्स',
                languageController: languageController,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => AnalyticsView()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_repeat, color: Colors.indigo),
              title: BilingualText(
                english: 'Recurring Assistant',
                marathi: 'नियमित खर्च सहाय्यक',
                languageController: languageController,
              ),
              onTap: () {
                Navigator.pop(context);
                if (_activeProfileId != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RecurringManagerView(profileId: _activeProfileId!)));
                }
              },
            ),
            const Divider(),

            // 2. Other Utilities Sub-menu Group
            ExpansionTile(
              leading: const Icon(Icons.handyman, color: Colors.teal),
              title: BilingualText(
                english: 'Utilities',
                marathi: 'उपयुक्त टूल्स',
                languageController: languageController,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              childrenPadding: const EdgeInsets.only(left: 16.0),
              children: [
                ListTile(
                  leading: const Icon(Icons.calculate, color: Colors.indigo),
                  title: BilingualText(
                    english: 'Voice Calculator',
                    marathi: 'व्हॉईस कॅल्क्युलेटर',
                    languageController: languageController,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickCalculatorView()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_basket, color: Colors.teal),
                  title: BilingualText(
                    english: 'Kirana & Grocery',
                    marathi: 'किराणा यादी',
                    languageController: languageController,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (_activeProfileId != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GroceryNotesView()));
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent),
                  title: BilingualText(
                    english: 'Health Hisaab',
                    marathi: 'आरोग्य हिशोब',
                    languageController: languageController,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (_activeProfileId != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => HealthHomeView(profileId: _activeProfileId!)));
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_gas_station, color: Colors.deepOrangeAccent),
                  title: BilingualText(
                    english: 'Mileage Calculator',
                    marathi: 'मायलेज कॅल्क्युलेटर',
                    languageController: languageController,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MileageCalculatorView()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.straighten, color: Colors.blueGrey),
                  title: BilingualText(
                    english: 'Unit Management',
                    marathi: 'युनिट मॅनेजमेंट',
                    languageController: languageController,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (_activeProfileId != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => UnitManagementView(profileId: _activeProfileId!)));
                    }
                  },
                ),
              ],
            ),
            const Divider(),

            // 3. Category & Profiles Sub-menu Group
            ExpansionTile(
              leading: const Icon(Icons.category, color: Colors.orange),
              title: BilingualText(
                english: 'Management',
                marathi: 'व्यवस्थापन',
                languageController: languageController,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              childrenPadding: const EdgeInsets.only(left: 16.0),
              children: [
                ListTile(
                  leading: const Icon(Icons.label, color: Colors.orange),
                  title: BilingualText(
                    english: 'Categories',
                    marathi: 'कॅटेगरी',
                    languageController: languageController,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryView()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.teal),
                  title: BilingualText(
                    english: 'Profiles',
                    marathi: 'प्रोफाईल',
                    languageController: languageController,
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileView()));
                    _initProfiles();
                  },
                ),
              ],
            ),
            const Divider(),

            // 4. Voice Lab Group
            ExpansionTile(
              leading: const Icon(Icons.mic, color: Colors.purple),
              title: BilingualText(
                english: 'Voice Lab',
                marathi: 'व्हॉईस लॅब',
                languageController: languageController,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              childrenPadding: const EdgeInsets.only(left: 16.0),
              children: [
                ListTile(
                  leading: const Icon(Icons.mic_external_on, color: Colors.purple),
                  title: BilingualText(
                    english: 'Voice Calibration Exercise',
                    marathi: 'आवाज चाचणी',
                    languageController: languageController,
                  ),
                  subtitle: BilingualText(
                    english: 'Improve voice recognition accuracy',
                    marathi: 'मराठी कॅप्चर सुधारण्यासाठी',
                    languageController: languageController,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _startCalibrationExercise();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history_edu, color: Colors.deepOrange),
                  title: BilingualText(
                    english: 'Voice Logs',
                    marathi: 'व्हॉईस लॉग',
                    languageController: languageController,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showVoiceLogs();
                  },
                ),
              ],
            ),
            // Subscription & Offline Licensing
            ListTile(
              leading: const Icon(Icons.workspace_premium, color: Color(0xFFD97706)),
              title: BilingualText(
                english: 'Subscription & License',
                marathi: 'सबस्क्रिप्शन व परवाना',
                languageController: languageController,
              ),
              subtitle: Text(
                SubscriptionManager.instance.isPro ? 'PRO Active' : 'CSC Studio Activation',
                style: TextStyle(
                  fontSize: 11,
                  color: SubscriptionManager.instance.isPro ? Colors.green.shade700 : Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(Icons.qr_code, size: 20, color: Color(0xFFD97706)),
              onTap: () {
                Navigator.pop(context);
                SubscriptionModal.show(context);
              },
            ),
            const Divider(),

            // 5. App Settings & Support
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: BilingualText(
                english: 'App Settings',
                marathi: 'अ‍ॅप सेटिंग्ज',
                languageController: languageController,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsView()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_rate_rounded, color: Color(0xFFF59E0B)),
              title: BilingualText(
                english: 'Rate Us 5 Stars',
                marathi: '५-स्टार रेटिंग द्या',
                languageController: languageController,
              ),
              subtitle: const Text(
                'Google वर आपला अभिप्राय नोंदवा',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(context);
                ReviewPromptService.showReviewModal(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.redAccent),
              title: BilingualText(
                english: 'Visit CSC Center',
                marathi: 'शबाना केंद्र मॅपवर पहा',
                languageController: languageController,
              ),
              subtitle: const Text(
                'Google Maps वर स्थान पहा',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(context);
                ReviewPromptService.openMapLocation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_motion, color: Colors.amber),
              title: BilingualText(
                english: 'Ads & Images Configuration',
                marathi: 'जाहिरात व इमेज सेटिंग्ज',
                languageController: languageController,
              ),
              subtitle: const Text(
                'टायमिंग, इमेजेस व जाहिराती सानुकूलित करा',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PromotionSettingsView()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.blue),
              title: BilingualText(
                english: 'Help & Support',
                marathi: 'मदत आणि सपोर्ट',
                languageController: languageController,
              ),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      appBar: _isSelectionMode 
        ? AppBar(
            backgroundColor: Colors.teal,
            title: Text('${_selectedIds.length} Selected'),
            actions: [
              IconButton(icon: const Icon(Icons.copy), onPressed: _copySelected),
              IconButton(icon: const Icon(Icons.share), onPressed: _shareSelected),
              IconButton(icon: const Icon(Icons.delete), onPressed: _deleteSelected),
              IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _isSelectionMode = false; _selectedIds.clear(); })),
            ],
          )
        : null,
      body: Stack(children: [
        _activeProfileId == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<List<Transaction>>(
                stream: database.watchTransactionsFiltered(
                  profileId: _activeProfileId!,
                  type: _filterCriteria.type,
                  startDate: _filterCriteria.startDate,
                  endDate: _filterCriteria.endDate,
                  sortBy: _sortBy,
                ),
                builder: (context, snapshot) {
                  final transactions = snapshot.data ?? [];
                  double netBalance = 0;
                  double todayActivity = 0;
                  final now = DateTime.now();

                  for (var tx in transactions) {
                    if (tx.type == 'Income') {
                      netBalance += tx.amount;
                    } else if (tx.type == 'Expense') {
                      netBalance -= tx.amount;
                    }

                    if (tx.timestamp.year == now.year &&
                        tx.timestamp.month == now.month &&
                        tx.timestamp.day == now.day) {
                      if (tx.type == 'Income') {
                        todayActivity += tx.amount;
                      } else if (tx.type == 'Expense') {
                        todayActivity -= tx.amount;
                      }
                    }
                  }

                  String todayString = '';
                  if (todayActivity != 0) {
                    todayString = todayActivity > 0
                        ? '↑ ₹${todayActivity.toStringAsFixed(0)} Today'
                        : '↓ ₹${todayActivity.abs().toStringAsFixed(0)} Today';
                  }

                  // Apply search filter locally (since db method might not support it yet)
                  final filteredTransactions = transactions.where((tx) {
                    if (_searchQuery.isEmpty) return true;
                    final query = _searchQuery.toLowerCase();
                    return tx.partyName.toLowerCase().contains(query) ||
                           tx.amount.toString().contains(query);
                  }).toList();

                  return HomeCompositionWidget(
                    greetingSection: GreetingSection(
                      profileName: _activeProfileName,
                      netBalance: '₹${netBalance.toStringAsFixed(0)}',
                      todayActivity: todayString.isNotEmpty ? todayString : null,
                      onAvatarPressed: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ProfileView()));
                        _initProfiles();
                      },
                    ),
                    intelligenceSection: IntelligenceDashboardSection(profileId: _activeProfileId!),
                    universalCommandCenter: Column(
                      children: [
                        UniversalCommandCenter(
                          hasActiveFilters: _filterCriteria.hasActiveFilters,
                          onFilterPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => FilterBottomSheet(
                                initialCriteria: _filterCriteria,
                                onFilterApplied: (criteria) {
                                  setState(() {
                                    _filterCriteria = criteria;
                                  });
                                },
                              ),
                            );
                          },
                          onSortPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => SortBottomSheet(
                                initialSort: _sortBy,
                                onSortApplied: (sort) {
                                  setState(() {
                                    _sortBy = sort;
                                  });
                                },
                              ),
                            );
                          },
                          onSearch: (query, type) {
                            setState(() {
                              _searchQuery = query;
                            });
                          },
                        ),
                        if (_voiceQueryResult != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4)
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.record_voice_over,
                                    color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _voiceQueryResult!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white70),
                                  onPressed: () =>
                                      setState(() => _voiceQueryResult = null),
                                )
                              ],
                            ),
                          ).animate().fadeIn().slideY(begin: -1, end: 0)
                      ],
                    ),
                    onRefresh: () async {
                      if (_activeProfileId != null) {
                        await intelligenceOrchestrator.runPipeline(_activeProfileId!);
                        setState(() {});
                      }
                    },
                    transactionSliver: filteredTransactions.isEmpty
                        ? SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
                              alignment: Alignment.center,
                              child: Column(
                                children: const [
                                  Text('🎉', style: TextStyle(fontSize: 36)),
                                  SizedBox(height: 12),
                                  Text('व्यवहार सापडले नाहीत (No transactions)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 6),
                                  Text('Tap mic button or say "Paid 120 for Tea"', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final tx = filteredTransactions[index];
                                final isSelected = _selectedIds.contains(tx.id);

                                return TransactionTile(
                                  tx: tx,
                                  isSelected: isSelected,
                                  isSelectionMode: _isSelectionMode,
                                  onConfirmDismiss: (direction) async {
                                    if (direction == DismissDirection.endToStart) {
                                      _deleteTransaction(tx);
                                      return true;
                                    } else {
                                      _shareTransactionPdf(tx);
                                      return false;
                                    }
                                  },
                                  onImageTap: (path) => _showFullScreenImage(path),
                                  onLongPress: () {
                                    HapticFeedback.heavyImpact();
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (ctx) => SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.event_repeat, color: Colors.indigo),
                                              title: const Text('Make Recurring'),
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                // Pre-fill the wizard
                                                RecurringAssistantWizard.show(context, _activeProfileId!,
                                                  initialTitle: tx.partyName,
                                                  initialAmount: tx.amount,
                                                  initialType: tx.type,
                                                );
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.checklist),
                                              title: const Text('Select Multiple'),
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                setState(() {
                                                  _isSelectionMode = true;
                                                  _selectedIds.add(tx.id);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  onTap: () {
                                    if (_isSelectionMode) {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedIds.remove(tx.id);
                                          if (_selectedIds.isEmpty) {
                                            _isSelectionMode = false;
                                          }
                                        } else {
                                          _selectedIds.add(tx.id);
                                        }
                                      });
                                    } else {
                                      _editTransactionDialog(tx);
                                    }
                                  },
                                );
                              },
                              childCount: filteredTransactions.length,
                            ),
                          ),
                  );
                },
              ),
        if (_pendingTransaction != null) 
          Container(
            color: Colors.black54, 
            child: Center(
              child: SingleChildScrollView(
                child: Card(
                  margin: const EdgeInsets.all(20), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16), 
                    child: Column(
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        BilingualText(
                          english: 'Confirm Transaction',
                          marathi: 'व्यवहार तपासा',
                          languageController: languageController,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const Divider(),
                        const SizedBox(height: 10),
                        
                        // Amount Field
                        TextField(
                          controller: _confirmAmountCtrl, 
                          decoration: InputDecoration(
                            labelText: l10n?.amount ?? 'Amount', 
                            prefixText: '₹ ',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.mic, color: Colors.blue),
                              onPressed: () {
                                _startListening(onTargetedComplete: (text) {
                                  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
                                  if (digits.isNotEmpty) setState(() => _confirmAmountCtrl.text = digits);
                                });
                              },
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        
                        // Name Field
                        TextField(
                          controller: _confirmNameCtrl, 
                          decoration: InputDecoration(
                            labelText: l10n?.nameDetails ?? 'Party Name / Details',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.mic, color: Colors.blue),
                              onPressed: () {
                                _startListening(onTargetedComplete: (text) => setState(() => _confirmNameCtrl.text = text));
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Type & Category Row
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _confirmType,
                                items: ['Income', 'Expense', 'Udhaari'].map((t) => DropdownMenuItem(
                                  value: t, 
                                  child: Text(t == 'Income'
                                      ? (l10n?.income ?? 'Income')
                                      : (t == 'Expense' ? (l10n?.expense ?? 'Expense') : (l10n?.creditShort ?? 'Credit')))
                                )).toList(),
                                onChanged: (val) => setState(() => _confirmType = val!),
                                decoration: InputDecoration(labelText: l10n?.transactionType ?? 'Type', border: const OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _confirmCategory,
                                items: _allCategoryNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                                onChanged: (val) => setState(() => _confirmCategory = val),
                                decoration: InputDecoration(labelText: l10n?.category ?? 'Category', border: const OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        
                        if (_confirmCategory == 'पेट्रोल' || _confirmCategory == 'डिझेल' || _confirmCategory == 'Fuel' || _confirmCategory == 'इंधन') ...[
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200)
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.local_gas_station, color: Colors.orange, size: 20),
                                    const SizedBox(width: 8),
                                    BilingualText(
                                      english: 'Fuel Tracking',
                                      marathi: 'इंधन ट्रॅकिंग',
                                      languageController: languageController,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _confirmKmCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(labelText: l10n?.odometerKm ?? 'Odometer (KM)'),
                                        onChanged: (_) => _calculateMileage(),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _confirmLitersCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(labelText: l10n?.fuelLiters ?? 'Fuel (Liters)'),
                                        onChanged: (_) => _calculateMileage(),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_calculatedMileage != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    _calculatedMileage!,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                                  )
                                ]
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 15),
                        
                        // Date & Time Display
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Date: ${_confirmDate.day}/${_confirmDate.month}/${_confirmDate.year}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                  Text('Time: ${_confirmDate.hour}:${_confirmDate.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 16),
                                onPressed: () async {
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _confirmDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    TimeOfDay? time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.fromDateTime(_confirmDate),
                                    );
                                    if (time != null) {
                                      setState(() {
                                        _confirmDate = DateTime(
                                          picked.year, picked.month, picked.day,
                                          time.hour, time.minute,
                                        );
                                      });
                                    }
                                  }
                                },
                                label: Text(l10n?.changeDate ?? 'Change Date'),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        BilingualText(
                          english: 'Attach Photos',
                          marathi: 'फोटो जोडा',
                          languageController: languageController,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._pendingImages.map((path) => Stack(
                              children: [
                                GestureDetector(
                                  onTap: () => _showFullScreenImage(path, onChange: () {
                                    _pickImages(onComplete: (paths) {
                                      if (paths.isNotEmpty) {
                                        setState(() {
                                          final index = _pendingImages.indexOf(path);
                                          if (index != -1) {
                                            _pendingImages[index] = paths.first;
                                            if (paths.length > 1) {
                                              _pendingImages.addAll(paths.skip(1));
                                            }
                                          }
                                        });
                                      }
                                    });
                                  }),
                                  child: Image.file(File(path), width: 60, height: 60, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  right: 0, top: 0,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _pendingImages.remove(path)),
                                    child: Container(color: Colors.black54, child: const Icon(Icons.close, size: 16, color: Colors.white)),
                                  ),
                                ),
                              ],
                            )),
                            GestureDetector(
                              onTap: () => _pickImages(),
                              child: Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.add_a_photo)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        CheckboxListTile(
                          title: BilingualText(
                            english: 'Make this recurring',
                            marathi: 'पुन्हा पुन्हा येणारा खर्च',
                            languageController: languageController,
                          ),
                          value: _makeRecurring,
                          onChanged: (val) {
                            setState(() => _makeRecurring = val ?? false);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 20),
                        
                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: _cancelTransaction, 
                              label: Text(l10n?.cancel ?? 'Cancel', style: const TextStyle(color: Colors.red)),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              onPressed: () {
                                final updatedTx = _pendingTransaction!.copyWith(
                                  amount: double.tryParse(_confirmAmountCtrl.text) ?? _pendingTransaction!.amount,
                                  partyName: _confirmNameCtrl.text,
                                  type: _confirmType,
                                  categoryName: _confirmCategory,
                                  timestamp: _confirmDate,
                                  images: _pendingImages.isNotEmpty ? _pendingImages : null,
                                  metadata: _getMetadata(),
                                );

                                _saveTransaction(updatedTx);
                              }, 
                              label: Text(l10n?.save ?? 'Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
        floatingActionButton: _isSelectionMode ? null : SmartMicFab(
          isListening: _isListening,
          onTap: () => _isListening ? _stopListening() : _startListening(),
          onTypePressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('टाइप करा (Type)'),
                content: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(hintText: 'येथे लिहा...'),
                  autofocus: true,
                  onSubmitted: (text) {
                    Navigator.pop(context);
                    _handleParsedText(text);
                  },
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('रद्द करा (Cancel)')),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleParsedText(_textController.text);
                    },
                    child: const Text('सेव्ह करा (Save)'),
                  )
                ],
              ),
            );
          },
          onScanPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scanning Coming Soon')));
          },
          onPastePressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paste functionality...')));
          },
        ),
    );
  }

  @override
  void dispose() {
    _silenceTimer?.cancel(); 
    _confirmAmountCtrl.dispose(); 
    _confirmNameCtrl.dispose();
    _confirmKmCtrl.dispose();
    _confirmLitersCtrl.dispose();
    _pulsateController.dispose(); 
    _progressController.dispose(); 
    _voiceService.dispose(); 
    _textController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _parsedEntities = {};
  bool _makeRecurring = false;
  Map<String, dynamic>? _getMetadata() {
    final metadataMap = <String, dynamic>{};
    if (_confirmKmCtrl.text.isNotEmpty) {
      metadataMap['vehicleKm'] = double.tryParse(_confirmKmCtrl.text);
    }
    if (_confirmLitersCtrl.text.isNotEmpty) {
      metadataMap['fuelLiters'] = double.tryParse(_confirmLitersCtrl.text);
    }
    return metadataMap.isNotEmpty ? metadataMap : null;
  }

  Future<void> _calculateMileage() async {
    final kmText = _confirmKmCtrl.text;
    
    if (kmText.isEmpty) {
      setState(() => _calculatedMileage = null);
      return;
    }

    final currentKm = double.tryParse(kmText);
    if (currentKm == null) return;

    final previousTx = await (database.select(database.transactions)
      ..where((t) => t.profileId.equals(_activeProfileId!) & t.categoryName.equals(_confirmCategory!))
      ..orderBy([(t) => drift.OrderingTerm.desc(t.timestamp)])
      ..limit(1)
    ).getSingleOrNull();

    if (previousTx != null && previousTx.metadata != null) {
      try {
        final meta = jsonDecode(previousTx.metadata!);
        if (meta['vehicleKm'] != null && meta['fuelLiters'] != null) {
          final prevKm = double.parse(meta['vehicleKm'].toString());
          final prevLiters = double.parse(meta['fuelLiters'].toString());
          
          final distance = currentKm - prevKm;
          if (distance > 0 && prevLiters > 0) {
            final mileage = distance / prevLiters;
            setState(() {
              _calculatedMileage = '⛽ मायलेज: ${mileage.toStringAsFixed(1)} KM/L';
            });
            return;
          }
        }
      } catch (e) {
        debugPrint("Error parsing metadata: $e");
      }
    }
    setState(() => _calculatedMileage = null);
  }

  final List<String> _calibrationSentences = ["पाचशे रुपये मिळाले", "दोन हजार रुपये दिले", "एकशे पन्नास रुपये जमा", "शंभर रुपये खर्च", "राहुलला दोनशे रुपये दिले", "साडेचारशे रुपये खर्च झाले"];

  void _startCalibrationExercise() {
    int currentStep = 0;
    void showStep() {
      if (currentStep >= _calibrationSentences.length) {
        showDialog(context: context, builder: (context) => AlertDialog(title: const Text('चाचणी पूर्ण!'), content: const Text('तुमची आवाज चाचणी पूर्ण झाली आहे. कृपया "View Logs" मध्ये जाऊन लॉग्स तपासा.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ठीक आहे'))]));
        return;
      }
      String expected = _calibrationSentences[currentStep];
      showDialog(context: context, barrierDismissible: false, builder: (context) => StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(title: Text('वाक्य ${currentStep + 1}/${_calibrationSentences.length}'), content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('खालील वाक्य स्पष्टपणे बोला:'),
          const SizedBox(height: 10),
          Text(expected, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 20),
          if (_isListening) const CircularProgressIndicator() else ElevatedButton.icon(onPressed: () {
            setStateDialog(() {});
            _startListening(onTargetedComplete: (text) async {
              final normalized = _parser.normalizePublic(text);
              final parsed = _parser.parse(text, profileType: 'SHOP', profileId: _activeProfileId ?? 1);
              await VoiceLogService.logEntry(expected: expected, raw: text, normalized: normalized, parsedAmount: parsed?.amount.toString() ?? "0", parsedType: parsed?.type ?? "Unknown");
              Navigator.pop(context); currentStep++; showStep();
            });
          }, icon: const Icon(Icons.mic), label: const Text('बोलण्यासाठी दाबा')),
        ]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('रद्द करा'))]);
      }));
    }
    showStep();
  }

  void _showVoiceLogs() async {
    final logs = await VoiceLogService.readLogs();
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Voice Logs'), content: SingleChildScrollView(child: Text(logs, style: const TextStyle(fontSize: 12))), actions: [
      TextButton(onPressed: () => VoiceLogService.clearLogs().then((_) => Navigator.pop(context)), child: const Text('Clear')),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ElevatedButton(onPressed: () => Share.share(logs), child: const Text('Share')),
    ]));
  }
}
extension TransactionExtension on Transaction {
  TransactionModel copyWith({double? amount, String? partyName, String? type, drift.Value<String?>? categoryName, DateTime? timestamp, int? profileId, drift.Value<String?>? images, drift.Value<String?>? metadata}) {
    return TransactionModel(
      id: id,
      amount: amount ?? this.amount,
      partyName: partyName ?? this.partyName,
      type: type ?? this.type,
      categoryName: categoryName?.value ?? this.categoryName,
      profileId: profileId ?? this.profileId,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt,
      images: images != null ? (images.value != null ? List<String>.from(jsonDecode(images.value!)) : null) : (this.images != null ? List<String>.from(jsonDecode(this.images!)) : null),
      metadata: metadata != null ? (metadata.value != null ? Map<String, dynamic>.from(jsonDecode(metadata.value!)) : null) : (this.metadata != null ? Map<String, dynamic>.from(jsonDecode(this.metadata!)) : null),
    );
  }
}

extension TransactionModelExtension on TransactionModel {
  TransactionModel copyWith({double? amount, String? partyName, String? type, String? categoryName, DateTime? timestamp, int? profileId, List<String>? images, Map<String, dynamic>? metadata}) {
    return TransactionModel(
      id: id,
      amount: amount ?? this.amount,
      partyName: partyName ?? this.partyName,
      type: type ?? this.type,
      categoryName: categoryName ?? this.categoryName,
      profileId: profileId ?? this.profileId,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt,
      images: images ?? this.images,
      metadata: metadata ?? this.metadata,
    );
  }
}