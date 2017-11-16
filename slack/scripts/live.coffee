# Description:
#   This module is for the app health check.

module.exports = (robot) ->
  robot.router.get '/', (req, res) ->
    res.send 'ok'
