<?php
/**
 * Mautibox config overrides to behave like dev/test at all times.
 */
if (!defined('PULL')) {
    define('PULL', basename(realpath(MAUTIC_ROOT_DIR)));
}
$container->setParameter('kernel.logs_dir', realpath(MAUTIC_ROOT_DIR.'/../../data/'.PULL));
// $container->setParameter('kernel.debug', true);
// $container->loadFromExtension(
//     'framework',
//     [
//         'profiler' => [
//             'collect' => true,
//         ],
//     ]
// );
// $container->loadFromExtension(
//     'web_profiler',
//     [
//         'toolbar'             => true,
//         'intercept_redirects' => false,
//     ]
// );
// $container->loadFromExtension(
//     'swiftmailer',
//     [
//         'disable_delivery' => false,
//     ]
// );
//
// $container->loadFromExtension(
//     'web_profiler',
//     [
//         'toolbar'             => true,
//         'intercept_redirects' => false,
//         'only_exceptions'     => false,
//     ]
// );
// throw new \Exception('asf');

//Twig Configuration
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
        ],
    ]
);


// Log notices and above, with full traces and output to *.log files for a week.
// $container->loadFromExtension(
//     'monolog',
//     [
//         'channels' => [
//             'mautic',
//         ],
//         'handlers' => [
//             'main'   => [
//                 'formatter'    => 'mautic.monolog.fulltrace.formatter',
//                 'type'         => 'fingers_crossed',
//                 'buffer_size'  => '200',
//                 'action_level' => 'notice',
//                 'handler'      => 'nested',
//                 'channels'     => [
//                     '!mautic',
//                 ],
//             ],
//             'nested' => [
//                 'type'      => 'rotating_file',
//                 'path'      => '%mautic.log_path%/%kernel.environment%.log',
//                 'level'     => 'notice',
//                 'max_files' => 7,
//             ],
//             'mautic' => [
//                 'formatter' => 'mautic.monolog.fulltrace.formatter',
//                 'type'      => 'rotating_file',
//                 'path'      => '%mautic.log_path%/mautic_%kernel.environment%.log',
//                 'level'     => 'notice',
//                 'channels'  => [
//                     'mautic',
//                 ],
//                 'max_files' => 7,
//             ],
//         ],
//     ]
// );