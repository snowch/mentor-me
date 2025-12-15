/// Claude function calling schemas for reflection session tools
///
/// These schemas define what tools are available to the AI and how to use them.
/// Each schema follows the Claude API function calling format.

class ReflectionFunctionSchemas {
  static const List<Map<String, dynamic>> allTools = [
    // Goal tools
    createGoalTool,
    updateGoalTool,
    deleteGoalTool,
    moveGoalToActiveTool,
    moveGoalToBacklogTool,
    completeGoalTool,
    abandonGoalTool,

    // Milestone tools
    createMilestoneTool,
    updateMilestoneTool,
    deleteMilestoneTool,
    completeMilestoneTool,
    uncompleteMilestoneTool,

    // Habit tools
    createHabitTool,
    updateHabitTool,
    deleteHabitTool,
    pauseHabitTool,
    activateHabitTool,
    archiveHabitTool,
    markHabitCompleteTool,

    // Check-in template tools
    createCheckInTemplateTool,
    scheduleCheckInReminderTool,

    // Session tools
    saveSessionAsJournalTool,
    scheduleFollowUpTool,

    // Win tracking tools
    recordWinTool,

    // Todo tools
    createTodoTool,
    updateTodoTool,
    deleteTodoTool,
    completeTodoTool,

    // Conversion tools
    convertHabitToGoalTool,
    convertHabitToTodoTool,
    convertGoalToHabitTool,
    convertGoalToTodoTool,
    convertTodoToGoalTool,
    convertTodoToHabitTool,
  ];

  // ==========================================================================
  // GOAL TOOLS
  // ==========================================================================

  static const Map<String, dynamic> createGoalTool = {
    'name': 'create_goal',
    'description': 'Creates a new goal for the user with optional milestones',
    'input_schema': {
      'type': 'object',
      'properties': {
        'title': {
          'type': 'string',
          'description': 'The goal title (e.g., "Launch my website")',
        },
        'description': {
          'type': 'string',
          'description': 'Optional detailed description of the goal',
        },
        'category': {
          'type': 'string',
          'enum': ['health', 'career', 'personal', 'financial', 'learning', 'relationships'],
          'description': 'Goal category',
        },
        'targetDate': {
          'type': 'string',
          'description': 'Optional target completion date in ISO 8601 format (e.g., "2025-12-31T00:00:00.000")',
        },
        'milestones': {
          'type': 'array',
          'description': 'Optional list of milestones for this goal',
          'items': {
            'type': 'object',
            'properties': {
              'title': {'type': 'string'},
              'description': {'type': 'string'},
              'targetDate': {'type': 'string'},
            },
            'required': ['title'],
          },
        },
      },
      'required': ['title', 'category'],
    },
  };

  static const Map<String, dynamic> updateGoalTool = {
    'name': 'update_goal',
    'description': 'Updates an existing goal',
    'input_schema': {
      'type': 'object',
      'properties': {
        'goalId': {'type': 'string', 'description': 'ID of the goal to update'},
        'title': {'type': 'string', 'description': 'New title'},
        'description': {'type': 'string', 'description': 'New description'},
        'category': {
          'type': 'string',
          'enum': ['health', 'career', 'personal', 'financial', 'learning', 'relationships'],
        },
        'targetDate': {'type': 'string', 'description': 'New target date (ISO 8601)'},
      },
      'required': ['goalId'],
    },
  };

  static const Map<String, dynamic> deleteGoalTool = {
    'name': 'delete_goal',
    'description': 'Permanently deletes a goal',
    'input_schema': {
      'type': 'object',
      'properties': {
        'goalId': {'type': 'string', 'description': 'ID of the goal to delete'},
      },
      'required': ['goalId'],
    },
  };

