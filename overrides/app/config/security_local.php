<?php
/**
 * Mautibox security overrides.
 */
$container->setParameter('mautic.security.disableUpdates', true);
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
