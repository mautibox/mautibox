(function () {
    if (typeof window.jQuery !== 'undefined') {
        var $ = window.jQuery;
    }
    else if (typeof window.mQuery !== 'undefined') {
        var $ = window.mQuery;
    }
    else {
        console.warn('No jQuery/mQuery found.');
        return;
    }
    $.extend($.easing,
        {
            easeInSine: function (x, t, b, c, d) {
                return -c * Math.cos(t / d * (Math.PI / 2)) + c + b;
            },
        });

    $(document).ready(function () {
        let $user = $('.form-group.login-form #username:first');
        if ($user.length && $user.val().length === 0) {
            let $pass = $('.form-group.login-form #password:first');
            if ($pass.length && $pass.val().length === 0) {
                $user.val('admin');
                $pass.val('mautic');
            }
        }
    });

    var sad = false;
    var build_overlay_sad = function (data) {
        clearTimeout(timer);
        clearTimeout(retry);
        // console.warn(':(');
        sad = true;
        if (typeof data.message !== 'undefined' && data.message) {
            build_overlay_load(data.message, pullNo);
        }
        setTimeout(function () {
            let $overlay = $('body:first,html:first').first().find('#build-overlay');
            if ($overlay && $overlay.length) {
                $overlay.removeClass('build-overlay-loaded');
                $overlay.find('#build-overlay-progressbar-inner').stop().fadeTo(100, 0);
                $overlay.find('#build-overlay-message-links').stop().fadeTo(500, 1);
            }
            // Try again in a while.
            retry = setTimeout(function () {
                clearTimeout(timer);
                check_for_build(pullNo);
            }, 60000);
        }, 1000);
    };
    var build_overlay_happy = function (data, pullNo) {
        clearTimeout(timer);
        clearTimeout(retry);
        setTimeout(function () {
            data.message = data.message.replace('READY', 'LOADING');
            build_overlay_load(data.message, pullNo);
        }, 1500);
        window.location.reload();
        return false;
    };

    var build_overlay_load = function (message, pullNo) {
        let $target = $('body:first,html:first').first();
        let $overlay = $target.find('#build-overlay');
        let styles = $('#build-styles:first');
        if (!styles || !styles.length) {
            $('head:first,body:first,html:first').first().append('<link id="build-styles" href="/assets/css/build.css" type="text/css" rel="stylesheet"/>');
        }
        if (!$overlay || !$overlay.length) {
            // Define markup
            let html = '<div id="build-overlay">' +
                '<div id="build-overlay-bg">' +
                '<img src="/assets/img/spinner.gif" class="build-overlay-spinner">' +
                '<div id="build-overlay-progressbar">' +
                '<div id="build-overlay-progressbar-inner"></div>' +
                '</div>' +
                '</div>' +
                '<p id="build-overlay-message"></p>' +
                '<p id="build-overlay-message-links">' +
                '<a href="/">&larr; <span>Go back</span> and try another</a> or <a href="https://github.com/mautic/mautic/pull/' + pullNo + '">help with the <span>Pull Request</span> &rarr;</a></p>' +
                '</div>';

            // Create the overlay
            $overlay = $target
                .append(html)
                .find('#build-overlay');

            // Set message
            $overlay.find('#build-overlay-message').html(message);

            // Fade it in.
            $overlay.find('#build-overlay-bg')
                .css('opacity', 0, 'easeInSine')
                .fadeTo(500, 1, null, function () {
                    $overlay
                        .css('opacity', 0)
                        .fadeTo(500, 1);
                });

            // Fade in images once loaded.
            $overlay.find('img').each(function () {
                if ($(this).attr('url').length) {
                    $(this).load(function () {
                        $(this).fadeTo(4000, 1);
                        // Start the fancy stuff after a while
                        setTimeout(function () {
                            if (!sad) {
                                $overlay.addClass('build-overlay-loaded');
                            }
                        }, 4000);
                    });
                }
            });

            // Start animating the progress bar
            $overlay.find('#build-overlay-progressbar')
                .css('opacity', 0)
                .fadeTo(1000, .7)
                .find('#build-overlay-progressbar-inner')
                .css('width', '0%')
                .animate({'width': '100%'}, 25000, 'easeInSine');

            // Fade in the message
            $overlay.find('#build-overlay-message').fadeTo(2000, 1);

            // Close overlay by hitting escape
            $(document).keyup(function (e) {
                if (e.which === 27) {
                    if (typeof $overlay !== 'undefined') {
                        $overlay.fadeTo(500, 0);
                        setTimeout(function () {
                            $overlay.remove();
                        }, 1000);
                    }
                }
            });
        }
        else {
            // Already exists, just change the message.
            $overlay.find('#build-overlay-message').html(message);
        }
    };

    var timer, retry;
    var check_for_build = function (pullNo) {
        $.getJSON('/api/pull/?pullNo=' + pullNo, function (data) {
            if (typeof data.error === 'undefined') {
                console.error('Something has gone wrong with the pull script.', data);
                return;
            }
            if (data.error === null) {
                // All is well.
                sad = false;
                if (data.build.status === 'building' || data.build.status === 'queued' || data.build.status === 'warming') {
                    window.mautiboxReloadNeeded = true;
                    if (typeof data.message !== 'undefined' && data.message) {
                        build_overlay_load(data.message, pullNo);
                    }
                    timer = setTimeout(function () {
                        check_for_completion(pullNo);
                    }, 500);
                }
                else if (
                    typeof window.mautiboxReloadNeeded !== 'undefined'
                    && window.mautiboxReloadNeeded
                    && data.build.status === 'ready'
                ) {
                    // Reload the page.
                    return build_overlay_happy(data, pullNo);
                }
            }
            else {
                // Error.
                console.log(data);
                build_overlay_sad(data);
            }
        });
    };
    var check_for_completion = function (pullNo) {
        $.getJSON('/api/pull/?pullNo=' + pullNo, function (data) {
            clearTimeout(timer);
            // console.log(data);
            if (typeof data.message !== 'undefined' && data.message) {
                build_overlay_load(data.message, pullNo);
            }
            if (
                typeof data.error !== 'undefined'
                && data.error
            ) {
                return build_overlay_sad(data);
            }
            else if (
                typeof data.build.status !== 'undefined'
                && data.build.status === 'ready'
            ) {
                // Reload the page.
                return build_overlay_happy(data, pullNo);
            }
            timer = setTimeout(function () {
                check_for_completion(pullNo);
            }, 500);
        });
    };

    // Discern the PR number and get details.
    var parts = window.location.pathname.split('/');
    if (typeof parts[1] !== 'undefined') {
        var pullNo = parts[1].match(/^\d+$/) ? parseInt(parts[1]) : parts[1];
        if (pullNo) {
            check_for_build(pullNo);
        }
        else {
            build_overlay_load('<h1>GREETINGS HUMAN</h1><h4>There is a problem is between your keyboard and chair. Please try a pull request number.</h4>');
            build_overlay_sad();
        }
    }
})();