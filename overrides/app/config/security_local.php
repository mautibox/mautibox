<?php
/**
 * Mautibox security overrides.
 */
$loader->import('security.php');
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
$container->setParameter('mautic.security.restrictedConfigFields.displayMode', \Mautic\ConfigBundle\Form\Helper\RestrictionHelper::MODE_MASK);
