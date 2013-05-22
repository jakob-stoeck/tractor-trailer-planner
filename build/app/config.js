// Generated by CoffeeScript 1.6.2
(function() {
  window.config = {
    wallNumber: ko.observable(0),
    frameRate: ko.observable(0),
    debug: 0,
    canvasWidth: 800,
    canvasHeight: 800,
    steer: ko.observable(0.55),
    steeringRate: ko.observable(0.012),
    steps: ko.observable(20),
    speed: ko.observable(0.2),
    direction: ko.observable(1),
    searchMax: ko.observable(5000),
    goalMin: ko.observable(10),
    rChangePenalty: ko.observable(10),
    raytraceAngles: ko.observable(200),
    lat: ko.observable(48.162945),
    lon: ko.observable(11.59515),
    advanced: ko.observable(false),
    showAllFeasiblePaths: ko.observable(false),
    ed: {
      maxDistance: ko.observable(60),
      maxDistanceToLine: ko.observable(4),
      minLength: ko.observable(3),
      minR2: ko.observable(0.63),
      frequency: ko.observable(50),
      maxTime: ko.observable(1000)
    },
    truck: {
      tractor: {
        length: ko.observable(45),
        width: ko.observable(24),
        body: {
          lengthFront: ko.observable(0),
          lengthRear: ko.observable(0),
          width: ko.observable(0)
        }
      },
      trailer: {
        length: ko.observable(110),
        body: {
          lengthFront: ko.observable(0),
          lengthRear: ko.observable(0),
          width: ko.observable(0)
        }
      }
    },
    scale: 1,
    computeVisibility: true
  };

}).call(this);