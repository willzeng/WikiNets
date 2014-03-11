$(document).ready(function() {
  var numbers, countries, repos, arabic, nba, nhl, films, anExcitedSource;

  films = new Bloodhound({
    datumTokenizer: function(d) { return Bloodhound.tokenizers.whitespace(d.value); },
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: '../data/films/queries/%QUERY.json',
    prefetch: '../data/films/post_1960.json'
  });

  films.initialize();

  $('.example-films .typeahead').typeahead(null, {
    displayKey: 'value',
    source: films.ttAdapter(),
    templates: {
      suggestion: Handlebars.compile(
        '<p><strong>{{value}}</strong> – {{year}}</p>'
      )
    }
  });
});
