{AtomFoldFunctions} = require '../lib/fold-functions'

describe "autofolding", ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('fold-functions').then ->
        atom.config.set('fold-functions.autofold', true)
        atom.config.set('fold-functions.shortfileCutoff', 42)
        atom.config.set('fold-functions.skipAutofoldWhenNotFirstLine', true)
        atom.config.set('fold-functions.skipAutofoldWhenOnlyOneFunction', true)

  it "should autofold", ->
    atom.workspace.open('files/php-oop.php').then (editor) ->
      expect(editor.getPath()).toContain 'php-oop.php'
      expect(editor.isFoldedAtBufferRow(10)).toBe true
      expect(editor.isFoldedAtBufferRow(17)).toBe true

describe "fold functions methods", ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('fold-functions').then ->
        atom.config.set('fold-functions.autofold', true)
        atom.config.set('fold-functions.shortfileCutoff', 42)
        atom.config.set('fold-functions.skipAutofoldWhenNotFirstLine', true)
        atom.config.set('fold-functions.skipAutofoldWhenOnlyOneFunction', true)

  it "count() should count correctly", ->
    atom.workspace.open('files/php-oop.php').then (editor) ->
      expect(editor.getPath()).toContain 'php-oop.php'
      expect(AtomFoldFunctions.count(editor)).toEqual 2

  describe "hasScopeAtBufferRow()", ->
    it "should return true when the scope matches", ->
      atom.workspace.open('files/php-oop.php').then (editor) ->
        expect(AtomFoldFunctions.hasScopeAtBufferRow(editor, 6, 'source.php'))
          .toBe true
        expect(AtomFoldFunctions.hasScopeAtBufferRow(
          editor,
          10,
          'meta.function',
          'meta.method',
          'storage.type.arrow',
          'entity.name.function.constructor')
        )
          .toBe true



    it "should return false when the scope does not match", ->
      atom.workspace.open('files/php-oop.php').then (editor) ->
        expect(AtomFoldFunctions.hasScopeAtBufferRow(editor, 6, 'source.bogus'))
          .toBe false
        expect(AtomFoldFunctions.hasScopeAtBufferRow(
          editor,
          6,
          'meta.function',
          'meta.method',
          'storage.type.arrow',
          'entity.name.function.constructor')
        )
          .toBe false
