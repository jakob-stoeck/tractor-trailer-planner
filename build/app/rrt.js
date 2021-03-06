// Generated by CoffeeScript 1.6.2
(function() {
  var Graph, Holonomic, Nonholomonic, Planner, drawPath, getPercent, grow, rectCenter, rrt, rrtBalancedBidirectional, rrtConfig, _ref, _ref1,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Graph = (function() {
    function Graph() {
      this.V = [];
      this.E = [];
    }

    Graph.prototype.addVertex = function(q) {
      var i;

      i = (this.V.push(q)) - 1;
      return i;
    };

    Graph.prototype.size = function() {
      var e, j, length, tail;

      j = this.E.length - 1;
      e = [];
      tail = this.V.length - 1;
      length = 0;
      while (j >= 0) {
        if (this.E[j][1] === tail) {
          length++;
          tail = this.E[j][0];
        }
        j--;
      }
      return length;
    };

    Graph.prototype.addEdge = function(i, j) {
      return this.E.push([i, j]);
    };

    Graph.prototype.traverseUp = function(reverse) {
      var j, path, tail;

      if (reverse == null) {
        reverse = false;
      }
      j = this.E.length - 1;
      path = [];
      tail = this.V.length - 1;
      while (j >= 0) {
        if (this.E[j][1] === tail) {
          this.V[this.E[j][1]].phi *= -1;
          if (reverse) {
            this.V[this.E[j][1]].s *= -1;
          }
          path.push(this.V[this.E[j][1]]);
          tail = this.E[j][0];
        }
        j--;
      }
      if (tail !== 0) {
        console.error("tail is " + tail + ", something went wrong");
      }
      return path;
    };

    return Graph;

  })();

  Planner = (function() {
    function Planner(sampling) {
      this.sampling = sampling;
      this.start = new Conf(400, 400, -PIHALF, -PIHALF);
      this.goal = new Conf(400, 400, -PIHALF, -PIHALF);
      this.borders = [];
    }

    Planner.prototype.distance = function(q, v) {};

    Planner.prototype.setGoal = function(conf) {};

    Planner.prototype.setBorders = function(borders) {
      return this.borders = borders;
    };

    Planner.prototype.distRot = function(q, v) {
      return 0;
    };

    Planner.prototype.nearestVertex = function(q, G) {};

    Planner.prototype.randConf = function() {};

    Planner.prototype.newConf = function(qNear, qRand, deltaQ) {};

    Planner.prototype.beforeSearch = function() {};

    Planner.prototype.afterStep = function(step, qNear, qRand) {};

    Planner.prototype.afterSearch = function(qGoal) {};

    return Planner;

  })();

  Holonomic = (function(_super) {
    __extends(Holonomic, _super);

    function Holonomic() {
      _ref = Holonomic.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Holonomic.prototype.setStart = function(conf) {
      return this.start = conf;
    };

    Holonomic.prototype.setStartAngle = function(angle) {
      return this.start.theta1 = angle;
    };

    Holonomic.prototype.setGoal = function(conf) {
      return this.goal = new Conf(conf.x, conf.y, conf.theta, conf.theta1);
    };

    Holonomic.prototype.distance = function(q, v) {
      return Math.pow(q.x - v.x, 2) + Math.pow(q.y - v.y, 2);
    };

    Holonomic.prototype.nearestVertex = function(q, G) {
      var d, d_i, i, r, r_i, v, vNear, _i, _len, _ref1;

      d = Number.MAX_VALUE;
      r = Number.MAX_VALUE;
      _ref1 = G.V;
      for (i = _i = 0, _len = _ref1.length; _i < _len; i = ++_i) {
        v = _ref1[i];
        d_i = this.distance(q, v);
        if (d_i < d) {
          vNear = i;
          d = d_i;
          r = this.distRot(q, v);
        } else if (d_i === d) {
          r_i = this.distRot(q, v);
          if (r_i < r) {
            vNear = i;
          }
        }
      }
      return vNear;
    };

    Holonomic.prototype.randConf = function() {
      return {
        x: getRandomArbitrary(this.start.x - 400, this.start.x + 400),
        y: getRandomArbitrary(this.start.y - 400, this.start.y + 400)
      };
    };

    Holonomic.prototype.newConf = function(qNear, qRand, deltaQ) {
      var dRand, i, k;

      dRand = this.distance(qNear, qRand);
      if (dRand > deltaQ) {
        k = deltaQ / dRand;
        return qRand = (function() {
          var _i, _len, _ref1, _results;

          _ref1 = [0, 1];
          _results = [];
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            i = _ref1[_i];
            _results.push(Math.floor(qNear[i] + k * (qRand[i] - qNear[i])));
          }
          return _results;
        })();
      }
    };

    Holonomic.prototype.draw = function(q) {
      return ctx.rect(q.x - 2, q.y - 2, 4, 4);
    };

    Holonomic.prototype.motion = function(start, goal, borders) {
      var dist, found, newDist, newPath, path, pathFound, r, _i, _ref1;

      if (borders == null) {
        borders = [];
      }
      this.borders = borders;
      this.goal = goal;
      this.start = start;
      path = [];
      dist = Infinity;
      found = 0;
      for (r = _i = 0, _ref1 = rrtConfig.maxRounds; 0 <= _ref1 ? _i < _ref1 : _i > _ref1; r = 0 <= _ref1 ? ++_i : --_i) {
        pathFound = false;
        newPath = this.sampling(rrtConfig.K, rrtConfig.deltaQ, rrtConfig.goalBias);
        if (newPath.length > 0) {
          pathFound = true;
          newDist = this.distance(newPath.last(), goal);
        }
        if ((pathFound && newPath.length <= path.length && newDist <= dist) || path.length === 0) {
          dist = newDist;
          path = newPath;
          if (++found === rrtConfig.rounds) {
            break;
          }
        }
      }
      return path;
    };

    Holonomic.prototype.actionPath = function(start, goal, borders) {
      var found, i, nextMove, path, _i, _ref1;

      if (borders == null) {
        borders = [];
      }
      found = lookupTable.get(start, goal);
      path = [];
      if (found) {
        path.push(start);
        for (i = _i = 0, _ref1 = found.step; 0 <= _ref1 ? _i < _ref1 : _i > _ref1; i = 0 <= _ref1 ? ++_i : --_i) {
          nextMove = truck.legalMoves(path.last(), borders, null, [found.s], [found.phi]);
          if (nextMove.length > 0) {
            path.push(nextMove[0]);
          } else {
            return [];
          }
        }
      }
      return path;
    };

    return Holonomic;

  })(Planner);

  Nonholomonic = (function(_super) {
    __extends(Nonholomonic, _super);

    function Nonholomonic() {
      _ref1 = Nonholomonic.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    Nonholomonic.prototype.distRot = function(q, v) {
      var dist, rotational, rotational2;

      rotational = Math.abs(q.theta - v.theta) / Math.PI;
      rotational2 = Math.abs(q.theta1 - v.theta1) / Math.PI;
      dist = rotational + rotational2;
      return dist;
    };

    Nonholomonic.prototype.draw = function(q) {
      var m_canvas, m_ctx;

      m_canvas = document.createElement('canvas');
      m_canvas.width = 800;
      m_canvas.height = 800;
      m_ctx = m_canvas.getContext('2d');
      return renderCar(m_ctx, new Conf(q.x, q.y, q.theta, q.theta1, q.theta2));
    };

    return Nonholomonic;

  })(Holonomic);

  grow = function(G, deltaQ, qGoal, growRandom, useActionPath) {
    var iNear, path, q, qNear, qNews, qRand, vertex1, vertex2, _i, _j, _len, _len1;

    if (useActionPath == null) {
      useActionPath = true;
    }
    qRand = growRandom ? planner.randConf() : qGoal;
    iNear = planner.nearestVertex(qRand, G);
    qNear = G.V[iNear];
    path = [];
    if (useActionPath) {
      path = planner.actionPath(qNear, qGoal, planner.borders);
    }
    if (path.length > 0 && equals(path.last(), qGoal, rrtConfig.distTrans, rrtConfig.distRot)) {
      vertex1 = iNear;
      qNear = path.last();
      for (_i = 0, _len = path.length; _i < _len; _i++) {
        q = path[_i];
        vertex2 = G.addVertex(q);
        G.addEdge(vertex1, vertex2);
        vertex1 = vertex2;
      }
    } else {
      qNews = truck.legalMoves(qNear, planner.borders);
      for (_j = 0, _len1 = qNews.length; _j < _len1; _j++) {
        q = qNews[_j];
        G.addEdge(iNear, G.addVertex(q));
      }
    }
    planner.afterStep(qNear, qRand, path);
    return qNear;
  };

  window.equals = function(q0, q1, distTrans, distRot) {
    var dist, rot;

    if (distTrans == null) {
      distTrans = 0;
    }
    if (distRot == null) {
      distRot = 0;
    }
    dist = planner.distance(q0, q1);
    if ((q0.theta != null) && (q0.theta1 != null) && (q1.theta != null) && (q1.theta1 != null)) {
      rot = planner.distRot(q0, q1);
    } else {
      rot = 0;
    }
    if (dist <= distTrans && rot <= distRot) {
      return true;
    } else {
      return false;
    }
  };

  getPercent = function(x, max) {
    return Math.floor(x * 100 / max);
  };

  rrtBalancedBidirectional = function(K, deltaQ, goalBias) {
    var G, H, found, k, one, path, qNew, qNewR, target, two, unidirectional;

    G = new Graph();
    G.addVertex(this.start);
    H = new Graph();
    H.addVertex(this.goal);
    k = 0;
    path = [];
    found = false;
    unidirectional = false;
    while (k < K) {
      target = k % goalBias ? null : this.goal;
      qNew = grow(G, deltaQ, this.goal, k % goalBias);
      qNewR = grow(H, deltaQ, qNew, 0, false);
      if (equals(qNew, this.goal, rrtConfig.distTrans, rrtConfig.distRot)) {
        found = true;
        unidirectional = true;
        break;
      }
      if (equals(qNew, qNewR, rrtConfig.distTrans, rrtConfig.distRot)) {
        found = true;
        break;
      }
      k++;
    }
    if (found) {
      one = H.traverseUp(true).reverse();
      two = G.traverseUp();
      if (unidirectional) {
        path = two.reverse();
      } else {
        path = one.concat(two).reverse();
      }
    }
    return path;
  };

  drawPath = function(path, color) {
    var ctx, curr, from, i, to;

    ctx = ctxPath;
    ctx.save();
    ctx.strokeStyle = color;
    ctx.lineWidth = 5;
    to = path.length - 1;
    from = 0;
    ctx.beginPath();
    ctx.moveTo(path[from].x, path[from].y);
    i = from;
    if (to - from > 0) {
      while (i < to) {
        curr = path[i];
        ctx.lineTo(curr.x, curr.y);
        i++;
      }
    }
    ctx.stroke();
    return ctx.restore();
  };

  rrt = function(K, deltaQ, goalBias) {
    var G, k, path, qNew;

    G = new Graph();
    G.addVertex(this.start);
    path = [];
    k = 0;
    this.beforeSearch();
    while (k < K) {
      qNew = grow(G, deltaQ, this.goal, k % goalBias);
      if (equals(qNew, this.goal, rrtConfig.distTrans, rrtConfig.distRot)) {
        path = G.traverseUp().reverse();
        break;
      }
      k++;
    }
    this.afterSearch(this.goal);
    return path;
  };

  rrtConfig = {
    bidirectional: window.config.advanced(),
    bigIsGreedy: true,
    collisionDetectionTries: 1,
    deltaQ: window.config.steps(),
    distRot: 0.5,
    distTrans: 1000,
    goalBias: 10,
    K: window.config.searchMax(),
    maxRounds: 1,
    rounds: 20,
    showAllPaths: true,
    showCollisionDetection: true,
    showTruckPosition: false,
    stopWhenFound: true,
    tryTrivial: true
  };

  window.planner = new Nonholomonic(rrt);

  rectCenter = function(ctx, x, y, size) {
    return ctx.rect(x - size / 2, y - size / 2, size, size);
  };

  if (rrtConfig.showTruckPosition) {
    planner.beforeSearch = function() {
      ctxTruck.clearRect(0, 0, 800, 800);
      ctxTruck.beginPath();
      return ctxTruck.fillStyle = '#0f0';
    };
    planner.afterStep = function(qNear, qRand, path) {
      ctxTruck.strokeStyle = path.length > 0 ? '#f00' : '#000';
      ctxTruck.beginPath();
      if (path.length > 0) {
        renderCar(ctxTruck, path[0]);
      }
      renderCar(ctxTruck, qNear);
      ctxTruck.stroke();
      ctxPath.clearRect(0, 0, 800, 800);
      rectCenter(ctxPath, qRand.x, qRand.y, 15);
      ctxPath.fill();
      debugger;
    };
    planner.afterSearch = function(qGoal) {
      ctxTruck.beginPath();
      ctxTruck.strokeStyle = '#00f';
      renderCar(ctxTruck, qGoal);
      console.info('goal', this.goal);
      return ctxTruck.stroke();
    };
  }

}).call(this);
