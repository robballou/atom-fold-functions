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
        editor.displayBuffer.tokenizedBuffer.onDidTokenize =>
          autofoldGrammars = atom.config.get('fold-functions.autofoldGrammars')
          grammar = editor.getGrammar()
          if autofoldGrammars.length > 0 and grammar.name not in autofoldGrammars
            console.log('autofold grammar not whitelisted', grammar.name)
            return

          autofoldIgnoreGrammars = atom.config.get('fold-functions.autofoldIgnoreGrammars')
          if autofoldIgnoreGrammars.length > 0 and grammar.name in autofoldIgnoreGrammars
            console.log('autofold ignored grammar', grammar.name)
            return

          if shortfileCutoff = atom.config.get('fold-functions.shortfileCutoff')
            # make sure the file is longer than the cutoff before folding
            if shortfileCutoff > 0 and editor.getLineCount() >= shortfileCutoff
              @fold('autofold', editor)

  deactivate: ->
    @subscriptions.dispose()

  fold: (action, editor) ->
    if !action then action = 'fold'
    if not editor
      editor = atom.workspace.getActiveTextEditor()

    @indentLevel = null
    hasFoldableLines = false
    for row in [0..editor.getLastBufferRow()]
      foldable = editor.isFoldableAtBufferRow(row)
      isFolded = editor.isFoldedAtBufferRow(row)
      isCommented = editor.isBufferRowCommented(row)

      # check the indent level for this line and make sure it is the same as
      # previous lines where we found functions
      thisIndentLevel = editor.indentationForBufferRow(row)
      if @indentLevel and thisIndentLevel != @indentLevel
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
