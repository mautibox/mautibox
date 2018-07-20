<?php
/**
 * Mautibox parameter overrides.
 */
define('PULL', basename(realpath(MAUTIC_ROOT_DIR)));
$parameters = [
    'db_driver'             => 'pdo_mysql',
    'api_enabled'           => true,
    'api_enable_basic_auth' => true,
    'debug'                 => true,
    'rss_notification_url'  => null,
    'db_table_prefix'       => PULL,
    'db_host'               => getenv('RDS_HOSTNAME'),
    'db_port'               => getenv('RDS_PORT'),
    'db_name'               => getenv('RDS_DB_NAME'),
    'db_user'               => getenv('RDS_USERNAME'),
    'db_password'           => getenv('RDS_PASSWORD'),
    'site_url'              => getenv('APP_URL').'/'.PULL,
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
    // 'mailer_spool_path' => '/tmp/'.PULL.'/spool',
    'secret_key'            => '68c7e75470c02cba06dd543431411e0de94e04fdf2b3a2eac05957060edb66d0',
    'cache_path'            => realpath(MAUTIC_ROOT_DIR.'/app/cache'),
    'log_path'              => realpath(MAUTIC_ROOT_DIR.'/../../data/'.PULL),
    'tmp_path'              => '/tmp/'.PULL,
];
putenv('RDS_HOSTNAME=');
putenv('RDS_PORT=');
putenv('RDS_DB_NAME=');
putenv('RDS_USERNAME=');
putenv('RDS_HOSTNAME=');
putenv('RDS_PASSWORD=');
putenv('APP_URL=');