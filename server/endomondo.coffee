# ENDOMONDO MANAGER
# -----------------------------------------------------------------------------
# Handles communications with Endomondo.

class Endomondo

    async = require "async"
    cache = require "./cache.coffee"
    expresser = require "expresser"
    http = require "http"
    moment = require "moment"
    url = require "url"

    # Endomondo settings.
    refreshInterval = 14400 * 1000
    recentMonths = 3
    baseUrl = "http://www.endomondo.com/embed/user/summary?id=6630895&measure=0&zone=Gp0100_AMS&width=680&height=217&sport="


    # INIT
    # -------------------------------------------------------------------------

    # Init the Endomondo module.
    init: =>
        @recentRunningStats()
        @recentCyclingStats()
        setInterval @recentRunningStats, refreshInterval
        setInterval @recentCyclingStats, refreshInterval


    # ENDOMONDO DATA
    # -------------------------------------------------------------------------

    # Helper to get the Endomondo URL.
    getUrl = (sportId, pastMonths) ->
        from = moment().subtract("M", pastMonths).format "YYYYMMDD"
        to = moment().format "YYYYMMDD"
        resultUrl = "#{baseUrl}#{sportId}&from=#{from}&to=#{to}"
        return resultUrl

    # Helper to download data from Endomondo.
    download = (urlInfo, callback) =>
        options = {host: urlInfo.hostname, port: urlInfo.port, path: urlInfo.path}
        req = http.get options, (response) =>

            # If status is not 200 or 304, it means something went wrong so do not proceed
            # with the download. Otherwise proceed and listen to the `data` and `end` events.
            if response.statusCode isnt 200 and response.statusCode isnt 304
                expresser.logger.warn "Endomondo.download", cacheKey, "Status code #{response.statusCode}"
            else
                html = ""

                response.addListener "data", (data) => html += data
                response.addListener "end", () =>
                    text = html
                    text = text.replace /<(?:.|\n)*?>/g, ""
                    text = text.replace /(\r\n|\n|\r|\t)/g, " "
                    text = text.replace " km", "km"
                    text = text.replace /\  /g, " " while text.indexOf("  ") >= 0
                    text = text.toLowerCase()

                    # Get workout count.
                    workouts = text.indexOf "workouts:"
                    workouts = text.substring workouts
                    workouts = workouts.substring(workouts.indexOf(":") + 2)
                    workouts = workouts.substring 0, workouts.indexOf " "

                    # Get distance.
                    distance = text.indexOf "distance:"
                    distance = text.substring distance
                    distance = distance.substring(distance.indexOf(":") + 2)
                    distance = distance.substring 0, distance.indexOf " "
                    distance = distance.replace "km", ""

                    # Get duration.
                    duration = text.indexOf "duration:"
                    duration = text.substring duration
                    duration = duration.substring(duration.indexOf(":") + 2)
                    duration = duration.substring 0, duration.indexOf " "

                    # Set stats.
                    stats = {workouts: workouts, distance: distance, duration: duration}

                    # Pass results to callback.
                    callback null, stats
                    expresser.logger.info "Endomondo.download", urlInfo.path, stats

        req.on "error", (err) ->
            # Pass error to callback.
            callback err, null
            expresser.logger.error "Endomondo.download", urlInfo.path, err

    # Helper to merge similar sport results.
    mergeResults = (data, key) ->
        result = {workouts: 0, distance: 0, duration: 0}
        for r in data
            result.workouts += parseInt r.workouts
            result.distance += parseInt r.distance
            arr = r.duration.split ":"

            if arr.length > 2
                duration = {hours: parseInt(arr[0]), minutes: parseInt(arr[1]), seconds: parseInt(arr[2])}
            else
                duration = {minutes: parseInt(arr[0]), seconds: parseInt(arr[1])}

            result.duration += moment.duration(duration).asMilliseconds()

        # Parse duration.
        result.duration = moment.duration result.duration
        hours = Math.floor result.duration.asHours()
        minutes = Math.floor result.duration.minutes()

        # Convert duration to readable time.
        result.duration = hours + "h " + minutes + "m"

        # Delayed cache set.
        delayedCache = ->
            cache.set "endomondo-#{key}", result
            expresser.logger.info "Endomondo.mergeResults", key, result
        setTimeout delayedCache, 100

    # Get running stats from the last 3 months.
    recentRunningStats: =>
        runningSport = (c) -> download url.parse(getUrl 0, recentMonths), c
        runningFitness = (c) -> download url.parse(getUrl 14, recentMonths), c
        merger = (err, data) ->
            mergeResults data, "recent-running"

        async.series [runningSport, runningFitness], merger
        expresser.logger.info "Endomondo.recentRunningStats"

    # Get cycling stats from the last 3 months.
    recentCyclingStats: =>
        cyclingSport = (c) -> download url.parse(getUrl 2, recentMonths), c
        cyclingTransport = (c) -> download url.parse(getUrl 1, recentMonths), c
        merger = (err, data) ->

            # Add non-tracked cycling to/from work. Average of 10 times a week, 4.3km each, in 14min.
            weekDay = moment().day()
            workouts = recentMonths * 4 * 10
            distance = workouts * 4.3
            distance = Math.round distance
            duration = workouts * 14 * 60

            # GOing to/from gym.
            if weekDay is 1 or weekDay is 3 or weekDay is 5
                workouts += 1
                distance += 6
                duration += 1200

            # Calculate duration.
            duration = moment.duration duration, "s"
            hours = duration.hours()
            minutes = duration.minutes()
            duration = hours + ":" + minutes + ":00"

            data.push {workouts: workouts, distance: distance, duration: duration}
            mergeResults data, "recent-cycling"

        async.series [cyclingSport, cyclingTransport], merger
        expresser.logger.info "Endomondo.recentCyclingStats"


# Singleton implementation
# -----------------------------------------------------------------------------
Endomondo.getInstance = ->
    @instance = new Endomondo() if not @instance?
    return @instance

module.exports = exports = Endomondo.getInstance()