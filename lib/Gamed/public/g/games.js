define([
    'g/app',
    'g/HiLo/controller',
    'g/RoboRally/controller',
    'g/Rook/controller',
    'g/SpeedRisk/controller',
    'g/Spitzer/controller',
], function(app, HiLoCtl, RoboRallyCtl, RookCtl, SpeedRiskCtl, SpitzerCtl) {
    console.log(app);
    app.controller('HiLoCtl', HiLoCtl);
    app.controller('RoboRallyCtl', RoboRallyCtl);
    app.controller('RookCtl', RookCtl);
    app.controller('SpeedRiskCtl', SpeedRiskCtl);
    app.controller('SpitzerCtl', SpitzerCtl);
    return app;
});
