<?php

require_once __DIR__.'/../vendor/autoload.php';
$client = new Github\Client();
$pager  = new Github\ResultPager($client);
$client->authenticate(getenv('GH_TOKEN'), null, Github\Client::AUTH_HTTP_TOKEN);

$params = ['state' => 'open', 'pr' => true, 'locked' => false];
$issues = $client->issues()->all('mautic', 'mautic', $params);

$tmp = 1;