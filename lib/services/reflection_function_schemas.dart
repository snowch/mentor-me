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
  // CHECK-IN TEMPLATE TOOLS
  // ==========================================================================

  static const Map<String, dynamic> createCheckInTemplateTool = {
    'name': 'create_checkin_template',
    'description': 'Creates a custom recurring check-in with specific questions',
    'input_schema': {
      'type': 'object',
      'properties': {
        'name': {'type': 'string', 'description': 'Template name (e.g., "Weekly Urge Surfing Check-In")'},
        'description': {'type': 'string', 'description': 'Optional description'},
        'questions': {
          'type': 'array',
          'description': 'List of questions to ask during check-in',
          'items': {
            'type': 'object',
            'properties': {
              'text': {'type': 'string', 'description': 'Question text'},
              'type': {
                'type': 'string',
                'enum': ['freeform', 'scale1to5', 'yesNo', 'multipleChoice'],
                'description': 'Question type',
              },
              'options': {
                'type': 'array',
                'items': {'type': 'string'},
                'description': 'Options for multiple choice questions',
              },
              'isRequired': {'type': 'boolean'},
            },
            'required': ['text', 'type'],
          },
        },
        'schedule': {
          'type': 'object',
          'description': 'When to remind user',
          'properties': {
            'frequency': {
              'type': 'string',
              'enum': ['daily', 'weekly', 'biweekly', 'custom'],
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
          'required': ['frequency', 'time'],
        },
        'emoji': {'type': 'string', 'description': 'Optional emoji for the template'},
      },
      'required': ['name', 'questions', 'schedule'],
    },
  };

  static const Map<String, dynamic> scheduleCheckInReminderTool = {
    'name': 'schedule_checkin_reminder',
    'description': 'Schedules a reminder for an existing check-in template',
    'input_schema': {
      'type': 'object',
      'properties': {
        'templateId': {'type': 'string', 'description': 'ID of the template'},
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
}
