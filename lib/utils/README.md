# Navigation Transitions

This directory contains utilities for smooth navigation transitions in the NomNom app.

## FadePageRoute

The `FadePageRoute` class provides smooth fade in/out transitions for navigation instead of the default Flutter slide transitions.

### Features

- **Smooth fade transition**: Pages fade in/out with a subtle scale effect
- **Customizable duration**: Configure transition and reverse transition durations
- **Easy to use**: Drop-in replacement for `MaterialPageRoute`
- **Extension methods**: Convenient extension methods on `NavigatorState`
- **Static helpers**: Static methods for quick access

### Usage

#### Using FadeNavigation static methods (Recommended)

```dart
// Push a new page
FadeNavigation.push(context, MyNewScreen());

// Push and replace current page
FadeNavigation.pushReplacement(context, MyNewScreen());

// Push and remove all previous pages
FadeNavigation.pushAndRemoveUntil(
  context, 
  MyNewScreen(), 
  (route) => false,
);
```

#### Using Navigator extension methods

```dart
// Push a new page
Navigator.of(context).pushFade(MyNewScreen());

// Push and replace current page
Navigator.of(context).pushReplacementFade(MyNewScreen());
```

#### Using FadePageRoute directly

```dart
Navigator.of(context).push(
  FadePageRoute(
    child: MyNewScreen(),
    duration: Duration(milliseconds: 400), // Optional
    reverseDuration: Duration(milliseconds: 300), // Optional
  ),
);
```

### Customization

You can customize the transition duration:

```dart
FadePageRoute(
  child: MyScreen(),
  duration: Duration(milliseconds: 500),
  reverseDuration: Duration(milliseconds: 250),
)
```

### Implementation Details

The fade transition includes:
- **Fade effect**: Opacity animates from 0.0 to 1.0
- **Scale effect**: Subtle scale from 0.95 to 1.0 for polish
- **Smooth curves**: Uses `Curves.easeInOut` for natural motion
- **Optimized performance**: Efficient animation implementation

### Migration from MaterialPageRoute

Replace existing navigation:

```dart
// Before
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => MyScreen()),
);

// After
FadeNavigation.push(context, MyScreen());
```

This provides a consistent, smooth navigation experience throughout the app.