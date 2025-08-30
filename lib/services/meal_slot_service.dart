import '../models/meal_slot.dart';
import 'storage_service.dart';

class MealSlotService {
  final StorageService _storageService = StorageService();

  /// Get default meal slots (Breakfast, Lunch, Dinner, Snacks)
  Future<List<MealSlot>> getDefaultMealSlots() async {
    try {
      return MealSlot.getDefaultSlots();
    } catch (e) {
      throw MealSlotException(
        'Failed to get default meal slots: ${e.toString()}',
        'GET_DEFAULT_SLOTS_ERROR',
      );
    }
  }

  /// Get meal slots for a specific family
  Future<List<MealSlot>> getFamilyMealSlots(String familyId) async {
    try {
      final slotMaps = await _storageService.loadFamilyMealSlots(familyId);

      if (slotMaps.isEmpty) {
        // If no custom slots are defined, return default slots
        return await getDefaultMealSlots();
      }

      return slotMaps.map((map) => MealSlot.fromMap(map)).toList();
    } catch (e) {
      throw MealSlotException(
        'Failed to get family meal slots: ${e.toString()}',
        'GET_FAMILY_SLOTS_ERROR',
      );
    }
  }

  /// Update meal slots for a specific family
  Future<void> updateFamilyMealSlots(
    String familyId,
    List<MealSlot> slots,
  ) async {
    try {
      // Validate all slots
      for (final slot in slots) {
        slot.validate();
      }

      // Check for duplicate names (case-insensitive)
      final slotNames = slots.map((slot) => slot.name.toLowerCase()).toList();
      final uniqueNames = slotNames.toSet();
      if (slotNames.length != uniqueNames.length) {
        throw MealSlotException(
          'Duplicate meal slot names are not allowed',
          'DUPLICATE_SLOT_NAMES',
        );
      }

      // Check for duplicate orders
      final orders = slots.map((slot) => slot.order).toList();
      final uniqueOrders = orders.toSet();
      if (orders.length != uniqueOrders.length) {
        throw MealSlotException(
          'Duplicate meal slot orders are not allowed',
          'DUPLICATE_SLOT_ORDERS',
        );
      }

      // Convert to maps for storage
      final slotMaps = slots.map((slot) => slot.toMap()).toList();

      // Save to storage
      await _storageService.saveFamilyMealSlots(familyId, slotMaps);
    } catch (e) {
      if (e is MealSlotException) {
        rethrow;
      }
      throw MealSlotException(
        'Failed to update family meal slots: ${e.toString()}',
        'UPDATE_FAMILY_SLOTS_ERROR',
      );
    }
  }

  /// Add a new meal slot for a family
  Future<void> addMealSlot(String familyId, MealSlot newSlot) async {
    try {
      final existingSlots = await getFamilyMealSlots(familyId);

      // Check if slot name already exists (case-insensitive)
      final existingNames = existingSlots
          .map((slot) => slot.name.toLowerCase())
          .toSet();
      if (existingNames.contains(newSlot.name.toLowerCase())) {
        throw MealSlotException(
          'A meal slot with the name "${newSlot.name}" already exists',
          'SLOT_NAME_EXISTS',
        );
      }

      // Check if order already exists
      final existingOrders = existingSlots.map((slot) => slot.order).toSet();
      if (existingOrders.contains(newSlot.order)) {
        throw MealSlotException(
          'A meal slot with order ${newSlot.order} already exists',
          'SLOT_ORDER_EXISTS',
        );
      }

      // Add the new slot
      final updatedSlots = [...existingSlots, newSlot];

      // Sort by order
      updatedSlots.sort((a, b) => a.order.compareTo(b.order));

      await updateFamilyMealSlots(familyId, updatedSlots);
    } catch (e) {
      if (e is MealSlotException) {
        rethrow;
      }
      throw MealSlotException(
        'Failed to add meal slot: ${e.toString()}',
        'ADD_MEAL_SLOT_ERROR',
      );
    }
  }

  /// Remove a meal slot for a family
  Future<void> removeMealSlot(String familyId, String slotId) async {
    try {
      final existingSlots = await getFamilyMealSlots(familyId);

      // Check if slot exists
      final slotToRemove = existingSlots
          .where((slot) => slot.id == slotId)
          .firstOrNull;
      if (slotToRemove == null) {
        throw MealSlotException(
          'Meal slot with ID "$slotId" not found',
          'SLOT_NOT_FOUND',
        );
      }

      // Don't allow removing if it's the last slot
      if (existingSlots.length <= 1) {
        throw MealSlotException(
          'Cannot remove the last meal slot. At least one slot is required.',
          'CANNOT_REMOVE_LAST_SLOT',
        );
      }

      // Remove the slot
      final updatedSlots = existingSlots
          .where((slot) => slot.id != slotId)
          .toList();

      await updateFamilyMealSlots(familyId, updatedSlots);
    } catch (e) {
      if (e is MealSlotException) {
        rethrow;
      }
      throw MealSlotException(
        'Failed to remove meal slot: ${e.toString()}',
        'REMOVE_MEAL_SLOT_ERROR',
      );
    }
  }

