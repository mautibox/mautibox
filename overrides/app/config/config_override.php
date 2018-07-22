<?php
/**
 * Mautibox config overrides to behave like dev/test at all times.
 */
$container->setParameter('kernel.debug', true);
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
        'disable_delivery' => false,
    ]
);
// Log notices and above, with full traces and output to *.log files for a week.
$container->loadFromExtension('monolog', [
    'channels' => [
        'mautic',
    ],
    'handlers' => [
        'main' => [
            'formatter'    => 'mautic.monolog.fulltrace.formatter',
            'type'         => 'fingers_crossed',
            'buffer_size'  => '200',
            'action_level' => 'notice',
            'handler'      => 'nested',
            'channels'     => [
                '!mautic',
            ],
        ],
        'nested' => [
            'type'      => 'rotating_file',
            'path'      => '%kernel.logs_dir%/%kernel.environment%.log',
            'level'     => 'notice',
            'max_files' => 7,
        ],
        'mautic' => [
            'formatter' => 'mautic.monolog.fulltrace.formatter',
            'type'      => 'rotating_file',
            'path'      => '%kernel.logs_dir%/mautic_%kernel.environment%.log',
            'level'     => 'notice',
            'channels'  => [
                'mautic',
            ],
            'max_files' => 7,
        ],
    ],
]);