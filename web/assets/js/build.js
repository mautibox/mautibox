(function () {
    if (typeof jQuery !== 'undefined') {
        let $ = jQuery;
    }
    else if (typeof mQuery !== 'undefined') {
        let $ = mQuery;
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

    var sad = false;
    let build_overlay_sad = function () {
        // console.warn(':(');
        sad = true;
        let $overlay = $('body:first,html:first').first().find('#build-overlay');
        if ($overlay && $overlay.length) {
            $overlay.removeClass('build-overlay-loaded');
            $overlay.find('#build-overlay-progressbar-inner').hide();
        }
    };

    let build_overlay_load = function (message) {
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
                '<img src="http://i.imgur.com/S3LuSg1.gif" class="build-overlay-spinner">' +
                '<div id="build-overlay-progressbar">' +
                '<div id="build-overlay-progressbar-inner"></div>' +
                '</div>' +
                '</div>' +
                '<p id="build-overlay-message"></p>' +
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
                $(this).load(function () {
                    $(this).fadeTo(4000, 1);
                    // Start the fancy stuff after a while
                    setTimeout(function () {
                        if (!sad) {
                            $overlay.addClass('build-overlay-loaded');
                        }
                    }, 4000);
                });
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

    let check_for_build = function (pullNo) {
        $.getJSON('/pull.php?pullNo=' + pullNo, function (data) {
            console.log(data);
            window.data = data;
            if (typeof data.error === 'undefined') {
                console.error('Something has gone wrong with the pull script.', data);
                return;
            }

            if (data.error == null) {
                // All is well.
                sad = false;
                if (data.build.status === 'building') {
                    if (typeof data.message !== 'undefined' && data.message) {
                        build_overlay_load(data.message);
                    }
                    setInterval(function () {
                        $.getJSON('/pull.php?pullNo=' + pullNo, function (data) {
                            // console.log(data);
                            if (typeof data.message !== 'undefined' && data.message) {
                                build_overlay_load(data.message);
                            }
                            if (
                                typeof data.error !== 'undefined'
                                && (!data.error || data.error.length === 0)
                                && data.build.status === 'ready'
                            ) {
                                // Reload the page.
                                window.location.reload();
                                return false;
                            }
                        });
                    }, 500);
                }
                else if (
                    typeof window.mautiboxReloadNeeded !== 'undefined'
                    && window.mautiboxReloadNeeded
                    && data.build.status === 'ready'
                ) {
                    // Reload the page.
                    window.location.reload();
                    return false;
                }
            }
            else {
                // Error.
                if (typeof data.message !== 'undefined' && data.message) {
                    build_overlay_load(data.message);
                }
                build_overlay_sad();
            }
            // Try again in a while.
            setTimeout(function () {
                check_for_build(pullNo);
            }, 60000);
        });
    };

    // Discern the PR number and get details.
    let parts = window.location.pathname.split('/');
    if (typeof parts[1] !== 'undefined') {
        let pullNo = parseInt(parts[1]);
        if (pullNo) {
            check_for_build(pullNo);
        }
    }
})();