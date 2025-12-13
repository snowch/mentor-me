// lib/models/dashboard_config.dart
// Configuration for customizable dashboard widgets

import 'package:flutter/material.dart';

/// Represents a single widget configuration on the dashboard
class DashboardWidgetConfig {
  final String id;
  final bool visible;
  final int order;

  const DashboardWidgetConfig({
    required this.id,
    this.visible = true,
    required this.order,
  });

  DashboardWidgetConfig copyWith({
    String? id,
    bool? visible,
    int? order,
  }) {
    return DashboardWidgetConfig(
      id: id ?? this.id,
      visible: visible ?? this.visible,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visible': visible,
      'order': order,
    };
  }

  factory DashboardWidgetConfig.fromJson(Map<String, dynamic> json) {
    return DashboardWidgetConfig(
      id: json['id'] as String,
      visible: json['visible'] as bool? ?? true,
      order: json['order'] as int,
    );
  }
}

/// Metadata for available dashboard widgets
class DashboardWidgetInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool canHide; // Some widgets might always be visible

  const DashboardWidgetInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.canHide = true,
  });
}

/// Registry of all available dashboard widgets
class DashboardWidgetRegistry {
  static const List<DashboardWidgetInfo> availableWidgets = [
    DashboardWidgetInfo(
      id: 'mentorCard',
      name: 'AI Mentor Card',
      description: 'Personalized coaching messages',
      icon: Icons.psychology,
      color: Colors.purple,
      canHide: true, // Can be hidden via dashboard customization
    ),
    DashboardWidgetInfo(
      id: 'actionButtons',
      name: 'Quick Actions',
      description: 'Chat and reflection session buttons',
      icon: Icons.touch_app,
      color: Colors.blue,
    ),
    DashboardWidgetInfo(
      id: 'nextCheckin',
      name: 'Next Check-in',
      description: 'Upcoming reminder notifications',
      icon: Icons.notifications_active,
      color: Colors.orange,
    ),
    DashboardWidgetInfo(
      id: 'quickHalt',
      name: 'HALT Check-in',
      description: 'Quick wellness self-assessment',
      icon: Icons.psychology_alt,
      color: Colors.teal,
    ),
    DashboardWidgetInfo(
      id: 'recentWins',
      name: 'Recent Wins',
      description: 'Celebrate your recent accomplishments',
      icon: Icons.emoji_events,
      color: Colors.amber,
    ),
    DashboardWidgetInfo(
      id: 'hydration',
      name: 'Hydration Tracker',
      description: 'Track daily water intake',
      icon: Icons.water_drop,
      color: Colors.lightBlue,
    ),
    DashboardWidgetInfo(
      id: 'weight',
      name: 'Weight Tracker',
      description: 'Log and track weight progress',
      icon: Icons.monitor_weight,
      color: Colors.indigo,
    ),
    DashboardWidgetInfo(
      id: 'exercise',
      name: 'Exercise Tracker',
      description: 'Track workouts and exercise plans',
      icon: Icons.fitness_center,
      color: Colors.orange,
    ),
    DashboardWidgetInfo(
      id: 'foodLog',
      name: 'Food Log',
      description: 'Track meals and nutrition',
      icon: Icons.restaurant_menu,
      color: Colors.green,
    ),
    DashboardWidgetInfo(
      id: 'quickCapture',
      name: 'Quick Capture',
      description: 'Quickly add todos and see upcoming tasks',
      icon: Icons.add_task,
      color: Colors.deepPurple,
    ),
    DashboardWidgetInfo(
      id: 'goals',
      name: 'Active Goals',
      description: 'Quick view of your current goals',
      icon: Icons.flag,
      color: Colors.green,
    ),
    DashboardWidgetInfo(
      id: 'habits',
      name: "Today's Habits",
      description: 'Track daily habit completion',
      icon: Icons.check_circle,
      color: Colors.amber,
    ),
  ];

