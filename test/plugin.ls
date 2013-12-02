should = (require \chai).should!
{provide-dbconn} = require \./testlib

var pgrest, testopts

unload-pgrest = ->
  delete require.cache[require.resolve \../lib]
  delete require.cache[require.resolve \../lib/plugin]

describe 'Plugin Validation', ->
  beforeEach (done) ->
    unload-pgrest!
    pgrest := require \../
    done!
  describe 'ensures a plugin is valid.', -> ``it``
    .. 'should throw exception if a plugin does not implement isactive', (done) ->
      (-> pgrest.use {}).should.throw "plugin does not have isactive function!"
      done!
    .. 'should throw exception if a plugin uses unsupported hookname.', (done) ->
      errmsg = ["plugin uses unsupported hooks:"
                "- posthook-unsupported-hook"]
      fake-plugin = do
        process-opts: ->
        isactive: -> true
        initialize: -> true
        posthook-unsupported-hook: -> false
      (-> pgrest.use fake-plugin)
        .should.throw errmsg.join "\n"
      done!
    .. 'should be slince if a plugin use valid hooknames.', (done) ->
      fake-plugin = do
        isactive: -> true
        posthook-cli-create-plx: -> false
      (-> pgrest.use fake-plugin)
        .should.not.throw!
      done!

describe 'Plugin', ->
  beforeEach (done) ->
    unload-pgrest!
    pgrest := require \../
    getopts = pgrest.get-opts!
    testopts := getopts!
    testopts.conString = provide-dbconn!
    done!
  describe 'should be able to hook cli.', -> ``it``
    .. 'should be able to hook option processing.', (done) ->
      opts = {}
      fake-plugin = do
        isactive: -> true
        process-opts: (opts) -> opts.test = 1
      pgrest.use fake-plugin
      pgrest.init-plugins! opts
      opts.test.should.eq 1
      done!
    .. 'should be able to do initialize.', (done) ->
      fake-plugin = do
        initialized: false
        isactive: -> true
        initialize: -> @initialized = true
      fake-plugin.initialized.should.not.be.ok
      pgrest.use fake-plugin
      pgrest.init-plugins! null
      fake-plugin.initialized.should.be.ok
      done!
    .. 'should be able to hook plx creating.', (done) ->
      fake-plugin = do
        isactive: -> true
        posthook-cli-create-plx: (opts, plx) ->
          opts.should.be.deep.eq testopts
          plx.query.should.be.ok
      pgrest.use fake-plugin
      <- pgrest.cli! testopts, {}, [], null
      done!
