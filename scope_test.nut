class testScope {

    _waiting = {};
    _data = {};
    _root = null;
    _path = null;

    constructor(init = true) {
        server.log("constructor _data: " + http.jsonencode(_data))
        server.log("constructor _waiting: " + http.jsonencode(_waiting))

        this._path = http.agenturl();
        this._root = this;

        if(init) {
            initilize();
            init = false;
        }

    }

    function initilize() {
        server.log("in init")
         _restore(); //needs to be accessed by all instances - look into errors
    }

    function store_data(data) {
        server.save({ "ib" : {"version": -1, "data" : data} });
    }

    function _restore() {
        local persist = server.load();
        if ("ib" in persist) {
            _data.root <- persist.ib.root;
            _data.version <- persist.ib.version;
        } else {
            _data["version"] <- -1;
            _data["root"] <- null;
        }
        server.log("in _restore. data: " + http.jsonencode(_data));
    }

    function create_waiting(path, eventtype, callback) {
        if (!(path in _waiting)) _waiting[path] <- {};
        if (!(eventtype in _waiting[path])) _waiting[path][eventtype] <- [];
        _waiting[path][eventtype].push(callback);
    }
}

t1 <- testScope();
// t1.store_data("dog"); // this is now stored to the server
t1.create_waiting("/path_test", "value", "callback_test");

server.log("t1 _waiting " + http.jsonencode(t1._waiting))
server.log("t1 _data " + t1._data)

imp.wakeup(3, function() {
    t2 <- testScope(false);
    server.log("t2 _waiting " + http.jsonencode(t2._waiting))
    server.log("t2 _data " + http.jsonencode(t2._data))
})


// this replicates the issue I'm seeing in impbase if restore is only called in the init

// logs
// 2015-05-21 16:41:10 UTC-7  [Agent] constructor _data: { }
// 2015-05-21 16:41:10 UTC-7  [Agent] constructor _waiting: { }
// 2015-05-21 16:41:10 UTC-7  [Agent] in init
// 2015-05-21 16:41:10 UTC-7  [Agent] in _restore. data: "dog"
// 2015-05-21 16:41:10 UTC-7  [Agent] t1 _waiting { "/path_test": { "value": [ "callback_test" ] } }
// 2015-05-21 16:41:10 UTC-7  [Agent] t1 _data dog
// 2015-05-21 16:41:10 UTC-7  [Status]  Device connected
// 2015-05-21 16:41:13 UTC-7  [Agent] constructor _data: { }
// 2015-05-21 16:41:13 UTC-7  [Agent] constructor _waiting: { "/path_test": { "value": [ "callback_test" ] } }
// 2015-05-21 16:41:13 UTC-7  [Agent] t2 _waiting { "/path_test": { "value": [ "callback_test" ] } }
// 2015-05-21 16:41:13 UTC-7  [Agent] t2 _data { }




class testScopeFixed {

    _waiting = {};
    _data = {};
    _root = null;
    _path = null;

    constructor(init = true) {
        server.log("constructor _data: " + http.jsonencode(_data))
        server.log("constructor _waiting: " + http.jsonencode(_waiting))

        this._path = http.agenturl();
        this._root = this;

        if(init) {
            initilize();
            init = false;
        }

    }

    function initilize() {
        server.log("in init")
         _restore(); //needs to be accessed by all instances
    }

    function store_data(data) {
        server.log("in store data")
        server.save({ "ib" : {"version": -1, "root" : data} });
    }

    function _restore() {
        local persist = server.load();
        server.log(http.jsonencode(persist))

        if ("ib" in persist) {
            _data.root <- persist.ib.root;
            _data.version <- persist.ib.version
        } else {
            _data.root <- null;
            _data.version <- -1;
        }

        server.log("in _restore. data: " + http.jsonencode(_data));
    }

    function create_waiting(path, eventtype, callback) {
        if (!(path in _waiting)) _waiting[path] <- {};
        if (!(eventtype in _waiting[path])) _waiting[path][eventtype] <- [];
        _waiting[path][eventtype].push(callback);
    }


}

t1 <- testScopeFixed();
// t1.store_data("dog"); // this is now stored to the server
t1.create_waiting("/path_test", "value", "callback_test");

server.log("t1 _waiting " + http.jsonencode(t1._waiting))
server.log("t1 _data " + http.jsonencode(t1._data))

imp.wakeup(3, function() {
    t2 <- testScopeFixed(false);
    server.log("t2 _waiting " + http.jsonencode(t2._waiting))
    server.log("t2 _data " + http.jsonencode(t2._data))
})


// this is how I addressed the restore issue in ImpBase

// logs
// 2015-05-27 09:59:38 UTC-7    [Agent] constructor _data: { }
// 2015-05-27 09:59:38 UTC-7    [Agent] constructor _waiting: { }
// 2015-05-27 09:59:38 UTC-7    [Agent] in init
// 2015-05-27 09:59:38 UTC-7    [Agent] { "ib": { "version": -1, "root": "dog" } }
// 2015-05-27 09:59:38 UTC-7    [Agent] in _restore. data: { "version": -1, "root": "dog" }
// 2015-05-27 09:59:38 UTC-7    [Agent] t1 _waiting { "/path_test": { "value": [ "callback_test" ] } }
// 2015-05-27 09:59:38 UTC-7    [Agent] t1 _data { "version": -1, "root": "dog" }
// 2015-05-27 09:59:38 UTC-7    [Status]    Device connected
// 2015-05-27 09:59:41 UTC-7    [Agent] constructor _data: { "version": -1, "root": "dog" }
// 2015-05-27 09:59:41 UTC-7    [Agent] constructor _waiting: { "/path_test": { "value": [ "callback_test" ] } }
// 2015-05-27 09:59:41 UTC-7    [Agent] t2 _waiting { "/path_test": { "value": [ "callback_test" ] } }
// 2015-05-27 09:59:41 UTC-7    [Agent] t2 _data { "version": -1, "root": "dog" }