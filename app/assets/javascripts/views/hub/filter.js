var TW = TW || {};
TW.views = TW.views || {};
TW.views.hub = TW.views.hub || {};
TW.views.hub.filter = TW.views.hub.filter || {};

Object.assign(TW.views.hub.filter, {
	filterHubTask: undefined,
	init: function() {
		if(!$("#filter").attr('loaded') == true) { 
			$("#filter").attr('loaded', 'true');
			this.filterHubTask = new FilterHub();
			if(document.querySelector('#task_carrousel')) {
				this.resizeTaskCarrousel();
			}
			this.loadCategoriesIcons();
			this.handleEvents();
		}
	},

	resizeTaskCarrousel() {
		var userWindowWidth = $(window).width();
		var userWindowHeight = $(window).height();
		var minWindowWidth = ($("#favorite-page").length ? 1000 : 700);
		var cardWidth = 427.5;
		var cardHeight = 180;

		var tmpHeight = userWindowHeight - document.querySelector('.task-section').offsetTop
		tmpHeight = tmpHeight / cardHeight

		if(userWindowWidth < minWindowWidth) {
			if($("#favorite-page").length)
				this.filterHubTask.changeTaskSize(1)
			else
				this.filterHubTask.changeTaskSize(1, Math.floor(tmpHeight))
		}
		else {
			var tmp = userWindowWidth - minWindowWidth

			tmp = tmp / cardWidth
			if(tmp > 0) {
				if($("#favorite-page").length)
					this.filterHubTask.changeTaskSize(Math.ceil(tmp))
				else 
					this.filterHubTask.changeTaskSize(Math.ceil(tmp), Math.floor(tmpHeight))
			}
		}
	},

	handleEvents: function() {
		var that = this
		window.addEventListener("resize", function(){ that.resizeTaskCarrousel() })
	},

	loadCategoriesIcons: function () {
		const DATE_TYPES = [
			'collecting_event',
			'nomenclature',
			'collection_object',
			'source',
			'biology',
			'matrix',
			'dna',
			'image'
		]
		
		DATE_TYPES.forEach(type => {
			const elements = [...document.querySelectorAll(`.data_card [data-category-${type}]`)]

			elements.forEach(element => {
				const iconElement = document.createElement('span')

				iconElement.classList.add(
					'filter-category-icon',
					type
				)
				element.append(iconElement)
			})
		})
	}
});


$(document).on('turbolinks:load', function() {
	if($("#data_cards").length || $("#task_carrousel").length) {
		TW.views.hub.filter.init();
	}
});
