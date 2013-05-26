# MAIN SERVER
# -----------------------------------------------------------------------------

# Required modules.
expresser = require "expresser"
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