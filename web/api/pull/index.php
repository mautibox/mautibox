<?php

error_reporting(E_ALL);


/**
 * Slightly modified version of http://www.geekality.net/2011/05/28/php-tail-tackling-large-files/
 *
 * @param      $filepath
 * @param int  $lines
 * @param bool $adaptive
 *
 * @return bool|string
 */
function tailCustom($filepath, $lines = 1, $adaptive = true)
{
    // Open file
    $f = @fopen($filepath, "rb");
    if ($f === false) {
        return false;
    }

    // Sets buffer size, according to the number of lines to retrieve.
    // This gives a performance boost when reading a few lines from the file.
    if (!$adaptive) {
        $buffer = 4096;
    } else {
        $buffer = ($lines < 2 ? 64 : ($lines < 10 ? 512 : 4096));
    }

    // Jump to last character
    fseek($f, -1, SEEK_END);

    // Read it and adjust line number if necessary
    // (Otherwise the result would be wrong if file doesn't end with a blank line)
    if (fread($f, 1) != "\n") {
        $lines -= 1;
    }

    // Start reading
    $output = '';
    $chunk  = '';

    // While we would like more
    while (ftell($f) > 0 && $lines >= 0) {

        // Figure out how far back we should jump
        $seek = min(ftell($f), $buffer);

        // Do the jump (backwards, relative to where we are)
        fseek($f, -$seek, SEEK_CUR);

        // Read a chunk and prepend it to our output
        $output = ($chunk = fread($f, $seek)).$output;

        // Jump back to where we started reading
        fseek($f, -mb_strlen($chunk, '8bit'), SEEK_CUR);

        // Decrease our line counter
        $lines -= substr_count($chunk, "\n");

    }

    // While we have too many lines
    // (Because of buffer size we might have read too many)
    while ($lines++ < 0) {

        // Find first newline and remove all text before that
        $output = substr($output, strpos($output, "\n") + 1);

    }
    // Close file and return
    fclose($f);

    return trim($output);

}

require_once __DIR__.'/../../../vendor/autoload.php';

define('BASE', realpath(__DIR__.'/../../../'));
$error      = null;
$message    = null;
$pullNumber = !empty($_GET['pullNo']) ? (is_numeric($_GET['pullNo']) ? (int) $_GET['pullNo'] : trim($_GET['pullNo'])) : null;
if (!$pullNumber) {
    $urlParts   = explode('/', ltrim($_SERVER['REQUEST_URI'], '/'));
    $pullNumber = !empty($urlParts[0]) && is_numeric(trim($urlParts[0])) ? (int) $urlParts[0] : null;
}
if (!$pullNumber) {
    $pullNumber = !empty($_GET['pullNo']) && getenv('STAGING_BRANCH') == trim($_GET['pullNo']) ? getenv('STAGING_BRANCH') : null;
}
if (!$pullNumber) {
    header("HTTP/1.0 404 Not Found");
    die('A pull request number is required.');
}
$key   = 'mautic_pull_'.$pullNumber;
$ttl   = 60;
$pool  = new Cache\Adapter\Apcu\ApcuCachePool();
$build = [
    'sha'     => '',
    'date'    => '',
    'pull'    => $pullNumber,
    'status'  => 'queued',
    'error'   => '',
    'staging' => getenv('STAGING_BRANCH'),
];

$cached = $pool->get($key);
$pull   = [];
if ($pullNumber == getenv('STAGING_BRANCH')) {
    $queueFile = BASE.'/queue/'.getenv('STAGING_BRANCH').'.pull';
    if (!is_file($queueFile)) {
        file_put_contents($queueFile, time());
    }
} else {
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
        if ($pull['merged'] === true) {
            throwError('This pull request is already merged :O');
        }
        if ($pull['state'] !== 'open') {
            throwError('Pull request must be open.');
        }
        if ($pull['mergeable'] === false) {
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
}

// Get the build logs if pertinent.
$logs    = '';
$logFile = BASE.'/code/data/'.$pullNumber.'/build.log';
if (is_file($logFile)) {
    $logs = tailCustom($logFile, 100);
} else {
    $logs = 'No log file found at '.$logFile;
}

// Get the build status (if available) and merge it with the PR output.
$buildFile = BASE.'/code/data/'.$pullNumber.'/build.json';
if (is_file($buildFile)) {
    if ($buildStatus = file_get_contents($buildFile)) {
        $buildArray = json_decode($buildStatus, true);
        if (!empty($buildArray)) {
            $build = $buildArray;
            if (!empty($build['error'])) {
                throwError($build['error']);
            }
        }
    }
}

// Store the pull request in a file for permanent use by Mautic.
if (!empty($pull) && is_dir(BASE.'/code/data/'.$pullNumber)) {
    $pullFile = BASE.'/code/data/'.$pullNumber.'/pull.json';
    if (!is_file($pullFile) || time() - filemtime($pullFile) > (5 * 60 * 60)) {
        @file_put_contents($pullFile, json_encode($pull));
    }
}

// An arbitrary "size" of this pull request for visualization.
// $size = $pull['comments'] + $pull['review_comments'] + $pull['commits'] + $pull['additions'] + $pull['deletions'] + $pull['changed_files'];

outputResult(
    [
        'error' => $error,
        'pull'  => $pull,
        'build' => $build,
        'logs'  => $logs,
    ]
);

function throwError($error)
{
    global $pull, $build, $logs;
    outputResult(
        [
            'error' => $error,
            'pull'  => !empty($pull) ? $pull : [],
            'build' => !empty($build) ? $build : [],
            'logs'  => !empty($logs) ? $logs : '',
        ]
    );
}

function outputResult($array)
{
    // Customize the message.
    if ($array['error']) {
        $array['build']['status'] = 'error';
    }
    if (!empty($array['build']['status'])) {
        $array['message'] = '<h1>'.strtoupper($array['build']['status']).'</h1>';
    }
    if (!empty($array['pull']['title'])) {
        $array['message'] .= '<a href="https://github.com/mautic/mautic/pull/'.$array['pull']['number'].'" target="_blank">'.
            '<h4>'.htmlentities(trim(strip_tags($array['pull']['title']))).'</h4></a>';
    }
    if (!empty($array['error'])) {
        $array['message'] .= '<h4>'.$array['error'].'</h4>';
    }

    header("HTTP/1.1 200 OK");
    header('Content-Type: application/json');
    echo json_encode($array);
    exit;
}