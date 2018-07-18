<?php

/**
 * Configuration similar to dev/test environment.
 */
define('PULL', basename(realpath(MAUTIC_ROOT_DIR)));
$container->setParameter('kernel.debug', true);
$container->setParameter('mautic.api_enabled', true);
$container->setParameter('mautic.api_enable_basic_auth', true);
$container->setParameter('mautic.debug', true);
$container->setParameter('mautic.secret_key', '68c7e75470c02cba06dd543431411e0de94e04fdf2b3a2eac05957060edb66d0');
$container->setParameter('mautic.security.disableUpdates', true);
$container->setParameter('mautic.rss_notification_url', null);
$container->setParameter('mautic.db_table_prefix', PULL);
$container->setParameter('mautic.tmp_path', '/tmp/'.PULL);
$container->setParameter('mautic.db_driver', 'pdo_mysql');
$container->setParameter('mautic.db_host', getenv('RDS_HOSTNAME')); putenv('RDS_HOSTNAME=');
$container->setParameter('mautic.db_port', getenv('RDS_PORT')); putenv('RDS_PORT=');
$container->setParameter('mautic.db_name', getenv('RDS_DB_NAME')); putenv('RDS_DB_NAME=');
$container->setParameter('mautic.db_user', getenv('RDS_USERNAME')); putenv('RDS_USERNAME=');
$container->setParameter('mautic.db_password', getenv('RDS_PASSWORD')); putenv('RDS_PASSWORD=');
$container->setParameter('mautic.site_url', getenv('APP_URL').'/'.PULL);
$container->setParameter(
    'mautic.security.restrictedConfigFields',
    array_merge(
        $container->getParameter('mautic.security.restrictedConfigFields'),
        [
            'tmp_path',
            'log_path',
            'image_path',
            'upload_dir',
            'site_url',
        ]
    )
);
$container->loadFromExtension(
    'framework',
    [
        'profiler' => [
            'collect' => true,
        ],
    ]
);
$container->loadFromExtension(
    'web_profiler',
    [
        'toolbar'             => true,
        'intercept_redirects' => false,
    ]
);
$container->loadFromExtension(
    'swiftmailer',
    [
        'disable_delivery' => true,
    ]
);
// 'mailer_from_name'  => getenv('MAILER_FROM_NAME') ?: $parameters['mailer_from_name'] ?? 'Web Developer',
// 'mailer_from_email' => getenv('MAILER_FROM_EMAIL') ?: $parameters['mailer_from_email'] ?? 'web@developer.com',
// 'mailer_transport'  => 'mail',
// 'mailer_host'       => null,
// 'mailer_port'       => null,
// 'mailer_user'       => 'root',
// 'mailer_password'   => 'root',
// 'mailer_encryption' => null,
// 'mailer_auth_mode'  => null,
// 'mailer_spool_type' => 'file',
// 'mailer_spool_path' => '%kernel.root_dir%/spool',
