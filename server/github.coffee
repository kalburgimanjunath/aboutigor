# GITHUB MANAGER
# -----------------------------------------------------------------------------
# Handles communications with GitHub.

class GitHub

    cache = require "./cache.coffee"
    expresser = require "expresser"
    githubApi = require "github"

    # GitHub settings.
    refreshInterval = 1800 * 1000
    recentCount = 5
    github = new githubApi {version: "3.0.0"}


    # INIT
    # -------------------------------------------------------------------------

    # Init the GitHub module.
    init: =>
        @recentActivity()
        setInterval @recentActivity, refreshInterval


    # GITHUB DATA
    # -------------------------------------------------------------------------

    # Get recent activity.
    recentActivity: =>
        github.events.getFromUser {user: "igoramadas"}, (err, data) ->
            if err?
                expresser.logger.error "GitHub.recentActivity", err
            else
                arr = []

                for evt in data
                    if arr.length <= recentCount
                        activity = {}
                        activity.type = evt.type
                        activity.repo = evt.repo
                        activity.date = evt.created_at
                        activity.toString = -> return "#{@type} on #{@date}"
                        arr.push activity

                cache.set "github-recent-activity", arr
                expresser.logger.info "GitHub.recentActivity", "Got #{data.length} recent activities."


# Singleton implementation
# -----------------------------------------------------------------------------
GitHub.getInstance = ->
    @instance = new GitHub() if not @instance?
    return @instance

module.exports = exports = GitHub.getInstance()