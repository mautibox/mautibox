<?php

require_once __DIR__.'/../vendor/autoload.php';

$urlParts   = explode('/', ltrim($_SERVER['REQUEST_URI'], '/'));
$pullNumber = !empty($urlParts[0]) && is_numeric(trim($urlParts[0])) ? (int) $urlParts[0] : null;
if (!$pullNumber) {
    header("HTTP/1.0 404 Not Found");
    die('Sorry, the path you put in is wonky... Try a Pull Request number.');
}
$key  = 'mautic_pull';
$ttl  = 60;
$pool = new Cache\Adapter\Apcu\ApcuCachePool();

$client = new Github\Client();
$pager  = new Github\ResultPager($client);
$client->addCache($pool, ['default_ttl' => $ttl]);
$client->authenticate(getenv('GH_TOKEN'), null, Github\Client::AUTH_HTTP_TOKEN);

// Get all open PRs sorted by popularity.
$repoApi    = $client->api('pullRequest');
try {
    $pull       = $pager->fetch($repoApi, 'show', ['mautic', 'mautic', $pullNumber]);
} catch (\Exception $exception) {
    die('Pull request is not valid. Github says "' .$exception->getMessage() . '"');
}
if ($pull['merged'] == true) {
    die('This pull request is already merged!');
}
if ($pull['state'] !== 'open') {
    die('Pull request must be open to test.');
}
if ($pull['mergeable'] == false) {
    die('This pull request cannot be merged, and as such a patch will not work. Conflicts must be resolved first!');
}
header('Content-Type: application/json');
echo json_encode($pull);
