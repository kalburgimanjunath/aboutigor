# SERVER ROUTES
# -----------------------------------------------------------------------------

# Require modules.
cache = require "./cache.coffee"
expresser = require "expresser"
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

        device = req.headers["user-agent"]

        if device.indexOf("Windows Phone") > 0 or device.indexOf("iPhone") > 0 or device.indexOf("Android") > 0
            mobile = true
        else
            mobile = false

        options =
            mobile: mobile
            recentGitHub: recentGitHub
            recentTopArtists: recentTopArtists
            recentRunning: recentRunning
            recentCycling: recentCycling

        app.renderView req, res, "index", options

    # The setup page (to get OAuth tokens and stuff).
    setupPage = (req, res) ->
        expresser.logger.info "Entered setup page!"


    # BIND ROUTES
    # -------------------------------------------------------------------------

    app.server.get "/", indexPage,
    app.server.get "/#{expresser.settings.general.setupRoute}", setupPage