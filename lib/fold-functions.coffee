{CompositeDisposable} = require 'atom'

module.exports = AtomFoldFunctions =
  modalPanel: null
  subscriptions: null

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
    indentLevel = null
    for row in [0..editor.getLastBufferRow()]
      foldable = editor.isFoldableAtBufferRow(row)
      is_function = @hasScopeAtBufferRow(editor, row, 'meta.function')
      if foldable and is_function
        thisIndentLevel = editor.indentationForBufferRow(row)
        if indentLevel == null
          indentLevel = thisIndentLevel
        if thisIndentLevel == indentLevel
          if action == 'toggle'
            editor.toggleFoldAtBufferRow(row)
          else if action == 'unfold' and editor.isFoldedAtBufferRow(row)
            editor.unfoldBufferRow(row)
          else if !editor.isFoldedAtBufferRow(row)
            editor.foldBufferRow(row)

  toggle: ->
    @fold('toggle')

  unfold: ->
    @fold('unfold')

  hasScopeAtBufferRow: (editor, row, scope) ->
    found = false
    text = editor.lineTextForBufferRow(row)

    # scan the text line to see if there is a function somewhere
    for pos in [0..text.length]
      scopes = editor.scopesForBufferPosition([row, pos])
      found = true for item in scopes when item.startsWith(scope)
      if found then break
    found