  static const Map<String, dynamic> moveGoalToActiveTool = {
    'name': 'move_goal_to_active',
    'description': 'Moves a goal from backlog to active status',
    'input_schema': {
      'type': 'object',
      'properties': {
        'goalId': {'type': 'string', 'description': 'ID of the goal to activate'},
      },
      'required': ['goalId'],
    },
  };

  static const Map<String, dynamic> moveGoalToBacklogTool = {
    'name': 'move_goal_to_backlog',
    'description': 'Moves a goal to backlog (deprioritize)',
    'input_schema': {
      'type': 'object',
      'properties': {
        'goalId': {'type': 'string', 'description': 'ID of the goal to move'},
        'reason': {'type': 'string', 'description': 'Optional reason for moving to backlog'},
      },
      'required': ['goalId'],
    },
  };

  static const Map<String, dynamic> completeGoalTool = {
    'name': 'complete_goal',
    'description': 'Marks a goal as completed',
    'input_schema': {
      'type': 'object',
      'properties': {
        'goalId': {'type': 'string', 'description': 'ID of the goal to complete'},
      },
      'required': ['goalId'],
    },
  };

  static const Map<String, dynamic> abandonGoalTool = {
    'name': 'abandon_goal',
    'description': 'Marks a goal as abandoned (user decided not to pursue it)',
    'input_schema': {
      'type': 'object',
      'properties': {
        'goalId': {'type': 'string', 'description': 'ID of the goal to abandon'},
        'reason': {'type': 'string', 'description': 'Optional reason for abandoning'},
      },
      'required': ['goalId'],
    },
  };

  // ==========================================================================
  // MILESTONE TOOLS
  // ==========================================================================

  static const Map<String, dynamic> createMilestoneTool = {
    'name': 'create_milestone',
    'description': 'Creates a new milestone for a goal',
    'input_schema': {
      'type': 'object',
      'properties': {
        'goalId': {'type': 'string', 'description': 'ID of the goal'},
        'title': {'type': 'string', 'description': 'Milestone title'},
        'description': {'type': 'string', 'description': 'Optional description'},
        'targetDate': {'type': 'string', 'description': 'Optional target date (ISO 8601)'},
      },
      'required': ['goalId', 'title'],
    },
  };

  static const Map<String, dynamic> updateMilestoneTool = {
    'name': 'update_milestone',
    'description': 'Updates an existing milestone',
    'input_schema': {
      'type': 'object',
      'properties': {
        'goalId': {'type': 'string'},
        'milestoneId': {'type': 'string'},
        'title': {'type': 'string'},
        'description': {'type': 'string'},
        'targetDate': {'type': 'string'},
      },
      'required': ['goalId', 'milestoneId'],
    },
  };

  static const Map<String, dynamic> deleteMilestoneTool = {
    'name': 'delete_milestone',
    'description': 'Deletes a milestone',
    'input_schema': {
      'type': 'object',
      'properties': {
        'goalId': {'type': 'string'},
        'milestoneId': {'type': 'string'},
      },
      'required': ['goalId', 'milestoneId'],
    },
  };

  static const Map<String, dynamic> completeMilestoneTool = {
    'name': 'complete_milestone',
    'description': 'Marks a milestone as completed',
    'input_schema': {
      'type': 'object',
      'properties': {
        'goalId': {'type': 'string'},
        'milestoneId': {'type': 'string'},
      },
      'required': ['goalId', 'milestoneId'],
    },
  };

  static const Map<String, dynamic> uncompleteMilestoneTool = {
    'name': 'uncomplete_milestone',
    'description': 'Unmarks a milestone as completed',
    'input_schema': {
      'type': 'object',
      'properties': {
        'goalId': {'type': 'string'},
        'milestoneId': {'type': 'string'},
      },
      'required': ['goalId', 'milestoneId'],
    },
  };

  // ==========================================================================
  // HABIT TOOLS
  // ==========================================================================

