'use strict';

angular.module('playtogether').controller('SpeedRiskCtl', ['$scope', '$document', '$http', '$modal',
    function ($scope, $document, $http, $modal) {

        var players, country, countries, stage, renderer, themes, state, id, backgroundImg, assetsLoaded;

        $scope.$on('$routeChangeSuccess', function () {
            assetsLoaded = false;
            $http.get('g/SpeedRisk/themes.json').success(initialize_themes);
            $scope.ws.send({cmd: 'status'});
        });

        $scope.$on('join', on_join);
        $scope.$on('not ready', function (event, data) {
            players[data.player].ready = false;
            if (data.player === id)
                $scope.ready = false;
            update_hud();
        });
        $scope.$on('ready', function (event, data) {
            players[data.player].ready = true;
            if (data.player === id)
                $scope.ready = true;
            update_hud();
        });
        $scope.$on('status', on_status);
        $scope.$on('theme', function (event, data) {
            players[data.player].theme = data.theme;
            players[data.player].dirty = true;
        });
        $scope.$on('armies', function (event, data) {
            $scope.private.armies = data.armies;
        });
        $scope.$on('placing', function (event, data) {
            for (var p in players) {
                players[p].ready = false;
            }
            $scope.ready = false;
            countries = data.countries;
        });

        $scope.quit = function () {
            $modal.open({
                animation: true,
                templateUrl: 'quit.html',
                size: 'sm',
                controller: function ($scope, $modalInstance) {
                    $scope.ok = function () {
                        $scope.ws.send({cmd: 'quit'});
                        $modalInstance.close(true);
                    };
                    $scope.cancel = function () {
                        $modalInstance.dismiss(false);
                    };
                }
            });
        };

        function animate() {
            if (assetsLoaded) {
                for (var i = 0; i < $scope.public.countries.length; i++) {
                    var c = $scope.public.countries[i];
                    var owner = players[c.owner];
                    if (owner !== undefined && owner.dirty) {
                        var t = country[i];
                        t.sprite.setTexture(PIXI.Texture.fromFrame(owner.theme + '_' + c.name));
                        t.token.setTexture(PIXI.Texture.fromFrame(owner.theme + '_icon'));
                    }
                }
            }
            requestAnimFrame(animate);
            renderer.render(stage);
        }

        function onAssetsLoaded() {
            assetsLoaded = true;
            stage = new PIXI.Stage(0xFFFFFF, true);
            renderer = PIXI.autoDetectRenderer(1600, 1600, angular.element("canvas")[0]);
            renderer.view.style.position = "absolute";
            renderer.view.style.width = window.innerWidth + "px";
            renderer.view.style.height = window.innerHeight + "px";
            renderer.view.style.display = "block";
            angular.element("[ng-controller=SpeedRiskCtl]")[0].appendChild(renderer.view);

            renderer.view.style.width = '1600px';
            renderer.view.style.height = '1600px';

            $scope.toggleReady = function () {
                $scope.ws.send({cmd: $scope.ready ? 'not ready' : 'ready'});
            };

            var background = PIXI.Sprite.fromFrame(backgroundImg);
            var new_countries = [];
            background.position.x = 0;
            background.position.y = 0;
            stage.addChild(background);

            for (var i in $scope.public.countries) {
                var c = $scope.public.countries[i];
                var t = {};
                t.owner = c.owner === undefined ? id : c.owner;
                var theme = players[t.owner].theme;
                t.sprite = overlay(i, theme + '_' + c.name, c.sprite);
                t.token = overlay(i, theme + '_icon', c.token);
                t.token.anchor.x = t.token.anchor.y = 0.5;
                t.armies = new PIXI.Text(c.armies === undefined ? '' : c.armies, {font: '12px Arial', fill: themes[theme]['text-color']});
                t.armies.position.x = c.token.x;
                t.armies.position.y = c.token.y;
                t.armies.anchor.x = t.token.anchor.y = 0.5;
                stage.addChild(t.armies);
                new_countries[i] = t;
            }
            country = new_countries;

            requestAnimFrame(animate);
        }

        function overlay(c_id, image, loc) {
            var sprite = PIXI.Sprite.fromFrame(image);
            sprite.position.x = loc.x;
            sprite.position.y = loc.y;
            stage.addChild(sprite);
            sprite.interactive = true;
            sprite.hitArea = new Country(loc, image);
            sprite.click = sprite.tap = function (e) {
                if (e.originalEvent.ctrlKey === true && $scope.public.countries[c_id].owner == id) {
                    $scope.ws.send({cmd: 'place', country: c_id, armies: $scope.private.armies});
                }
                else {
                    console.log({cmd: 'select', country: c_id});
                }
            };
            return sprite;
        }

        function updateCountries() {
            if (country === undefined)
                return;

            for (var i in $scope.public.countries) {
                var c = $scope.public.countries[i];
                if (c.armies !== undefined) {
                    country[i].armies.setText(c.armies);
                }
                var t = country[i];
                if (t.owner !== c.owner && c.owner !== undefined) {
                    t.owner = c.owner;
                    var theme = players[t.owner].theme;
                    t.sprite.setTexture(PIXI.Texture.fromFrame(theme + '_' + c.name));
                    t.token.setTexture(PIXI.Texture.fromFrame(theme + '_icon'));
                }
            }
        }

        function on_join(event, player) {
            if (players === undefined) {
                $scope.ws.send({cmd: 'status'});
            }
            else {
                players[player.player] = new Player(player);

            }
        }

        function on_status(event, data) {
            if (data === undefined)
                return;

            state = data.state;
            id = data.id;
            $scope.public = data.public;
            $scope.private = data.private;
            players = {};
            for (var p in data.players) {
                players[p] = new Player(data.players[p]);
            }
            if (backgroundImg === undefined) {
                backgroundImg = "g/SpeedRisk/" + data.public.rules.board + "/board.png";
                var assets = [backgroundImg, "g/SpeedRisk/images/img.json"];
                for (var theme in data.public.themes) {
                    assets.push('g/SpeedRisk/' + data.public.rules.board + '/' + theme + '.json');
                }
                var loader = new PIXI.AssetLoader(assets);
                loader.onComplete = onAssetsLoaded;
                loader.load();
            }
            else {
                updateCountries();
            }
        }

        function initialize_themes(data) {
            themes = data;
            for (var t in themes) {
                if (themes[t]['text-color'] === undefined)
                    themes[t]['text-color'] = 'fff';
                if (themes[t]['text-color'][0] !== '#') {
                    themes[t]['text-color'] = '#' + themes[t]['text-color'];
                }
            }
        }

        //------------- Objects ------------------//
        function Player(data) {
            for (var k in data) {
                this[k] = data[k];
            }
            this.dirty = true;
        }

        function Country(loc, image) {
            this.images = image;
            this.texture = PIXI.Texture.fromFrame(image);
            this.x = loc.x;
            this.y = loc.y;
            this.w = this.texture.width;
            this.h = this.texture.height;
        }

        Country.prototype.contains = function (x, y) {
            if (this.w <= 0 || this.h <= 0)
                return false;

            var p = stage.interactionManager.mouse.getLocalPosition(stage);
            var x1 = p.x - this.x;
            if (x1 < 0 || x1 > this.w)
                return false;

            var y1 = p.y - this.y;
            if (y1 < 0 || y1 > this.h)
                return false;

            var base = this.texture.baseTexture;
            if (!base.canvas) {
                base.canvas = document.createElement("canvas");
                base.canvas.width = base.width;
                base.canvas.height = base.height;
                base.canvas.getContext('2d').drawImage(base.source, 0, 0, base.width, base.height);
            }

            return base.canvas.getContext('2d').getImageData(x1 + this.texture.crop.x, y1 + this.texture.crop.y, 1, 1).data[3] > 0;
        };

        function button(type, x, y, anchor_x, anchor_y) {
            var textureBase = PIXI.Texture.fromFrame(type);
            var textureHover = PIXI.Texture.fromFrame(type + '_hover');
            var texturePressed = PIXI.Texture.fromFrame(type + '_pressed');
            var button = new PIXI.Sprite(textureBase);
            button.buttonMode = true;
            if (anchor_x !== undefined)
                button.anchor.x = anchor_x;
            if (anchor_y !== undefined)
                button.anchor.y = anchor_y;
            button.position.x = x;
            button.position.y = y;
            button.interactive = true;

            button.mouseover = function (data) {
                this.isOver = true;
                if (isdown)
                    return;
                setTexture(textureHover);
            };

            button.mouseout = function (data) {
                this.isOver = false;
                if (isdown)
                    return;
                setTexture(textureBase);
            };

            button.mousedown = button.touchstart = function (data) {
                this.isdown = true;
                setTexture(texturePressed);
            };

            button.mouseup = button.touchend = button.mouseupoutside = button.touchendoutside = function (data) {
                this.isdown = false;
                if (isOver)
                    setTexture(textureHover);
                else
                    setTexture(textureBase);
            };

            return button;
        }

    }]);
