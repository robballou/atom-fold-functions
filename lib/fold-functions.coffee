{CompositeDisposable} = require 'atom'

module.exports = AtomFoldFunctions =
  modalPanel: null
  subscriptions: null
  indentLevel: null

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

  deactivate: ->
    @subscriptions.dispose()

  fold: (action) ->
    if !action then action = 'fold'
    editor = atom.workspace.getActiveTextEditor()
    @indentLevel = null
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

      isFunction = @hasScopeAtBufferRow(editor, row, 'meta.function')
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

  hasScopeAtBufferRow: (editor, row, scope) ->
    found = false
    text = editor.lineTextForBufferRow(row).trim()
    if text.length > 0
      # scan the text line to see if there is a function somewhere
      for pos in [0..text.length]
        scopes = editor.scopesForBufferPosition([row, pos])

        # see if we found the scope we're after...
        found = true for item in scopes when item.startsWith(scope)
        if found then break
    found
