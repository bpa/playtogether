'use strict';

angular.module('playtogether').controller('SpeedRiskCtl', ['$scope', '$document', '$http',
	function ($scope, $document, $http) {

		var armies, players, countries, stage, renderer, public_data, private_data, themes, state, id, backgroundImg;
		var country = [];

		var stage = new PIXI.Stage(0xFFFFFF, true);
		var renderer = PIXI.autoDetectRenderer(1200, 800, angular.element("canvas")[0]);
		renderer.view.style.width = '1200px';
		renderer.view.style.height = '800px';

		$document.bind('keydown', function (e) {
			if (e.which === 82) { // r
				$scope.ws.send({cmd: 'ready'});
			}
		});

		$scope.$on('join', on_join);
		$scope.$on('not ready', function (event, data) {
			players[data.player].ready = false;
		});
		$scope.$on('ready', function (event, data) {
			players[data.player].ready = true;
		});
		$scope.$on('status', on_status);
		$scope.$on('theme', function (event, data) {
			players[data.player].theme = data.theme;
		});
		$scope.$on('armies', function (event, data) {
			armies = data.armies;
		});
		$scope.$on('placing', function (event, data) {
			for (var p in players) {
				players[p].ready = false;
			}
			countries = data.countries;
		});

		$http.get('g/SpeedRisk/themes.json').success(initialize_themes);
		socket.send({cmd: 'status'});

		function animate() {
			var c = public_data.countries[i];
			if (players[c.owner].dirty) {
				t = country[i];
				t.sprite.setTexture(PIXI.Texture.fromFrame(t.theme + '_' + c.name));
				t.token.setTexture(PIXI.Texture.fromFrame(t.theme + '_icon'));
			}
			requestAnimFrame(animate);
			renderer.render(stage);
		}

		function onAssetsLoaded() {
			var background = PIXI.Sprite.fromFrame(backgroundImg);
			background.position.x = 0;
			background.position.y = 0;
			stage.addChild(background);

			for (var i in public_data.countries) {
				var c = public_data.countries[i];
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
				country[i] = t;
			}

			var quit = button('quit', background.width, background.height, 1, 1);
			quit.click = quit.tap = function () {
				if (confirm('Are you sure you want to quit?')) {
					$scope.ws.send({cmd: 'quit'});
				}
			};

			stage.addChild(quit);
			requestAnimFrame(animate);
		}

		function overlay(id, image, loc) {
			var sprite = PIXI.Sprite.fromFrame(image);
			sprite.position.x = loc.x;
			sprite.position.y = loc.y;
			stage.addChild(sprite);
			sprite.interactive = true;
			sprite.hitArea = new Country(loc, image);
			sprite.click = sprite.tap = function (e) {
				if (e.originalEvent.altKey === true && public_data.countries[id].owner === id) {
					console.log({cmd: 'place', country: id, armies: private_data.armies});
					$scope.ws.send({cmd: 'place', country: id, armies: private_data.armies});
				}
				else {
					console.log({cmd: 'select', country: id, armies: private_data.armies});
				}
			};
			return sprite;
		}

		function updateCountries() {
			for (var i in public_data.countries) {
				var c = public_data.countries[i];
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
			public_data = data.public;
			private_data = data.private;
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
				var ui = this;
				loader.onComplete = function () {
					ui.onAssetsLoaded();
				};
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

		Object.defineProperty(Player.prototype, "theme", {
			set: function (theme) {
				this.theme = theme;
				this.dirty = true;
			}
		});

		function Country(loc, image) {
			this.image = image;
			this.texture = PIXI.Texture.fromFrame(image);
			this.x = loc.x;
			this.y = loc.y;
			this.h = this.texture.height;
			this.w = this.texture.width;
		}

		Country.prototype.contains = function (x, y) {
			if (w <= 0 || h <= 0)
				return false;

			var x1 = x - x;
			if (x1 < 0 || x1 > w)
				return false;

			//console.log(x, y);
			var y1 = y - y;
			if (y1 < 0 || y1 > h)
				return false;

			//console.log(x, y, x, y, x1, y1, image);
			//console.log(texture.frame, texture.baseTexture);
			return true;
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
		}

	}]);
