AtomFoldFunctions = require '../lib/fold-functions'

describe 'autofolding', ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('fold-functions').then ->
        atom.config.set('fold-functions.autofold', true)
        atom.config.set('fold-functions.shortfileCutoff', 0)
        atom.config.set('fold-functions.skipAutofoldWhenNotFirstLine', true)
        atom.config.set('fold-functions.skipAutofoldWhenOnlyOneFunction', true)

  it 'should autofold', ->
    atom.workspace.open('files/php-oop.php').then (editor) ->
      expect(editor.getPath()).toContain 'php-oop.php'
      expect(editor.isFoldedAtBufferRow(10)).toBe true
      expect(editor.isFoldedAtBufferRow(17)).toBe true

  it 'should not break for when there is no editor (#11)', ->
    atom.workspace.open('files').then (editor) ->
      expect(AtomFoldFunctions.autofold(editor)).toBe false

describe 'fold functions methods', ->
  editor = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-javascript')

    waitsForPromise ->
      atom.packages.activatePackage('fold-functions').then ->
        atom.config.set('fold-functions.autofold', true)
        atom.config.set('fold-functions.shortfileCutoff', 0)
        atom.config.set('fold-functions.skipAutofoldWhenNotFirstLine', true)
        atom.config.set('fold-functions.skipAutofoldWhenOnlyOneFunction', true)

    waitsForPromise ->
      atom.workspace.open(__dirname + '/files/js-sample.js').then (o) -> editor = o

  it 'count() should count correctly', ->
    expect(AtomFoldFunctions.count(editor)).toEqual 1

  describe 'hasScopeAtBufferRow()', ->
    it 'should return true when the scope matches', ->
      expect(AtomFoldFunctions.hasScopeAtBufferRow(editor, 0, 'source.js'))
        .toBe true
      expect(AtomFoldFunctions.hasScopeAtBufferRow(
        editor,
        0,
        'meta.function',
        'meta.method',
        'storage.type.arrow',
        'entity.name.function.constructor')
      )
        .toBe true

    it 'should return false when the scope does not match', ->
      atom.workspace.open('files/php-oop.php').then (editor) ->
        expect(AtomFoldFunctions.hasScopeAtBufferRow(editor, 0, 'source.bogus'))
          .toBe false
        expect(AtomFoldFunctions.hasScopeAtBufferRow(
          editor,
          1,
          'meta.function',
          'meta.method',
          'storage.type.arrow',
          'entity.name.function.constructor')
        )
          .toBe false

  it 'getScopesForBufferRow() returns all scopes', ->
    text = editor.lineTextForBufferRow(0)
    scopes = AtomFoldFunctions.getScopesForBufferRow(editor, 0)

    expect(scopes.length).toBeGreaterThan 0
    expected = [
      'source.js',
      'meta.function.js',
      'storage.type.function.js',
      'entity.name.function.js',
      'punctuation.definition.parameters.begin.js'
      'punctuation.definition.parameters.end.js',
      'variable.parameter.function.js',
      'meta.object.delimiter.js',
      'meta.brace.curly.js',
    ]
    for expectedScope in expected
      expect(scopes).toContain expectedScope

  it 'scopeInScopes() returns true when matching', ->
    testScopes = ['meta.function', 'meta.method', 'storage.type.arrow', 'entity.name.function.constructor']
    scopes = ['meta.function']
    expect(AtomFoldFunctions.scopeInScopes(scopes, testScopes)).toBe.true
    scopes = [
      'text.html.php.drupal',
      'meta.embedded.block.php',
      'source.phpmeta.function.php',
      'storage.type.function.php',
      'entity.name.function.php',
      'punctuation.definition.parameters.begin.php',
      'meta.function.arguments.php',
      'meta.function.argument.no-default.php',
      'variable.other.php',
      'punctuation.definition.variable.php',
      'meta.function.argument.array.php',
      'storage.type.php',
      'keyword.operator.assignment.php',
      'support.function.construct.php',
      'punctuation.definition.array.begin.php',
      'punctuation.definition.array.end.php',
      'punctuation.definition.parameters.end.php',
      'punctuation.section.scope.begin.php'
    ]
    expect(AtomFoldFunctions.scopeInScopes(scopes, testScopes)).toBe.true
