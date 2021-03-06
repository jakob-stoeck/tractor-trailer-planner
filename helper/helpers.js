// Generated by CoffeeScript 1.3.3
(function() {

  window.roundNumber = function(num, dec) {
    return Math.round(num * Math.pow(10, dec)) / Math.pow(10, dec);
  };

  window.multiDimArray = function(cols, rows) {
    var array, c, r, _i, _j;
    array = [];
    for (r = _i = 0; 0 <= rows ? _i < rows : _i > rows; r = 0 <= rows ? ++_i : --_i) {
      array[r] = [];
      for (c = _j = 0; 0 <= cols ? _j < cols : _j > cols; c = 0 <= cols ? ++_j : --_j) {
        array[r][c] = 0;
      }
    }
    return array;
  };

  window.pad = function(number, length) {
    if ((number + "").length >= length) {
      return number + "";
    } else {
      return pad("0" + number, length);
    }
  };

  window.getRandomInt = function(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  };

  window.getRandomArbitrary = function(min, max) {
    return Math.random() * (max - min) + min;
  };

  window.matrix = {
    multiply: function(A, B) {
      return [A[0] * B[0] + A[2] * B[1], A[1] * B[0] + A[3] * B[1], A[0] * B[2] + A[2] * B[3], A[1] * B[2] + A[3] * B[3], A[0] * B[4] + A[2] * B[5] + A[4], A[1] * B[4] + A[3] * B[5] + A[5]];
    },
    multiplyCoords: function(V, A) {
      return this.multiply(A, [V[0], 0, 0, V[1], 0, 0]);
    },
    reset: function() {
      return [1, 0, 0, 1, 0, 0];
    },
    rotate: function(A, rad) {
      var c, s;
      c = Math.cos(rad);
      s = Math.sin(rad);
      return [A[0] * c + A[2] * s, A[1] * c + A[3] * s, -A[0] * s + A[2] * c, -A[1] * s + A[3] * c, A[4], A[5]];
    },
    translate: function(A, x, y) {
      return [A[0], A[1], A[2], A[3], A[0] * x + A[2] * y, A[1] * x + A[3] * y];
    },
    getCoords: function(A) {
      return [Math.round(A[0] + A[2]), Math.round(A[1] + A[3])];
    }
  };

  window.rotateRect = function(rad, x, y, L, W) {
    var c, s;
    L = L / 2;
    W = W / 2;
    c = Math.cos(rad);
    s = Math.sin(rad);
    return [
      {
        x: Math.round(x + L * c - W * s),
        y: Math.round(y + W * c + L * s)
      }, {
        x: Math.round(x - L * c - W * s),
        y: Math.round(y + W * c - L * s)
      }, {
        x: Math.round(x + L * c + W * s),
        y: Math.round(y - W * c + L * s)
      }, {
        x: Math.round(x - L * c + W * s),
        y: Math.round(y - W * c - L * s)
      }
    ];
  };

}).call(this);
