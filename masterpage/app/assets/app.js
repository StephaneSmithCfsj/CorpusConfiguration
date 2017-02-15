(function () {
    "use strict";

    window.Negotium = window.Negotium || {};
    window.Negotium.Boost = window.Negotium.Boost || {};

    Negotium.Boost.MasterPageService = function () {
        var baseUrl = _spPageContextInfo.siteAbsoluteUrl + "/_catalogs/masterpage/FSJ/vendor";
        var masterPageAppName = 'fsjApp';
        var service = {
            startApp: startApp
        };

        return service;

        function defineRequireJsDependencies() {

        }


        function startAngularApp() {
            var requirePaths = [];
            requirePaths['ngAria'] = 'angular-aria.min';
            requirePaths['ngAnimate'] = 'angular-animate.min';
            requirePaths['ngMaterial'] = 'angular-material.min';
            require.config({
                baseUrl: baseUrl,
                paths: requirePaths
            });
            require(['ngAria', 'ngAnimate', 'ngMaterial'], function(){bootstrapFSJApp(masterPageAppName)});
        }

        function startApp() {
            defineRequireJsDependencies();
            startAngularApp();
        }

    }

    function bootstrapFSJApp(appName) {
        angular
            .module(appName, ['ngMaterial'])
            .config(function ($mdThemingProvider, $mdIconProvider) {
                $mdIconProvider
                    .defaultIconSet("./assets/svg/avatars.svg", 128)
                    .icon("menu", "./assets/svg/menu.svg", 24)
                    .icon("share", "./assets/svg/share.svg", 24)
                    .icon("google_plus", "./assets/svg/google_plus.svg", 512)
                    .icon("hangouts", "./assets/svg/hangouts.svg", 512)
                    .icon("twitter", "./assets/svg/twitter.svg", 512)
                    .icon("phone", "./assets/svg/phone.svg", 512);

                $mdThemingProvider.theme('default')
                    .primaryPalette('blue')
                    .accentPalette('teal');

            });
        //Enable multiple angular apps to be nested by using ng-non-bindable. Reset the injector of each element allows angular to provide a new injector for the block
        var appMarkers = "#s4-workspace [data-name='WebPartZone'] > div";
        excludeAngularApps(appMarkers);
        angular.bootstrap($('body'), [appName]);
    }

    function excludeAngularApps(appElementSelector){
        angular.element(appElementSelector).addClass('ng-non-bindable').data('$injector', '');
    }

    $(document).ready(function () {
        console.log('Initializing the master page...');
        var masterPageService = Negotium.Boost.MasterPageService();
        masterPageService.startApp();
    });

})();
