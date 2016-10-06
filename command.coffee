colors        = require 'colors'
dashdash      = require 'dashdash'
MeshbluConfig = require 'meshblu-config'
MeshbluHttp   = require 'meshblu-http'

packageJSON = require './package.json'

OPTIONS = [{
  names: ['emitter-uuid', 'e']
  type: 'string'
  env: 'MESHBLU_EMITTER_UUID'
  help: 'Meshblu UUID of the device you wish to spy on.'
}, {
  names: ['help', 'h']
  type: 'bool'
  help: 'Print this help and exit.'
}, {
  names: ['version', 'v']
  type: 'bool'
  help: 'Print the version and exit.'
}]

class Command
  constructor: ->
    process.on 'uncaughtException', @die
    {@emitterUuid} = @parseOptions()
    @meshbluConfig = @parseMeshbluConfig()

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

    unless options.emitter_uuid
      console.error @usage parser.help({includeEnv: true})
      console.error colors.red 'Missing required parameter --emitter-uuid, -e, or env: MESHBLU_EMITTER_UUID'
      process.exit 1

    return {
      emitterUuid: options.emitter_uuid
    }

  run: =>
    console.log JSON.stringify @meshbluConfig

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
