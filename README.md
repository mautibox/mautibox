# Mautibox

Public sandbox for testing [Mautic](https://github.com/mautic/mautic)

## Elastic Beanstalk Environment Variables

    APP_URL             - URL for Mautibox.
    FREQUENCY           - Frequency of build updates (default 5min).         
    RDS_HOSTNAME        - Set by EB.
    RDS_PORT            - Set by EB.
    RDS_DB_NAME         - Set by EB.
    RDS_USERNAME        - Set by EB.
    RDS_PASSWORD        - Set by EB.
    NR_APPNAME          - Optional: Application name for NR monitors.
    NR_APM_INSTALL_KEY  - Optional: Install NewRelic Application monitor.
    NR_INF_INSTALL_KEY  - Optional: Install NewRelic Infrastructure monitor.

## Caveats:

* Temporary: Test environments will be disbanded when not in use, and will be re-built if the PR changes.
* Public: Test environments are public, shared and by that nature, insecure. Do not store private information here.
* Email: Emails can not be sent from the environment, but you can view them as if they were.

## Paths:

    /code/pulls                Pull requests
    /code/pulls/xxxx           Pull request
    /code/pulls/xxxx/.patches/ Patches applied to the build.
    /code/stage                Working copy of the core repo with permissions applied for faster local cloning.
    /www/data/xxxx/statis.json Current status of the PR in question.
    /www/data/xxxx/*.log       Aggregated logs for the PR.
    /www/index.php             Home page where you select PRs.
    /www/
    /www/xxxx                  Symlink to /code/prs/xxxx when ready.
                               Internal redirect to /www/status when not present.

## Routes:

    /                          Home page, PR selection, links.
    /xxxx                      PR number, either status screen or symlink to /code/prs/xxxx
    /xxxx/data                 Status/logs stream.
    /xxxx/mail                 Mailhog interface.
