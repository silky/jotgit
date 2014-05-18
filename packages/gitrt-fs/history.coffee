EventEmitter = Npm.require('events').EventEmitter
ot = Npm.require('ot')

# ot doesn't export this by default
ot.WrappedOperation = Npm.require(
  './npm/gitrt-fs/main/node_modules/ot/lib/wrapped-operation.js')

#
# Manage the sequence of operational transformation edits maintained on the
# server. All clients that are editing a particular file share this sequence,
# but, crucially, they do not write their edits to the sequence directly,
# because the server may have to transform them before they are added to this
# sequence.
#
class EditorServer extends EventEmitter
  constructor: (document, operations=[]) ->
    @server = new ot.Server(document, operations)
    @clientSelections = {}

  document: -> @server.document
  operations: -> @server.operations
  revision: -> @server.operations.length

  receiveOperation: (clientId, revision, operation, selection) ->
    #console.log ['receiveOperation', arguments...]

    wrapped = new ot.WrappedOperation(
      ot.TextOperation.fromJSON(operation),
      selection && ot.Selection.fromJSON(selection)
    )

    wrappedPrime = @server.receiveOperation(revision, wrapped)
    selectionPrime = wrappedPrime.meta
    @updateSelection(clientId, selectionPrime)

    this.emit 'operationApplied', clientId, wrappedPrime, selectionPrime

    null

  updateSelection: (clientId, selection) ->
    if selection
      @clientSelections[clientId] = ot.Selection.fromJSON(selection)
    else
      delete @clientSelections[clientId]

    this.emit 'selectionsUpdated', @clientSelections

    null
  
GitRt.EditorServer = EditorServer
