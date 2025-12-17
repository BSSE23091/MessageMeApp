//= require jquery
//= require semantic-ui
//= require_tree .

// Initialize Semantic UI dropdowns once Turbolinks loads the page
$(document).on("turbolinks:load", function () {
  $(".ui.dropdown").dropdown();
});
