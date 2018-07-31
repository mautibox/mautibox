'use strict';

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

/* jshint esversion: 6 */

(function (main) {
    var a = {};
    a.requestAnimationFrame = function () {
        return window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame || function (callback) {
                window.setTimeout(callback, 1000 / 60);
            };
    }();

    main(a, document, THREE);
})(function (window, document, three, a) {

    'use strict';

    var PI = Math.PI,
        SIN = Math.sin,
        COS = Math.cos;

    var CONFIG = {
        dimensions: {
            x: 0,
            y: 0
        },
        map: {
            width: 0,
            height: 0
        },
        camera: {
            fov: 120,
            nearPlane: 1,
            farPlane: 10000,
            aspectRatio: 0.7
        }
    };

    var App = function () {
        function App() {
            _classCallCheck(this, App);

            var self = this;
            self.tick = 0;
            self.props = JSON.parse(JSON.stringify(CONFIG));
            self.initCamera();
            self.initScene();
            self.initLights();
            self.initSphere();
            self.render();
            window.onresize = function () {
                self.setSize();
            };
        }

        _createClass(App, [{
            key: 'setSize',
            value: function setSize() {
                this.props.dimensions.x = window.innerWidth;
                this.props.dimensions.y = window.innerHeight;
                this.renderer.setSize(this.props.dimensions.x, this.props.dimensions.y);
                this.camera.aspect = this.props.camera.aspectRatio = this.props.dimensions.x / this.props.dimensions.y;
                this.camera.updateProjectionMatrix();
            }
        }, {
            key: 'initCamera',
            value: function initCamera() {
                this.camera = new three.PerspectiveCamera(this.props.camera.fov, this.props.camera.aspectRatio, this.props.camera.nearPlane, this.props.camera.farPlane);
            }
        }, {
            key: 'initScene',
            value: function initScene() {
                this.scene = new three.Scene();
                this.scene.add(this.camera);
                this.renderer = new THREE.WebGLRenderer({
                    alpha: true,
                    antialias: true
                });
                this.setSize();
                this.container = document.querySelector('.container');
                this.container.appendChild(this.renderer.domElement);
            }
        }, {
            key: 'initLights',
            value: function initLights() {
                this.mainLight = new three.HemisphereLight(0x000000, 0xffffff, 0.1);
                this.mainLight.position.set(0, -500, 0);
                this.scene.add(this.mainLight);

                this.ambientLight = new three.AmbientLight(0xd40000, 0.1);
                this.ambientLight.position.set(0, -100, 0);
                this.scene.add(this.ambientLight);
            }
        }, {
            key: 'initSphere',
            value: function initSphere() {
                var geom = new three.SphereGeometry(2000, 200, 50, 0, PI * 2, 0, PI * 2),
                    mat = new three.MeshNormalMaterial();
                geom.mergeVertices();
                this.sphere = new three.Mesh(geom, mat);
                this.sphere.rotation.x = PI / 2;
                this.scene.add(this.sphere);
            }
        }, {
            key: 'render',
            value: function render() {
                var self = this;
                self.update();
                self.renderer.render(self.scene, self.camera);
                window.requestAnimationFrame(self.render.bind(self));
            }
        }, {
            key: 'update',
            value: function update() {
                this.tick++;
                var delta = this.tick * 0.025;
                for (var i = 0, len = this.sphere.geometry.vertices.length; i < len; i++) {
                    var v = this.sphere.geometry.vertices[i],
                        dX = COS(delta + i),
                        dZ = SIN(delta + i);
                    v.x += dX;
                    v.z += dZ;
                }
                this.sphere.geometry.verticesNeedUpdate = true;
                this.sphere.rotation.x += 0.0025;
                this.sphere.rotation.y += 0.00125;
                this.sphere.rotation.z += 0.0025;
                this.mainLight.position.x = COS(delta) * 500;
                this.mainLight.position.y = SIN(delta) * 500;
            }
        }]);

        return App;
    }();

    window.onload = function () {
        var app = new App();
        console.log('loading?');
    };
});