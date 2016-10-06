async         = require 'async'
colors        = require 'colors'
dashdash      = require 'dashdash'
MeshbluConfig = require 'meshblu-config'
MeshbluHttp   = require 'meshblu-http'

packageJSON = require './package.json'
Spy         = require './src/spy'

OPTIONS = [{
  names: ['emitter-uuid', 'e']
  type: 'string'
  env: 'MESHBLU_EMITTER_UUID'
  help: 'Meshblu UUID of the device you wish to spy on.'
}, {
  names: ['url', 'u']
  type: 'string'
  help: 'URL to forward messages to. Requestb.in works well for this'
}, {
  names: ['help', 'h']
  type: 'bool'
  help: 'Print this help and exit.'
}, {
  names: ['version', 'v']
  type: 'bool'
  help: 'Print the version and exit.'
}]

SUBSCIPTION_TYPES = ['message.received']

class Command
  constructor: ->
    process.on 'uncaughtException', @die
    {@emitterUuid, @url} = @parseOptions()
    @meshbluConfig = @parseMeshbluConfig()
    @meshblu = new MeshbluHttp @meshbluConfig

  parseMeshbluConfig: =>
    options = new MeshbluConfig().toJSON()
    unless options.uuid && options.token
      console.error colors.red 'Missing a meshblu.json file in this directory with a uuid and token'
    return options

  parseOptions: =>
    parser = dashdash.createParser({options: OPTIONS})
    options = parser.parse(process.argv)

    if options.help
      console.log @usage parser.help({includeEnv: true})
      process.exit 0

    if options.version
      console.log packageJSON.version
      process.exit 0

    unless options.emitter_uuid && options.url
      console.error @usage parser.help({includeEnv: true})
      unless options.emitter_uuid
        console.error colors.red 'Missing required parameter --emitter-uuid, -e, or env: MESHBLU_EMITTER_UUID'
      unless options.url
        console.error colors.red 'Missing required parameter --url or -u'
      process.exit 1

    return {
      emitterUuid: options.emitter_uuid
      url: options.url
    }

  run: =>
    @meshblu.register @spyTemplate(), (error, @spyDevice) =>
      return @die error if error?

      console.log 'using device: ', @spyDevice.uuid

      async.eachSeries SUBSCIPTION_TYPES, @spyOnType, (error) =>
        return @die error if error?
        process.exit 0

  spyOnType: (type, callback) =>
    spy = new Spy {@spyDevice, @meshbluConfig, @emitterUuid, @url, type}
    spy.spy callback

  spyTemplate: =>
    userUuid = @meshbluConfig.uuid

    {
      name: "Spying on #{@emitterUuid}"
      online: true
      owner: userUuid
      meshblu:
        version: '2.0.0'
        forwarders:
          version: '2.0.0'
        whitelists:
          discover: view: [{uuid: userUuid}]
          configure: update: [{uuid: userUuid}]
    }

  usage: (optionsStr) =>
    return """
      usage: meshblu-forward-to-webhook [OPTIONS]
      options:
        #{optionsStr}
    """

  die: (error) =>
    return process.exit(0) unless error?
    console.error 'ERROR'
    console.error error.stack
    process.exit 1

module.exports = Command
