<?php

require_once __DIR__.'/../../../vendor/autoload.php';

$key        = 'mautic_pulls';
$ttl        = 300;
$pool       = new Cache\Adapter\Apcu\ApcuCachePool();
$simplified = $pool->get($key);
if (!$simplified) {
    $simplified = [];
    $client     = new Github\Client();
    $pager      = new Github\ResultPager($client);
    $client->addCache($pool, ['default_ttl' => $ttl]);
    $client->authenticate(getenv('GH_TOKEN'), null, Github\Client::AUTH_HTTP_TOKEN);

    // Get all open PRs sorted by popularity.
    $params  = [
        'state'     => 'open',
        'sort'      => 'popularity',
        'direction' => 'desc',
        'per_page'  => 100,
    ];
    $repoApi = $client->api('pullRequest');
    $pulls   = $pager->fetch($repoApi, 'all', ['mautic', 'mautic', $params]);
    while (!empty($pulls)) {
        foreach ($pulls as $pull) {
            // Mautic 2 branches no longer supported.
            if (0 === strpos($pull['base']['ref'], '2.')) {
                continue;
            }
            $simplified[(string) $pull['number']] = [
                'title' => $pull['title'],
                'user'  => !empty($pull['user']['login']) ? $pull['user']['login'] : '',
                'base'  => $pull['base']['ref'] ?? getenv('STAGING_BRANCH'),
            ];
        }
        $pulls = [];
        if ($pager->hasNext()) {
            $pulls = $pager->fetchNext();
        }
    }
    $pool->set($key, $simplified, $ttl);
}

outputResult(
    [
        'error'      => null,
        'pulls'      => $simplified,
    ]
);

function outputResult($array)
{
    header('Content-Type: application/json');
    echo json_encode($array);
    exit;
}