  /// Update a specific meal slot for a family
  Future<void> updateMealSlot(
    String familyId,
    String slotId,
    MealSlot updatedSlot,
  ) async {
    try {
      final existingSlots = await getFamilyMealSlots(familyId);

      // Find the slot to update
      final slotIndex = existingSlots.indexWhere((slot) => slot.id == slotId);
      if (slotIndex == -1) {
        throw MealSlotException(
          'Meal slot with ID "$slotId" not found',
          'SLOT_NOT_FOUND',
        );
      }

      // Validate the updated slot
      updatedSlot.validate();

      // Check for duplicate names (excluding the current slot)
      final otherSlots = existingSlots.where((slot) => slot.id != slotId);
      final existingNames = otherSlots
          .map((slot) => slot.name.toLowerCase())
          .toSet();
      if (existingNames.contains(updatedSlot.name.toLowerCase())) {
        throw MealSlotException(
          'A meal slot with the name "${updatedSlot.name}" already exists',
          'SLOT_NAME_EXISTS',
        );
      }

      // Check for duplicate orders (excluding the current slot)
      final existingOrders = otherSlots.map((slot) => slot.order).toSet();
      if (existingOrders.contains(updatedSlot.order)) {
        throw MealSlotException(
          'A meal slot with order ${updatedSlot.order} already exists',
          'SLOT_ORDER_EXISTS',
        );
      }

      // Update the slot (preserve the original ID)
      final slotToUpdate = updatedSlot.copyWith(id: slotId);
      final updatedSlots = [...existingSlots];
      updatedSlots[slotIndex] = slotToUpdate;

      // Sort by order
      updatedSlots.sort((a, b) => a.order.compareTo(b.order));

      await updateFamilyMealSlots(familyId, updatedSlots);
    } catch (e) {
      if (e is MealSlotException) {
        rethrow;
      }
      throw MealSlotException(
        'Failed to update meal slot: ${e.toString()}',
        'UPDATE_MEAL_SLOT_ERROR',
      );
    }
  }

  /// Reset family meal slots to default
  Future<void> resetToDefaultSlots(String familyId) async {
    try {
      final defaultSlots = await getDefaultMealSlots();
      await updateFamilyMealSlots(familyId, defaultSlots);
    } catch (e) {
      throw MealSlotException(
        'Failed to reset to default slots: ${e.toString()}',
        'RESET_TO_DEFAULT_ERROR',
      );
    }
  }

  /// Get meal slot by ID for a family
  Future<MealSlot?> getMealSlotById(String familyId, String slotId) async {
    try {
      final slots = await getFamilyMealSlots(familyId);
      return slots.where((slot) => slot.id == slotId).firstOrNull;
    } catch (e) {
      throw MealSlotException(
        'Failed to get meal slot by ID: ${e.toString()}',
        'GET_SLOT_BY_ID_ERROR',
      );
    }
  }

  /// Get the next available order number for a family
  Future<int> getNextAvailableOrder(String familyId) async {
    try {
      final slots = await getFamilyMealSlots(familyId);
      if (slots.isEmpty) {
        return 1;
      }

      final maxOrder = slots
          .map((slot) => slot.order)
          .reduce((a, b) => a > b ? a : b);
      return maxOrder + 1;
    } catch (e) {
      throw MealSlotException(
        'Failed to get next available order: ${e.toString()}',
        'GET_NEXT_ORDER_ERROR',
      );
    }
  }

  /// Reorder meal slots for a family
  Future<void> reorderMealSlots(
    String familyId,
    List<String> slotIdsInOrder,
  ) async {
    try {
      final existingSlots = await getFamilyMealSlots(familyId);

      // Validate that all slot IDs are provided
      if (slotIdsInOrder.length != existingSlots.length) {
        throw MealSlotException(
          'All slot IDs must be provided for reordering',
          'INVALID_REORDER_LIST',
        );
      }

      // Validate that all slot IDs exist
      final existingIds = existingSlots.map((slot) => slot.id).toSet();
      final providedIds = slotIdsInOrder.toSet();
      if (!existingIds.containsAll(providedIds) ||
          !providedIds.containsAll(existingIds)) {
        throw MealSlotException(
          'Invalid slot IDs provided for reordering',
          'INVALID_SLOT_IDS',
        );
      }

      // Create reordered slots with new order numbers
      final reorderedSlots = <MealSlot>[];
      for (int i = 0; i < slotIdsInOrder.length; i++) {
        final slotId = slotIdsInOrder[i];
        final originalSlot = existingSlots.firstWhere(
          (slot) => slot.id == slotId,
        );
        final reorderedSlot = originalSlot.copyWith(order: i + 1);
        reorderedSlots.add(reorderedSlot);
      }

      await updateFamilyMealSlots(familyId, reorderedSlots);
    } catch (e) {
      if (e is MealSlotException) {
        rethrow;
      }
      throw MealSlotException(
        'Failed to reorder meal slots: ${e.toString()}',
        'REORDER_SLOTS_ERROR',
      );
    }
  }
}

// Extension to add firstOrNull method for older Dart versions
extension _IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
