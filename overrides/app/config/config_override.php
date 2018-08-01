<?php
/**
 * Mautibox config overrides to behave like dev/test at all times.
 */
if (!defined('PULL')) {
    define('PULL', basename(realpath(MAUTIC_ROOT_DIR)));
}
$container->setParameter('kernel.logs_dir', realpath(MAUTIC_ROOT_DIR.'/../../data/'.PULL));
if (!defined('DATA')) {
    define('DATA', realpath(MAUTIC_ROOT_DIR.'/../../data/'.PULL));
}
if (function_exists('apcu_fetch')) {
    $pull = apcu_fetch('mautic_pull_'.PULL);
    if ($pull && !empty($pull['title'])) {
        $pull_title = strip_tags($pull['title']);
    }
}
$container->setParameter('kernel.logs_dir', DATA);
$container->loadFromExtension(
    'twig',
    [
        'cache'            => '%mautic.tmp_path%/%kernel.environment%/twig',
        'auto_reload'      => true,
        'debug'            => '%kernel.debug%',
        'strict_variables' => '%kernel.debug%',
        'globals'          => [
            'mautic_version' => MAUTIC_VERSION,
            'pull_request'   => PULL,
            'pull_title'     => !empty($pull_title) ? $pull_title : 'Pull Request',
        ],
    ]
);