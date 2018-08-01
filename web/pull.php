<?php

error_reporting(E_ALL);

require_once __DIR__.'/../vendor/autoload.php';

$pullNumber = !empty($_GET['pullNo']) ? (int) $_GET['pullNo'] : null;
if (!$pullNumber) {
    $urlParts   = explode('/', ltrim($_SERVER['REQUEST_URI'], '/'));
    $pullNumber = !empty($urlParts[0]) && is_numeric(trim($urlParts[0])) ? (int) $urlParts[0] : null;
}
if (!$pullNumber) {
    header("HTTP/1.0 404 Not Found");
    die('A pull request number is required.');
}
$key  = 'mautic_pull';
$ttl  = 60;
$pool = new Cache\Adapter\Apcu\ApcuCachePool();

$client = new Github\Client();
$pager  = new Github\ResultPager($client);
$client->addCache($pool, ['default_ttl' => $ttl]);
$client->authenticate(getenv('GH_TOKEN'), null, Github\Client::AUTH_HTTP_TOKEN);

// Get all open PRs sorted by popularity.
$repoApi = $client->api('pullRequest');
try {
    $pull = $pager->fetch($repoApi, 'show', ['mautic', 'mautic', $pullNumber]);
} catch (\Exception $exception) {
    throwError('Pull request is not valid. Github says "'.$exception->getMessage().'"');
}
if ($pull['merged'] == true) {
    throwError('This pull request is already merged!');
}
if ($pull['state'] !== 'open') {
    throwError('Pull request must be open to test.');
}
if ($pull['mergeable'] == false) {
    throwError('This pull request cannot be merged. Conflicts must be resolved and tests must pass first.');
}

# Add this pull to the queue to be checked/updated/installed
define('BASE', realpath(__DIR__.'/../'));
$queueFile = BASE.'/queue/'.$pullNumber.'.pull';
if (!is_file($queueFile)) {
    file_put_contents($queueFile, time());
}

// FGet the build status (if available) and merge it with the PR output.
$build     = [];
$buildFile = BASE.'/code/data/'.$pullNumber.'/status.json';
if (is_file($buildFile)) {
    if ($buildStatus = file_get_contents($buildFile)) {
        $build = json_decode($buildStatus);
    }
}

// An arbitrary "size" of this pull request for visualization.
// $size = $pull['comments'] + $pull['review_comments'] + $pull['commits'] + $pull['additions'] + $pull['deletions'] + $pull['changed_files'];

outputResult(
    [
        'error' => null,
        'pull'  => $pull,
        'build' => $build,
    ]
);

function throwError($message)
{
    outputResult(
        [
            'error' => $message,
            'pull'  => [],
            'build' => [],
        ]
    );
}

function outputResult($array)
{
    header("HTTP/1.1 200 OK");
    header('Content-Type: application/json');
    echo json_encode($array);
    exit;
}