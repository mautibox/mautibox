<?php
$suggestion = 0;
if (!empty($_SERVER['HTTP_REFERER'])) {
    $prefix = 'https://github.com/mautic/mautic/pull/';
    if (!empty($_SERVER['HTTP_REFERER']) && false !== strpos($_SERVER['HTTP_REFERER'], $prefix)) {
        $parts = explode('/', str_ireplace($prefix, '', $_SERVER['HTTP_REFERER']));
        if (isset($parts[0]) && is_numeric($parts[0])) {
            $suggestion = (int) $parts[0];
        }
    }
    if ($suggestion) {
        setcookie('suggestion', $suggestion, time() + (86400 * 30), '/');
        header('Location: /'.$suggestion);
        exit;
    }
}
if (!$suggestion && !empty($_COOKIE['suggestion'])) {
    $suggestion = $_COOKIE['suggestion'];
}
?><!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta http-equiv="x-ua-compatible" content="ie=edge">
        <meta name="description" content="Mautibox is a free sandbox for testing open source marketing automation Mautic">
        <link rel="apple-touch-icon" sizes="180x180" href="/assets/favicon/apple-touch-icon.png">
        <link rel="icon" type="image/png" sizes="32x32" href="/assets/favicon/favicon-32x32.png">
        <link rel="icon" type="image/png" sizes="16x16" href="/assets/favicon/favicon-16x16.png">
        <link rel="manifest" href="/assets/favicon/site.webmanifest">
        <link rel="mask-icon" href="/assets/favicon/safari-pinned-tab.svg" color="#4e5e9e">
        <link rel="shortcut icon" href="/assets/favicon/favicon.ico">
        <meta name="apple-mobile-web-app-title" content="Mautibox">
        <meta name="application-name" content="Mautibox">
        <meta name="msapplication-TileColor" content="#00aba9">
        <meta name="msapplication-config" content="/assets/favicon/browserconfig.xml">
        <meta name="theme-color" content="#ffffff">
        <link rel="stylesheet" href="/assets/js/libs/materialize/css/materialize.min.css">
        <link rel="stylesheet" href="/assets/js/libs/textillate/assets/animate.css">
        <link rel="stylesheet" href="/assets/js/libs/chosen/chosen.min.css">
        <link rel="stylesheet" href="/assets/css/nas.css">
        <meta name="theme-color" content="#ffffff">
        <title>Mautibox</title>
    </head>
    <body>
        <main class="main" id="main">
            <div class="triangles hero" id="triangles">
                <div id="output"></div>
                <h1>
                    Let's Test Mautic&nbsp;3
                    <form action="#">
                        <div id="spinner">
                            Please wait...
                        </div>
                        <select id="pull-selector" data-placeholder="Select a request..." placeholder="Select a request..." tabindex="1">
                            <option value=""></option>
                        </select>
                        <input type="submit" id="lets-go" class="btn btn-large" value="Let's Go!" style="display:none;">
                    </form>
                </h1>
            </div>
            <section class="section scrollspy">
                <div class="container">
                    <div class="row">
                        <div class="col s12 l6">
                            <h2>Mautibox</h2>
                            <h3>What is this thing?</h3>
                        </div>
                        <div class="col s12 l6">
                            <p class="flow-text">
                                A sandbox for testing the open marketing automation software <a href="https://mautic.org">Mautic</a>.
                                New features and fixes can be tested here by humans (like you, probably).
                                To begin, just select what you wish to test above.
                            </p>
                        </div>
                        <div class="col s12 l6 clearfix">
                            <h2>Mail</h2>
                            <h3>Where did it go?</h3>
                        </div>
                        <div class="col s12 l6">
                            <p class="flow-text">
                                This service cannot send outgoing real-world email, <br/>
                                To view the email that would have been sent see <a href="/mail">/mail</a>.<br/>
                                This is a service called MailHog, and it's awesome for testing outgoing email.
                            </p>
                        </div>
                        <div class="col s12 l6 clearfix">
                            <h2>Mautic 2</h2>
                            <h3>How do I test?</h3>
                        </div>
                        <div class="col s12 l6">
                            <p class="flow-text">
                                Pull requests for Mautic 2 are no longer supported here as we've transitioned fully to Mautic 3.
                                To test Mautic 2 code, you will need to do it locally now.
                            </p>
                        </div>
                    </div>
                </div>
            </section>
        </main>
        <footer>
            <div class="container">
                <div class="row">
                    <div class="col s12 l12 margin-on-medium-and-down">
                        <p>
                            Mautibox is a free resource for the <a href="https://mautic.org">Mautic Community</a> and is not affiliated with <a href="https://mautic.com">Mautic, inc</a>. Mautic is a trademark of <a href="http://dbhurley.com">David Hurley</a>.
                        </p>
                    </div>
                </div>
            </div>
        </footer>
        <script src="/assets/js/libs/jquery/jquery.min.js"></script>
        <script src="/assets/js/config.js"></script>
        <!--<script src="/assets/js/nas.js"></script>-->
        <script src="/assets/js/libs/flat-surface-shader/deploy/fss.js"></script>
        <script src="/assets/js/triangles-i.js"></script>
        <script src="/assets/js/libs/chosen/chosen.jquery.min.js"></script>
        <script>
            var suggestion = <?php echo $suggestion; ?>;
        </script>
        <script src="/assets/js/pulls.js"></script>
        <script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
                new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
            j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
            'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
        })(window,document,'script','dataLayer','GTM-M6L27V3');</script>
    </body>
</html>