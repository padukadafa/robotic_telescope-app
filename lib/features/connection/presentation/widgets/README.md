# Connection Widgets - Clean Architecture

This directory contains UI widgets for the connection feature, following Clean Architecture principles.

## 📁 Structure

```
widgets/
├── scan_button.dart          # Pure UI scan button widget
├── scan_results.dart         # Scan results display widget
├── network_list_item.dart    # Network item widget
└── README.md                 # This documentation
```

## 🎯 Clean Architecture Principles

### Presentation Layer Only

- **No Business Logic**: Widgets only handle UI rendering
- **No State Management**: State is passed from parent components
- **Callbacks Only**: Use callbacks for user interactions
- **Pure UI**: Focus solely on visual representation

## 🧩 ScanButton Widget

### Usage Example

```dart
// Basic usage
ScanButton(
  isScanning: false,
  onScanPressed: () {
    // Handle scan action
  },
)

// With custom text
ScanButton(
  isScanning: true,
  buttonText: 'Find Telescopes',
  scanningText: 'Searching...',
  onScanPressed: null, // Disabled during scanning
)
```

### Parameters

| Parameter       | Type            | Required | Description                                   |
| --------------- | --------------- | -------- | --------------------------------------------- |
| `isScanning`    | `bool`          | ✅       | Current scanning state                        |
| `onScanPressed` | `VoidCallback?` | ❌       | Callback when button pressed                  |
| `buttonText`    | `String?`       | ❌       | Custom button text (default: "Scan Networks") |
| `scanningText`  | `String?`       | ❌       | Custom scanning text (default: "Scanning...") |

### Features

- ✅ **Animated Progress**: Circular progress indicator during scanning
- ✅ **Scanning Rings**: Animated expanding rings effect
- ✅ **State-based Styling**: Different colors for normal/scanning states
- ✅ **Responsive Design**: Adapts to different screen sizes
- ✅ **Accessibility**: Proper contrast and touch targets

## 🎨 Visual States

### Normal State

- Primary color background
- "Scan Networks" text
- WiFi icon
- Elevated shadow

### Scanning State

- Surface variant background
- "Scanning..." text
- Circular progress indicator
- Animated scanning rings
- Reduced elevation

## 🔧 Integration with Parent Components

### Connection Screen Integration

```dart
// In ConnectionScreen
class ConnectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Other widgets...

            ScanButton(
              isScanning: provider.isScanning,
              onScanPressed: () async {
                await provider.scanForTelescopes();
              },
            ),

            // Other widgets...
          ],
        );
      },
    );
  }
}
```

### Custom Implementation

```dart
// Custom parent widget
class CustomScanScreen extends StatefulWidget {
  @override
  _CustomScanScreenState createState() => _CustomScanScreenState();
}

class _CustomScanScreenState extends State<CustomScanScreen> {
  bool _isScanning = false;

  void _handleScan() async {
    setState(() => _isScanning = true);

    // Your scan logic here
    await Future.delayed(Duration(seconds: 3));

    setState(() => _isScanning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ScanButton(
          isScanning: _isScanning,
          onScanPressed: _handleScan,
          buttonText: 'Start Scan',
          scanningText: 'Please wait...',
        ),
      ),
    );
  }
}
```

## 🎯 Benefits of This Architecture

### 1. **Separation of Concerns**

- UI logic separated from business logic
- Easy to test presentation layer independently
- Clear responsibilities for each component

### 2. **Reusability**

- Widget can be used in multiple screens
- Customizable through parameters
- No tight coupling to specific providers

### 3. **Maintainability**

- Easy to modify UI without affecting business logic
- Simple to add new features or styling
- Clear code structure and documentation

### 4. **Testability**

- UI can be tested with mock data
- No complex state management in widget
- Predictable behavior based on inputs

## 📚 Best Practices

### Do ✅

```dart
// Pass state and callbacks from parent
ScanButton(
  isScanning: provider.isScanning,
  onScanPressed: () => provider.scan(),
)

// Use meaningful parameter names
ScanButton(
  isScanning: false,
  buttonText: 'Find Devices',
  scanningText: 'Searching for devices...',
)
```

### Don't ❌

```dart
// Don't access providers directly in widget
Consumer<ConnectionProvider>(
  builder: (context, provider, child) {
    return ScanButton(provider: provider); // ❌ Wrong
  },
)

// Don't put business logic in widget
onPressed: () {
  // ❌ Business logic should not be here
  provider.scanForTelescopes();
  analytics.trackScan();
  showNotification();
}
```

## 🔄 Migration Guide

If you're migrating from the old ScanButton:

### Before (Tightly Coupled)

```dart
ScanButton(provider: connectionProvider)
```

### After (Clean Architecture)

```dart
ScanButton(
  isScanning: connectionProvider.isScanning,
  onScanPressed: () async {
    await connectionProvider.scanForTelescopes();
  },
)
```

This ensures better separation of concerns and makes the widget more testable and reusable.
