PRD – NomNom Meal Planner SaaS (Spec Level, No Tiers)

1. Product Summary

NomNom is a SaaS for personal and family meal planning. It helps users organize recipes, build reusable monthly meal plans, and generate grocery lists split into weeks.
Unlike social-first cooking apps, NomNom is private-first, productivity-focused, with optional sharing for discovery and collaboration.

⸻

2. Core Entities
	•	User – an individual account holder.
	•	Family – a group of users sharing recipes, plans, and grocery lists (starts as a family of 1).
	•	Recipe – an individual meal entry (ingredients, instructions, tags).
	•	Meal Plan – a 4-week structured calendar (7 days × multiple slots per day).
	•	Grocery List – weekly shopping list generated from a plan.

⸻

3. Core Features

3.1 Recipes
	•	Create/edit recipes with metadata:
	•	Title, ingredients (with quantities/units), instructions, prep/cook time, servings, tags.
	•	Photos optional.
	•	Private by default, can be published.
	•	Shared within family by default.

⸻

3.2 Meal Plans
	•	Structured as 4 weeks × 7 days × meal slots.
	•	Configurable slots (default: Breakfast, Lunch, Dinner, Snacks).
	•	Assign recipes to slots.
	•	Save as reusable template.
	•	Apply template to any calendar month.
	•	Plans shared across family by default.

⸻

3.3 Grocery Lists
	•	Generate from a meal plan.
	•	Split into weekly lists (Week 1, Week 2, etc.).
	•	Auto-merge ingredient quantities across recipes.
	•	Editable:
	•	Add/remove custom items.
	•	Mark items as “bought”.
	•	Export:
	•	Mobile checklist.
	•	PDF/print.
	•	Shareable link.

⸻

3.4 Family Mode (Default)
	•	Every user belongs to a Family (default = 1 member).
	•	Recipes, meal plans, and grocery lists are family-shared.
	•	Roles:
	•	Owner – manages family invites.
	•	Admins – can create/edit/delete recipes and plans.
	•	Members – can view, mark groceries, and duplicate plans.
	•	Invite system:
	•	Email invite or shareable code.
	•	Pending invites visible to owner/admins.

⸻

3.5 Sharing & Discovery
	•	Within Family – automatic sharing.
	•	Outside Family –
	•	Plans/recipes private by default.
	•	Option to publish publicly to the NomNom community.
	•	Other users can:
	•	Apply directly.
	•	Duplicate + edit.
	•	Community library: searchable, filterable by tags/diet type.