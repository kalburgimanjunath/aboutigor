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
        from = moment().subtract("M", pastMonths).format "yyyyMMdd"
        to = moment().format "yyyyMMdd"
        return "#{baseUrl}#{sportId}&from=#{from}&to=#{to}"

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
            if r.duration.length is 7
                result.duration += moment("1970-01-01 0" + r.duration).valueOf()
            else
                result.duration += moment("1970-01-01 " + r.duration).valueOf()


        # Parse duration.
        result.duration = moment.duration result.duration
        hours = result.duration.hours()
        minutes = result.duration.minutes()

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
            # Add static / non-tracked cycling. Average of 9 times a week, 4.3km each, in 12min.
            weekDay = moment().day()
            workouts = recentMonths * 4 * 9
            workouts = workouts - 1 if weekDay is 0

            distance = workouts * 4.3

            duration = workouts * 12 * 60 * 1000
            duration = moment.duration duration
            hours = duration.hours()
            minutes = duration.minutes()
            duration = hours + "h " + minutes + "m"

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