  static const Map<String, dynamic> createHabitTool = {
    'name': 'create_habit',
    'description': 'Creates a new daily habit to track',
    'input_schema': {
      'type': 'object',
      'properties': {
        'title': {'type': 'string', 'description': 'Habit title (e.g., "Meditate for 10 minutes")'},
        'description': {'type': 'string', 'description': 'Optional description'},
      },
      'required': ['title'],
    },
  };

  static const Map<String, dynamic> updateHabitTool = {
    'name': 'update_habit',
    'description': 'Updates an existing habit',
    'input_schema': {
      'type': 'object',
      'properties': {
        'habitId': {'type': 'string'},
        'title': {'type': 'string'},
        'description': {'type': 'string'},
      },
      'required': ['habitId'],
    },
  };

  static const Map<String, dynamic> deleteHabitTool = {
    'name': 'delete_habit',
    'description': 'Permanently deletes a habit',
    'input_schema': {
      'type': 'object',
      'properties': {
        'habitId': {'type': 'string'},
      },
      'required': ['habitId'],
    },
  };

  static const Map<String, dynamic> pauseHabitTool = {
    'name': 'pause_habit',
    'description': 'Pauses a habit temporarily',
    'input_schema': {
      'type': 'object',
      'properties': {
        'habitId': {'type': 'string'},
      },
      'required': ['habitId'],
    },
  };

  static const Map<String, dynamic> activateHabitTool = {
    'name': 'activate_habit',
    'description': 'Activates a paused habit',
    'input_schema': {
      'type': 'object',
      'properties': {
        'habitId': {'type': 'string'},
      },
      'required': ['habitId'],
    },
  };

  static const Map<String, dynamic> archiveHabitTool = {
    'name': 'archive_habit',
    'description': 'Archives a habit (no longer tracking)',
    'input_schema': {
      'type': 'object',
      'properties': {
        'habitId': {'type': 'string'},
      },
      'required': ['habitId'],
    },
  };

  static const Map<String, dynamic> markHabitCompleteTool = {
    'name': 'mark_habit_complete',
    'description': 'Marks a habit as completed for a specific date',
    'input_schema': {
      'type': 'object',
      'properties': {
        'habitId': {'type': 'string'},
        'date': {'type': 'string', 'description': 'Date in ISO 8601 format'},
      },
      'required': ['habitId', 'date'],
    },
  };

  // ==========================================================================
  // TEMPLATE TOOLS (Unified journaling/check-in templates)
  // ==========================================================================

