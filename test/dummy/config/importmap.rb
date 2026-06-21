# The dummy host's import map. Stimulus is pinned by the host (as in any Rails 8 app);
# the engine merges its own `pinnable` pin in via Pinnable::Engine's importmap initializer.
pin "application"
pin "@hotwired/stimulus", to: "stimulus.min.js"