  /// Get widget info by ID
  static DashboardWidgetInfo? getWidgetInfo(String id) {
    try {
      return availableWidgets.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get default configuration (all widgets visible, in default order)
  static List<DashboardWidgetConfig> getDefaultConfig() {
    return availableWidgets.asMap().entries.map((entry) {
      return DashboardWidgetConfig(
        id: entry.value.id,
        visible: true,
        order: entry.key,
      );
    }).toList();
  }

  /// Get default order for a widget ID
  static int getDefaultOrder(String id) {
    final index = availableWidgets.indexWhere((w) => w.id == id);
    return index >= 0 ? index : 999;
  }
}

/// Full dashboard layout configuration
class DashboardLayout {
  final List<DashboardWidgetConfig> widgets;

  const DashboardLayout({required this.widgets});

  /// Get visible widgets sorted by order
  List<DashboardWidgetConfig> get visibleWidgets {
    return widgets.where((w) => w.visible).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Check if a widget is visible
  bool isWidgetVisible(String id) {
    final widget = widgets.firstWhere(
      (w) => w.id == id,
      orElse: () => DashboardWidgetConfig(id: id, visible: true, order: 999),
    );
    return widget.visible;
  }

  /// Get widget order
  int getWidgetOrder(String id) {
    final widget = widgets.firstWhere(
      (w) => w.id == id,
      orElse: () => DashboardWidgetConfig(
        id: id,
        order: DashboardWidgetRegistry.getDefaultOrder(id),
      ),
    );
    return widget.order;
  }

  /// Create a new layout with a widget visibility toggled
  DashboardLayout toggleWidgetVisibility(String id) {
    final info = DashboardWidgetRegistry.getWidgetInfo(id);
    if (info != null && !info.canHide) {
      return this; // Can't hide this widget
    }

    final newWidgets = widgets.map((w) {
      if (w.id == id) {
        return w.copyWith(visible: !w.visible);
      }
      return w;
    }).toList();

    return DashboardLayout(widgets: newWidgets);
  }

  /// Create a new layout with widgets reordered
  DashboardLayout reorder(int oldIndex, int newIndex) {
    final visibleList = visibleWidgets.toList();

    if (oldIndex < 0 || oldIndex >= visibleList.length ||
        newIndex < 0 || newIndex >= visibleList.length) {
      return this;
    }

    final item = visibleList.removeAt(oldIndex);
    visibleList.insert(newIndex, item);

    // Rebuild order based on new positions
    final newWidgets = widgets.map((w) {
      final visibleIndex = visibleList.indexWhere((v) => v.id == w.id);
      if (visibleIndex >= 0) {
        return w.copyWith(order: visibleIndex);
      }
      return w;
    }).toList();

    return DashboardLayout(widgets: newWidgets);
  }

  /// Reset to default layout
  static DashboardLayout defaultLayout() {
    return DashboardLayout(widgets: DashboardWidgetRegistry.getDefaultConfig());
  }

  Map<String, dynamic> toJson() {
    return {
      'widgets': widgets.map((w) => w.toJson()).toList(),
    };
  }

  factory DashboardLayout.fromJson(Map<String, dynamic> json) {
    final widgetsList = json['widgets'] as List?;
    if (widgetsList == null || widgetsList.isEmpty) {
      return DashboardLayout.defaultLayout();
    }

    final widgets = widgetsList
        .map((w) => DashboardWidgetConfig.fromJson(w as Map<String, dynamic>))
        .toList();

    // Ensure all available widgets are present (for forward compatibility)
    final existingIds = widgets.map((w) => w.id).toSet();
    for (final info in DashboardWidgetRegistry.availableWidgets) {
      if (!existingIds.contains(info.id)) {
        widgets.add(DashboardWidgetConfig(
          id: info.id,
          visible: true,
          order: widgets.length,
        ));
      }
    }

    return DashboardLayout(widgets: widgets);
  }
}
