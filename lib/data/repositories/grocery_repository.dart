import '../../main.dart';
import '../database/database.dart';
import 'package:drift/drift.dart';
import '../../core/voice/kirana_import_engine.dart';

class GroceryRepository {
  Stream<List<GroceryList>> watchLists(int profileId) {
    return database.watchGroceryLists(profileId);
  }

  Future<int> createList(int profileId, String name) {
    return database.addGroceryList(GroceryListsCompanion.insert(
      name: name,
      profileId: profileId,
    ));
  }

  Stream<List<GroceryItem>> watchItems(int listId) {
    return database.watchGroceryItems(listId);
  }

  Future<void> addItem({
    required int listId,
    required String name,
    required double quantity,
    required String unit,
    String? category,
    double? estimatedPrice,
    String? notes,
  }) async {
    // Check for duplicates to merge
    final existing = await (database.select(database.groceryItems)
          ..where((i) => i.listId.equals(listId) & i.itemName.equals(name) & i.unit.equals(unit)))
        .getSingleOrNull();

    if (existing != null) {
      // Merge
      await database.updateGroceryItem(existing.copyWith(
        quantity: existing.quantity + quantity,
        category: category != null ? Value(category) : const Value.absent(),
        estimatedPrice: estimatedPrice != null ? Value(estimatedPrice) : const Value.absent(),
        updatedAt: DateTime.now(),
      ));
    } else {
      await database.addGroceryItem(GroceryItemsCompanion.insert(
        listId: listId,
        itemName: name,
        quantity: Value(quantity),
        unit: Value(unit),
        category: category != null ? Value(category) : const Value.absent(),
        estimatedPrice: estimatedPrice != null ? Value(estimatedPrice) : const Value.absent(),
        notes: Value(notes),
      ));
    }
  }

  Future<double?> getLastKnownPrice(String itemName) async {
    final lastItem = await (database.select(database.groceryItems)
          ..where((i) => i.itemName.equals(itemName) & i.estimatedPrice.isNotNull())
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    return lastItem?.estimatedPrice;
  }

  Future<List<String>> getSuggestedItems(int profileId, int currentListId) async {
    // Basic approach: get all distinct item names ever used in lists for this profile
    final listsQuery = await (database.select(database.groceryLists)..where((l) => l.profileId.equals(profileId))).get();
    final listIds = listsQuery.map((l) => l.id).toList();

    if (listIds.isEmpty) return [];

    final currentItems = await (database.select(database.groceryItems)..where((i) => i.listId.equals(currentListId))).get();
    final currentNames = currentItems.map((i) => i.itemName.toLowerCase()).toSet();

    // Query past items
    final allItems = await (database.select(database.groceryItems)..where((i) => i.listId.isIn(listIds))).get();
    
    // Count frequencies
    final counts = <String, int>{};
    for (var item in allItems) {
      final nameLower = item.itemName.toLowerCase();
      if (!currentNames.contains(nameLower)) {
        counts[item.itemName] = (counts[item.itemName] ?? 0) + 1;
      }
    }

    // Sort by frequency descending and return top 10
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).map((e) => e.key).toList();
  }

  Future<void> toggleItemStatus(GroceryItem item, bool isChecked) {
    return database.updateGroceryItem(item.copyWith(
      isChecked: isChecked,
      checkedAt: Value(isChecked ? DateTime.now() : null),
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> deleteItem(GroceryItem item) {
    return database.deleteGroceryItem(item);
  }

  Future<void> clearList(int listId) {
    return database.deleteItemsByList(listId);
  }

  Future<void> deleteList(int listId) async {
    // First clear items
    await clearList(listId);
    // Then delete list
    final list = await (database.select(database.groceryLists)..where((l) => l.id.equals(listId))).getSingle();
    await database.deleteGroceryList(list);
  }

  Future<void> updateListName(int listId, String newName) async {
    final list = await (database.select(database.groceryLists)..where((l) => l.id.equals(listId))).getSingle();
    await database.updateGroceryList(list.copyWith(name: newName, updatedAt: DateTime.now()));
  }

  Future<ImportBatchResult> importItemsBatch({
    required int listId,
    required List<ImportedParsedItem> items,
  }) async {
    List<int> createdIds = [];
    List<GroceryItem> previousStates = [];
    int importedCount = 0;
    int mergedCount = 0;
    int unknownCount = 0;

    await database.transaction(() async {
      for (var item in items) {
        if (item.isUnknown) unknownCount++;

        final existing = await (database.select(database.groceryItems)
              ..where((i) => i.listId.equals(listId) & i.itemName.equals(item.canonicalName) & i.unit.equals(item.unit)))
            .getSingleOrNull();

        if (existing != null) {
          if (item.duplicateStrategy == DuplicateStrategy.skip) {
            continue;
          }

          previousStates.add(existing);

          if (item.duplicateStrategy == DuplicateStrategy.merge) {
            await database.updateGroceryItem(existing.copyWith(
              quantity: existing.quantity + item.quantity,
              category: Value(item.category),
              updatedAt: DateTime.now(),
            ));
            mergedCount++;
            importedCount++;
          } else if (item.duplicateStrategy == DuplicateStrategy.replace) {
            await database.updateGroceryItem(existing.copyWith(
              quantity: item.quantity,
              category: Value(item.category),
              updatedAt: DateTime.now(),
            ));
            importedCount++;
          } else if (item.duplicateStrategy == DuplicateStrategy.keepBoth) {
            final estPrice = await getLastKnownPrice(item.canonicalName);
            final newId = await database.addGroceryItem(GroceryItemsCompanion.insert(
              listId: listId,
              itemName: item.canonicalName,
              quantity: Value(item.quantity),
              unit: Value(item.unit),
              category: Value(item.category),
              estimatedPrice: Value(estPrice),
            ));
            createdIds.add(newId);
            importedCount++;
          }
        } else {
          final estPrice = await getLastKnownPrice(item.canonicalName);
          final newId = await database.addGroceryItem(GroceryItemsCompanion.insert(
            listId: listId,
            itemName: item.canonicalName,
            quantity: Value(item.quantity),
            unit: Value(item.unit),
            category: Value(item.category),
            estimatedPrice: Value(estPrice),
          ));
          createdIds.add(newId);
          importedCount++;
        }
      }
    });

    return ImportBatchResult(
      createdItemIds: createdIds,
      previousStates: previousStates,
      summary: ImportSummary(
        totalParsed: items.length,
        totalImported: importedCount,
        totalMerged: mergedCount,
        totalUnknown: unknownCount,
        failedCount: 0,
      ),
    );
  }

  Future<void> undoImportBatch({
    required List<int> createdItemIds,
    required List<GroceryItem> previousStates,
  }) async {
    await database.transaction(() async {
      // 1. Delete created items
      for (var id in createdItemIds) {
        await (database.delete(database.groceryItems)..where((i) => i.id.equals(id))).go();
      }
      // 2. Restore previous states
      for (var prev in previousStates) {
        await database.updateGroceryItem(prev);
      }
    });
  }
}

class ImportBatchResult {
  final List<int> createdItemIds;
  final List<GroceryItem> previousStates;
  final ImportSummary summary;

  ImportBatchResult({
    required this.createdItemIds,
    required this.previousStates,
    required this.summary,
  });
}

