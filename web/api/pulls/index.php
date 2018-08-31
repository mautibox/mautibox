<?php

require_once __DIR__.'/../../../vendor/autoload.php';

$key        = 'mautic_pulls';
$ttl        = 300;
$pool       = new Cache\Adapter\Apcu\ApcuCachePool();
$simplified = $pool->get($key);
$simplified = false;
if (!$simplified) {
    $simplified = [];
    $client     = new Github\Client();
    $pager      = new Github\ResultPager($client);
    $client->addCache($pool, ['default_ttl' => $ttl]);
    $client->authenticate(getenv('GH_TOKEN'), null, Github\Client::AUTH_HTTP_TOKEN);

    // Get all open PRs sorted by popularity.
    $params  = [
        'state'     => 'open',
        'base'      => 'staging',
        'sort'      => 'popularity',
        'direction' => 'desc',
        'per_page'  => 100,
    ];
    $repoApi = $client->api('pullRequest');
    $pulls   = $pager->fetch($repoApi, 'all', ['mautic', 'mautic', $params]);
    while (!empty($pulls)) {
        foreach ($pulls as $pull) {
            $simplified[(string) $pull['number']] = [
                'title' => $pull['title'],
                'user'  => !empty($pull['user']['login']) ? $pull['user']['login'] : '',
            ];
        }
        $pulls = [];
        if ($pager->hasNext()) {
            $pulls = $pager->fetchNext();
        }
    }
    $pool->set($key, $simplified, $ttl);
}

// Discern if we are coming from a github issue.
$suggestion = null;
if (!empty($_SERVER['HTTP_REFERER']) && false !== strpos(
        $_SERVER['HTTP_REFERER'],
        'github.com/mautic/mautic/'
    )) {
    $parts = explode('/', str_replace('https://github.com/mautic/mautic/', '', $_SERVER['HTTP_REFERER']));
    if (isset($parts[0]) && is_numeric($parts[0])) {
        $suggestion = (int) $parts[0];
    }
}

outputResult(
    [
        'error'      => null,
        'pulls'      => $simplified,
        'suggestion' => $suggestion,
    ]
);

function outputResult($array)
{
    header('Content-Type: application/json');
    echo json_encode($array);
    exit;
}