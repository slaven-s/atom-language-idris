IdrisIdeMode = require './idris-ide-mode'
Logger = require './Logger'
Rx = require 'rx-lite'

class IdrisModel
  requestId: 0
  ideModeRef: null
  subjects: {}
  warnings: {}

  ideMode: ->
    if !@ideModeRef
      @ideModeRef = new IdrisIdeMode
      @ideModeRef.on 'message', @handleCommand
    @ideModeRef

  stop: ->
    @ideModeRef?.stop()

  handleCommand: (cmd) =>
    if cmd.length > 0
      [op, params..., id] = cmd
      if @subjects[id]?
        subject = @subjects[id]
        switch op
          when ':return'
            ret = params[0]
            if ret[0] == ':ok'
              okparams = ret[1]
              if okparams[0] == ':metavariable-lemma'
                subject.onNext
                  responseType: 'return'
                  msg: okparams
              else
                subject.onNext
                  responseType: 'return'
                  msg: ret.slice(1)
            else
              subject.onError
                message: ret[1]
                warnings: @warnings[id]
            subject.onCompleted()
            delete @subjects[id]
          when ':write-string'
            msg = params[0]
            subject.onNext
              responseType: 'write-string'
              msg: msg
          when ':warning'
            warning = params[0]
            @warnings[id].push warning
          when ':set-prompt'
            # Ignore
          else
            console.log op, params

  getUID: -> ++@requestId

  prepareCommand: (cmd) ->
    id = @getUID()
    subject = new Rx.Subject
    @subjects[id] = subject
    @warnings[id] = []
    @ideMode().send [cmd, id]
    subject

  load: (uri) ->
    @prepareCommand [':load-file', uri]

  docsFor: (word) ->
    @prepareCommand [':docs-for', word]

  getType: (word) ->
    @prepareCommand [':type-of', word]

  caseSplit: (line, word) ->
    @prepareCommand [':case-split', line, word]

  makeWith: (line, word) ->
    @prepareCommand [':make-with', line, word]

  makeLemma: (line, word) ->
    @prepareCommand [':make-lemma', line, word]

  makeCase: (line, word) ->
    @prepareCommand [':make-case', line, word]

  addClause: (line, word) ->
    @prepareCommand [':add-clause', line, word]

  holes: (width) ->
    @prepareCommand [':metavariables', width]

  proofSearch: (line, word) ->
    @prepareCommand [':proof-search', line, word, []]

  printDefinition: (name) ->
    @prepareCommand [':print-definition', name]

module.exports = IdrisModel
