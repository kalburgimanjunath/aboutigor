# CACHE
# --------------------------------------------------------------------------
# Data cache for all other modules.

class Cache

    moment = require "moment"

    # Global data store.
    data = {}

    # Default expires is 1 day.
    defaultExpires = -> return moment().add "d", 1


    # CACHE METHODS
    # --------------------------------------------------------------------------

    # Helper to get data from the cache.
    get: (key) =>
        result = data[key]

        if result? and result.expires > moment()
            return result.value

        return null


    # Helper to save data to the cache. Optional expires
    set: (key, value, expires) =>
        return if not value?

        expires = defaultExpires() if not expires?
        obj = {value: value, expires: expires}
        data[key] = obj


# Singleton implementation
# --------------------------------------------------------------------------
Cache.getInstance = ->
    @instance = new Cache() if not @instance?
    return @instance

module.exports = exports = Cache.getInstance()