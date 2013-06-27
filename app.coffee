propagit = require 'propagit'
fleet = require './lib/fleet'
surveyor = require './lib/surveyor'
butler = require './lib/butler'
fs = require 'fs'

OPTS =
  hub: '127.0.0.1:7000'
  secret: 'lolwat'

p = propagit(OPTS)
p.on 'error', (err) ->
  healthy = false
  console.error err
healthy = false
getManifest = (cb) ->
  fs.readFile './manifest.json', (err, data) ->
    return cb err if err?
    cb null, JSON.parse data.toString()

startChecking = (hub) ->
  setInterval ->
    getManifest (err, manifest) ->
      model =
        hub: hub
        manifest: manifest
      fleet.listDrones model, (err, model) ->
        return console.error "No drones available" if Object.keys(model.swarm).length < 1
        surveyor.bootstrapStatus model, (err, model) ->
          fleet.checkFleet model, (err, model) ->
            surveyor.buildPending model, (err, model) ->
              fleet.repairFleet model, (err, model, procList) ->
                console.error err if err?
                console.log "Spawned processes for #{reponame}", procs for reponame, procs of procList
                healthy = false if err?
                model = butler.associateHosts model
                model = surveyor.createRoutingTable model
                  butler.propagateRoutingTable model, (err, model) ->
                    console.error err if err?
                    console.log "Wrote routing table on all drones" unless err?
  , 3000

p.hub.on 'up', (hub) ->
  console.log 'connection up'
  healthy = true
  startChecking hub

exit = () ->
  p.hub.close()
