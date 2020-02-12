# Mautibox

A sandbox for testing the open marketing automation software [Mautic](https://github.com/mautic/mautic).

## Elastic Beanstalk Environment Variables

    APP_URL             - URL for Mautibox
    GH_TOKEN            - Github user token (for public repo read access)
    FREQUENCY           - Frequency of build updates (default 5min)
    STAGING_BRANCH      - Branch to base all PR merges on.
    RDS_HOSTNAME        - Set by EB
    RDS_PORT            - Set by EB
    RDS_DB_NAME         - Set by EB
    RDS_USERNAME        - Set by EB
    RDS_PASSWORD        - Set by EB
    NR_APPNAME          - Optional: Application name for NR monitors
    NR_APM_INSTALL_KEY  - Optional: Install NewRelic Application monitor
    NR_INF_INSTALL_KEY  - Optional: Install NewRelic Infrastructure monitor

## Caveats:

* Temporary: Test environments will be discarded after a time.
* Public: Test environments are public and insecure. Do not insert private information. Be courteous to other users.
* Email: Outgoing emails are captured for review, and are not sent.

## Paths:

    /code/pulls/####           Pull request
    /code/pulls/####/.patches/ Patches applied to the build
    /code/stage                Working copy of the core repo with permissions applied for faster local cloning
    /web/data/####/status.json Current status of the PR in question
    /web/data/####/*.log       Various logs for the PR
    /web/index.html            Home page where you select PRs
    /web/pulls.php             Grabs cached open pull request list as JSON
    /web/pull.php              Checks the status of a pull request/build and spawns builds as needed
    /web/####                  Symlink to /code/prs/#### when ready
                               Internal redirect to /www/status when not present
## Routes

    /                          Home page
    /####                      Checks/builds/renders the completed build
    /mail                      Mailhog interface for all PRs on deck

## Ideas

* [ ] Countdown timer
* [ ] Log streaming
* [ ] Vhost & user generation to isolate instances better
* [ ] Support "staging" environment at /staging
* [ ] Support "master" environment at /master
* [ ] Provide a one-click "deploy build" option for some of the typical hosting providers
* [ ] Support third-party plugin testing by going to /org/repo
* [ ] Support private builds with multiple plugins/patches

Mautibox is a free resource for the [Mautic Community](https://mautic.org) and is not affiliated with [Mautic, inc](https://mautic.com). Mautic is a trademark of [David Hurley](http://dbhurley.com).