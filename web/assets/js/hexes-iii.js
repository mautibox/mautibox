(function () {
    var canvas = document.getElementById('canvas');

    if (canvas) {
        var ctx = canvas.getContext('2d');

        var width = 2560;
        var height = 720;

        var centerX = width * 0.5;
        var centerY = height * 0.5;
        var colors = ['#2962ff', '#304ffe', '#00b8d4', '#303f9f', '#536dfe'];

        canvas.width = width;
        canvas.height = height;

        var MAX_LINE_WIDTH = 1,
            SIZE = 25,
            OFFSET = SIZE / 5,
            ENEMY_RADIUS = 100,
            HEX_SIZE = SIZE / 2,
            MAX_SIZE = HEX_SIZE + OFFSET;

        var objs = [];
        var spacingX = SIZE + OFFSET;
        var spacingY = SIZE;
        var enemyObj = {
            x: centerX,
            y: centerY,
            r: ENEMY_RADIUS
        };

        function iterate(cb) {
            var i = 0;

            for (var y = 0; y < height + spacingY; y += spacingY) {
                var iY = y / spacingY % 2;

                for (var x = 0; x < width + spacingX; x += spacingX) {
                    var cX = x;
                    if (iY % 2 === 0) {
                        cX += spacingX / 2;
                    }

                    cb({
                        x: cX,
                        y: y,
                        i: i
                    });

                    i++;
                }
            }
        }

        function init() {
            if (!objs.length) {
                iterate(function (_ref) {
                    var x = _ref.x,
                        y = _ref.y,
                        i = _ref.i;

                    objs.push(newObj(x, y));
                });
            }
        }

        function animate() {
            window.requestAnimationFrame(animate);
            render();
        }

        function render() {
            ctx.clearRect(0, 0, width, height);

            reset();
            enemyLoop();

            iterate(function (_ref) {
                var i = _ref.i;

                var o = objs[i];

                if (isEnemy(o)) {
                    if (o.s < MAX_SIZE) {
                        o.s += 0.1;
                    }
                } else {
                    var d = new Date();
                    if (o.s < 0) {
                        o.s = Math.sin(d);
                    } else {
                        o.s -= 0.1;
                    }
                }

                drawHex(o);
            });
        }

        function isEnemy(hex) {
            var x = hex.x < enemyObj.x + enemyObj.r && hex.x > enemyObj.x - enemyObj.r;
            var y = hex.y < enemyObj.y + enemyObj.r && hex.y > enemyObj.y - enemyObj.r;
            return x && y;
        }

        function reset() {
            if (enemyObj.r > Math.max(width, height)) {
                enemyObj.r = 10;
            }

            if (enemyObj.x > width || enemyObj.x < 0) {
                enemyObj.x = centerX;
            }

            if (enemyObj.y > height || enemyObj.y < 0) {
                enemyObj.y = centerX;
            }
        }

        var angle = 0;

        function enemyLoop() {
            var a = Math.PI / 180 * angle;
            var x = centerX + Math.cos(a) * enemyObj.r;
            var y = centerY + Math.sin(a) * enemyObj.r;

            enemyObj.x = x;
            enemyObj.y = y;
            angle += 1;
            enemyObj.r += 1;
        }

        function drawHex(o) {
            ctx.beginPath();
            ctx.moveTo(o.x + o.s * Math.cos(o.r), o.y + o.s * Math.sin(o.r));

            for (var i = 1; i <= o.nS; i += 1) {
                var angle = (i * 2 * Math.PI / o.nS) + o.r;
                ctx.lineTo(o.x + o.s * Math.cos(angle), o.y + o.s * Math.sin(angle));
            }

            ctx.fillStyle = o.c;
            ctx.lineWidth = o.lW;
            ctx.fill();
        }

        function newObj(x, y) {
            return {
                nS: 6,
                s: HEX_SIZE,
                x: x,
                y: y,
                c: randomC(),
                r: 100,
                lW: MAX_LINE_WIDTH
            }
        }

        init();
        animate();

        function random(min, max) {
            min = Math.ceil(min);
            max = Math.floor(max);
            return Math.floor(Math.random() * (max - min + 1)) + min;
        }

        function randomC() {
            return colors[random(0, colors.length - 1)];
        }

        setTimeout(init, 3000);
    } else {
        console.warn('No #canvas element for hexes');
    }
})();
