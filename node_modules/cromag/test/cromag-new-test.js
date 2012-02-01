var vows   = require('vows');
var assert = require('assert');

var Cromag = require('../cromag');

vows.describe('Cromag New').addBatch({
    'can return a new object from today static method': {
        topic: function () { return Cromag.today(); },
        'returns the correct time': function (date) {
            var compare = new Cromag().clearTime();
            assert.equal(date.valueOf(), compare.valueOf());
        }
    },

    'clearTime() works': {
        topic: function() { return new Cromag().clearTime(); },
        'returns the correct value': function (date) {
            var compare = new Cromag();
            compare.setHours(0);
            compare.setMinutes(0);
            compare.setSeconds(0);
            compare.setMilliseconds(0);

            assert.equal(date.valueOf(), compare.valueOf());
        }
    },

    'clearUTCTime() works': {
        topic: function() { return new Cromag().clearUTCTime(); },
        'returns the correct value': function (date) {
            var compare = new Cromag();
            compare.setUTCHours(0);
            compare.setUTCMinutes(0);
            compare.setUTCSeconds(0);
            compare.setUTCMilliseconds(0);

            assert.equal(date.valueOf(), compare.valueOf());
        }
    },

    'today() works': {
        topic: function() {
            return Cromag.today();
        },
        'returns the correct value': function(date) {
            var compare = new Cromag().clearTime();
            assert.equal(date.valueOf(), compare.valueOf());
        }
    },

    'UTCtoday() works': {
        topic: function() {
            return Cromag.UTCtoday();
        },
        'returns the correct value': function(date) {
            var compare = new Cromag().clearUTCTime();
            assert.equal(date.valueOf(), compare.valueOf());
        }
    },

    'yesterday() works': {
        topic: function() {
            return Cromag.yesterday();
        },
        'returns the correct value': function(date) {
            var compare = new Cromag().clearTime();
            compare.setSeconds(compare.getSeconds() - 86400);
            assert.equal(date.valueOf(), compare.valueOf());
        }
    },

    'UTCyesterday() works': {
        topic: function() {
            return Cromag.UTCyesterday();
        },
        'returns the correct value': function(date) {
            var compare = new Cromag().clearUTCTime();
            compare.setSeconds(compare.getSeconds() - 86400);
            assert.equal(date.valueOf(), compare.valueOf());
        }
    },

    'tomorrow() works': {
        topic: function() {
            return Cromag.tomorrow();
        },
        'returns the correct value': function(date) {
            var compare = new Cromag().clearTime();
            compare.setSeconds(compare.getSeconds() + 86400);
            assert.equal(date.valueOf(), compare.valueOf());
        }
    },

    'UTCtomorrow() works': {
        topic: function() {
            return Cromag.UTCtomorrow();
        },
        'returns the correct value': function(date) {
            var compare = new Cromag().clearUTCTime();
            compare.setSeconds(compare.getSeconds() + 86400);
            assert.equal(date.valueOf(), compare.valueOf());
        }
    }

}).export(module);