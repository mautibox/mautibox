<?php

error_reporting(E_ALL);

require_once __DIR__.'/../vendor/autoload.php';

define('BASE', realpath(__DIR__.'/../'));
$error      = null;
$message    = null;
$pullNumber = !empty($_GET['pullNo']) ? (int) $_GET['pullNo'] : null;
if (!$pullNumber) {
    $urlParts   = explode('/', ltrim($_SERVER['REQUEST_URI'], '/'));
    $pullNumber = !empty($urlParts[0]) && is_numeric(trim($urlParts[0])) ? (int) $urlParts[0] : null;
}
if (!$pullNumber) {
    header("HTTP/1.0 404 Not Found");
    die('A pull request number is required.');
}
$key  = 'mautic_pull_'.$pullNumber;
$ttl  = 60;
$pool = new Cache\Adapter\Apcu\ApcuCachePool();

$cached = $pool->get($key);
if (!$cached) {
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
        throwError('This pull request is already merged :O');
    }
    if ($pull['state'] !== 'open') {
        throwError('Pull request must be open.');
    }
    if ($pull['mergeable'] == false) {
        throwError(
            'This pull request cannot be tested. Standard checks must pass and conflicts must be resolved first.'
        );
    }

    # Add this pull to the queue to be checked/updated/installed
    if ($cached !== $pull) {
        $queueFile = BASE.'/queue/'.$pullNumber.'.pull';
        if (!is_file($queueFile)) {
            file_put_contents($queueFile, time());
        }
    }
    $pool->set($key, $cached, $ttl);
}

// Get the build status (if available) and merge it with the PR output.
$build     = [
    'sha'    => '',
    'date'   => '',
    'pull'   => $pullNumber,
    'status' => 'building',
    'error'  => '',
];
$buildFile = BASE.'/code/data/'.$pullNumber.'/status.json';
if (is_file($buildFile)) {
    if ($buildStatus = file_get_contents($buildFile)) {
        $build = json_decode($buildStatus, true);
        if (!empty($build['error'])) {
            throwError($build['error']);
        }
    }
}

if (!empty($pull)) {
    if (!is_dir(BASE.'/code/data/'.$pullNumber)) {
        mkdir(BASE.'/code/data/'.$pullNumber);
    }
    $pullFile = BASE.'/code/data/'.$pullNumber.'/pull.json';
    if (!is_file($pullFile) || time() - filemtime($pullFile) > (5 * 60 * 60)) {
        file_put_contents($pullFile, json_encode($pull));
    }
}

if ($build['status'] == 'error') {
    throwError($build['error']);
}

// An arbitrary "size" of this pull request for visualization.
// $size = $pull['comments'] + $pull['review_comments'] + $pull['commits'] + $pull['additions'] + $pull['deletions'] + $pull['changed_files'];

outputResult(
    [
        'error'   => $error,
        'message' => $message,
        'pull'    => $pull,
        'build'   => $build,
    ]
);

function throwError($error)
{
    outputResult(
        [
            'error'   => $error,
            'message' => !empty($message) ? $message : $error,
            'pull'    => !empty($pull) ? $pull : [],
            'build'   => !empty($build) ? $build : [],
        ]
    );
}

function outputResult($array)
{
    // Customize the message.
    if (!empty($array['build']['status'])) {
        if ($array['build']['status'] == 'building' && !empty($array['pull']['number'])) {
            $array['message'] = '<h1>BUILDING '.
                '<a href="https://github.com/mautic/mautic/pull/'.$array['pull']['number'].'" target="_blank">'.
                $array['pull']['number'].
                '</a></h1>';
        } elseif ($array['build']['status'] == 'ready') {
            $array['message'] = '<h1>READY</h1>';
        } elseif ($array['build']['status'] == 'error') {
            $array['message'] = '<h1>BUILD ERROR</h1>';
            if (!empty($array['build']['error'])) {
                $array['message'] .= '<h4>'.$array['build']['error'].'</h4>';
            }
        }
    } else {
        if (!empty($array['error'])) {
            $array['message'] = '<h1>ERROR</h1><h4>'.$array['message'].'</h4>';
        }
    }
    if (!empty($array['pull']['title'])) {
        $array['message'] .= '<h4>'.htmlentities(trim(strip_tags($array['pull']['title']))).'</h4>';
    }

    header("HTTP/1.1 200 OK");
    header('Content-Type: application/json');
    echo json_encode($array);
    exit;
}