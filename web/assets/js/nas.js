/*!
 * Nas
 * Project Website: http://nas.pimmey.com
 * @version 1.0
 * @author Yegor Borisenco <pimmey@pimmey.com>
 */

'use strict';

var App = {};

App = {
    /*
    * Injecting the data from config.js
    * */
    CONFIG: CONFIG === 'undefined' ? console.error('Missing config file') : CONFIG,

    /*
    * Global variables used throughout the app
    * */
    GLOBAL: {
        activeToasts: 0,
        $pace: $('.pace'),
        progress: {
            show: function show () {
                App.GLOBAL.$pace.show().css('visibility', 'visible');
            },
            hide: function hide () {
                App.GLOBAL.$pace.hide().css('visibility', 'hidden');
            }
        },
        isTouch: function isTouch () {
            return (('ontouchstart' in window) || (navigator.MaxTouchPoints > 0) || (navigator.msMaxTouchPoints > 0));
        },
        $nav: $('nav')
    },

    /*
    * Initialising Google Maps
    * More information: https://developers.google.com/maps/documentation/javascript/
    * */
    initMap: function initMap () {
        var map = new google.maps.Map(document.getElementById('map'), {
            center: {
                lat: App.CONFIG.map.lat,
                lng: App.CONFIG.map.lng
            },
            zoom: 14,
            disableDefaultUI: true,
            styles: App.CONFIG.map.styles
        });

        var marker = new google.maps.Marker({
            position: {
                lat: App.CONFIG.map.lat,
                lng: App.CONFIG.map.lng
            },
            map: map,
            icon: App.CONFIG.map.markerIcon,
            title: 'Nas'
        });
    },

    /*
    * Loader handling
    * */
    onLoad: function onLoad () {
        window.onload = function () {
            $('#loading-overlay').fadeOut();
            App.GLOBAL.progress.hide();
        };
    },

    /*
     * Initing side nav for medium and smaller devices
     * */
    initSideNav: function sinitSideNav () {
        $('#sidenav-toggle').sideNav({
            closeOnClick: true
        });
    },

    /*
     Contact form handling
     @param String suffix helps differentiate between human and classic form modes
     Constricted to human and classic
     */
    initContactForm: function initContactForm () {
        var $name = $('#name');
        var $email = $('#email');
        var $message = $('#message');
        var $sendButton = $('#send-message');
        var initialMessage = $message.html();

        $sendButton.on('click', function (e) {
            e.preventDefault();
            App._sendMessage($name, $email, $message, initialMessage, $sendButton);
        });
    },

    /*
     A private function that sends the message, once everything is cool
     @param Obj $name the object that contains name value
     Obj $email the object that contains contact value
     Obj $message the object that contains message value
     String initialMessage initial message value
     Obj $sendButton the button that submits the form
     */
    _sendMessage: function _sendMessage ($name, $email, $message, initialMessage, $sendButton) {
        // Creating the conditions of the form's validity
        var isNameValid = App._verifyField($name, App.CONFIG.toastMessages.nameMissing);
        var isEmailValid = App._verifyField($email, App.CONFIG.toastMessages.contactMissing);
        var isMessageValid = App._verifyField($message, App.CONFIG.toastMessages.messageMissing, initialMessage);

        if (isNameValid && isEmailValid && isMessageValid) {
            App.GLOBAL.progress.show();

            // Disabling the button while we're waiting for the response
            $sendButton.attr('disabled', true);
            $.ajax({
                url: '/mailer/mailer.php',
                type: 'POST',
                data: {
                    name: $name.html() || $name.val(),
                    email: $email.html() || $email.val(),
                    message: $message.html() || $message.val()
                }
            }).done(function (res) {
                // res should return 1, if PHPMailer has done its job right
                if (res === '200') {
                    Materialize.toast(App.CONFIG.toastMessages.messageSent, App.CONFIG.toastSpeed, 'success');

                    // Resetting the form
                    $name.html('') && $name.val('');
                    $email.html('') && $email.val('');
                    $message.html(initialMessage) && $message.val(initialMessage);

                    // Removing active class from label
                    $name.next().removeClass('active');
                    $email.next().removeClass('active');
                    $message.next().removeClass('active');
                } else {
                    Materialize.toast(App.CONFIG.toastMessages.somethingWrong + res, App.CONFIG.toastSpeed, 'error');
                }
            }).error(function (error) {
                console.error(error);
                Materialize.toast(App.CONFIG.toastMessages.somethingWrong + error, App.CONFIG.toastSpeed, 'error');
            }).complete(function () {
                App.GLOBAL.progress.hide();

                // Re-enabling the button on request complete
                $sendButton.attr('disabled', false);
            });
        }
    },

    /*
     A private function that handles field verifying
     @param Obj $field the object that contains selected field
     String errorMessage error message relevant to the selected field
     String initialMessage initial message value
     */
    _verifyField: function _verifyField ($field, errorMessage, initialMessage) {
        var fieldValue = $field.html() || $field.val();
        var isFieldInvalid;
        var isFieldLengthInvalid = fieldValue.length === 0;

        if (initialMessage !== 'undefined') {
            isFieldInvalid = isFieldLengthInvalid || (fieldValue === initialMessage);
        } else {
            isFieldInvalid = isFieldLengthInvalid;
        }

        if ($field.attr('type') === 'email' && ! /.+\@.+\..+/.test(fieldValue)) {
            Materialize.toast(App.CONFIG.toastMessages.enterValidEmail, App.CONFIG.toastSpeed, 'error', function () {
                App.GLOBAL.activeToasts--;
            });
            App.GLOBAL.activeToasts++;
            return false;
        }

        if (isFieldInvalid) {
            Materialize.toast(errorMessage, App.CONFIG.toastSpeed, 'error', function () {
                App.GLOBAL.activeToasts--;
            });
            App.GLOBAL.activeToasts++;
            return false;
        } else {
            return true;
        }
    },

    /*
    * A function that handles stories hovers
    * */
    initPostsHovers: function initPostHovers () {
        if ( ! this.GLOBAL.isTouch()) {
            var $postLinks = $('.posts a');
            var $postCoverImages = $('.posts-covers > div');
            var $navbar = $('.navbar-fixed');

            $(document).on('mouseenter', '.posts a', function () {
                var slug = $(this).data('slug');
                $navbar.css('z-index', 0);
                $postLinks.addClass('opacity');
                $postCoverImages.removeClass('active zoom');
                $('.' + slug).addClass('active');
                setTimeout(function () {
                    $('.' + slug).addClass('zoom');
                }, 1);
            }).on('mouseleave', '.posts a', function () {
                $navbar.css('z-index', '');
                $postLinks.removeClass('opacity');
                $postCoverImages.removeClass('active');
            });
        }
    },

    /*
    * Adding .animate class to services section on scroll
    * */
    initAnimateServiceIcons: function initAnimateServiceIcons () {
        var $servicesSection = $('.services-section');
        var servicesSectionOffset = $servicesSection.offset().top;
        var windowOffset;
        $(document).on('scroll', function () {
            windowOffset = $(window).scrollTop() + 150;
            if (windowOffset > servicesSectionOffset) {
                $servicesSection.addClass('animate');
            }
        });
    },

    /*
    * Handling nav color scheme, depending on scroll position
    * */
    initNavColorChange: function initNavColorChange () {
        var $trianglesHeight = $('#triangles').height() || 720;
        $(document).on('scroll ready', function () {
            App._switchNavColorSchemes($trianglesHeight);
        });
    },

    /*
    * A private function that toggles .dark class for nav element
    * */
    _switchNavColorSchemes: function _switchNavColorSchemes ($trianglesHeight) {
        if ($(window).scrollTop() > $trianglesHeight) {
            App.GLOBAL.$nav.addClass('dark');
        } else {
            App.GLOBAL.$nav.removeClass('dark');
        }
    },

    /*
    * Initialising scroll spy to detect current section
    * Check it out here: http://materializecss.com/scrollspy.html
    * */
    initScrollSpy: function initScrollSpy () {
        $('.scrollspy').scrollSpy({
            scrollOffset: 50
        });
    },

    /*
    * Initialising parallax
    * http://materializecss.com/parallax.html
    * */
    initParallax: function initParallax () {
        $('.parallax').parallax();
    },

    /*
    * Initialising slider
    * http://materializecss.com/media.html#slider
    * */
    initSlider: function initSlider () {
        $('.slider').slider({
            full_width: true,
            height: 720
        });
    },

    /*
    * Handling modals behaviour
    * http://materializecss.com/modals.html
    * */
    initModal: function initModal () {
        if (window.location.hash.length > 0 && window.location.hash !== '#!') {
            $(window.location.hash).openModal({
                complete: function () {
                    history.replaceState('', document.title, window.location.pathname);
                }
            });
        }

        $('.modal-trigger').leanModal({
            opacity: .5,
            ready: function () {

            },
            complete: function () {
                history.replaceState('', document.title, window.location.pathname);
            }
        }).on('click', function () {
            var href = $(this).attr('href');
            setTimeout(function () {
                window.location.hash = href;
            }, 400);
        });
    },

    /*
    * A function that handles modal navigation
    * */
    initModalNav: function initModalNav () {
        var $links = $('.modal-nav');

        $links.on('click', function (e) {
            e.preventDefault();

            var $this = $(this);
            var current = window.location.hash;
            var next = $this.data('next-modal');
            var prev = $this.data('previous-modal');

            $(current).closeModal();

            if (typeof prev !== 'undefined') {
                $('#' + prev).openModal({
                    ready: function () {
                        $('.modal').scrollTop(0);
                        window.location.hash = prev;
                    },
                    complete: function () {
                        history.replaceState('', document.title, window.location.pathname);
                    }
                });
            }

            if (typeof next !== 'undefined') {
                $('#' + next).openModal({
                    ready: function () {
                        $('.modal').scrollTop(0);
                        window.location.hash = next;
                    },
                    complete: function () {
                        history.replaceState('', document.title, window.location.pathname);
                    }
                });
            }
        });
    },

    /*
    * Textillate effect on hover of .block elements
    * */
    initTextillate: function initTextillate () {
        var $tlt = $('.tlt');

        if ($tlt) {
            $tlt.textillate({
                loop: false,
                minDisplayTime: 0,
                initialDelay: 0,
                autoStart: false,
                'in': {
                    effect: 'fadeIn',
                    delay: 15
                },
                out: {
                    effect: 'fadeOut',
                    delay: 15
                }
            });

            $('.block').on({
                'mouseenter': function () {
                    $(this).find('.tlt').textillate('in');
                },
                'mouseleave': function () {
                    $(this).find('.tlt').textillate('out');
                }
            });
        }
    }
};

$(document).on('ready', function () {
    App.onLoad();
    App.initSideNav();
    App.initPostsHovers();
    App.initAnimateServiceIcons();
    App.initNavColorChange();
    App.initScrollSpy();
    App.initParallax();
    App.initSlider();
    App.initModal();
    App.initModalNav();
    App.initTextillate();
    App.initContactForm();
});
