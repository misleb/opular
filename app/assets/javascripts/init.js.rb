Document.ready? do
  # opal-browser code to add a button
  $document[".home-index"] << DOM do
    button.show_irb! "Show Irb"
  end

  # opal-jquery code to add a button
  Element.find(".main").append "<button class='btn' id='show_irb'>Show Irb</button>"

  # creates a panel at the bottom
  OpalIrbJqconsole.create_bottom_panel(hidden=true)
  # adds open panel behavior to element w/id show_irb
  OpalIrbJqconsole.add_open_panel_behavior("show_irb")

  OpularRB.boot

  # Temporary until I figure out how to bootstrap this monster
  $opular_injector = Op::Injector.new(['op', ->(_root_scope_provider) { _root_scope_provider.digest_ttl(19) }])


  HomeView.new
  puts "Ready!"
end
