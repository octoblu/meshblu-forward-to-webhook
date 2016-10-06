async       = require 'async'
_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'

class Spy
  constructor: ({meshbluConfig, @spyDevice, @emitterUuid, @url, @type}) ->
    @meshblu = new MeshbluHttp meshbluConfig

  spy: (callback) =>
    async.series [
      @assertWhitelistVersion
      @updateWhitelist
      @createSubscriptionToSelf
      @createSubscriptionToEmitter
      @createWebhook
    ], callback

  assertWhitelistVersion: (callback) =>
    @meshblu.device @emitterUuid, (error, device) =>
      return callback error if error?
      return callback() if '2.0.0' == _.get(device, 'meshblu.version')
      return callback new Error 'Forwarding only works on meshblu.version 2.0.0 devices'

  updateWhitelist: (callback) =>
    @meshblu.updateDangerously @emitterUuid, {
      $addToSet:
        "meshblu.whitelists.#{@type}": {uuid: @spyDevice.uuid}
    }, callback

  createSubscriptionToSelf: (callback) =>
    @meshblu.createSubscription {
      subscriberUuid: @spyDevice.uuid
      emitterUuid: @spyDevice.uuid
      type: _.replace(@type, 'sent', 'received')
    }, callback

  createSubscriptionToEmitter: (callback) =>
    @meshblu.createSubscription {
      subscriberUuid: @spyDevice.uuid
      emitterUuid: @emitterUuid
      type: @type
    }, callback

  createWebhook: (callback) =>
    @meshblu.updateDangerously @spyDevice.uuid, {
      $addToSet: {
        "meshblu.forwarders.#{@type}": {
          type: 'webhook'
          url: @url
          method: 'POST'
        }
      }
    }, callback

module.exports = Spy
