# Implementation Plan

- [x] 1. Set up meal planning data models and storage
  - Create MealPlan, MealSlot, and MealAssignment model classes with validation
  - Implement serialization methods for JSON storage and database operations
  - Add database schema migration for meal_plans, meal_assignments, and family_meal_slots tables
  <!-- - Write unit tests for model validation and serialization -->
  - _Requirements: 1.1, 1.4, 3.2, 6.1_

- [x] 2. Implement core meal planning service layer
- [x] 2.1 Create MealPlanService with CRUD operations
  - Write MealPlanService class with create, read, update, delete operations
  - Implement meal plan retrieval with family filtering
  - Add database integration for persistent storage
  - Create unit tests for service operations
  - _Requirements: 1.1, 1.4, 6.1, 6.5_

- [x] 2.2 Implement meal assignment functionality
  - Add assignRecipeToSlot and removeRecipeFromSlot methods
  - Create getMealAssignments method with recipe population
  - Implement assignment key generation for date-slot combinations
  - Write unit tests for assignment operations
  - _Requirements: 2.1, 2.2, 2.4, 5.5_

- [x] 2.3 Add calendar utility functions
  - Implement generateWeekDates and generateFourWeekDates methods
  - Create date calculation utilities for 4-week periods
  - Add helper methods for week navigation and date formatting
  - Write unit tests for calendar calculations including edge cases
  - _Requirements: 1.1, 1.5, 5.1, 5.3_

- [x] 3. Implement meal slot management
- [x] 3.1 Create MealSlotService for slot configuration
  - Write MealSlotService with default and family-specific slot management
  - Implement getFamilyMealSlots and updateFamilyMealSlots methods
  - Add default meal slot initialization (Breakfast, Lunch, Dinner)
  - Create unit tests for slot management operations
  - _Requirements: 1.2, 1.3_

- [x] 3.2 Build MealSlotWidget component
  - Create reusable widget for displaying individual meal slots
  - Implement recipe assignment display with recipe information
  - Add tap handling for recipe selection and editing
  - Write widget tests for slot display and interaction
  - _Requirements: 2.2, 2.3, 5.5_

- [x] 4. Create meal plan calendar interface
- [x] 4.1 Build MealPlanCalendarWidget
  - Create 4-week calendar grid widget with date display
  - Implement week navigation with current week highlighting
  - Add meal slot integration for each day
  - Write widget tests for calendar display and navigation
  - _Requirements: 1.1, 1.5, 5.1, 5.2, 5.4_

- [x] 4.2 Implement recipe selection dialog
  - Create RecipeSelectionDialog for choosing recipes from family collection
  - Add search and filtering capabilities for recipe selection
  - Implement recipe preview with key information display
  - Write widget tests for recipe selection interactions
  - _Requirements: 2.1, 2.5_

- [x] 5. Build main meal planning screen
- [x] 5.1 Create MealPlanScreen with calendar integration
  - Build main screen with MealPlanCalendarWidget integration
  - Implement meal plan creation and editing interface
  - Add navigation between weeks and meal plan management
  - Create screen-level tests for meal planning workflows
  - _Requirements: 1.1, 1.5, 2.1, 5.1, 5.3_

- [x] 5.2 Add meal plan CRUD interface
  - Implement meal plan creation form with name and date selection
  - Add meal plan editing capabilities with save/cancel functionality
  - Create meal plan deletion with confirmation dialogs
  - Write integration tests for meal plan management
  - _Requirements: 1.1, 1.4, 6.1_

- [ ] 6. Implement template management system
- [x] 6.1 Add template creation functionality
  - Implement saveAsTemplate method in MealPlanService
  - Create template naming and description interface
  - Add template validation and duplicate name handling
  <!-- - Write unit tests for template creation operations -->
  - _Requirements: 3.1, 3.2, 3.5_

- [x] 6.2 Build template library interface
  - Create TemplateManagementScreen for viewing saved templates
  - Implement template search and filtering capabilities
  - Add template preview with meal assignment summary
  - Write widget tests for template library interactions
  - _Requirements: 3.4, 3.5_

- [ ] 6.3 Implement template application functionality
  - Add applyTemplate method with date selection
  - Create template application dialog with calendar picker
  - Implement template-to-meal-plan conversion with date mapping
  - Write integration tests for template application workflows
  - _Requirements: 4.1, 4.2, 4.3, 4.5_

- [ ] 7. Add family collaboration features
- [ ] 7.1 Implement permission-based meal plan access
  - Add family role validation for meal plan operations
  - Implement read-only vs edit access based on family permissions
  - Create permission checking utilities for meal plan actions
  <!-- - Write unit tests for permission validation scenarios -->
  - _Requirements: 6.2, 6.3, 6.4_

- [ ] 7.2 Add real-time meal plan sharing
  - Implement meal plan visibility for all family members
  - Add meal plan change notifications within family context
  - Create family meal plan synchronization logic
  - Write integration tests for family collaboration workflows
  - _Requirements: 6.1, 6.5_

- [ ] 8. Enhance error handling and validation
- [ ] 8.1 Add comprehensive form validation
  - Implement meal plan name validation with character limits
  - Add date validation for start dates and template application
  - Create meal slot validation with quantity limits
  <!-- - Write unit tests for validation scenarios and error messages -->
  - _Requirements: 1.1, 3.2, 4.1_

- [ ] 8.2 Implement conflict resolution
  - Add handling for recipe deletion affecting meal plans
  - Implement graceful degradation when recipes become unavailable
  - Create conflict resolution dialogs for overlapping operations
  - Write integration tests for error recovery scenarios
  - _Requirements: 2.4, 4.4_

- [ ] 9. Add advanced calendar features
- [ ] 9.1 Implement calendar navigation enhancements
  - Add month view integration with 4-week meal plans
  - Create calendar date highlighting for current day and planned meals
  - Implement smooth transitions between weeks and months
  - Write widget tests for enhanced calendar navigation
  - _Requirements: 5.1, 5.2, 5.4_

- [ ] 9.2 Add meal plan analytics and insights
  - Create meal plan completion tracking and statistics
  - Implement recipe usage analytics within meal plans
  - Add meal plan comparison tools for template optimization
  <!-- - Write unit tests for analytics calculations and data aggregation -->
  - _Requirements: 5.1, 5.5_