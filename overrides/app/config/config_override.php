<?php
/**
 * Mautibox config overrides to behave like dev/test at all times.
 */
if (!defined('PULL')) {
    define('PULL', basename(realpath(MAUTIC_ROOT_DIR)));
}
if (!defined('DATA')) {
    define('DATA', realpath(MAUTIC_ROOT_DIR.'/../../data/'.PULL));
}
if (is_file(DATA.'/pull.json')) {
    $pull = json_decode(file_get_contents(DATA.'/pull.json'), true);
    if (is_array($pull)) {
        $pull_labels = '';
        if (isset($pull['labels'])) {
            $label_names = [];
            foreach ($pull['labels'] as $label) {
                $label_names[] = str_replace('%', '', strip_tags($label['name']));
            }
            $pull_labels = implode(', ', $label_names);
        }
        $pull_title  = str_replace('%', '', strip_tags($pull['title']));
        $pull_user   = str_replace('%', '', strip_tags($pull['user']['login']));
        $pull_avatar = str_replace('%', '', strip_tags($pull['user']['avatar_url']));
        $pull_body   = str_replace('%', '', nl2br(htmlentities(strip_tags($pull['body']))));
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
            'pull_title'     => !empty($pull_title) ? $pull_title : 'Branch',
            'pull_body'      => !empty($pull_body) ? $pull_body : '',
            'pull_labels'    => !empty($pull_labels) ? $pull_labels : '',
            'pull_user'      => !empty($pull_user) ? $pull_user : 'https://github.com/mautic/mautic',
            'pull_avatar'    => !empty($pull_avatar) ? $pull_avatar : 'https://avatars2.githubusercontent.com/u/5257677?s=200&v=4',
        ],
    ]
);