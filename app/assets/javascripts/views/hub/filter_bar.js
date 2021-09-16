var TW = TW || {};
TW.workbench = TW.workbench || {};
TW.workbench.hub = TW.workbench.hub || {};
TW.workbench.hub.filter_hub = TW.workbench.hub.filter_hub || {};

Object.assign(TW.workbench.hub.filter_hub, {

  init: function () {
    if (!$("#filter").attr('icons-loaded')) { 
      const FILTER_TYPES = [...document.querySelectorAll('#filter .category-filter [data-filter-category]')]
        .map(element =>
          element.getAttribute('data-filter-category'))

      FILTER_TYPES.forEach(type => {
        const iconElement = document.createElement('span')
        const categoryElement = document.querySelector(`[data-filter-category="${type}"]`)

        iconElement.classList.add(
          'margin-small-right',
          'filter-category-icon',
          type
        )
        categoryElement.prepend(iconElement);
      })

      $("#filter").attr('icons-loaded', 'true');
    }

    function deactivateBackgroundColorLink(selector) {
      $(selector).removeClass("activated");
    }

    function activateBackgroundColorLink(selector) {
      $(selector).addClass("activated");
    }

    function changeBackgroundColorLink(selector) {
      if ($(selector).hasClass("activated")) {
        deactivateBackgroundColorLink(selector);
      }
      else {
        activateBackgroundColorLink(selector);
      }
    }

    $('#filter [data-filter-category]').on('click', function () {
      if(!$(this).parent().hasClass('navigation-controls-type')) {
        changeBackgroundColorLink('[data-filter-category="' + $(this).attr("data-filter-category") + '"]');
      }
    });

    $('#filter .filter-category [data-filter-category]').on('click', function () {
      var hasClass = $(this).hasClass("activated");
      deactivateBackgroundColorLink('.filter-category [data-filter-category]');
      if (hasClass) {
        $('.status-name').text($(this).data("filter-category"));
        $('.status-name').css("color", $(this).css("background-color"));
        activateBackgroundColorLink('[data-filter-category="' + $(this).attr("data-filter-category") + '"]');
      }
      else {
        restartFilterStatus();
      }
    });


    //Add classes for cards when the filter status is active
    $('#filter .switch input').on('click', function () {
      if ($(this).is(':checked')) {
        $('.filter-category').css('display', 'flex');
        $('.filter-category').hide();
        $('.filter-category').show("slide", { direction: "left" }, 250);
        $('.filter-category').fadeIn(250);
        $('.filter_data').each(function () {
          if ($(this).children().length > 0) {
            $(this).addClass("categories");
          }
        });
      }
      else {
        restartFilterStatus();
        deactivateBackgroundColorLink('.filter-category [data-filter-category]');
        $('.filter-category').hide("slide", {direction: "left"}, 500);

        $('.filter_data').each(function () {
          $(this).removeClass("categories");
          $(this).removeClass("status");
        });
      }
    });

    function restartFilterStatus() {
      $('.status-name').css("color", "");
      $('.status-name').text("Status");
    }

    $('#filter [data-filter-category="reset"]').on('click', function () {
      restartFilterStatus();
      deactivateBackgroundColorLink('[data-filter-category]');
    });

    $('.reset-all-filters').on('click', function () {
      restartFilterStatus();
      deactivateBackgroundColorLink('[data-filter-category]');
    });
  }
});

$(document).on('turbolinks:load', function () {
  if ($("#filter").length) {
    TW.workbench.hub.filter_hub.init();
  }
});
