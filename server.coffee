# MAIN SERVER
# -----------------------------------------------------------------------------

# Init expresser and settings.
expresser = require "expresser"
expresser.settings.General.appTitle = "Igor Ramadas"
expresser.settings.Sockets.enabled = false
expresser.settings.Logger.Logentries.token = process.env.LOGENTRIES_TOKEN

# Init the app.
expresser.init()

# Routes.
routes = require "./server/routes.coffee"
routes.set expresser.app

# Get data from Endomondo.
endomondo = require "./server/endomondo.coffee"
endomondo.init()

# Get data from GitHub.
github = require "./server/github.coffee"
github.init()

# Get data from Last.fm.
lastfm = require "./server/lastfm.coffee"
lastfm.init()