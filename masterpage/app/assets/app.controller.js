(function () {
    'use strict';

    angular
      .module('fsjApp')
      .controller('AppController', AppController);

    AppController.$inject = [];
    function AppController() {
      var vm = this;

      activate();

      function activate() {
          console.log('AppController is Loaded')
      }




    }
})();