{CompositeDisposable} = require 'atom'

module.exports = AtomFoldFunctions =
  modalPanel: null
  subscriptions: null
  indentLevel: null

  config:
    autofold:
      type: 'boolean'
      default: false
    shortfileCutoff:
      type: 'integer'
      default: 42
    autofoldGrammars:
      type: 'array'
      default: []
    autofoldIgnoreGrammars:
      type: 'array'
      default: ['SQL', 'CSV', 'JSON', 'CSON', 'Plain Text']
    skipAutofoldWhenNotFirstLine:
      type: 'boolean'
      default: false
    skipAutofoldWhenOnlyOneFunction:
      type: 'boolean'
      default: false
    debug:
      type: 'boolean'
      default: false

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a
    # CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'fold-functions:toggle': => @toggle()

    @subscriptions.add atom.commands.add 'atom-workspace',
      'fold-functions:fold': => @fold()

    @subscriptions.add atom.commands.add 'atom-workspace',
      'fold-functions:unfold': => @unfold()

    if atom.config.get('fold-functions.autofold')
      atom.workspace.observeTextEditors (editor) =>
        editor.displayBuffer.tokenizedBuffer.onDidTokenize => @autofold(editor)

  deactivate: ->
    @subscriptions.dispose()

  autofold: (editor) ->
    grammar = editor.getGrammar()
    autofold = false

    # the grammar is not white listed (and there are things whitelisted)
    autofoldGrammars = atom.config.get('fold-functions.autofoldGrammars')
    if autofoldGrammars.length > 0 and grammar.name not in autofoldGrammars
      @debugMessage('fold functions: autofold grammar not whitelisted', grammar.name)
      return

    # the grammar is not in the ignore grammar list
    autofoldIgnoreGrammars = atom.config.get('fold-functions.autofoldIgnoreGrammars')
    if autofoldIgnoreGrammars.length > 0 and grammar.name in autofoldIgnoreGrammars
      @debugMessage('fold functions: autofold ignored grammar', grammar.name)
      return

    # check if the file is too short to run
    if shortfileCutoff = atom.config.get('fold-functions.shortfileCutoff')
      # make sure the file is longer than the cutoff before folding
      if shortfileCutoff > 0 and editor.getLineCount() >= shortfileCutoff
        autofold = true

    # figure out if we should skip autofolding because we are not on the first
    # line of the file.
    if autofold and atom.config.get('fold-functions.skipAutofoldWhenNotFirstLine')
      onFirstLine = true
      for cursor in editor.getCursors()
        if cursor.getBufferRow() > 0
          onFirstLine = false
          break

      if not onFirstLine
        @debugMessage('fold function: not on first line, skipping autofold')
        autofold = false

    # figure out if we should skip autofolding because there is only one
    # top-level function to fold
    if autofold and atom.config.get('fold-functions.skipAutofoldWhenOnlyOneFunction')
      if @count(editor) == 1
        @debugMessage('fold functions: only one function, skipping autofold')
        autofold = false

    if autofold
      console.log('fold functions: autofolding')
      @fold('autofold', editor)

  # Figure out the number of functions in this file.
  count: (editor) ->
    if not editor
      editor = atom.workspace.getActiveTextEditor()

    @indentLevel = @indentLevel || null
    hasFoldableLines = false

    functionCount = 0
    for row in [0..editor.getLastBufferRow()]
      foldable = editor.isFoldableAtBufferRow(row)
      isFolded = editor.isFoldedAtBufferRow(row)
      isCommented = editor.isBufferRowCommented(row)

      # check the indent level for this line and make sure it is the same as
      # previous lines where we found functions
      thisIndentLevel = editor.indentationForBufferRow(row)
      if @indentLevel != null and thisIndentLevel != @indentLevel
        continue

      if foldable
        hasFoldableLines = true

      isFunction = @hasScopeAtBufferRow(
        editor,
        row,
        'meta.function',
        'meta.method',
        'storage.type.arrow',
        'entity.name.function.constructor'
      )
      if foldable and isFunction and not isCommented
        if @indentLevel == null
          @indentLevel = thisIndentLevel
        functionCount++
    functionCount

  debugMessage: ->
    if atom.config.get('fold-functions.debug', false)
      console.log.apply(console, arguments)

  fold: (action, editor) ->
    if !action then action = 'fold'
    if not editor
      editor = atom.workspace.getActiveTextEditor()

    if not editor
      @debugMessage('no editor, skipping')
      return

    @debugMessage('fold functions:', action)
    @indentLevel = @indentLevel || null
    hasFoldableLines = false
    for row in [0..editor.getLastBufferRow()]
      foldable = editor.isFoldableAtBufferRow(row)
      isFolded = editor.isFoldedAtBufferRow(row)
      isCommented = editor.isBufferRowCommented(row)

      # check the indent level for this line and make sure it is the same as
      # previous lines where we found functions
      thisIndentLevel = editor.indentationForBufferRow(row)
      if @indentLevel != null and thisIndentLevel != @indentLevel
        continue

      # if we are unfolding lines, we don't need to pay attention to lines that
      # are not folded
      if action == 'unfold' and not isFolded
        continue

      # ignore commented lines
      if isCommented
        continue

      if foldable
        hasFoldableLines = true

      isFunction = @hasScopeAtBufferRow(editor, row,
      'meta.function', 'meta.method',
      'storage.type.arrow', 'entity.name.function.constructor')
      if foldable and isFunction and not isCommented
        if @indentLevel == null
          @indentLevel = thisIndentLevel
        if action == 'toggle'
          editor.toggleFoldAtBufferRow(row)
        else if action == 'unfold' and isFolded
          editor.unfoldBufferRow(row)
        else if !editor.isFoldedAtBufferRow(row)
          editor.foldBufferRow(row)

  toggle: ->
    @fold('toggle')

  unfold: ->
    @fold('unfold')

  hasScopeAtBufferRow: (editor, row, scopes...) ->
    for scope in scopes
      if this._hasScopeAtBufferRow(editor, row, scope)
        return true
    false

  _hasScopeAtBufferRow: (editor, row, scope) ->
    found = false
    text = editor.lineTextForBufferRow(row).trim()
    if text.length > 0
      # scan the text line to see if there is a function somewhere
      for pos in [0..text.length]
        scopes = editor.scopeDescriptorForBufferPosition([row, pos])
        # see if we found the scope we're after...
        found = true for item in scopes.scopes when item.startsWith(scope)
        if found then break
    found
