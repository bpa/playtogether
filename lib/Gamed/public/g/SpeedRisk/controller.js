'use strict';

angular.module('playtogether').controller('SpeedRiskCtl', ['$scope', '$document', '$http', '$modal',
    function ($scope, $document, $http, $modal) {

        var players, country, stage, renderer, themes, state, id, backgroundImg, assetsLoaded, hud, pub, selected;
		$scope.availableThemes = [];

        $scope.stateMap = {
            WaitingForPlayers: {text: "Waiting for players", class: "alert-danger"},
            Placing: {text: "Place initial armies", class: "alert-warning"},
            Playing: {text: "At War", class: "alert-success", hide: true},
            GameOver: {text: "Game Over", class: "alert-default", hide: true},
        };

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
            hud.update();
        });
        $scope.$on('ready', function (event, data) {
            players[data.player].ready = true;
            if (data.player === id)
                $scope.ready = true;
            hud.update();
        });
        $scope.$on('status', on_status);
        $scope.$on('theme', function (event, data) {
            players[data.player].theme = data.theme;
            players[data.player].dirty = true;
            hud.update();
        });
        $scope.$on('armies', function (event, data) {
            $scope.private.armies = data.armies;
        });
		$scope.$on('theme', function (event, data) {
			var p = players[data.player];
			pub.themes[p.theme] = null;
			p.theme = data.theme;
			p.dirty = true;
			pub.themes[p.theme] = p.id;
			updateAvailableThemes();
			hud.update();
			$scope.theme = data.theme;
		});
        $scope.$on('placing', function (event, data) {
            for (var p in players) {
                players[p].ready = false;
            }
            hud.update();
            $scope.state = 'Placing';
            $scope.ready = false;
            pub.countries = data.countries;
            updateCountries();
        });
		$scope.$on('playing', function (event, data) {
			$scope.state = 'Playing';
		});
        $scope.$on('country', function (event, data) {
            var c = pub.countries[parseInt(data.country.id)];
            c.armies = data.country.armies;
            c.owner = data.country.owner;
            updateCountries();
        });
        $scope.$on('move', move_or_attack_result);
        $scope.$on('attack', move_or_attack_result);
		$scope.$on('victory', function (event, data) {
			$scope.state = 'GameOver';
		});

        function move_or_attack_result(event, data) {
            for (var i = 0; i < 2; i++) {
                var c = pub.countries[parseInt(data.result[i].country)];
                c.armies = data.result[i].armies;
                c.owner = data.result[i].owner;
            }
            if (data.result[0].country == selected && data.result[1].owner == id) {
				set_selected(data.result[1].country);
            }
            updateCountries();
        }

		function set_selected(cid) {
			if (selected !== undefined)
				country[selected].sprite.blendMode = PIXI.blendModes.NORMAL;
			selected = cid;
			country[selected].sprite.blendMode = PIXI.blendModes.ADD;
		}

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
                for (var i = 0; i < pub.countries.length; i++) {
                    var c = pub.countries[i];
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

			var tokens = [];
			var armies = [];
            for (var i in pub.countries) {
                var c = pub.countries[i];
                var t = {};
                t.owner = c.owner === undefined ? id : c.owner;
                var theme = players[t.owner].theme;
                t.sprite = overlay(i, theme + '_' + c.name, c.sprite);
            	stage.addChild(t.sprite);
                t.token = overlay(i, theme + '_icon', c.token);
				tokens.push(t.token);
                t.token.anchor.x = t.token.anchor.y = 0.5;
                t.armies = new PIXI.Text(c.armies === undefined ? '' : c.armies, {font: '12px Arial', fill: themes[theme]['text-color'], strokeThickness: 3});
                t.armies.position.x = c.token.x;
                t.armies.position.y = c.token.y;
                t.armies.anchor.x = t.token.anchor.y = 0.5;
				armies.push(t.armies);
                new_countries[i] = t;
            }
			for (var i=0; i<tokens.length; i++) {
            	stage.addChild(tokens[i]);
                stage.addChild(armies[i]);
			}
            country = new_countries;
            hud = new Hud(background.height);
            stage.addChild(hud);

            requestAnimFrame(animate);
        }

        function overlay(c_id, image, loc) {
            var sprite = PIXI.Sprite.fromFrame(image);
            sprite.position.x = loc.x;
            sprite.position.y = loc.y;
            sprite.interactive = true;
            sprite.hitArea = new Country(loc, image);
            sprite.click = sprite.tap = function (e) {
                var c = pub.countries[c_id];
                var owned = c.owner == id;
                if (e.originalEvent.ctrlKey === true && owned) {
                    $scope.ws.send({cmd: 'place', country: c_id, armies: $scope.private.armies});
                }
                else {
                    if (c.borders[selected]) {
                        var armies = pub.countries[selected].armies - $scope.defense;
						if (armies > 0)
							$scope.ws.send({cmd: 'move', from: selected, to: c_id, armies: armies});
                    }
                }
				if (owned)
					set_selected(c_id);
            };
            return sprite;
        }

        function updateCountries() {
            if (country === undefined)
                return;

            for (var i in pub.countries) {
                var c = pub.countries[i];
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
                hud.update();
            }
        }

        function on_status(event, data) {
            if (data === undefined)
                return;

            $scope.state = data.state;
            id = data.id;
            pub = data.public;
            $scope.private = data.private;
            players = {};
            for (var p in data.players) {
                players[p] = new Player(data.players[p]);
            }
			updateAvailableThemes();
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
                if (hud !== undefined)
                    hud.update();
            }
        }

        function initialize_themes(data) {
			$scope.themes = [];
            themes = data;
            for (var t in themes) {
				$scope.themes.push({id: t, name: themes[t].name});
                if (themes[t]['text-color'] === undefined)
                    themes[t]['text-color'] = '#fff';
                if (themes[t]['text-color'][0] !== '#') {
                    themes[t]['text-color'] = '#' + themes[t]['text-color'];
                }
            }
			updateAvailableThemes();
        }
		
		function updateAvailableThemes() {
			$scope.availableThemes = [];
			if ($scope.themes !== undefined) {
				for (var i = 0; i < $scope.themes.length; i++) {
					var t = $scope.themes[i];
					if (pub.themes[t.id] === null || pub.themes[t.id] == id)
						$scope.availableThemes.push(t);
					if (pub.themes[t.id] == id)
						$scope.theme = t.id;
				}
			}
		}
		
		$scope.changeTheme = function() {
			$scope.ws.send({cmd: 'theme', theme: $scope.theme});
		}

        //------------- Objects ------------------//
        function Player(data) {
            for (var k in data) {
                this[k] = data[k];
            }
            this.id = parseInt(this.id);
            this.dirty = true;
        }

        function Hud(bottom) {
            PIXI.DisplayObjectContainer.call(this);
            this._slots = [];
            this._pad_bottom = bottom - 10;
            this.update();
        }

        Hud.prototype = Object.create(PIXI.DisplayObjectContainer.prototype);
        Hud.prototype.constructor = Hud;

        Hud.prototype.update = function () {
            var existing = {}, i;
            for (i = 0; i < this._slots.length; i++) {
                var p = this._slots[i];
                if (p.id in players) {
                    existing[p.id] = 1;
                }
                else {
                    this._slots.splice(i, 1);
                    i--;
                }
            }
            for (var p in players) {
                if (!(p in existing))
                    this.make_player_row(p);
//				if (players[p].dirty) {
//					for (var i=0; i<this._slots.length; i++) {
//						var s = this._slots[i];
//						s.theme = players[p].theme;
//						if (s.id == p) {
//							console.log(s, players[p]);
//							s.panel.setTexture(PIXI.Texture.fromFrame(players[p].theme + '_background'));
//						}
//					}
//				}
            }
            for (i = 0; i < this._slots.length; i++) {
                var e = this._slots[i];
                var p = players[e.id];
                if (e.ready != p.ready) {
                    e.readyText.setText(e.ready ? "(/)" : "(X)");
                }
                e.panel.y = i * 25;
            }
            this.position = new PIXI.Point(10, this._pad_bottom - this.height);
        };

        Hud.prototype.make_player_row = function (p) {
            var e = JSON.parse(JSON.stringify(players[p]));
			if (e.theme !== undefined) {
				e.panel = new PIXI.TilingSprite(PIXI.Texture.fromFrame(e.theme + "_background"), 150, 25);
				this.addChild(e.panel);
			}
			else {
				return;
			}
            e.readyText = new PIXI.Text(e.ready ? "(/)" : "(X)", {font: "15px Ariel", fill: themes[e.theme]['text-color'], strokeThickness: 3});
            e.readyText.x = 5;
            e.readyText.y = 5;
            e.panel.addChild(e.readyText);
            var nameText = new PIXI.Text(e.name, {font: "15px Ariel", fill: themes[e.theme]['text-color'], strokeThickness: 3});
            nameText.x = 30;
            nameText.y = 5;
            e.panel.addChild(nameText);
            this._slots.push(e);
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
