<?php

error_reporting(E_ALL);

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

define('BASE', realpath(__DIR__.'/../'));
if (!is_dir(BASE.'/code')) {
    mkdir(BASE.'/code');
}
if (!is_dir(BASE.'/code/data')) {
    mkdir(BASE.'/code/data');
}
if (!is_dir(BASE.'/code/data/'.$pullNumber)) {
    mkdir(BASE.'/code/data/'.$pullNumber);
}
$command = 'nohup bash '.BASE.'/scripts/build.sh '.$pullNumber.' >>'.BASE.'/code/data/'.$pullNumber.'/build.log 2>&1 &';
exec($command);
// @todo - Start a build/update process (auto de-duping).

// @todo - Get the build status and merge it with the PR output.

// The pull is valid, and mergable, see if we're already building it, and return status.

// An arbitrary "size" of this pull request for visualization.
// $size = $pull['comments'] + $pull['review_comments'] + $pull['commits'] + $pull['additions'] + $pull['deletions'] + $pull['changed_files'];

outputResult(
    [
        'error' => null,
        'pull'  => $pull,
        'build' => [],
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