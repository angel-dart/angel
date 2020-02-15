const String authenticateAction = 'authenticate';
const String indexAction = 'index';
const String readAction = 'read';
const String createAction = 'create';
const String modifyAction = 'modify';
const String updateAction = 'update';
const String removeAction = 'remove';

@deprecated
const String ACTION_AUTHENTICATE = authenticateAction;

@deprecated
const String ACTION_INDEX = indexAction;

@deprecated
const String ACTION_READ = readAction;

@deprecated
const String ACTION_CREATE = createAction;

@deprecated
const String ACTION_MODIFY = modifyAction;

@deprecated
const String ACTION_UPDATE = updateAction;

@deprecated
const String ACTION_REMOVE = removeAction;

const String authenticatedEvent = 'authenticated';
const String errorEvent = 'error';
const String indexedEvent = 'indexed';
const String readEvent = 'read';
const String createdEvent = 'created';
const String modifiedEvent = 'modified';
const String updatedEvent = 'updated';
const String removedEvent = 'removed';

@deprecated
const String EVENT_AUTHENTICATED = authenticatedEvent;

@deprecated
const String EVENT_ERROR = errorEvent;

@deprecated
const String EVENT_INDEXED = indexedEvent;

@deprecated
const String EVENT_READ = readEvent;

@deprecated
const String EVENT_CREATED = createdEvent;

@deprecated
const String EVENT_MODIFIED = modifiedEvent;

@deprecated
const String EVENT_UPDATED = updatedEvent;

@deprecated
const String EVENT_REMOVED = removedEvent;

/// The standard Angel service actions.
const List<String> actions = const <String>[
  indexAction,
  readAction,
  createAction,
  modifyAction,
  updateAction,
  removeAction
];

@deprecated
const List<String> ACTIONS = actions;

/// The standard Angel service events.
const List<String> events = const <String>[
  indexedEvent,
  readEvent,
  createdEvent,
  modifiedEvent,
  updatedEvent,
  removedEvent
];

@deprecated
const List<String> EVENTS = events;
