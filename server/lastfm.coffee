# LAST.FM MANAGER
# -----------------------------------------------------------------------------
# Handles communications with Last.fm.

class LastFm

    cache = require "./cache.coffee"
    expresser = require "expresser"
    lodash = require "lodash"

    # Require last.fm node.
    LastFmNode = require("lastfm").LastFmNode
    lastfm = null

    # Last.fm settings.
    refreshInterval = 7200 * 1000
    recentPeriod = "3month"
    apiKey = "1ae8a1da63e4addf540a66b0eb9ac0c8"
    apiSecret = "03e6752c7593c7f9157dc640e6f5c397"
    apiUser = "igoramadas"


    # INIT
    # -------------------------------------------------------------------------

    # Init the Last.fm module
    init: =>
        config = {api_key: apiKey, secret: apiSecret, useragent: "aboutigor.com"}
        lastfm = new LastFmNode config

        @recentTopArtists()
        setInterval @recentTopArtists, refreshInterval


    # LAST.FM DATA
    # -------------------------------------------------------------------------

    # Get top artists for the specified period.
    recentTopArtists: =>
        callback = (data) ->
            artists = data?.topartists.artist
            cache.set "lastfm-recent-topartists", artists
            expresser.logger.info "LastFm.recentTopArtists", lodash.pluck(artists, "name").join()

        lastfm.request "user.getTopArtists", {period: recentPeriod, limit: 10, user: apiUser, handlers: {success: callback}}


# Singleton implementation
# -----------------------------------------------------------------------------
LastFm.getInstance = ->
    @instance = new LastFm() if not @instance?
    return @instance

module.exports = exports = LastFm.getInstance()