  /// Creates a journal template - can be used for:
  /// - Structured journaling sessions (no schedule)
  /// - Recurring check-ins with reminders (with schedule)
  static const Map<String, dynamic> createCheckInTemplateTool = {
    'name': 'create_checkin_template',
    'description': 'Creates a custom template for structured reflection or recurring check-ins. '
        'Templates can be used on-demand for guided journaling, or scheduled for regular reminders. '
        'Schedule is optional - omit it for on-demand templates.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'name': {
          'type': 'string',
          'description': 'Template name (e.g., "Weekly Urge Surfing Check-In", "Evening Reflection")',
        },
        'description': {
          'type': 'string',
          'description': 'Optional description explaining the purpose of this template',
        },
        'category': {
          'type': 'string',
          'enum': ['therapy', 'wellness', 'productivity', 'creative', 'custom'],
          'description': 'Template category for organization',
        },
        'fields': {
          'type': 'array',
          'description': 'List of prompts/questions for the template',
          'items': {
            'type': 'object',
            'properties': {
              'label': {
                'type': 'string',
                'description': 'Short label for the field (e.g., "Current Mood", "Today\'s Focus")',
              },
              'prompt': {
                'type': 'string',
                'description': 'The full question or prompt text',
              },
              'type': {
                'type': 'string',
                'enum': ['text', 'longText', 'scale', 'multipleChoice', 'checklist', 'number'],
                'description': 'Field type: text (short), longText (paragraph), scale (1-10), multipleChoice, checklist, number',
              },
              'required': {
                'type': 'boolean',
                'description': 'Whether this field must be answered',
              },
              'helpText': {
                'type': 'string',
                'description': 'Optional hint text to help user answer',
              },
              'validation': {
                'type': 'object',
                'description': 'Optional validation: {min, max} for scale/number, {options: [...]} for multipleChoice/checklist',
              },
            },
            'required': ['label', 'prompt', 'type'],
          },
        },
        'schedule': {
          'type': 'object',
          'description': 'OPTIONAL: When to remind user to complete this template. Omit for on-demand templates.',
          'properties': {
            'frequency': {
              'type': 'string',
              'enum': ['daily', 'weekly', 'biweekly', 'custom', 'none'],
              'description': 'How often to remind (use "none" or omit schedule entirely for no reminders)',
            },
            'time': {
              'type': 'object',
              'properties': {
                'hour': {'type': 'integer', 'minimum': 0, 'maximum': 23},
                'minute': {'type': 'integer', 'minimum': 0, 'maximum': 59},
              },
              'required': ['hour', 'minute'],
            },
            'daysOfWeek': {
              'type': 'array',
              'items': {'type': 'integer', 'minimum': 1, 'maximum': 7},
              'description': 'For weekly/biweekly: 1=Monday, 7=Sunday',
            },
            'customDayInterval': {
              'type': 'integer',
              'description': 'For custom frequency: check in every N days',
            },
          },
        },
        'emoji': {
          'type': 'string',
          'description': 'Optional emoji for visual identification (e.g., "🧘", "✨")',
        },
        'aiGuidance': {
          'type': 'string',
          'description': 'Optional instructions for how AI should interact with responses',
        },
        'completionMessage': {
          'type': 'string',
          'description': 'Optional message to show when user completes the template',
        },
      },
      'required': ['name', 'fields'],
    },
  };

  static const Map<String, dynamic> scheduleCheckInReminderTool = {
    'name': 'schedule_checkin_reminder',
    'description': 'Schedules or updates a reminder for an existing template',
    'input_schema': {
      'type': 'object',
      'properties': {
        'templateId': {'type': 'string', 'description': 'ID of the template'},
        'schedule': {
          'type': 'object',
          'description': 'New schedule configuration',
          'properties': {
            'frequency': {
              'type': 'string',
              'enum': ['daily', 'weekly', 'biweekly', 'custom', 'none'],
            },
            'time': {
              'type': 'object',
              'properties': {
                'hour': {'type': 'integer'},
                'minute': {'type': 'integer'},
              },
            },
            'daysOfWeek': {
              'type': 'array',
              'items': {'type': 'integer'},
            },
          },
        },
      },
      'required': ['templateId'],
    },
  };

  // ==========================================================================
  // SESSION TOOLS
  // ==========================================================================

  static const Map<String, dynamic> saveSessionAsJournalTool = {
    'name': 'save_session_as_journal',
    'description': 'Saves the reflection session as a journal entry',
    'input_schema': {
      'type': 'object',
      'properties': {
        'sessionId': {'type': 'string'},
        'content': {'type': 'string', 'description': 'Summary of the session'},
        'linkedGoalIds': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Optional goal IDs discussed in session',
        },
      },
      'required': ['sessionId', 'content'],
    },
  };

  static const Map<String, dynamic> scheduleFollowUpTool = {
    'name': 'schedule_followup',
    'description': 'Schedules a follow-up reminder to check progress',
    'input_schema': {
      'type': 'object',
      'properties': {
        'daysFromNow': {
          'type': 'integer',
          'description': 'Number of days from now (e.g., 7 for 1 week)',
        },
        'reminderMessage': {
          'type': 'string',
          'description': 'Message to show in reminder',
        },
      },
      'required': ['daysFromNow', 'reminderMessage'],
    },
  };

  // ==========================================================================
  // WIN TRACKING TOOLS
  // ==========================================================================

  static const Map<String, dynamic> recordWinTool = {
    'name': 'record_win',
    'description': 'Records a win or accomplishment mentioned by the user. '
        'Use this when the user shares something they are proud of, '
        'achieved, or completed. This helps track progress and provides '
        'motivation through a visible record of accomplishments.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'description': {
          'type': 'string',
          'description': 'Description of the win/accomplishment (e.g., "Completed 5 workouts this week", "Had a difficult conversation I\'d been avoiding")',
        },
        'category': {
          'type': 'string',
          'enum': ['health', 'fitness', 'career', 'learning', 'relationships', 'finance', 'personal', 'habit', 'other'],
          'description': 'Category of the win',
        },
        'linkedGoalId': {
          'type': 'string',
          'description': 'Optional ID of a goal this win relates to',
        },
        'linkedHabitId': {
          'type': 'string',
          'description': 'Optional ID of a habit this win relates to',
        },
      },
      'required': ['description'],
    },
  };

  // ==========================================================================
  // TODO TOOLS
  // ==========================================================================

  static const Map<String, dynamic> createTodoTool = {
    'name': 'create_todo',
    'description': 'Creates a new one-time todo/task for the user. '
        'Use this for quick action items that need to be done once (unlike habits which are recurring).',
    'input_schema': {
      'type': 'object',
      'properties': {
        'title': {
          'type': 'string',
          'description': 'The todo title (e.g., "Call the dentist", "Buy groceries")',
        },
        'description': {
          'type': 'string',
          'description': 'Optional detailed description',
        },
        'dueDate': {
          'type': 'string',
          'description': 'Optional due date in ISO 8601 format (e.g., "2025-12-31T00:00:00.000")',
        },
        'priority': {
          'type': 'string',
          'enum': ['low', 'medium', 'high'],
          'description': 'Priority level (default: medium)',
        },
        'linkedGoalId': {
          'type': 'string',
          'description': 'Optional ID of a goal this todo supports',
        },
        'linkedHabitId': {
          'type': 'string',
          'description': 'Optional ID of a habit this todo relates to',
        },
      },
      'required': ['title'],
    },
  };

  static const Map<String, dynamic> updateTodoTool = {
    'name': 'update_todo',
    'description': 'Updates an existing todo',
    'input_schema': {
      'type': 'object',
      'properties': {
        'todoId': {'type': 'string', 'description': 'ID of the todo to update'},
        'title': {'type': 'string', 'description': 'New title'},
        'description': {'type': 'string', 'description': 'New description'},
        'dueDate': {'type': 'string', 'description': 'New due date (ISO 8601)'},
        'priority': {
          'type': 'string',
          'enum': ['low', 'medium', 'high'],
        },
      },
      'required': ['todoId'],
    },
  };

  static const Map<String, dynamic> deleteTodoTool = {
    'name': 'delete_todo',
    'description': 'Permanently deletes a todo',
    'input_schema': {
      'type': 'object',
      'properties': {
        'todoId': {'type': 'string', 'description': 'ID of the todo to delete'},
      },
      'required': ['todoId'],
    },
  };

  static const Map<String, dynamic> completeTodoTool = {
    'name': 'complete_todo',
    'description': 'Marks a todo as completed',
    'input_schema': {
      'type': 'object',
      'properties': {
        'todoId': {'type': 'string', 'description': 'ID of the todo to complete'},
      },
      'required': ['todoId'],
    },
  };

  // ==========================================================================
  // CONVERSION TOOLS
  // ==========================================================================

  static const Map<String, dynamic> convertHabitToGoalTool = {
    'name': 'convert_habit_to_goal',
    'description': 'Converts a habit into a goal. Use when the user realizes their habit '
        'is more of a one-time achievement than a daily practice.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'habitId': {'type': 'string', 'description': 'ID of the habit to convert'},
        'category': {
          'type': 'string',
          'enum': ['health', 'career', 'personal', 'financial', 'learning', 'relationships'],
          'description': 'Category for the new goal',
        },
        'targetDate': {
          'type': 'string',
          'description': 'Optional target date for the goal (ISO 8601)',
        },
        'deleteOriginal': {
          'type': 'boolean',
          'description': 'Whether to delete the original habit after conversion (default: true)',
        },
      },
      'required': ['habitId', 'category'],
    },
  };

  static const Map<String, dynamic> convertHabitToTodoTool = {
    'name': 'convert_habit_to_todo',
    'description': 'Converts a habit into a one-time todo. Use when the user realizes '
        'their habit is a single task rather than a recurring practice.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'habitId': {'type': 'string', 'description': 'ID of the habit to convert'},
        'dueDate': {
          'type': 'string',
          'description': 'Optional due date for the todo (ISO 8601)',
        },
        'priority': {
          'type': 'string',
          'enum': ['low', 'medium', 'high'],
          'description': 'Priority for the new todo (default: medium)',
        },
        'deleteOriginal': {
          'type': 'boolean',
          'description': 'Whether to delete the original habit after conversion (default: true)',
        },
      },
      'required': ['habitId'],
    },
  };

  static const Map<String, dynamic> convertGoalToHabitTool = {
    'name': 'convert_goal_to_habit',
    'description': 'Converts a goal into a daily habit. Use when the user realizes their goal '
        'is better tracked as a recurring practice (e.g., "Exercise daily" instead of "Get fit").',
    'input_schema': {
      'type': 'object',
      'properties': {
        'goalId': {'type': 'string', 'description': 'ID of the goal to convert'},
        'deleteOriginal': {
          'type': 'boolean',
          'description': 'Whether to delete the original goal after conversion (default: true)',
        },
      },
      'required': ['goalId'],
    },
  };

  static const Map<String, dynamic> convertGoalToTodoTool = {
    'name': 'convert_goal_to_todo',
    'description': 'Converts a goal into a one-time todo. Use when the user realizes their goal '
        'is a simple task rather than a larger objective.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'goalId': {'type': 'string', 'description': 'ID of the goal to convert'},
        'dueDate': {
          'type': 'string',
          'description': 'Optional due date for the todo (defaults to goal target date)',
        },
        'priority': {
          'type': 'string',
          'enum': ['low', 'medium', 'high'],
          'description': 'Priority for the new todo (default: medium)',
        },
        'deleteOriginal': {
          'type': 'boolean',
          'description': 'Whether to delete the original goal after conversion (default: true)',
        },
      },
      'required': ['goalId'],
    },
  };

  static const Map<String, dynamic> convertTodoToGoalTool = {
    'name': 'convert_todo_to_goal',
    'description': 'Converts a todo into a goal. Use when the user realizes their task '
        'is a larger objective that needs milestones and tracking.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'todoId': {'type': 'string', 'description': 'ID of the todo to convert'},
        'category': {
          'type': 'string',
          'enum': ['health', 'career', 'personal', 'financial', 'learning', 'relationships'],
          'description': 'Category for the new goal',
        },
        'targetDate': {
          'type': 'string',
          'description': 'Optional target date for the goal (defaults to todo due date)',
        },
        'deleteOriginal': {
          'type': 'boolean',
          'description': 'Whether to delete the original todo after conversion (default: true)',
        },
      },
      'required': ['todoId', 'category'],
    },
  };

  static const Map<String, dynamic> convertTodoToHabitTool = {
    'name': 'convert_todo_to_habit',
    'description': 'Converts a todo into a daily habit. Use when the user realizes their task '
        'should be a recurring practice rather than a one-time action.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'todoId': {'type': 'string', 'description': 'ID of the todo to convert'},
        'deleteOriginal': {
          'type': 'boolean',
          'description': 'Whether to delete the original todo after conversion (default: true)',
        },
      },
      'required': ['todoId'],
    },
  };
}
