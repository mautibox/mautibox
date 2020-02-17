<?php
/**
 * Mautibox parameter overrides.
 */
if (!defined('PULL')) {
    define('PULL', basename(realpath(MAUTIC_ROOT_DIR)));
}
$parameters = [
    'api_enabled'           => true,
    'api_enable_basic_auth' => true,
    'debug'                 => true,
    'rss_notification_url'  => null,
    'db_driver'             => 'pdo_mysql',
    'db_table_prefix'       => PULL.'_',
    'db_host'               => getenv('RDS_HOSTNAME') ?: 'localhost',
    'db_port'               => getenv('RDS_PORT') ?: '3306',
    'db_name'               => 'mautic_'.str_replace('.', '_', PULL),
    'db_user'               => getenv('RDS_USERNAME') ?: 'root',
    'db_password'           => getenv('RDS_PASSWORD') ?: 'root',
    'site_url'              => getenv('APP_URL').'/'.PULL,
    'mailer_from_name'      => getenv('MAILER_FROM_NAME') ?: 'Web Developer',
    'mailer_from_email'     => getenv('MAILER_FROM_EMAIL') ?: 'web@developer.com',
    'mailer_transport'      => 'smtp',
    'mailer_host'           => '127.0.0.1',
    'mailer_port'           => '1025',
    'mailer_user'           => null,
    'mailer_password'       => null,
    'mailer_encryption'     => null,
    'mailer_auth_mode'      => null,
    'mailer_spool_type'     => 'file',
    'mailer_spool_path'     => '/tmp/'.PULL.'/spool',
    'secret_key'            => '68c7e75470c02cba06dd543431411e0de94e04fdf2b3a2eac05957060edb66d0',
    'cache_path'            => realpath(MAUTIC_ROOT_DIR.'/app/cache'),
    'log_path'              => realpath(MAUTIC_ROOT_DIR.'/../../data/'.PULL),
    'tmp_path'              => '/tmp/'.PULL,
];