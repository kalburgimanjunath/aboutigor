# SERVER ROUTES
# -----------------------------------------------------------------------------

# Require modules.
cache = require "./cache.coffee"
lodash = require "lodash"
moment = require "moment"

# Bind all routes.
exports.set = (app) ->

    # The index / homepage.
    indexPage = (req, res) ->
        recentGitHub = cache.get "github-recent-activity"

        recentRunning = cache.get "endomondo-recent-running"
        recentCycling = cache.get "endomondo-recent-cycling"

        recentTopArtists = cache.get "lastfm-recent-topartists"
        recentTopArtists = lodash.pluck recentTopArtists, "name"
        recentTopArtists = recentTopArtists.join ", "

        options =
            recentGitHub: recentGitHub
            recentTopArtists: recentTopArtists
            recentRunning: recentRunning
            recentCycling: recentCycling

        app.renderView req, res, "index", options


    # BIND ROUTES
    # -------------------------------------------------------------------------

    app.server.get "/", indexPage